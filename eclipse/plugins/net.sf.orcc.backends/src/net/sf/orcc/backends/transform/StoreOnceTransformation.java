/*
 * Copyright (c) 2011, IETR/INSA of Rennes and EPFL
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
 *   * Neither the name of the IETR/INSA of Rennes and EPFL nor the names of its
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
package net.sf.orcc.backends.transform;

import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;

import net.sf.orcc.df.Action;
import net.sf.orcc.df.Actor;
import net.sf.orcc.df.util.DfVisitor;
import net.sf.orcc.ir.Arg;
import net.sf.orcc.ir.ArgByVal;
import net.sf.orcc.ir.BlockBasic;
import net.sf.orcc.ir.ExprList;
import net.sf.orcc.ir.ExprVar;
import net.sf.orcc.ir.Expression;
import net.sf.orcc.ir.InstAssign;
import net.sf.orcc.ir.InstCall;
import net.sf.orcc.ir.InstLoad;
import net.sf.orcc.ir.InstStore;
import net.sf.orcc.ir.Instruction;
import net.sf.orcc.ir.IrFactory;
import net.sf.orcc.ir.Procedure;
import net.sf.orcc.ir.Type;
import net.sf.orcc.ir.TypeList;
import net.sf.orcc.ir.Var;
import net.sf.orcc.ir.util.AbstractIrVisitor;
import net.sf.orcc.ir.util.ExpressionPrinter;
import net.sf.orcc.ir.util.IrUtil;

import org.eclipse.emf.common.util.EList;

/**
 * This class defines an actor transformation that transforms code so that at
 * most it contains at most one store and one per static global variable per
 * cycle.
 * 
 * @author Matthieu Wipliez
 * @author Thavot Richard
 * @version 1.1
 * 
 */
public class StoreOnceTransformation extends DfVisitor<Object> {

	/**
	 * Locks a variable whether all accesses are not static. e.g x=0, x[10] are
	 * static but not x[i] or is call by a procedure
	 * 
	 * @author Thavot Richard
	 * 
	 */
	private class GlobalsLocked extends AbstractIrVisitor<Set<Var>> {

		Set<Var> globalsLockedSet = new HashSet<Var>();

		@Override
		public Set<Var> caseInstCall(InstCall call) {
			for (Arg arg : call.getArguments()) {
				if (arg.isByVal()) {
					ArgByVal argByVal = (ArgByVal) arg;
					if (argByVal.getValue().isExprVar()) {
						Var var = ((ExprVar) argByVal.getValue()).getUse()
								.getVariable();
						if (var.isGlobal())
							globalsLockedSet.add(var);
					}
				}
			}
			return null;
		}

		@Override
		public Set<Var> caseInstLoad(InstLoad load) {
			Var loadedVar = load.getSource().getVariable();
			if (loadedVar.isGlobal()) {
				if (procedure.eContainer() instanceof Action) {
					EList<Expression> indexes = load.getIndexes();
					if (isStaticIndexes(indexes)) {
						if (indexes == null & loadedVar.getType().isList()) {
							globalsLockedSet.add(loadedVar);
						} else if (indexes.isEmpty()
								& loadedVar.getType().isList()) {
							globalsLockedSet.add(loadedVar);
						}
					} else {
						globalsLockedSet.add(loadedVar);
					}
				} else {
					globalsLockedSet.add(loadedVar);
				}
			}
			return null;
		}

		@Override
		public Set<Var> caseInstStore(InstStore store) {
			Var storedVar = store.getTarget().getVariable();
			if (storedVar.isGlobal()) {
				if (procedure.eContainer() instanceof Action) {
					EList<Expression> indexes = store.getIndexes();
					if (isStaticIndexes(indexes)) {
						if (indexes == null & storedVar.getType().isList()) {
							globalsLockedSet.add(storedVar);
						} else if (indexes.isEmpty()
								& storedVar.getType().isList()) {
							globalsLockedSet.add(storedVar);
						}
					} else {
						globalsLockedSet.add(storedVar);
					}
				} else {
					globalsLockedSet.add(storedVar);
				}
			}
			return null;
		}

		@Override
		public Set<Var> caseProcedure(Procedure procedure) {
			globalsLockedSet.clear();
			super.caseProcedure(procedure);
			return globalsLockedSet;
		}

		/**
		 * Returns true whether the indexes is null or empty and whether every
		 * indexes are an ExprInt
		 * 
		 * @param indexes
		 * 
		 */
		private boolean isStaticIndexes(Collection<Expression> indexes) {
			boolean s = true;
			if (indexes != null) {
				for (Expression expr : indexes) {
					s &= expr.isExprInt();
				}
			}
			return s;
		}

	}

	/**
	 * 
	 * @author thavot
	 * 
	 */
	private class OverrideProcedure extends AbstractIrVisitor<Void> {

