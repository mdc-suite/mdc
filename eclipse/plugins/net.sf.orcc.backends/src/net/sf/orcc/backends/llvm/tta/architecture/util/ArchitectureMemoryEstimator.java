/*
 * Copyright (c) 2012, IRISA
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
 *   * Neither the name of the IETR/INSA of Rennes nor the names of its
 *     contributors may be used to endorse or promote products derived from this
 *     software without specific prior written permission.
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
package net.sf.orcc.backends.llvm.tta.architecture.util;

import net.sf.orcc.backends.llvm.tta.architecture.Design;
import net.sf.orcc.backends.llvm.tta.architecture.Memory;
import net.sf.orcc.backends.llvm.tta.architecture.Processor;
import net.sf.orcc.backends.util.BackendUtil;
import net.sf.orcc.df.Action;
import net.sf.orcc.df.Actor;
import net.sf.orcc.df.Connection;
import net.sf.orcc.df.Instance;
import net.sf.orcc.df.util.DfVisitor;
import net.sf.orcc.graph.Vertex;
import net.sf.orcc.ir.Procedure;
import net.sf.orcc.ir.Type;
import net.sf.orcc.ir.TypeList;
import net.sf.orcc.ir.Var;
import net.sf.orcc.ir.util.AbstractIrVisitor;
import net.sf.orcc.util.OrccLogger;

/**
 * The class defines an estimator of the quantity of memory needed by an design
 * after the projection of an application on this design.
 * 
 * @author Herve Yviquel
 */
public class ArchitectureMemoryEstimator extends ArchitectureVisitor<Void> {

	final double ERROR_MARGIN = 0.4;

	/**
	 * The class defines a Network visitor used to evaluate the memory needs of
	 * the given dataflow entities.
	 */
	private class InnerDfVisitor extends DfVisitor<Long> {
		private int fifosize = 0;
		
		private class InnerIrVisitor extends AbstractIrVisitor<Long> {

			@Override
			public Long caseProcedure(Procedure procedure) {
				long bits = 0;
				for (Var local : procedure.getLocals()) {
					bits += doSwitch(local);
				}
				return bits;
			}

			@Override
			public Long caseVar(Var var) {
				return (long) getSize(var.getType());
			}

		}

		public InnerDfVisitor(int fifosize) {
			this.irVisitor = new InnerIrVisitor();
			this.fifosize = fifosize;
		}

		@Override
		public Long caseAction(Action action) {
			long bits = doSwitch(action.getScheduler())
					+ doSwitch(action.getBody());
			return (long) Math.ceil(bits + bits * ERROR_MARGIN);
		}

		@Override
		public Long caseActor(Actor actor) {
			long bits = 0;
			for (Var var : actor.getStateVars()) {
				if (var.isAssignable() || var.getType().isList()) {
					int tmp = getSize(var.getType());
					bits += tmp;
				}
			}
			for (Action action : actor.getActions()) {
				long tmp = doSwitch(action);
				bits += tmp;
			}
			return bits;
		}

		@Override
		public Long caseConnection(Connection connection) {
			Integer size = connection.getSize();
			
			if (size == null) {
				size = fifosize;
			}

			int bits = size
					* getSize(connection.getSourcePort().getType()) + 2 * 32;
			return (long) Math.ceil(bits);
		}

		@Override
		public Long caseInstance(Instance instance) {
			return doSwitch(instance.getActor());
		}
	}

	private DfVisitor<Long> dfVisitor;

	public ArchitectureMemoryEstimator(int fifosize) {
		dfVisitor = new InnerDfVisitor(fifosize);
	}

	@Override
	public Void caseDesign(Design design) {
		long lramSize = 0, sramSize = 0;
		OrccLogger.noticeln("****** Memory size estimation ******");
		super.caseDesign(design);
		OrccLogger.traceln("Size of shared RAMs (in bits)");
		for(Memory smem : design.getSharedMemories()) {
			OrccLogger.traceln(smem.getName() + " = " + smem.getSizeAsString());
			sramSize += smem.getDepth() * smem.getWordWidth();
		}
		OrccLogger.traceln("Size of local RAMs (in bits)");
		for(Processor processor : design.getProcessors()) {
			Memory lram = processor.getLocalRAMs().get(0);
			OrccLogger.traceln("Processor " + processor.getName() + " = " + lram.getSizeAsString());
			lramSize += lram.getDepth() * lram.getWordWidth();
		}
		OrccLogger.traceln("Total size of shared RAM = " + sramSize / 8 + " Bytes");
		OrccLogger.traceln("Total size of local RAM  = " + lramSize / 8 + " Bytes");
		OrccLogger.noticeln("******************************");
		return null;
	}

	@Override
	public Void caseMemory(Memory buffer) {
		int bits = 0;
		for (Connection connection : buffer.getMappedConnections()) {
			bits += dfVisitor.doSwitch(connection);
		}
		buffer.setDepth(BackendUtil.quantizeUp(bits / 8 + 64));
		buffer.setWordWidth(8);
		buffer.setMinAddress(0);
		return null;
	}



	@Override
	public Void caseProcessor(Processor processor) {
		Memory rom = processor.getROM();
		rom.setDepth(480000);
		rom.setWordWidth(8);
		rom.setMinAddress(0);

		// Compute size of the local circular buffer
		for (Memory ram : processor.getLocalRAMs()) {
			doSwitch(ram);
		}

		// Increase the size of the first RAM according to the memory needs for
		// the stack and the state of the actors.
		long bits = 0;
		for (Vertex entity : processor.getMappedActors()) {
			bits += dfVisitor.doSwitch(entity);
		}
		Memory ram = processor.getLocalRAMs().get(0);
		long size = BackendUtil.quantizeUp(ram.getDepth() + bits / 8);
		ram.setDepth(size);
		ram.setWordWidth(8);
		ram.setMinAddress(0);
		return null;
	}

	/**
	 * Compute the size in bits of the given type. The method getSizeInBits() of
	 * the class Type is not relevant here because the TCE consider boolean as
	 * an 8-bits type.
	 * 
	 * @param type
	 *            the type to evaluate
	 * @return the size of the type in bits.
	 */
	private int getSize(Type type) {
		int size;
		if (type.isList()) {
			size = getSize(((TypeList) type).getInnermostType());
			for (int dim : type.getDimensions()) {
				size *= dim;
			}
		} else if (type.isBool()) {
			size = 8;
		} else {
			size = type.getSizeInBits();
		}
		return size;
	}

}
