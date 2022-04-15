/*
 * Copyright (c) 2009-2013, IETR/INSA of Rennes
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
package net.sf.orcc.backends.c.hmpp;

import org.eclipse.core.runtime.Platform;

import net.sf.orcc.backends.BackendsConstants;
import net.sf.orcc.backends.c.CBackend;
import net.sf.orcc.backends.c.CMakePrinter;
import net.sf.orcc.backends.c.hmpp.transformations.CodeletInliner;
import net.sf.orcc.backends.c.hmpp.transformations.ConstantRegisterCleaner;
import net.sf.orcc.backends.c.hmpp.transformations.DisableAnnotations;
import net.sf.orcc.backends.c.hmpp.transformations.PrepareHMPPAnnotations;
import net.sf.orcc.backends.c.hmpp.transformations.SetHMPPAnnotations;
import net.sf.orcc.backends.transform.BlockForAdder;
import net.sf.orcc.df.Actor;
import net.sf.orcc.df.Instance;
import net.sf.orcc.df.Network;
import net.sf.orcc.df.util.DfVisitor;
import net.sf.orcc.ir.CfgNode;
import net.sf.orcc.ir.InstCall;
import net.sf.orcc.ir.Procedure;
import net.sf.orcc.ir.transform.ControlFlowAnalyzer;
import net.sf.orcc.util.FilesManager;
import net.sf.orcc.util.Result;

/**
 * HMPP back-end.
 * 
 * @author Jérôme Gorin
 * @author Antoine Lorence
 * 
 */
public class HMPPBackend extends CBackend {

	final private InstancePrinter instancePrinter;
	final private CMakePrinter cmakePrinter;

	public HMPPBackend() {
		instancePrinter = new InstancePrinter();
		cmakePrinter = new CMakePrinter();
	}

	@Override
	protected void doInitializeOptions() {

		instancePrinter.setOptions(getOptions());

		boolean disableAnnotation = getOption(BackendsConstants.HMPP_NO_PRAGMAS,
				false);

		// Must be applied before CodeletInliner:
		childrenTransfos.add(new DfVisitor<Void>(new PrepareHMPPAnnotations()));
		childrenTransfos.add(new DfVisitor<Void>(new ConstantRegisterCleaner()));

		// Must be applied after PrepareHMPPAnnotations:
		childrenTransfos.add(new DfVisitor<Void>(new CodeletInliner()));
		// Must be applied after CodeletInliner:
		childrenTransfos.add(new SetHMPPAnnotations());

		childrenTransfos.add(new DfVisitor<CfgNode>(new ControlFlowAnalyzer()));
		childrenTransfos.add(new BlockForAdder());

		if (disableAnnotation) {
			childrenTransfos.add(new DisableAnnotations());
		}
	}

	@Override
	protected Result doGenerateInstance(Instance instance) {
		return FilesManager.writeFile(
				instancePrinter.getInstanceContent(instance), srcPath,
				instance.getName() + ".c");
	}

	@Override
	protected Result doGenerateActor(Actor actor) {
		return FilesManager.writeFile(
				instancePrinter.getActorContent(actor), srcPath,
				actor.getName() + ".c");
	}

	@Override
	protected Result doAdditionalGeneration(Instance instance) {
		final Result result = Result.newInstance();
		for(Procedure proc : instancePrinter.getCodelets()) {
			result.merge(FilesManager.writeFile(
					instancePrinter.getDefaultContent(proc), srcPath,
					instancePrinter.defaultFileName(proc)));

			result.merge(FilesManager.writeFile(
					instancePrinter.getWrapperContent(proc), srcPath,
					instancePrinter.wrapperFileName(proc)));
		}

		for (InstCall call : instancePrinter.getCallSites()) {
			result.merge(FilesManager.writeFile(
					instancePrinter.getSelectorContent(call), srcPath,
					instancePrinter.selectorFileName(call)));
		}

		return result;
	}

	@Override
	protected Result doLibrariesExtraction() {

		final Result result = FilesManager.extract("/runtime/C/libs", outputPath);
		result.merge(FilesManager.extract("/runtime/C/README.txt", outputPath));

		// Copy specific windows batch file
		if (Platform.OS_WIN32.equals(Platform.getOS())) {
			result.merge(FilesManager.extract(
					"/runtime/C/run_cmake_with_VS_env.bat", outputPath));
		}

		return result;
	}

	@Override
	protected Result doAdditionalGeneration(Network network) {
		cmakePrinter.setNetwork(network);
		final Result result = Result.newInstance();
		result.merge(FilesManager.writeFile(cmakePrinter.rootCMakeContent(), outputPath, "CMakeLists.txt"));
		result.merge(FilesManager.writeFile(cmakePrinter.srcCMakeContent(), srcPath, "CMakeLists.txt"));
		return result;
	}
}
