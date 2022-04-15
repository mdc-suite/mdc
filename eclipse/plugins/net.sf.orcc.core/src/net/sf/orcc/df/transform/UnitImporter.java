/*
 * Copyright (c) 2011, IETR/INSA of Rennes
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
package net.sf.orcc.df.transform;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import net.sf.orcc.df.Action;
import net.sf.orcc.df.Actor;
import net.sf.orcc.df.Instance;
import net.sf.orcc.df.Unit;
import net.sf.orcc.df.util.DfVisitor;
import net.sf.orcc.ir.Def;
import net.sf.orcc.ir.InstCall;
import net.sf.orcc.ir.InstLoad;
import net.sf.orcc.ir.Procedure;
import net.sf.orcc.ir.Use;
import net.sf.orcc.ir.Var;
import net.sf.orcc.ir.util.AbstractIrVisitor;

import org.eclipse.emf.common.util.TreeIterator;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.util.EcoreUtil;
import org.eclipse.emf.ecore.util.EcoreUtil.Copier;

/**
 * This class defines a transformation that imports objects defined in units.
 * 
 * @author Matthieu Wipliez
 * 
 */
public class UnitImporter extends DfVisitor<Procedure> {

	private Copier copier;

	private int indexProc;

	private int indexVar;

	private Instance instance;
	
	public UnitImporter() {
		this.irVisitor = new InnerIrVisitor();
	}

	private class InnerIrVisitor extends AbstractIrVisitor<Procedure> {
		@Override
		public Procedure caseInstCall(InstCall call) {
			Procedure proc = call.getProcedure();
			Procedure procInActor = doSwitch(proc);
			call.setProcedure(procInActor);
			return null;
		}

		@Override
		public Procedure caseInstLoad(InstLoad load) {
			Use use = load.getSource();
			Var var = use.getVariable();
			if (var.eContainer() instanceof Unit) {
				final String actorVarName = getCurrentEntityName() + "_"
						+ var.getName();
				Var varInActor = actor.getStateVar(actorVarName);
				if (varInActor == null) {
					varInActor = (Var) copier.get(var);
					if (varInActor == null) {
						varInActor = (Var) copier.copy(var);
						actor.getStateVars().add(indexVar++, varInActor);
						varInActor.setName(actorVarName);
					}
				}
				use.setVariable(varInActor);
			}

			return null;
		}

		@Override
		public Procedure caseProcedure(Procedure proc) {
			if (proc.eContainer() instanceof Unit) {
				final String actorProcName = getCurrentEntityName() + "_"
						+ proc.getName();

				Procedure procInActor = (Procedure) copier.get(proc);
				if (procInActor == null) {
					procInActor = (Procedure) copier.copy(proc);
					procInActor.setAttribute("package",
							getPackage(proc.eContainer()));
					if (!procInActor.isNative()) {
						procInActor.setName(actorProcName);
					}
					TreeIterator<EObject> it = EcoreUtil.getAllContents(proc,
							true);
					while (it.hasNext()) {
						EObject object = it.next();

						if (object instanceof Def) {
							Def def = (Def) object;
							Var copyVar = (Var) copier.get(def.getVariable());
							Def copyDef = (Def) copier.get(def);
							copyDef.setVariable(copyVar);
						} else if (object instanceof Use) {
							Use use = (Use) object;
							Var var = use.getVariable();
							Var copyVar = (Var) copier.get(var);
							Use copyUse = (Use) copier.get(use);
							if (copyVar == null) {
								// happens for variables loaded from units
								// handled by caseInstLoad
								copyUse.setVariable(var);
							} else {
								copyUse.setVariable(copyVar);
							}
						} else if (object instanceof InstCall) {
							InstCall innerCall = (InstCall) object;
							Procedure copyProc = doSwitch(innerCall
									.getProcedure());
							InstCall copyCall = (InstCall) copier
									.get(innerCall);
							copyCall.setProcedure(copyProc);
						}
					}
					actor.getProcs().add(indexProc++, procInActor);
					super.caseProcedure(procInActor);
				}
				
				return procInActor;
			} else {
				proc.setAttribute("package", getPackage(proc.eContainer()));
				super.caseProcedure(proc);
				return proc;
			}
		}
	}

	@Override
	public Procedure caseInstance(Instance instance) {
		this.instance = instance;
		final Procedure result = super.caseInstance(instance);
		this.instance = null;
		return result;
	}
	
	@Override
	public Procedure caseActor(Actor actor) {
		this.actor = actor;
		this.copier = new EcoreUtil.Copier();
		this.indexProc = 0;
		this.indexVar = 0;

		List<Procedure> procs = new ArrayList<Procedure>(actor.getProcs());
		for (Procedure procedure : procs) {
			doSwitch(procedure);
		}

		for (Action action : actor.getActions()) {
			doSwitch(action);
		}

		for (Action initialize : actor.getInitializes()) {
			doSwitch(initialize);
		}

		return null;
	}

	private List<String> getPackage(EObject eObject) {
		String[] name = { "" };
		if (eObject instanceof Actor) {
			name = ((Actor) eObject).getName().split("\\.");
		} else if (eObject instanceof Unit) {
			name = ((Unit) eObject).getName().split("\\.");
		}
		return Arrays.asList(name);
	}

	private String getCurrentEntityName() {
		if (instance != null) {
			return instance.getName();
		} else if (actor != null) {
			return actor.getName();
		} else {
			return "";
		}
	}
}
