/*
 * Copyright (c) 2010-2011, IETR/INSA of Rennes
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
package net.sf.orcc.simulators.slow;

import static net.sf.orcc.OrccLaunchConstants.DEFAULT_FIFO_SIZE;
import static net.sf.orcc.OrccLaunchConstants.ENABLE_TRACES;
import static net.sf.orcc.OrccLaunchConstants.FIFO_SIZE;
import static net.sf.orcc.OrccLaunchConstants.NO_DISPLAY;
import static net.sf.orcc.OrccLaunchConstants.PROJECT;
import static net.sf.orcc.OrccLaunchConstants.TRACES_FOLDER;
import static net.sf.orcc.OrccLaunchConstants.XDF_FILE;
import static net.sf.orcc.simulators.SimulatorsConstants.FRAMES_NUMBER;
import static net.sf.orcc.simulators.SimulatorsConstants.GOLDEN_REFERENCE;
import static net.sf.orcc.simulators.SimulatorsConstants.GOLDEN_REFERENCE_FILE;
import static net.sf.orcc.simulators.SimulatorsConstants.INPUT_STIMULUS;
import static net.sf.orcc.simulators.SimulatorsConstants.LOOP_NUMBER;
import static net.sf.orcc.simulators.SimulatorsConstants.OUTPUT_FILE;
import static net.sf.orcc.simulators.SimulatorsConstants.PROFILE;
import static net.sf.orcc.simulators.SimulatorsConstants.PROFILE_FOLDER;
import static net.sf.orcc.simulators.SimulatorsConstants.TYPE_RESIZER;
import static net.sf.orcc.simulators.SimulatorsConstants.TYPE_RESIZER_CAST_BOOLTOINT;
import static net.sf.orcc.simulators.SimulatorsConstants.TYPE_RESIZER_CAST_NATIVEPORTS;
import static net.sf.orcc.simulators.SimulatorsConstants.TYPE_RESIZER_CAST_TO2NBITS;
import static net.sf.orcc.simulators.SimulatorsConstants.TYPE_RESIZER_CAST_TO32BITS;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.swing.SwingUtilities;

import net.sf.orcc.df.Actor;
import net.sf.orcc.df.Connection;
import net.sf.orcc.df.Network;
import net.sf.orcc.df.Port;
import net.sf.orcc.df.transform.Instantiator;
import net.sf.orcc.df.transform.NetworkFlattener;
import net.sf.orcc.df.transform.TypeResizer;
import net.sf.orcc.graph.Vertex;
import net.sf.orcc.ir.util.ActorInterpreter;
import net.sf.orcc.simulators.AbstractSimulator;
import net.sf.orcc.simulators.SimulatorDescriptor;
import net.sf.orcc.simulators.runtime.impl.GenericDisplay;
import net.sf.orcc.simulators.runtime.impl.GenericSource;
import net.sf.orcc.simulators.runtime.impl.GenericWriter;
import net.sf.orcc.simulators.runtime.std.video.impl.Display;
import net.sf.orcc.tools.stats.StatisticsPrinter;
import net.sf.orcc.util.FilesManager;
import net.sf.orcc.util.OrccLogger;
import net.sf.orcc.util.OrccUtil;
import net.sf.orcc.util.util.EcoreHelper;

import org.eclipse.core.resources.IFile;
import org.eclipse.core.resources.IFolder;
import org.eclipse.core.resources.IProject;
import org.eclipse.core.resources.IWorkspaceRoot;
import org.eclipse.core.resources.ResourcesPlugin;
import org.eclipse.emf.ecore.resource.ResourceSet;
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl;

/**
 * This class implements a simulator using a slow, visitor-based approach.
 * 
 * @author Matthieu Wipliez
 * @author Pierre-Laurent Lagalaye
 * 
 */
public class SlowSimulator extends AbstractSimulator {

	private boolean enableTraces;

	private boolean enableTypeResizer;

	private String goldenReferenceFile;

	private boolean hasGoldenReference;

	protected Map<Actor, ActorInterpreter> interpreters;

	private int loopsNumber;

	private boolean noDisplay;

	private boolean profile;

	protected IProject project;