		private int index;
		private List<Var> loadedVarsList;
		private Map<Procedure, List<Var>> procedureToLoadedVarsMap;

		OverrideProcedure() {
			procedureToLoadedVarsMap = new HashMap<Procedure, List<Var>>();
		}

		OverrideProcedure(Map<Procedure, List<Var>> procedureToLoadedVarsMap) {
			this.procedureToLoadedVarsMap = procedureToLoadedVarsMap;
		}

		/**
		 * Adds one parameter to the given procedure for each loaded global
		 * variables by the given procedure.
		 * 
		 * @param procedure
		 *            a procedure
		 */
		private void addParameters(Procedure procedure) {
			index = 0;
			for (Var var : loadedVarsList) {
				procedure.getParameters().add(index++,
						IrFactory.eINSTANCE.createParam(IrUtil.copy(var)));
			}
		}

		@Override
		public Void caseInstCall(InstCall call) {
			Procedure calledProc = call.getProcedure();
			List<Var> loadedVars = procedureToLoadedVarsMap.get(calledProc);
			if (loadedVars == null) {
				// transform the called procedure
				new OverrideProcedure(procedureToLoadedVarsMap)
						.doSwitch(calledProc);
				loadedVars = procedureToLoadedVarsMap.get(calledProc);
			}
			index = 0;
			for (Var var : loadedVars) {
				call.getArguments().add(index++,
						IrFactory.eINSTANCE.createArgByVal(var));
			}
			return null;
		}

		@Override
		public Void caseInstLoad(InstLoad load) {
			Var loadedVar = load.getSource().getVariable();
			if (loadedVar.isGlobal()) {
				EList<Expression> indexes = load.getIndexes();
				if (!loadedVarsList.contains(loadedVar)) {
					loadedVarsList.add(loadedVar);
					if (!loadedVar.getType().isList()) {
						setGlobalAsList(loadedVar);
					}
				}
				if (indexes.isEmpty()) {
					indexes.add(IrFactory.eINSTANCE.createExprInt(0));
				}
			}
			return null;
		}

		@Override
		public Void caseInstStore(InstStore store) {
			Var storedVar = store.getTarget().getVariable();
			if (storedVar.isGlobal()) {
				EList<Expression> indexes = store.getIndexes();
				if (!loadedVarsList.contains(storedVar)) {
					loadedVarsList.add(storedVar);
					if (!storedVar.getType().isList()) {
						setGlobalAsList(storedVar);
					}
				}
				if (indexes.isEmpty()) {
					indexes.add(IrFactory.eINSTANCE.createExprInt(0));
				}
			}
			return null;
		}

		@Override
		public Void caseProcedure(Procedure procedure) {

			loadedVarsList = new ArrayList<Var>();

			if (procedure.eContainer() instanceof Action) {
				super.caseProcedure(procedure);
			} else {
				if (!procedureToLoadedVarsMap.containsKey(procedure)) {
					super.caseProcedure(procedure);
					addParameters(procedure);
					procedureToLoadedVarsMap.put(procedure, loadedVarsList);
				}
			}

			return null;
		}

		/**
		 * Modify the type as a list of on one value
		 * 
		 * @param var
		 */
		private void setGlobalAsList(Var var) {
			var.setType(IrFactory.eINSTANCE.createTypeList(1, var.getType()));
			if (var.getInitialValue() != null) {
				ExprList initValue = IrFactory.eINSTANCE.createExprList();
				initValue.getValue().add(var.getInitialValue());
				var.setInitialValue(initValue);
			}
		}

	}

	/**
	 * Transform the procedure to keep only one store
	 * 
	 * @author Thavot Richard
	 * 
	 */
	private class StoreTransformer extends AbstractIrVisitor<Void> {

		public StoreTransformer() {
			super(true);
		}

		/**
		 * Replace the local variable name if a reference already exists to a
		 * global variable
		 */
		@Override
		public Void caseExprVar(ExprVar exprVar) {
			Var var = exprVar.getUse().getVariable();
			if (localToLocalsMap.containsKey(var)) {
				exprVar.getUse().setVariable(localToLocalsMap.get(var));
			}
			return null;
		}

		@Override
		public Void caseInstLoad(InstLoad load) {
			Var loadedVar = load.getSource().getVariable();
			if (loadedVar.isGlobal()) {
				EList<Expression> indexes = load.getIndexes();
				for (Expression e : indexes) {
					super.doSwitch(e);
				}
				if (!globalsLockedSet.contains(loadedVar)) {
					// if (isStaticIndexes(indexes)) {
					Var localVar = load.getTarget().getVariable();
					String key = getKey(loadedVar, indexes);
					if (!keyToGlobalsMap.containsKey(key)) {
						keyToGlobalsMap.put(key, loadedVar);
						keyToLocalsMap.put(key, localVar);
						if (!indexes.isEmpty())
							keyToIndexesMap.put(key, indexes);
					} else {
						localToLocalsMap.put(localVar, keyToLocalsMap.get(key));
					}
					IrUtil.delete(load);
					indexInst--;
					// }
				}
			}
			return null;
		}

