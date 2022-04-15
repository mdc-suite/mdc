/*
 * Copyright (c) 2009-2011, IETR/INSA of Rennes
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
package net.sf.orcc.frontend;

import static net.sf.orcc.ir.IrFactory.eINSTANCE;
import static net.sf.orcc.util.OrccAttributes.COPY_OF_TOKENS;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Set;

import net.sf.orcc.cal.cal.AstAction;
import net.sf.orcc.cal.cal.AstActor;
import net.sf.orcc.cal.cal.AstEntity;
import net.sf.orcc.cal.cal.AstExpression;
import net.sf.orcc.cal.cal.AstPort;
import net.sf.orcc.cal.cal.AstProcedure;
import net.sf.orcc.cal.cal.AstState;
import net.sf.orcc.cal.cal.AstTag;
import net.sf.orcc.cal.cal.ExpressionVariable;
import net.sf.orcc.cal.cal.Function;
import net.sf.orcc.cal.cal.InputPattern;
import net.sf.orcc.cal.cal.OutputPattern;
import net.sf.orcc.cal.cal.RegExp;
import net.sf.orcc.cal.cal.ScheduleFsm;
import net.sf.orcc.cal.cal.Variable;
import net.sf.orcc.cal.cal.VariableReference;
import net.sf.orcc.cal.cal.util.CalSwitch;
import net.sf.orcc.cal.services.Evaluator;
import net.sf.orcc.cal.services.Typer;
import net.sf.orcc.cal.util.Util;
import net.sf.orcc.cal.util.VoidSwitch;
import net.sf.orcc.df.Action;
import net.sf.orcc.df.Actor;
import net.sf.orcc.df.DfFactory;
import net.sf.orcc.df.FSM;
import net.sf.orcc.df.Pattern;
import net.sf.orcc.df.Port;
import net.sf.orcc.df.State;
import net.sf.orcc.df.Tag;
import net.sf.orcc.frontend.schedule.ActionList;
import net.sf.orcc.frontend.schedule.ActionSorter;
import net.sf.orcc.frontend.schedule.FSMBuilder;
import net.sf.orcc.frontend.schedule.RegExpConverter;
import net.sf.orcc.ir.Block;
import net.sf.orcc.ir.BlockBasic;
import net.sf.orcc.ir.BlockWhile;
import net.sf.orcc.ir.Def;
import net.sf.orcc.ir.ExprVar;
import net.sf.orcc.ir.Expression;
import net.sf.orcc.ir.InstAssign;
import net.sf.orcc.ir.InstCall;
import net.sf.orcc.ir.InstLoad;
import net.sf.orcc.ir.InstStore;
import net.sf.orcc.ir.IrFactory;
import net.sf.orcc.ir.OpBinary;
import net.sf.orcc.ir.Procedure;
import net.sf.orcc.ir.Type;
import net.sf.orcc.ir.TypeList;
import net.sf.orcc.ir.Use;
import net.sf.orcc.ir.Var;
import net.sf.orcc.util.OrccUtil;
import net.sf.orcc.util.util.EcoreHelper;

import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.util.EcoreUtil;

/**
 * This class transforms an AST actor to its IR equivalent.
 * 
 * @author Matthieu Wipliez
 * 
 */
public class ActorTransformer extends CalSwitch<Actor> {

	/**
	 * count of un-tagged actions
	 */
	private int untaggedCount;

	final StructTransformer structTransformer;

	/**
	 * Creates a new AST to IR transformation.
	 */
	public ActorTransformer() {
		structTransformer = new StructTransformer();
	}