	private String stimulusFile;

	private String outputFile;
	
	private String traceFolder;

	private String profileFolder;

	private final Boolean[] typeResizer = { false, false, false, false };

	protected List<IFolder> vtlFolders;

	protected String xdfFile;

	/**
	 * Visit the network graph for building the required topology. Edges of the
	 * graph correspond to the connections between the actors. These connections
	 * should be implemented as FIFOs of specific size as defined in the CAL
	 * model or a common default size.
	 * 
	 * @param graph
	 */
	@SuppressWarnings("unchecked")
	public void connectNetwork(Network network) {
		for (Connection connection : network.getConnections()) {
			Actor src = connection.getSource().getAdapter(Actor.class);
			Actor tgt = connection.getTarget().getAdapter(Actor.class);
			Port srcPort = connection.getSourcePort();
			Port tgtPort = connection.getTargetPort();

			Integer fifoSize = connection.getSize();
			int size = fifoSize == null ? getAttribute(FIFO_SIZE, DEFAULT_FIFO_SIZE) : fifoSize;

			if (src == null || tgt == null || srcPort == null
					|| tgtPort == null) {
				OrccLogger.warnln("The connection " + connection + " cannot "
						+ "be connected to a pair of actors.");
				break;
			}

			String name = src.getName() + "." + srcPort.getName() + " --> "
					+ tgt.getName() + "." + tgtPort.getName();
			SimulatorFifo fifo = new SimulatorFifo(srcPort.getType(), size,
					traceFolder, name, enableTraces, profile);

			tgtPort.setAttribute("fifo", fifo);

			List<SimulatorFifo> fifos;
			if (srcPort.hasAttribute("fifo")) {
				fifos = (List<SimulatorFifo>) srcPort.getAttribute("fifo")
						.getObjectValue();
			} else {
				fifos = new ArrayList<SimulatorFifo>();
				srcPort.setAttribute("fifo", fifos);
			}
			fifos.add(fifo);

			connection.setAttribute("fifo", fifo);
		}

		// print a warning message if there are some unconnected ports
		for (Actor actor : network.getAllActors()) {
			// check input ports
			for (Port port : actor.getInputs()) {
				if (port.getAttribute("fifo") == null) {
					OrccLogger.warnln("Unconnected Input Port ["
							+ port.getName() + "] on Actor "
							+ actor.getSimpleName());
				}
			}

			// check output ports
			for (Port port : actor.getOutputs()) {
				if (port.getAttribute("fifo") == null) {
					OrccLogger.warnln("Unconnected Output Port ["
							+ port.getName() + "] on Actor "
							+ actor.getSimpleName());
				}
			}
		}

	}

	/**
	 * Visits the network and creates one interpreter per actor.
	 * 
	 * @param network
	 *            the network
	 */
	protected void createInterpreters(Network network) {
		for (Vertex vertex : network.getChildren()) {
			Actor actor = vertex.getAdapter(Actor.class);

			ConnectedActorInterpreter interpreter = new ConnectedActorInterpreter(
					actor);

			interpreters.put(actor, interpreter);
		}
	}

	protected void initializeNetwork(Network network) {
		GenericSource.setInputStimulus(stimulusFile);

		GenericSource.setNbLoops(loopsNumber);
		
		GenericWriter.setOutputFile(outputFile);

		if (hasGoldenReference) {
			GenericDisplay.setGoldenReference(goldenReferenceFile);
		}

		if (noDisplay) {
			GenericDisplay.setDisplayDisabled();
		}

		for (Vertex vertex : network.getChildren()) {
			Actor actor = vertex.getAdapter(Actor.class);
			ActorInterpreter interpreter = interpreters.get(actor);
			interpreter.initialize();
		}
	}

