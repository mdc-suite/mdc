/*
 * Copyright (c) 2010, EPFL
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 *   * Redistributions of source code must retain the above copyright notice,
 *     this list of conditions and the following disclaimer.
 *   * Redistributions in binary form must reproduce the above copyright notice,
 *     this list of conditions and the following disclaimer in the documentation
 *     and/or other materials provided with the distribution.
 *   * Neither the name of the EPFL nor the names of its contributors may be used 
 *     to endorse or promote products derived from this software without specific 
 *     prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 * WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */
package net.sf.orcc.tools.merger.actor;

import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;

import net.sf.orcc.df.Action;
import net.sf.orcc.df.Actor;
import net.sf.orcc.df.Connection;
import net.sf.orcc.df.Network;
import net.sf.orcc.df.Port;
import net.sf.orcc.graph.Vertex;
import net.sf.orcc.graph.visit.ReversePostOrder;
import net.sf.orcc.moc.CSDFMoC;
import net.sf.orcc.moc.Invocation;
import net.sf.orcc.moc.MoC;

/**
 * This class computes a single appearance schedule (SAS) with 1-level nested
 * loop from the given SDF graph.
 * 
 * @author Ghislain Roquier
 * 
 */
public class SASLoopScheduler {

	private int depth;

	private int maxDepth;

	protected Map<Connection, Integer> maxTokens;

	protected Network network;

	protected Map<Actor, Integer> repetitions;

	protected Schedule schedule;

	Map<Connection, Integer> tokens;

	public SASLoopScheduler(Network network) {
		this.network = network;
		this.repetitions = new RepetitionsAnalyzer(network).getRepetitions();
	}

	/**
	 * @param schedule
	 */
	private void computeDepth(Schedule schedule) {
		for (Iterand iterand : schedule.getIterands()) {
			if (iterand.isSchedule()) {
				depth++;
				computeDepth(iterand.getSchedule());
				depth--;
			} else {
				maxDepth = Math.max(depth, maxDepth);
			}
		}
	}

	/**
	 * @param schedule
	 */
	private void computeMemoryBound(Schedule schedule) {
		for (Iterand iterand : schedule.getIterands()) {
			if (iterand.isAction()) {
				Action action = iterand.getAction();
				for (Port port : action.getInputPattern().getPorts()) {
					Connection connection = ((Actor) action.eContainer())
							.getIncomingPortMap().get(port);
					if (connection.getSourcePort() != null) {
						tokens.put(connection, tokens.get(connection)
								- action.getInputPattern().getNumTokens(port));
					}
				}

				for (Port port : action.getOutputPattern().getPorts()) {

					for (Connection connection : ((Actor) action.eContainer())
							.getOutgoingPortMap().get(port)) {
						if (connection.getTargetPort() != null) {
							int current = tokens.get(connection);
							int max = maxTokens.get(connection);
							int prd = action.getOutputPattern().getNumTokens(
									port);
							tokens.put(connection, current + prd);
							if (max < current + prd) {
								maxTokens.put(connection, current + prd);
							}
						}
					}
				}
			} else {
				int count = iterand.getSchedule().getIterationCount();
				while (count != 0) {
					computeMemoryBound(iterand.getSchedule());
					count--;
				}
			}
		}

	}

	/**
	 * 
	 * @return
	 */
	public int getDepth() {
		depth = maxDepth = 0;
		computeDepth(schedule);
		return maxDepth;
	}

	/**
	 * @return
	 */
	public Map<Connection, Integer> getMaxTokens() {
		if (maxTokens == null) {
			maxTokens = new HashMap<Connection, Integer>();
			tokens = new HashMap<Connection, Integer>();

			for (Connection connection : network.getConnections()) {
				Actor src = connection.getSource().getAdapter(Actor.class);
				Actor tgt = connection.getTarget().getAdapter(Actor.class);
				if (src != null && tgt != null)
					maxTokens.put(connection, 0);
				tokens.put(connection, 0);
			}
			computeMemoryBound(schedule);
		}
		return maxTokens;
	}

	/**
	 * Returns the repetition factor associated with the given actor.
	 * 
	 * @param actor
	 *            the given actor
	 * @return the repetition factor associated
	 */
	public int getRepetitions(Actor actor) {
		return repetitions.get(actor);
	}

	/**
	 * Returns the scheduling computed by this scheduler.
	 * 
	 * @return the pre-computed schedule
	 */
	public Schedule getSchedule() {
		return schedule;
	}

	private Schedule getScheduleFromCsdf(Actor actor, int repetition) {
		Schedule schedule = new Schedule();
		schedule.setIterationCount(repetition);
		Iterator<Invocation> it = ((CSDFMoC) actor.getMoC()).getInvocations()
				.iterator();

		Invocation current = it.next();
		int iterationCount = 1;
		while (it.hasNext()) {
			Action action = current.getAction();
			Invocation next = it.next();
			if (current.getAction().equals(next.getAction())) {
				iterationCount++;
			} else {
				if (iterationCount == 1) {
					schedule.add(new Iterand(action));
				} else {
					Schedule sub = new Schedule();
					sub.setIterationCount(iterationCount);
					sub.add(new Iterand(action));
					schedule.add(new Iterand(sub));
				}
				iterationCount = 1;
			}
			current = next;
		}

		if (iterationCount == 1) {
			schedule.add(new Iterand(current.getAction()));
		} else {
			Schedule sub = new Schedule();
			sub.setIterationCount(iterationCount);
			sub.add(new Iterand(current.getAction()));
			schedule.add(new Iterand(sub));
		}

		return schedule;
	}

	/**
	 * Schedules the given network in-place.
	 */
	public void schedule() {
		schedule = new Schedule();

		schedule.setIterationCount(1);

		for (Vertex vertex : new ReversePostOrder(network, network.getInputs())) {
			Actor actor = vertex.getAdapter(Actor.class);
			if (actor != null) {
				int rep = repetitions.get(actor);
				Iterand iterand = null;
				MoC moc = actor.getMoC();
				if (rep > 1) {
					Schedule subSched = new Schedule();
					subSched.setIterationCount(repetitions.get(actor));
					if (moc.isSDF()) {
						subSched.add(new Iterand(actor.getActions().get(0)));
					} else {
						subSched = getScheduleFromCsdf(actor,
								repetitions.get(actor));
					}
					iterand = new Iterand(subSched);
				} else {
					if (moc.isSDF()) {
						iterand = new Iterand(actor.getActions().get(0));
					} else { // it's sdf
						iterand = new Iterand(getScheduleFromCsdf(actor, 1));
					}
				}
				schedule.add(iterand);
			}
		}
	}

}