	/**
	 * Transforms the given AST Actor to an IR actor.
	 * 
	 * @param astActor
	 *            the AST of the actor
	 * @return the actor in IR form
	 */
	@Override
	public Actor caseAstActor(AstActor astActor) {

		untaggedCount = 0;

		Actor actor = DfFactory.eINSTANCE.createActor();
		Frontend.instance.putMapping(astActor, actor);

		actor.setFileName(astActor.eResource().getURI().toPlatformString(true));

		int lineNumber = Util.getLocation(astActor);
		actor.setLineNumber(lineNumber);

		// parameters
		for (Variable variable : astActor.getParameters()) {
			final Var var = (Var) structTransformer.doSwitch(variable);
			actor.getParameters().add(var);
		}

		// state variables
		for (Variable variable : astActor.getStateVariables()) {
			final Var var = (Var) structTransformer.doSwitch(variable);
			actor.getStateVars().add(var);
		}

		// Create empty stubs for functions and procedures
		// This tip will allow to call a function/procedure declared later
		for (Function function : astActor.getFunctions()) {
			final Procedure procedure = IrFactory.eINSTANCE.createProcedure(
					function.getName(), 0, Typer.getType(function));
			Frontend.instance.putMapping(function, procedure);
			actor.getProcs().add(procedure);
		}
		for (AstProcedure astProcedure : astActor.getProcedures()) {
			final Procedure procedure = IrFactory.eINSTANCE.createProcedure(
					astProcedure.getName(), 0, Typer.getType(astProcedure));
			Frontend.instance.putMapping(astProcedure, procedure);
			actor.getProcs().add(procedure);
		}

		// Really transform functions / procedures
		for (Function function : astActor.getFunctions()) {
			structTransformer.doSwitch(function);
		}
		for (AstProcedure astProcedure : astActor.getProcedures()) {
			structTransformer.doSwitch(astProcedure);
		}

		// transform ports
		for (AstPort astPort : astActor.getInputs()) {
			final Port port = (Port) structTransformer.doSwitch(astPort);
			actor.getInputs().add(port);
		}
		for (AstPort astPort : astActor.getOutputs()) {
			final Port port = (Port) structTransformer.doSwitch(astPort);
			actor.getOutputs().add(port);
		}

		// transform actions
		ActionList actions = transformActions(astActor.getActions());

		// transform initializes
		ActionList initializes = transformActions(astActor.getInitializes());

		// sort actions by priority
		ActionSorter sorter = new ActionSorter(actions);
		ActionList sortedActions = sorter.applyPriority(astActor
				.getPriorities());

		// transform FSM
		ScheduleFsm schedule = astActor.getScheduleFsm();
		RegExp scheduleRegExp = astActor.getScheduleRegExp();
		if (schedule == null && scheduleRegExp == null) {
			actor.getActionsOutsideFsm().addAll(sortedActions.getAllActions());
		} else {
			FSM fsm = null;
			if (schedule != null) {
				FSMBuilder builder = new FSMBuilder();
				fsm = builder.buildFSM(schedule.getContents(), sortedActions);

				// set initial state
				AstState initialState = schedule.getInitialState();
				State state = (State) Frontend.instance
						.getMapping(initialState);
				fsm.setInitialState(state);
			} else {
				RegExpConverter converter = new RegExpConverter(scheduleRegExp);
				fsm = converter.convert(sortedActions);
			}

			actor.getActionsOutsideFsm().addAll(
					sortedActions.getUntaggedActions());
			actor.setFsm(fsm);
		}

		// create IR actor
		AstEntity entity = (AstEntity) astActor.eContainer();
		actor.setName(net.sf.orcc.cal.util.Util.getQualifiedName(entity));
		actor.setNative(Util.hasAnnotation("native", entity.getAnnotations()));

		Util.transformAnnotations(actor, entity.getAnnotations());

		actor.getActions().addAll(actions.getAllActions());
		actor.getInitializes().addAll(initializes.getAllActions());

		return actor;
	}

