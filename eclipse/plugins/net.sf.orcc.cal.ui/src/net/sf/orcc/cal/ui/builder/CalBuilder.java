/*
 * Copyright (c) 2014, IETR/INSA of Rennes
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
package net.sf.orcc.cal.ui.builder;

import org.eclipse.core.runtime.CoreException;
import org.eclipse.core.runtime.IProgressMonitor;
import org.eclipse.xtext.builder.BuilderParticipant;
import org.eclipse.xtext.generator.GeneratorDelegate;
import org.eclipse.xtext.generator.IGenerator;

import net.sf.orcc.cal.generator.CalGenerator;

/**
 * Hack the default BuilderParticipant to call methods at the beginning and the
 * end of a build.
 * 
 * @author Antoine Lorence
 * 
 */
public class CalBuilder extends BuilderParticipant {

	@Override
	public void build(IBuildContext context, IProgressMonitor monitor) throws CoreException {

		final IGenerator generator = getGenerator();
		if (generator instanceof GeneratorDelegate) {
			GeneratorDelegate generatorDelegate = (GeneratorDelegate) generator;
			if (generatorDelegate.getLegacyGenerator() instanceof CalGenerator) {
				((CalGenerator) generatorDelegate.getLegacyGenerator()).beforeBuild(context.getBuiltProject(),
						context.getResourceSet());
			}
		} else if (generator instanceof CalGenerator) {
			((CalGenerator) generator).beforeBuild(context.getBuiltProject(), context.getResourceSet());
		}

		super.build(context, monitor);

		if (generator instanceof GeneratorDelegate) {
			GeneratorDelegate generatorDelegate = (GeneratorDelegate) generator;
			if (generatorDelegate.getLegacyGenerator() instanceof CalGenerator) {
				((CalGenerator) generatorDelegate.getLegacyGenerator()).afterBuild();
			}
		} else if (generator instanceof CalGenerator) {
			((CalGenerator) generator).afterBuild();
		}
	}
}
