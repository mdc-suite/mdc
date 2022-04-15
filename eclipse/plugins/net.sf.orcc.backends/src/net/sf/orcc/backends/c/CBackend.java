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
package net.sf.orcc.backends.c;

import static net.sf.orcc.OrccLaunchConstants.ENABLE_TRACES;
import static net.sf.orcc.backends.BackendsConstants.ADDITIONAL_TRANSFOS;
import static net.sf.orcc.backends.BackendsConstants.BXDF_FILE;
import static net.sf.orcc.backends.BackendsConstants.IMPORT_BXDF;

import java.io.File;
import java.util.HashMap;
import java.util.Map;

import org.eclipse.core.runtime.Platform;

import net.sf.orcc.backends.AbstractBackend;
import net.sf.orcc.backends.c.transform.CBroadcastAdder;
import net.sf.orcc.backends.transform.CastAdder;
import net.sf.orcc.backends.transform.DeadVariableRemoval;
import net.sf.orcc.backends.transform.DisconnectedOutputPortRemoval;
import net.sf.orcc.backends.transform.DivisionSubstitution;
import net.sf.orcc.backends.transform.EmptyBlockRemover;
import net.sf.orcc.backends.transform.Inliner;
import net.sf.orcc.backends.transform.InlinerByAnnotation;
import net.sf.orcc.backends.transform.InstPhiTransformation;
import net.sf.orcc.backends.transform.InstTernaryAdder;
import net.sf.orcc.backends.transform.ListFlattener;
import net.sf.orcc.backends.transform.LoopUnrolling;
import net.sf.orcc.backends.transform.Multi2MonoToken;
import net.sf.orcc.backends.transform.ParameterImporter;
import net.sf.orcc.backends.transform.StoreOnceTransformation;
import net.sf.orcc.backends.util.Alignable;
import net.sf.orcc.backends.util.BroadcastMapper;
import net.sf.orcc.backends.util.Mapping;
import net.sf.orcc.df.Actor;
import net.sf.orcc.df.Instance;
import net.sf.orcc.df.Network;
import net.sf.orcc.df.transform.ArgumentEvaluator;
import net.sf.orcc.df.transform.BroadcastAdder;
import net.sf.orcc.df.transform.BroadcastRemover;
import net.sf.orcc.df.transform.FifoSizePropagator;
import net.sf.orcc.df.transform.Instantiator;
import net.sf.orcc.df.transform.NetworkFlattener;
import net.sf.orcc.df.transform.SharedVarsDetection;
import net.sf.orcc.df.transform.TypeResizer;
import net.sf.orcc.df.transform.UnitImporter;
import net.sf.orcc.df.util.DfVisitor;
import net.sf.orcc.ir.CfgNode;
import net.sf.orcc.ir.Expression;
import net.sf.orcc.ir.transform.BlockCombine;
import net.sf.orcc.ir.transform.ControlFlowAnalyzer;
import net.sf.orcc.ir.transform.DeadCodeElimination;
import net.sf.orcc.ir.transform.DeadGlobalElimination;
import net.sf.orcc.ir.transform.PhiRemoval;
import net.sf.orcc.ir.transform.RenameTransformation;
import net.sf.orcc.ir.transform.SSATransformation;
import net.sf.orcc.ir.transform.SSAVariableRenamer;
import net.sf.orcc.ir.transform.TacTransformation;
import net.sf.orcc.tools.classifier.Classifier;
import net.sf.orcc.tools.mapping.XmlBufferSizeConfiguration;
import net.sf.orcc.tools.merger.action.ActionMerger;
import net.sf.orcc.tools.merger.actor.ActorMerger;
import net.sf.orcc.tools.stats.StatisticsPrinter;
import net.sf.orcc.util.FilesManager;
import net.sf.orcc.util.OrccLogger;
import net.sf.orcc.util.Result;
import net.sf.orcc.util.Void;

/**
 * C back-end.
 * 
 * @author Matthieu Wipliez
 * @author Herve Yviquel
 * @author Antoine Lorence
 * 
 */
public class CBackend extends AbstractBackend {

	/**
	 * Path to target "src" folder
	 */
	protected String srcPath;

	private final NetworkPrinter networkPrinter;
	private final CMakePrinter cmakePrinter;
	private final InstancePrinter instancePrinter;

	private final TracesPrinter tracesPrinter;
	private final StatisticsPrinter statsPrinter;