	/**
	 * Loads tokens from the data that was read and put in portVariable.
	 * 
	 * @param portVariable
	 *            a local array that contains data.
	 * @param tokens
	 *            a list of token variables
	 * @param repeat
	 *            an integer number of repeat (equals to one if there is no
	 *            repeat)
	 */
	private void actionLoadTokens(StructTransformer transformer,
			Procedure procedure, Var portVariable, List<Variable> tokens,
			int repeat) {
		if (repeat == 1) {
			int i = 0;

			for (Variable token : tokens) {
				// declare a fresh new variable here because we can have one in
				// the body and one in the scheduler
				Var local = (Var) transformer.doSwitch(token);
				procedure.getLocals().add(local);

				List<Expression> indexes = new ArrayList<Expression>(1);
				indexes.add(eINSTANCE.createExprInt(i));
				int lineNumber = portVariable.getLineNumber();

				Var irToken = Frontend.instance.getMapping(token);
				InstLoad load = eINSTANCE.createInstLoad(lineNumber, irToken,
						portVariable, indexes);
				procedure.getLast().add(load);

				i++;
			}
		} else if (tokens.size() == 1) {
			Variable token = tokens.get(0);
			Frontend.instance.putMapping(token, portVariable);
		} else {
			// creates loop variable and initializes it
			Var loopVar = procedure.newTempLocalVariable(
					eINSTANCE.createTypeInt(32), "num_repeats");
			InstAssign assign = eINSTANCE.createInstAssign(loopVar,
					eINSTANCE.createExprInt(0));
			procedure.getLast().add(assign);

			BlockBasic block = eINSTANCE.createBlockBasic();

			int i = 0;
			int numTokens = tokens.size();
			Type type = ((TypeList) portVariable.getType()).getType();
			for (Variable token : tokens) {
				// declare a fresh new variable here because we can have one in
				// the body and one in the scheduler
				Var local = (Var) transformer.doSwitch(token);
				procedure.getLocals().add(local);

				int lineNumber = portVariable.getLineNumber();
				List<Expression> indexes = new ArrayList<Expression>(1);
				indexes.add(eINSTANCE.createExprBinary(eINSTANCE
						.createExprBinary(eINSTANCE.createExprInt(numTokens),
								OpBinary.TIMES,
								eINSTANCE.createExprVar(loopVar),
								eINSTANCE.createTypeInt(32)), OpBinary.PLUS,
						eINSTANCE.createExprInt(i), eINSTANCE.createTypeInt(32)));

				Var tmpVar = procedure.newTempLocalVariable(type, "token");
				InstLoad load = eINSTANCE.createInstLoad(lineNumber, tmpVar,
						portVariable, indexes);
				block.add(load);

				Var irToken = Frontend.instance.getMapping(token);

				indexes = new ArrayList<Expression>(1);
				indexes.add(eINSTANCE.createExprVar(loopVar));
				InstStore store = eINSTANCE.createInstStore(lineNumber,
						irToken, indexes, eINSTANCE.createExprVar(tmpVar));
				block.add(store);

				i++;
			}

			// add increment
			assign = eINSTANCE.createInstAssign(loopVar, eINSTANCE
					.createExprBinary(eINSTANCE.createExprVar(loopVar),
							OpBinary.PLUS, eINSTANCE.createExprInt(1),
							loopVar.getType()));
			block.add(assign);

			// create while block
			Expression condition = eINSTANCE
					.createExprBinary(eINSTANCE.createExprVar(loopVar),
							OpBinary.LT, eINSTANCE.createExprInt(repeat),
							eINSTANCE.createTypeBool());
			List<Block> blocks = new ArrayList<Block>(1);
			blocks.add(block);

			BlockWhile blockWhile = eINSTANCE.createBlockWhile();
			blockWhile.setJoinBlock(eINSTANCE.createBlockBasic());
			blockWhile.setCondition(condition);
			blockWhile.getBlocks().addAll(blocks);

			procedure.getBlocks().add(blockWhile);
		}
	}