		@Override
		public Void caseInstStore(InstStore store) {
			// Replace the local variable name by visiting caseExprVar
			super.doSwitch(store.getValue());
			//
			Var storedVar = store.getTarget().getVariable();
			if (storedVar.isGlobal()) {
				EList<Expression> indexes = store.getIndexes();
				for (Expression e : indexes) {
					super.doSwitch(e);
				}
				if (!globalsLockedSet.contains(storedVar)) {
					// if (isStaticIndexes(indexes)) {
					String key = getKey(storedVar, indexes);
					Var localVar = keyToLocalsMap.get(key);
					if (localVar == null) {
						Type type = storedVar.getType();
						if (!indexes.isEmpty()) {
							type = ((TypeList) type).getInnermostType();
						}
						localVar = procedure.newTempLocalVariable(type,
								"local_" + storedVar.getName());
						keyToGlobalsMap.put(key, storedVar);
						keyToIndexesMap.put(key, indexes);
						keyToLocalsMap.put(key, localVar);
					}
					BlockBasic block = store.getBlock();
					keyToStoreSet.add(key);
					InstAssign assign = IrFactory.eINSTANCE.createInstAssign(
							localVar, store.getValue());
					IrUtil.delete(store);
					block.getInstructions().add(indexInst, assign);
					// }
				}
			}
			return null;
		}

		@Override
		public Void caseProcedure(Procedure procedure) {

			// if a variable is locked then no transformation is applied
			globalsLockedSet = new GlobalsLocked().doSwitch(procedure);

			localToLocalsMap = new HashMap<Var, Var>();

			keyToGlobalsMap = new HashMap<String, Var>();
			keyToIndexesMap = new HashMap<String, Collection<Expression>>();
			keyToLocalsMap = new HashMap<String, Var>();
			keyToStoreSet = new HashSet<String>();

			this.procedure = procedure;
			super.caseProcedure(procedure);

			addLoads(procedure);
			addStores(procedure);

			return null;
		}
	}

	private Set<Var> globalsLockedSet;
	private Map<String, Var> keyToGlobalsMap;
	private Map<String, Collection<Expression>> keyToIndexesMap;
	private Map<String, Var> keyToLocalsMap;
	private Set<String> keyToStoreSet;
	private Map<Var, Var> localToLocalsMap;

	/**
	 * Add Load instructions at the beginning of the given procedure.
	 * 
	 * @param procedure
	 *            a procedure
	 */
	private void addLoads(Procedure procedure) {
		for (Entry<String, Var> entry : keyToGlobalsMap.entrySet()) {
			String key = entry.getKey();
			InstLoad load = IrFactory.eINSTANCE.createInstLoad(
					keyToLocalsMap.get(key), entry.getValue());
			Collection<Expression> indexes = keyToIndexesMap.get(key);
			if (indexes != null) {
				load.getIndexes().addAll(IrUtil.copy(indexes));
			}
			BlockBasic block = procedure.getFirst();
			block.getInstructions().add(0, load);
		}
	}

	/**
	 * Add Store instructions at the end of the given procedure.
	 * 
	 * @param procedure
	 *            a procedure
	 */
	private void addStores(Procedure procedure) {
		for (Entry<String, Var> entry : keyToGlobalsMap.entrySet()) {
			String key = entry.getKey();
			if (keyToStoreSet.contains(key)) {
				InstStore store = IrFactory.eINSTANCE.createInstStore(
						entry.getValue(), keyToLocalsMap.get(key));
				Collection<Expression> indexes = keyToIndexesMap.get(key);
				if (indexes != null) {
					store.getIndexes().addAll(IrUtil.copy(indexes));
				}
				EList<Instruction> block = procedure.getLast()
						.getInstructions();
				int lastInstIndex = block.size() - 1;
				block.add(lastInstIndex, store);
			}
		}
	}

	@Override
	public Object caseActor(Actor actor) {

		new DfVisitor<Void>(new OverrideProcedure()).doSwitch(actor);
		new DfVisitor<Void>(new StoreTransformer()).doSwitch(actor);

		return null;
	}

	/**
	 * Return a String key according the varName and the indexes
	 */
	private String getKey(Var var, Collection<Expression> indexes) {
		String s = var.getName();
		if (indexes != null) {
			for (Expression expr : indexes) {
				s += "[";
				s += new ExpressionPrinter().doSwitch(expr);
				s += "]";
			}
		}
		return s;
	}

}
