/*
 * Copyright (c) 2012, IETR/INSA of Rennes
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
package net.sf.orcc.simulators;

import static net.sf.orcc.OrccLaunchConstants.FIFO_SIZE;
import static net.sf.orcc.OrccLaunchConstants.NO_DISPLAY;
import static net.sf.orcc.OrccLaunchConstants.PROJECT;
import static net.sf.orcc.OrccLaunchConstants.SIMULATOR;
import static net.sf.orcc.OrccLaunchConstants.XDF_FILE;
import static net.sf.orcc.simulators.SimulatorsConstants.FRAMES_NUMBER;
import static net.sf.orcc.simulators.SimulatorsConstants.GOLDEN_REFERENCE;
import static net.sf.orcc.simulators.SimulatorsConstants.GOLDEN_REFERENCE_FILE;
import static net.sf.orcc.simulators.SimulatorsConstants.INPUT_STIMULUS;
import static net.sf.orcc.simulators.SimulatorsConstants.LOOP_NUMBER;

import java.util.HashMap;
import java.util.Map;

import net.sf.orcc.OrccRuntimeException;
import net.sf.orcc.util.OrccLogger;

import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.CommandLineParser;
import org.apache.commons.cli.HelpFormatter;
import org.apache.commons.cli.Option;
import org.apache.commons.cli.Options;
import org.apache.commons.cli.PosixParser;
import org.apache.commons.cli.UnrecognizedOptionException;
import org.eclipse.core.resources.IWorkspace;
import org.eclipse.core.resources.IWorkspaceDescription;
import org.eclipse.core.resources.ResourcesPlugin;
import org.eclipse.core.runtime.CoreException;
import org.eclipse.equinox.app.IApplication;
import org.eclipse.equinox.app.IApplicationContext;

/**
 * Command-line version of CAL simulator.
 * 
 * @author Antoine Lorence
 * 
 */
public class SimulatorCli implements IApplication {

	boolean isAutoBuildActivated;

	IWorkspace workspace;

	/**
	 * Initilize
	 */
	public SimulatorCli() {
		workspace = ResourcesPlugin.getWorkspace();
	}

	private void disableAutoBuild() throws CoreException {
		IWorkspaceDescription desc = workspace.getDescription();
		if (desc.isAutoBuilding()) {
			isAutoBuildActivated = true;
			desc.setAutoBuilding(false);
			workspace.setDescription(desc);
		}
	}

	private void restoreAutoBuild() throws CoreException {
		if (isAutoBuildActivated) {
			IWorkspaceDescription desc = workspace.getDescription();
			desc.setAutoBuilding(true);
			workspace.setDescription(desc);
		}
	}

	@Override
	public Object start(IApplicationContext context) throws Exception {

		Options clOptions = new Options();
		Option opt;

		// Required command line arguments
		opt = new Option("p", "project", true, "Set the project from ");
		opt.setRequired(true);
		clOptions.addOption(opt);

		opt = new Option("i", "input", true, "Set the input stimulus file");
		opt.setRequired(true);
		clOptions.addOption(opt);

		// Optional command line arguments
		clOptions.addOption("l", "loops_number", true,
				"Defines the number of times input stimulus will be read before "
						+ "application stop. A negative value means infinite. "
						+ "Default : 1 time.");

		clOptions.addOption("f", "frames_number", true,
				"Defines the number of frames to"
						+ "display before closing application.");

		clOptions.addOption("r", "golden_reference", true,
				"Reference file which used to compare with decoded stream.");
		clOptions.addOption("s", "fifo-size", true,
				"Default size of the FIFO channels");
		clOptions.addOption("n", "nodisplay", false,
				"Disable display initialization");
		clOptions.addOption("d", "debug", false,
				"Launch simulator in debug mode");
		clOptions.addOption("h", "help", false, "Print this help message");

		try {
			Map<String, Object> simulatorOptions = new HashMap<String, Object>();

			CommandLineParser parser = new PosixParser();
			CommandLine commandLine = parser.parse(
					clOptions,
					(String[]) context.getArguments().get(
							IApplicationContext.APPLICATION_ARGS));

			if (commandLine.hasOption('h')) {
				printUsage(clOptions, null);
				return IApplication.EXIT_RELAUNCH;
			}

			simulatorOptions.put(PROJECT, commandLine.getOptionValue('p'));
			simulatorOptions.put(INPUT_STIMULUS,
					commandLine.getOptionValue('i'));
			simulatorOptions.put(XDF_FILE, commandLine.getArgList().get(0));

			if (commandLine.hasOption('s')) {
				simulatorOptions.put(FIFO_SIZE,
						Integer.valueOf(commandLine.getOptionValue('s')));
			}

			if (commandLine.hasOption('l')) {
				simulatorOptions.put(LOOP_NUMBER,
						commandLine.getOptionValue('l'));
			}
			if (commandLine.hasOption('f')) {
				simulatorOptions.put(FRAMES_NUMBER,
						commandLine.getOptionValue('f'));
			}

			if (commandLine.hasOption('n')) {
				simulatorOptions.put(NO_DISPLAY, true);
			}

			if (commandLine.hasOption('d')) {
				OrccLogger.setLevel(OrccLogger.DEBUG);
			}

			if (commandLine.hasOption("r")) {
				simulatorOptions.put(GOLDEN_REFERENCE, true);
				simulatorOptions.put(GOLDEN_REFERENCE_FILE,
						commandLine.getOptionValue("r"));
			}

			simulatorOptions.put(SIMULATOR, "Visitor interpreter and debugger");

			try {

				disableAutoBuild();

				Simulator simulator = SimulatorFactory.getInstance()
						.getSimulator((String) simulatorOptions.get(SIMULATOR));
				simulator.setOptions(simulatorOptions);
				simulator.run();

			} catch (CoreException ce) {
				OrccLogger.severeln("Unable to set the workspace properties.");
				restoreAutoBuild();
				return IApplication.EXIT_RELAUNCH;
			} catch (OrccRuntimeException oe) {
				OrccLogger.severeln("Simulator has shut down");
				restoreAutoBuild();
				return IApplication.EXIT_RELAUNCH;
			} finally {
				restoreAutoBuild();
			}

			// Simulator correctly shut down
			return IApplication.EXIT_OK;

		} catch (UnrecognizedOptionException uoe) {
			printUsage(clOptions, uoe.getLocalizedMessage());
		}

		return IApplication.EXIT_RELAUNCH;
	}

	@Override
	public void stop() {

	}

	public void printUsage(Options options, String parserMsg) {

		String footer = "";
		if (parserMsg != null && !parserMsg.isEmpty()) {
			footer = "\nMessage of the command line parser :\n" + parserMsg;
		}

		HelpFormatter helpFormatter = new HelpFormatter();
		helpFormatter.setWidth(80);
		helpFormatter
				.printHelp(
						"net.sf.orcc.simulators.cli [options] <qualified path of your top network>",
						"Valid options are :", options, footer);
	}
}