	/**
	 * Assigns tokens to the data that will be written.
	 * 
	 * @param portVariable
	 *            a local array that will contain data.
	 * @param values
	 *            a list of AST expressions
	 * @param repeat
	 *            an integer number of repeat (equals to one if there is no
	 *            repeat)
	 */
	private void actionStoreTokens(StructTransformer transformer,
			Procedure procedure, Var portVariable, List<AstExpression> values,
			int repeat) {
		if (repeat == 1) {
			int i = 0;

			for (AstExpression value : values) {
				List<Expression> indexes = new ArrayList<Expression>(1);
				indexes.add(eINSTANCE.createExprInt(i));

				new ExprTransformer(procedure, procedure.getBlocks(),
						portVariable, indexes).doSwitch(value);
				i++;
			}
		} else if (values.size() == 1 && needToBeCopied(values.get(0))) {
			// assign the expression to a new variable
			AstExpression value = values.get(0);
			new ExprTransformer(procedure, procedure.getBlocks(), portVariable)
					.doSwitch(value);
		} else if (values.size() == 1) {
			// use directly the port variable
			Variable variable = ((ExpressionVariable) values.get(0)).getValue()
					.getVariable();
			Var old = Frontend.instance.getMapping(variable);
			// replace the use/def of the old variable without moving the new
			// one from its containing pattern
			for (Def def : new ArrayList<Def>(old.getDefs())) {
				def.setVariable(portVariable);
			}
			for (Use use : new ArrayList<Use>(old.getUses())) {
				use.setVariable(portVariable);
			}
			Frontend.instance.putMapping(variable, portVariable);
			EcoreUtil.remove(old);
		} else {
			// creates loop variable and initializes it
			Var loopVar = procedure.newTempLocalVariable(
					eINSTANCE.createTypeInt(32), "num_repeats");
			InstAssign assign = eINSTANCE.createInstAssign(loopVar,
					eINSTANCE.createExprInt(0));
			procedure.getLast().add(assign);

			BlockBasic block = eINSTANCE.createBlockBasic();

			int i = 0;
			int numTokens = values.size();
			Type type = ((TypeList) portVariable.getType()).getType();
			for (AstExpression value : values) {
				int lineNumber = portVariable.getLineNumber();
				List<Expression> indexes = new ArrayList<Expression>(1);
				indexes.add(eINSTANCE.createExprVar(loopVar));

				// each expression of an output pattern must be of type list
				// so they are necessarily variables
				Var tmpVar = procedure.newTempLocalVariable(type, "token");
				Expression expression = new ExprTransformer(procedure,
						procedure.getBlocks(), tmpVar).doSwitch(value);
				Use use = ((ExprVar) expression).getUse();

				InstLoad load = eINSTANCE.createInstLoad(tmpVar,
						use.getVariable(), indexes);
				block.add(load);

				indexes = new ArrayList<Expression>(1);
				indexes.add(eINSTANCE.createExprBinary(eINSTANCE
						.createExprBinary(eINSTANCE.createExprInt(numTokens),
								OpBinary.TIMES,
								eINSTANCE.createExprVar(loopVar),
								eINSTANCE.createTypeInt(32)), OpBinary.PLUS,
						eINSTANCE.createExprInt(i), eINSTANCE.createTypeInt(32)));
				InstStore store = eINSTANCE.createInstStore(lineNumber,
						portVariable, indexes, eINSTANCE.createExprVar(tmpVar));
				block.add(store);

				i++;
			}

			// add increment
			assign = eINSTANCE.createInstAssign(loopVar, eINSTANCE
					.createExprBinary(eINSTANCE.createExprVar(loopVar),
							OpBinary.PLUS, eINSTANCE.createExprInt(1),
							loopVar.getType()));
			block.add(assign);

			// create while block
			Expression condition = eINSTANCE
					.createExprBinary(eINSTANCE.createExprVar(loopVar),
							OpBinary.LT, eINSTANCE.createExprInt(repeat),
							eINSTANCE.createTypeBool());

			BlockWhile blockWhile = eINSTANCE.createBlockWhile();
			blockWhile.setJoinBlock(eINSTANCE.createBlockBasic());
			blockWhile.setCondition(condition);
			blockWhile.getBlocks().add(block);

			procedure.getBlocks().add(blockWhile);
		}
	}

	/**
	 * Creates the test for schedulability of the given action.
	 * 
	 * @param astAction
	 *            an AST action
	 * @param inputPattern
	 *            input pattern of action
	 * @param result
	 *            target local variable
	 */
	private void createActionTest(StructTransformer transformer,
			Procedure procedure, AstAction astAction, Pattern peekPattern,
			Var result) {
		Expression value;
		if (astAction.getGuard() == null) {
			value = eINSTANCE.createExprBool(true);
		} else {
			transformInputPatternPeek(transformer, procedure, astAction,
					peekPattern);
			value = transformGuards(transformer, procedure, astAction
					.getGuard().getExpressions());
		}

		InstAssign assign = eINSTANCE.createInstAssign(result, value);
		procedure.getLast().add(assign);
	}

	/**
	 * Creates a variable to hold the number of tokens on the given port.
	 * 
	 * @param port
	 *            a port
	 * @param numTokens
	 *            number of tokens
	 * @return the local array created
	 */
	private Var createPortVariable(int lineNumber, Port port, int numTokens) {
		// create the variable to hold the tokens
		return eINSTANCE.createVar(lineNumber,
				eINSTANCE.createTypeList(numTokens, port.getType()),
				port.getName(), true, 0);
	}