	public CBackend() {
		networkPrinter = new NetworkPrinter();
		cmakePrinter = new CMakePrinter();
		instancePrinter = new InstancePrinter();

		tracesPrinter = new TracesPrinter();
		statsPrinter = new StatisticsPrinter();
	}

	@Override
	protected void doInitializeOptions() {
		// Configure paths
		srcPath = outputPath + File.separator + "src";

		// Load options map into code generator instances
		networkPrinter.setOptions(getOptions());
		instancePrinter.setOptions(getOptions());
		tracesPrinter.setOptions(getOptions());

		// -----------------------------------------------------
		// Transformations that will be applied on the Network
		// -----------------------------------------------------
		if (mergeActors) {
			networkTransfos.add(new FifoSizePropagator(fifoSize));
			networkTransfos.add(new BroadcastAdder());
		} else {
			networkTransfos.add(new FifoSizePropagator(fifoSize, true));
		}
		networkTransfos.add(new Instantiator(true));
		networkTransfos.add(new NetworkFlattener());
		networkTransfos.add(new UnitImporter());
		networkTransfos.add(new DisconnectedOutputPortRemoval());
		if (classify) {
			networkTransfos.add(new Classifier());
		}
		if (mergeActors) {
			networkTransfos.add(new ActorMerger());
		} else {
			networkTransfos.add(new CBroadcastAdder());
		}
		if (mergeActors) {
			networkTransfos.add(new BroadcastRemover());
		}
		networkTransfos.add(new ArgumentEvaluator());
		networkTransfos.add(new TypeResizer(true, false, true, false));
		networkTransfos.add(new RenameTransformation(getRenameMap()));		
		networkTransfos.add(new SharedVarsDetection());

		// -------------------------------------------------------------------
		// Transformations that will be applied on children (instances/actors)
		// -------------------------------------------------------------------
		if (mergeActions) {
			childrenTransfos.add(new ActionMerger());
		}
		if (convertMulti2Mono) {
			childrenTransfos.add(new Multi2MonoToken());
		}
		childrenTransfos.add(new DfVisitor<Void>(new InlinerByAnnotation()));
		childrenTransfos.add(new DfVisitor<Void>(new LoopUnrolling()));

		// If "-t" option is passed to command line, apply additional
		// transformations
		if (getOption(ADDITIONAL_TRANSFOS, false)) {
			childrenTransfos.add(new StoreOnceTransformation());
			childrenTransfos.add(new DfVisitor<Void>(new SSATransformation()));
			childrenTransfos.add(new DfVisitor<Void>(new PhiRemoval()));
			childrenTransfos.add(new Multi2MonoToken());
			childrenTransfos.add(new DivisionSubstitution());
			childrenTransfos.add(new ParameterImporter());
			childrenTransfos.add(new DfVisitor<Void>(new Inliner(true, true)));

			// transformations.add(new UnaryListRemoval());
			// transformations.add(new GlobalArrayInitializer(true));

			childrenTransfos.add(new DfVisitor<Void>(new InstTernaryAdder()));
			childrenTransfos.add(new DeadGlobalElimination());

			childrenTransfos.add(new DfVisitor<Void>(new DeadVariableRemoval()));
			childrenTransfos.add(new DfVisitor<Void>(new DeadCodeElimination()));
			childrenTransfos.add(new DfVisitor<Void>(new DeadVariableRemoval()));
			childrenTransfos.add(new DfVisitor<Void>(new ListFlattener()));
			childrenTransfos.add(new DfVisitor<Expression>(new TacTransformation()));
			childrenTransfos.add(new DfVisitor<CfgNode>(new ControlFlowAnalyzer()));
			childrenTransfos.add(new DfVisitor<Void>(new InstPhiTransformation()));
			childrenTransfos.add(new DfVisitor<Void>(new EmptyBlockRemover()));
			childrenTransfos.add(new DfVisitor<Void>(new BlockCombine()));

			childrenTransfos.add(new DfVisitor<Expression>(new CastAdder(true, true)));
			childrenTransfos.add(new DfVisitor<Void>(new SSAVariableRenamer()));
		}
	}

	protected Map<String, String> getRenameMap() {
		Map<String, String> renameMap = new HashMap<String, String>();
		renameMap.put("abs", "abs_replaced");
		renameMap.put("getw", "getw_replaced");
		renameMap.put("exit", "exit_replaced");
		renameMap.put("index", "index_replaced");
		renameMap.put("log2", "log2_replaced");
		renameMap.put("max", "max_replaced");
		renameMap.put("min", "min_replaced");
		renameMap.put("select", "select_replaced");
		renameMap.put("OUT", "OUT_REPLACED");
		renameMap.put("IN", "IN_REPLACED");
		renameMap.put("SIZE", "SIZE_REPLACED");

		return renameMap;
	}