	@Override
	protected void initializeOptions() {
		stimulusFile = getAttribute(INPUT_STIMULUS, "");
		String outputDir = getAttribute(OUTPUT_FILE, "");
		outputFile = outputDir.equals("") ? "" : outputDir + "/orcc-simulation-out";
		hasGoldenReference = getAttribute(GOLDEN_REFERENCE, false);
		goldenReferenceFile = getAttribute(GOLDEN_REFERENCE_FILE, "");
		xdfFile = getAttribute(XDF_FILE, "");
		String name = getAttribute(PROJECT, "");
		enableTraces = getAttribute(ENABLE_TRACES, false);
		traceFolder = getAttribute(TRACES_FOLDER, "");
		profile = getAttribute(PROFILE, false);
		profileFolder = getAttribute(PROFILE_FOLDER, "");

		IWorkspaceRoot root = ResourcesPlugin.getWorkspace().getRoot();
		project = root.getProject(name);

		vtlFolders = OrccUtil.getOutputFolders(project);

		loopsNumber = getAttribute(LOOP_NUMBER, DEFAULT_NB_LOOPS);
		GenericDisplay.nbFrames = getAttribute(FRAMES_NUMBER, DEFAULT_NB_FRAMES);

		noDisplay = getAttribute(NO_DISPLAY, false);

		enableTypeResizer = getAttribute(TYPE_RESIZER, false);
		typeResizer[0] = getAttribute(TYPE_RESIZER_CAST_TO2NBITS, false);
		typeResizer[1] = getAttribute(TYPE_RESIZER_CAST_TO32BITS, false);
		typeResizer[2] = getAttribute(TYPE_RESIZER_CAST_NATIVEPORTS, false);
		typeResizer[3] = getAttribute(TYPE_RESIZER_CAST_BOOLTOINT, false);

		stopRequested = false;
		statusCode = 0;
	}

	/**
	 * Kill simulator descriptors and close the display with associated objects
	 * if necessary
	 */
	protected void killDescriptors() {
		Runnable killer = new Runnable() {
			@Override
			public void run() {
				SimulatorDescriptor.killDescriptors();
				Display.clearAll();
			}
		};
		SwingUtilities.invokeLater(killer);
	}

	@Override
	public void run() {
		try {
			killDescriptors();

			interpreters = new HashMap<Actor, ActorInterpreter>();

			IFile file = OrccUtil.getFile(project, xdfFile,
					OrccUtil.NETWORK_SUFFIX);
			ResourceSet set = new ResourceSetImpl();
			Network network = EcoreHelper.getEObject(set, file);

			// full instantiation (no more instances)
			new Instantiator(true).doSwitch(network);

			// flattens network
			new NetworkFlattener().doSwitch(network);

			// if required, use the type sizer transformation
			if (enableTypeResizer) {
				new TypeResizer(typeResizer[0], typeResizer[1], typeResizer[2],
						typeResizer[3]).doSwitch(network);
			}

			// create interpreters, connect network, initialize, and run
			createInterpreters(network);
			connectNetwork(network);
			initializeNetwork(network);

			SimulationEndOrigin returnStatus = runNetwork(network);

			killDescriptors();

			if (returnStatus == SimulationEndOrigin.EXTERNALSTOP) {
				OrccLogger
						.traceln("Simulation aborted (from application control).");
			} else {
				OrccLogger.traceln("End of simulation");
				OrccLogger.traceln("Simulation returned status code "
						+ statusCode);
			}

			if (profile) {
				CharSequence content = new StatisticsPrinter().getContent(network);
				FilesManager.writeFile(content, profileFolder, network.getSimpleName() + ".csv");
			}
		} finally {
			// clean up to prevent memory leak
			interpreters = null;
		}
	}

	protected SimulationEndOrigin runNetwork(Network network) {
		boolean hasExecuted;
		do {
			hasExecuted = false;
			for (Vertex vertex : network.getChildren()) {
				int nbFiring = 0;
				Actor actor = vertex.getAdapter(Actor.class);
				ActorInterpreter interpreter = interpreters.get(actor);

				while (interpreter.schedule()) {
					// check for cancelation
					if (isStopped()) {
						return SimulationEndOrigin.EXTERNALSTOP;
					}
					nbFiring++;
				}

				hasExecuted |= (nbFiring > 0);

				// check for cancelation
				if (isStopped()) {
					return SimulationEndOrigin.EXTERNALSTOP;
				}
			}
		} while (hasExecuted);

		return SimulationEndOrigin.NORMALEND;
	}
}