	/**
	 * Check if an expression need be be copied in the output port variable or
	 * not.
	 * 
	 * @param expr
	 *            the given expression
	 * @return true if the expression need be be copied in the output port
	 *         variable
	 */
	private boolean needToBeCopied(AstExpression expr) {
		// Expressions that are not variables cannot be used directly
		if (!(expr instanceof ExpressionVariable)) {
			return true;
		}
		// Global variables have to be copied to the FIFO
		Variable variable = ((ExpressionVariable) expr).getValue()
				.getVariable();
		if (Util.isGlobal(variable)) {
			return true;
		}
		// Input port variables have to be copied as well
		Var var = Frontend.instance.getMapping(variable);
		if (EcoreHelper.getContainerOfType(var, Pattern.class) != null) {
			return true;
		}
		// Variables used by a procedure have to be copied as well
		for (Use use : var.getUses()) {
			if (EcoreHelper.getContainerOfType(use, InstCall.class) != null) {
				// Mark the variable as a local copy of port variable to allow
				// later optimizations (at backend-level)
				var.addAttribute(COPY_OF_TOKENS);
				return true;
			}
		}

		return false;
	}

	/**
	 * Transforms the given AST action and adds it to the given action list.
	 * 
	 * @param actionList
	 *            an action list
	 * @param astAction
	 *            an AST action
	 */
	private void transformAction(AstAction astAction, ActionList actionList) {
		int lineNumber = Util.getLocation(astAction);

		// transform tag
		AstTag astTag = astAction.getTag();
		Tag tag;
		String name;
		if (astTag == null) {
			tag = DfFactory.eINSTANCE.createTag();
			name = "untagged_" + untaggedCount++;
		} else {
			tag = DfFactory.eINSTANCE.createTag();
			tag.getIdentifiers().addAll(astAction.getTag().getIdentifiers());
			name = OrccUtil.toString(tag.getIdentifiers(), "_");
		}

		Pattern inputPattern = DfFactory.eINSTANCE.createPattern();
		Pattern outputPattern = DfFactory.eINSTANCE.createPattern();
		Pattern peekPattern = DfFactory.eINSTANCE.createPattern();

		// creates scheduler and body
		Procedure scheduler = eINSTANCE
				.createProcedure("isSchedulable_" + name, lineNumber,
						eINSTANCE.createTypeBool());
		Procedure body = eINSTANCE.createProcedure(name, lineNumber,
				eINSTANCE.createTypeVoid());

		// creates IR action
		Action action = DfFactory.eINSTANCE.createAction(tag, inputPattern,
				outputPattern, peekPattern, scheduler, body);

		// transforms action body and scheduler
		transformActionBody(astAction, body, inputPattern, outputPattern);
		transformActionScheduler(astAction, scheduler, peekPattern);
		Util.transformAnnotations(action, astAction.getAnnotations());

		// add it to action list
		actionList.add(action);
	}

	/**
	 * Transforms the body of the given AST action into the given body
	 * procedure.
	 * 
	 * @param astAction
	 *            an AST action
	 * @param body
	 *            the procedure that will contain the body
	 */
	private void transformActionBody(AstAction astAction, Procedure body,
			Pattern inputPattern, Pattern outputPattern) {
		StructTransformer transformer = new StructTransformer(body);

		for (InputPattern pattern : astAction.getInputs()) {
			transformPattern(transformer, body, pattern, inputPattern);
		}

		transformer.transformLocalVariables(astAction.getVariables());
		transformer.transformStatements(astAction.getStatements());

		List<OutputPattern> astOutputPattern = astAction.getOutputs();
		for (OutputPattern pattern : astOutputPattern) {
			transformPattern(transformer, body, pattern, outputPattern);
		}

		transformer.addReturn(body, null);
	}

	/**
	 * Transforms the given list of AST actions to an ActionList of IR actions.
	 * 
	 * @param actions
	 *            a list of AST actions
	 * @return an ActionList of IR actions
	 */
	private ActionList transformActions(List<AstAction> actions) {
		ActionList actionList = new ActionList();
		for (AstAction astAction : actions) {
			transformAction(astAction, actionList);
		}

		return actionList;
	}

	/**
	 * Transforms the scheduling information of the given AST action into the
	 * given scheduler procedure.
	 * 
	 * @param astAction
	 *            an AST action
	 * @param scheduler
	 *            the procedure that will contain the scheduler
	 * @param inputPattern
	 *            the input pattern filled by
	 *            {@link #fillsInputPattern(AstAction, Pattern)}
	 */
	private void transformActionScheduler(AstAction astAction,
			Procedure scheduler, Pattern peekPattern) {
		StructTransformer transformer = new StructTransformer(scheduler);

		Var result = scheduler.newTempLocalVariable(eINSTANCE.createTypeBool(),
				"result");

		if (peekPattern.isEmpty() && astAction.getGuard() == null) {
			// the action is always fireable
			InstAssign assign = eINSTANCE.createInstAssign(result,
					eINSTANCE.createExprBool(true));
			scheduler.getLast().add(assign);
		} else {
			createActionTest(transformer, scheduler, astAction, peekPattern,
					result);
		}

		transformer.addReturn(scheduler, eINSTANCE.createExprVar(result));
	}