	@Override
	protected Result doLibrariesExtraction() {
		final Result result = FilesManager.extract("/runtime/C/README.txt", outputPath);

		// Copy specific windows batch file
		if (Platform.OS_WIN32.equals(Platform.getOS())) {
			result.merge(FilesManager.extract("/runtime/C/run_cmake_with_VS_env.bat", outputPath));
		}

		result.merge(FilesManager.extract("/runtime/C/libs", outputPath));

		String scriptsPath = outputPath + File.separator + "scripts";
		OrccLogger.traceln("Export scripts into " + scriptsPath + "... ");

		result.merge(FilesManager.extract("/runtime/common/scripts", outputPath));
		result.merge(FilesManager.extract("/runtime/C/scripts", outputPath));

		// Fix some permissions on scripts
		new File(scriptsPath + File.separator + "profilingAnalyse.py").setExecutable(true);
		new File(scriptsPath + File.separator + "benchAutoMapping.py").setExecutable(true);

		return result;
	}

	@Override
	protected void beforeGeneration(Network network) {
		new File(outputPath + File.separator + "build").mkdirs();
		new File(outputPath + File.separator + "bin").mkdirs();

		network.computeTemplateMaps();

		// if required, load the buffer size from the mapping file
		if (getOption(IMPORT_BXDF, false)) {
			File f = new File(getOption(BXDF_FILE, ""));
			new XmlBufferSizeConfiguration(true, true).load(f, network);
		}

		if (network.getVertex(network.getSimpleName()) != null) {
			final StringBuilder warnMsg = new StringBuilder();
			warnMsg.append('"').append(network.getSimpleName()).append('"');
			warnMsg.append(" is the name of both the network you want to generate");
			warnMsg.append(" and a vertex in this network.").append('\n');
			warnMsg.append("The 2 entities will be generated");
			warnMsg.append(" in the same file. Please rename one of these elements to prevent");
			warnMsg.append(" unwanted overwriting.");
			OrccLogger.warnln(warnMsg.toString());
		}
	}

	@Override
	protected Result doGenerateNetwork(Network network) {
		networkPrinter.setNetwork(network);
		return FilesManager.writeFile(networkPrinter.getNetworkFileContent(), srcPath, network.getSimpleName() + ".c");
	}

	@Override
	protected Result doAdditionalGeneration(Network network) {
		cmakePrinter.setNetwork(network);
		cmakePrinter.setOptions(getOptions());
		final Result result = Result.newInstance();
		result.merge(FilesManager.writeFile(cmakePrinter.rootCMakeContent(), outputPath, "CMakeLists.txt"));
		result.merge(FilesManager.writeFile(cmakePrinter.srcCMakeContent(), srcPath, "CMakeLists.txt"));

		if (getOption(ENABLE_TRACES, true)) {
			result.merge(FilesManager.writeFile(tracesPrinter.getTracesFileContent(network), srcPath, "traces.txt"));
		}

		result.merge(
				FilesManager.writeFile(statsPrinter.getContent(network), srcPath, network.getSimpleName() + ".csv"));

		if (mergeActors) {
			BroadcastMapper broadcastMapper = new BroadcastMapper();
			broadcastMapper.prepareBroadcastMapping(network);
		}

		final Mapping mapper = new Mapping(network, mapping);
		result.merge(FilesManager.writeFile(mapper.getContentFile(), srcPath, network.getSimpleName() + ".xcf"));

		return result;
	}

	@Override
	protected void beforeGeneration(Instance instance) {
		// update "vectorizable" information
		Alignable.setAlignability(instance.getActor());
	}

	@Override
	protected Result doGenerateInstance(Instance instance) {
		instancePrinter.setInstance(instance);
		return FilesManager.writeFile(instancePrinter.getFileContent(), srcPath, instance.getSimpleName() + ".c");
	}

	@Override
	protected void beforeGeneration(Actor actor) {
		// update "vectorizable" information
		Alignable.setAlignability(actor);
	}

	@Override
	protected Result doGenerateActor(Actor actor) {
		instancePrinter.setActor(actor);
		return FilesManager.writeFile(instancePrinter.getFileContent(), srcPath, actor.getSimpleName() + ".c");
	}
}