	/**
	 * Transforms the given guards and assign result the expression g1 && g2 &&
	 * .. && gn.
	 * 
	 * @param guards
	 *            list of guard expressions
	 */
	private Expression transformGuards(StructTransformer transformer,
			Procedure procedure, List<AstExpression> guards) {
		List<Expression> expressions = AstIrUtil.transformExpressions(
				procedure, procedure.getBlocks(), guards);
		Iterator<Expression> it = expressions.iterator();
		Expression value = it.next();
		while (it.hasNext()) {
			value = eINSTANCE.createExprBinary(value, OpBinary.LOGIC_AND,
					it.next(), eINSTANCE.createTypeBool());
		}

		return value;
	}

	/**
	 * Transforms the input patterns of the given AST action when necessary by
	 * generating Peek instructions. An input pattern needs to be transformed to
	 * Peeks when guards reference tokens from the pattern.
	 * 
	 * @param astAction
	 *            an AST action
	 */
	private void transformInputPatternPeek(StructTransformer transformer,
			Procedure scheduler, final AstAction astAction, Pattern peekPattern) {
		final Set<InputPattern> patterns = new HashSet<InputPattern>();
		VoidSwitch peekVariables = new VoidSwitch() {

			@Override
			public Void caseVariableReference(VariableReference reference) {
				EObject obj = reference.getVariable().eContainer();
				if (obj instanceof InputPattern) {
					patterns.add((InputPattern) obj);
				}

				return null;
			}

		};

		// fills the patterns set by visiting guards
		if (astAction.getGuard() != null) {
			for (AstExpression guard : astAction.getGuard().getExpressions()) {
				peekVariables.doSwitch(guard);
			}
		}

		// add peeks for each pattern of the patterns set
		for (InputPattern pattern : patterns) {
			transformPattern(transformer, scheduler, pattern, peekPattern);
		}
	}

	/**
	 * Transforms the given AST input/output pattern of the given action.
	 * 
	 * @param transformer
	 *            AST to IR transformer
	 * @param procedure
	 *            procedure to which instructions should be added (body or
	 *            scheduler)
	 * @param astPattern
	 *            AST input or output pattern
	 * @param irPattern
	 *            IR input or output pattern
	 */
	private void transformPattern(StructTransformer transformer,
			Procedure procedure, EObject astPattern, Pattern irPattern) {
		Port port;
		int totalConsumption;
		AstExpression astRepeat;
		if (astPattern instanceof InputPattern) {
			InputPattern pattern = ((InputPattern) astPattern);
			astRepeat = pattern.getRepeat();
			port = Frontend.instance.getMapping(pattern.getPort());
			totalConsumption = pattern.getTokens().size();
		} else {
			OutputPattern pattern = ((OutputPattern) astPattern);
			astRepeat = pattern.getRepeat();
			port = Frontend.instance.getMapping(pattern.getPort());
			totalConsumption = pattern.getValues().size();
		}

		// evaluates token consumption
		int repeat = 1;
		if (astRepeat != null) {
			repeat = Evaluator.getIntValue(astRepeat);
			totalConsumption *= repeat;
		}
		irPattern.setNumTokens(port, totalConsumption);

		// create port variable
		Var variable = createPortVariable(procedure.getLineNumber(), port,
				totalConsumption);
		irPattern.setVariable(port, variable);

		// load/store tokens (depending on the type of pattern)
		if (astPattern instanceof InputPattern) {
			InputPattern pattern = (InputPattern) astPattern;
			List<Variable> tokens = pattern.getTokens();
			actionLoadTokens(transformer, procedure, variable, tokens, repeat);
		} else {
			OutputPattern pattern = (OutputPattern) astPattern;
			List<AstExpression> values = pattern.getValues();
			actionStoreTokens(transformer, procedure, variable, values, repeat);
		}
	}

}
