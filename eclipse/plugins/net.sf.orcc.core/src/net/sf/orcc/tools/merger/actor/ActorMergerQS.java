package net.sf.orcc.tools.merger.actor;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import net.sf.orcc.df.Action;
import net.sf.orcc.df.Actor;
import net.sf.orcc.df.Network;
import net.sf.orcc.df.Port;
import net.sf.orcc.df.Connection;
import net.sf.orcc.df.FSM;
import net.sf.orcc.df.Pattern;
import net.sf.orcc.graph.Vertex;
import net.sf.orcc.ir.Block;
import net.sf.orcc.ir.BlockBasic;
import net.sf.orcc.ir.BlockWhile;
import net.sf.orcc.ir.Expression;
import net.sf.orcc.ir.InstAssign;
import net.sf.orcc.ir.InstLoad;
import net.sf.orcc.ir.InstStore;
import net.sf.orcc.ir.Instruction;
import net.sf.orcc.ir.OpBinary;
import net.sf.orcc.ir.Procedure;
import net.sf.orcc.ir.Type;
import net.sf.orcc.ir.Var;
import net.sf.orcc.ir.Param;
import net.sf.orcc.ir.util.AbstractIrVisitor;
import net.sf.orcc.ir.util.IrUtil;
import net.sf.orcc.util.OrccLogger;

import org.eclipse.emf.ecore.util.EcoreUtil;
import org.eclipse.emf.ecore.util.EcoreUtil.Copier;

/**
 * This class merges actors based on a merging specification in
 * an XML file. The class is analogous to ActorMergerSDF.
 * 
 * @author Jani Boutellier
 * @author Ghislain Roquier
 * 
 */

public class ActorMergerQS extends ActorMergerBase {

	private Network network;
	
	private List<Schedule> scheduleList;
	
	private List<Action> guardList;
	
	public class ActionUpdater extends AbstractIrVisitor<Void> {

		private Pattern oldInputPattern;

		private Pattern oldOutputPattern;

		/**
		 * Create a new visitor able to update the FIFO accesses.
		 * 
		 * @param action
		 *            the action containing the old patterns
		 */
		
		public ActionUpdater(Action action) {
			this.oldInputPattern = action.getInputPattern();
			this.oldOutputPattern = action.getOutputPattern();
		}

		@Override
		public Void caseInstLoad(InstLoad load) {
			Port port = oldInputPattern.getPort(load.getSource().getVariable());
			if (port != null) {
				List<Expression> indexes = load.getIndexes();
				String portName = port.getAttribute("shortName").getStringValue();
				Expression e1 = irFactory.createExprVar(irFactory.createVar(irFactory.createTypeInt(32), "offset_" + portName, false, 0));
				Expression e2 = IrUtil.copy(indexes.get(0));
				Expression bop = irFactory.createExprBinary(e1, OpBinary.PLUS,
						e2, e1.getType());
				if (!buffersMap.containsKey(port)) {
					indexes.set(0, bop);
				} else if (port.hasAttribute("externalized")) {
					int size = buffersMap.get(port).getType().getDimensions().get(0);
					indexes.set(0, irFactory.createExprBinary(bop, OpBinary.MOD,
							irFactory.createExprInt(size), e1.getType()));
				} else {
					indexes.set(0, bop);
				}
			}
			return null;
		}

		@Override
		public Void caseInstStore(InstStore store) {
			Port port = oldOutputPattern.getPort(store.getTarget().getVariable());
			if (port != null) {
				List<Expression> indexes = store.getIndexes();
				String portName = port.getAttribute("shortName").getStringValue();
				Expression e1 = irFactory.createExprVar(irFactory.createVar(irFactory.createTypeInt(32), "offset_" + portName, false, 0));
				Expression e2 = IrUtil.copy(indexes.get(0));
				Expression bop = irFactory.createExprBinary(e1, OpBinary.PLUS,
						e2, e1.getType());
				if (!buffersMap.containsKey(port)) {
					indexes.set(0, bop);
				} else if (port.hasAttribute("externalized")) {
					int size = buffersMap.get(port).getType().getDimensions().get(0);
					indexes.set(0, irFactory.createExprBinary(bop, OpBinary.MOD,
							irFactory.createExprInt(size), e1.getType()));
				} else {
					indexes.set(0, bop);
				}
			}
			return null;
		}

		@Override
		public Void caseProcedure(Procedure procedure) {
			super.caseProcedure(procedure);
			return null;
		}
	}
	
	private class ActionProcedureMap {

		private class ActionProcedurePair {
			Procedure procedure;
			Action action;
			
			ActionProcedurePair(Action action, Procedure procedure) {
				this.action = action;
				this.procedure = procedure;
			}
			
			Action getAction() {
				return action;
			}
			
			Procedure getProcedure() {
				return procedure;
			}
		}
		
		private List<ActionProcedurePair> list; 
		
		/**
		 * Keep track of actions that have been transformed to procedures.
		 * 
		 */
		public ActionProcedureMap() {
			this.list = new ArrayList<ActionProcedurePair>();
		}
		
		public void add(Action action, Procedure procedure) {
			list.add(new ActionProcedurePair(action, procedure));
		}
		
		public Procedure getProcedure(Action action) {
			for (ActionProcedurePair pair : list) {
				if (pair.getAction().equals(action)) {
					return pair.getProcedure();
				}
			}
			return null;
		}
	}
	
	ActionProcedureMap correspondences;
	
	public ActorMergerQS(Network network, Copier copier, String definitionFile, List<Schedule> scheduleList, List<Action> guardList) {
		this.network = network;
		this.copier = copier;
		this.correspondences = new ActionProcedureMap();
		this.scheduleList = scheduleList;
		this.guardList = guardList;
	}

	public Actor createMergedActor(Actor actor, FSM fsm) {
		superActor = actor;
		buffersMap = new HashMap<Port, Var>();
		superActor.setName(network.getName());
		superActor.setFsm(fsm);

		copyPorts(network);
		copyVariables(network);
		copyProcedures(network);
		copyActions(network);
		createSuperactions();
		modifyMemAccesses(network);

		return superActor;
	}
	
	private void copyPorts(Network network) {
		// Create input/output ports
		for (Port port : network.getInputs()) {
			superActor.getInputs().add((Port)copier.copy(port));
		}
		for (Port port : network.getOutputs()) {
			superActor.getOutputs().add((Port)copier.copy(port));
		}
	}

	private void copyAction(String actorName, Action action) {
		Procedure actionCopy = IrUtil.copy(action.getBody());
		actionCopy.setName(new String(actorName + "_" + action.getName() + "_p"));
		BlockBasic last = actionCopy.getLast();
		if(!last.getInstructions().get(last.getInstructions().size() -
				1).isInstReturn()) {
			last.add(irFactory.createInstReturn());
		}
		createParameters(actionCopy, action);
		correspondences.add(action, actionCopy);
		superActor.getProcs().add(actionCopy);
	}
	
	private void copyActions(Network network) {
		for (Vertex vertex : network.getChildren()) {
			Actor actor = vertex.getAdapter(Actor.class);
			for (Action action : actor.getActions()) {
				copyAction(actor.getName(), action);
			}
			for (Action action : actor.getInitializes()) {
				copyAction(actor.getName(), action);
			}
		}
	}

	private void modifyMemAccesses(Network network) {
		for (Vertex vertex : network.getChildren()) {
			Actor actor = vertex.getAdapter(Actor.class);
			for (Action action : actor.getActions()) {
				new ActionUpdater(action).doSwitch(correspondences.getProcedure(action));
			}
		}
	}

	private void createParameters(Procedure procedure, Action action) {
		Pattern inputPattern = action.getInputPattern();
		for(Port port : inputPattern.getPorts()) {
			createParameterPair(procedure, inputPattern.getVariable(port));
		}
		Pattern outputPattern = action.getOutputPattern();
		for(Port port : outputPattern.getPorts()) {
			createParameterPair(procedure, outputPattern.getVariable(port));
		}
	}
	
	private void createParameterPair(Procedure procedure, Var var) {
		Param param = irFactory.createParam(var);
		param.setByRef(true);
		procedure.getParameters().add(param);
		param = irFactory.createParam(irFactory.createVar(
				irFactory.createTypeInt(32),
				"offset_" + var.getName(), true, 0));
		param.setByRef(false);
		procedure.getParameters().add(param);
	}

	private void createSuperactions() {
		for(Action action : superActor.getActions()) {
			elaborateSuperaction(action);
		}
	}

	/**
	 * Creates the body of the static action.
	 * 
	 * @return the body of the static action
	 */
	private void elaborateSuperaction(Action superaction) {
		boolean useFullFifos = true;
		if (superActor.hasAttribute("RegisterFeedback")) {
			useFullFifos = false;
		}
		String actionName = superaction.getName();
		BufferSizer bufferSizer = new BufferSizer(network);
		Schedule schedule = getSchedule(scheduleList, network.getName(), actionName);

		ScheduleAnalyzer analyzer = new ScheduleAnalyzer(network, copier);
		analyzer.analyze(superActor, schedule);
		analyzer.markInternalFifos(superActor, useFullFifos);

		Pattern inputPattern = computeScheduleInputPattern(network, schedule.getIterands());
		Pattern outputPattern = computeScheduleOutputPattern(network, schedule.getIterands());
		superaction.setInputPattern(inputPattern);
		superaction.setOutputPattern(outputPattern);

		superaction.setBody(irFactory.createProcedure(actionName, 0,
				irFactory.createTypeVoid()));
		createBuffers(superaction.getBody(), bufferSizer.getMaxTokens(schedule), false);
		if (!useFullFifos) {
			createFeedbackBuffers(bufferSizer.getMaxTokens(schedule));
		}
		createPortVarCounters(superaction.getBody(), inputPattern, outputPattern);
		createInputBufferCopies(superaction.getBody(), inputPattern);
		createStaticSchedule(superaction.getBody(), schedule);
		createOutputBufferCopies(superaction.getBody(), outputPattern);
		superaction.getBody().getLast().add(irFactory.createInstReturn());
		Action guard = getGuard(guardList, network.getName(), actionName);

		superaction.setPeekPattern(guard.getPeekPattern());
		superaction.setScheduler(guard.getBody());
	}

	private Schedule getSchedule(List<Schedule> scheduleList, String actorName, String actionName) {
		for(Schedule schedule : scheduleList) {
			if (actorName.equals(schedule.getOwner()) && actionName.equals(schedule.getName())) {
				return schedule;
			}
		}
		OrccLogger.severeln("ActorMergerQS::getSchedule() could not find a schedule for " + actorName + " " + actionName);
		return null;
	}

	private Action getGuard(List<Action> guardList, String actorName, String actionName) {
		for(Action guard : guardList) {
			if (actorName.equals(guard.getAttribute("actorName").getStringValue()) && actionName.equals(guard.getAttribute("actionName").getStringValue())) {
				return guard;
			}
		}
		return null;
	}

	private void addToPattern(Pattern pattern, Port port, int count) {
		if (!pattern.contains(port)) {
			pattern.getPorts().add(port);
		}
		Port superactionPort = pattern.getPorts().get(
				MergerUtil.findPort(pattern.getPorts(), port.getName()));
		pattern.setNumTokens(superactionPort, 
				pattern.getNumTokens(superactionPort) + count);
	}
	
	/*
	 * Each superaction instance has an input and output pattern
	 * that is visible to the actors neighboring its superactor. 
	 * The pattern need to be determined from the invocations.
	 */
	
	public Pattern computeScheduleInputPattern(Network subNetwork, List<Iterand> invocations) {
		Pattern inputPattern = dfFactory.createPattern();
		for (Iterand iterand : invocations) {
			Pattern iterandPattern = iterand.getAction().getInputPattern();
			for (Port port : iterandPattern.getPorts()) {
				if (MergerUtil.findPort(subNetwork.getInputs(), port.getName()) >= 0) {
					addToPattern(inputPattern, port, iterandPattern.getNumTokens(port));
				} else {
					int superActorPortIndex = MergerUtil.findPort(superActor.getInputs(), port.getName());
					if (superActorPortIndex >= 0) {
						Port superActorPort = superActor.getInputs().get(superActorPortIndex);
						if (superActorPort.hasAttribute("externalized")) {
							addToPattern(inputPattern, port, iterandPattern.getNumTokens(port));
						}
					}
				}
			}
		}
		return createInputPattern(inputPattern);
	}

	public Pattern computeScheduleOutputPattern(Network subNetwork, List<Iterand> invocations) {
		Pattern outputPattern = dfFactory.createPattern();
		for (Iterand iterand : invocations) {
			Pattern iterandPattern = iterand.getAction().getOutputPattern();
			for (Port port : iterandPattern.getPorts()) {
				if (MergerUtil.findPort(subNetwork.getOutputs(), port.getName()) >= 0) {
					addToPattern(outputPattern, port, iterandPattern.getNumTokens(port));
				} else {
					int superActorPortIndex = MergerUtil.findPort(superActor.getOutputs(), port.getName());
					if (superActorPortIndex >= 0) {
						Port superActorPort = superActor.getOutputs().get(superActorPortIndex);
						if (superActorPort.hasAttribute("externalized")) {
							addToPattern(outputPattern, port, iterandPattern.getNumTokens(port));
						}
					}
				}
			}
		}
		return createOutputPattern(outputPattern);
	}

	private void createFeedbackBuffers(Map<Connection, Integer> maxTokens) {

		// Create buffers and counters for feedback connections
		for (Connection conn : maxTokens.keySet()) {
			if (conn.getSourcePort().hasAttribute("externalized")) {
				Var buffer = null;
				if (!conn.hasAttribute("bufferCreated")) {
					// create actor-level buffer
					Integer size = conn.getSize();
					if (size.intValue() > 0) {
						String name = "buffer_" + conn.getSourcePort().getName() + "_" + conn.getTargetPort().getName();
						Type eltType = conn.getSourcePort().getType();
						Type type = irFactory.createTypeList(size, eltType);
						buffer = irFactory.createVar(0, type, name, true);
						superActor.addStateVar(buffer);
			
						// create read and write counters
						buffer.addAttribute("_w");
						buffer.addAttribute("_r");
			
						buffersMap.put(conn.getSourcePort(), buffer);
						buffersMap.put(conn.getTargetPort(), buffer);
					}
					conn.addAttribute("bufferCreated");
				} else {
					buffer = buffersMap.get(conn.getSourcePort());
				}
				buffer.setAttribute("_w", Integer.valueOf(0));
				buffer.setAttribute("_r", Integer.valueOf(0));
			}
		}
	}
	
	private void createPortVarCounters(Procedure body, Pattern inputPattern, Pattern outputPattern) {
		// Create counters for inputs
		for (Port port : inputPattern.getPorts()) {
			Var buffer = irFactory.createVar(0, irFactory.createTypeList(
					inputPattern.getNumTokens(port), port.getType()),
					port.getName() + "_tmp", true);
			buffer.addAttribute("_w");
			buffer.addAttribute("_r");
			buffer.setAttribute("_w", Integer.valueOf(0));
			buffer.setAttribute("_r", Integer.valueOf(0));
			body.addLocal(buffer);
		}
		// Create counters for outputs
		for (Port port : outputPattern.getPorts()) {
			Var buffer = irFactory.createVar(0, irFactory.createTypeList(
					outputPattern.getNumTokens(port), port.getType()),
					port.getName() + "_tmp", true);
			buffer.addAttribute("_w");
			buffer.addAttribute("_r");
			buffer.setAttribute("_w", Integer.valueOf(0));
			buffer.setAttribute("_r", Integer.valueOf(0));
			body.addLocal(buffer);
		}
	}
	
	private InstLoad createInputCopyLoopLoad(Var loopVar, Var tmpToken, Var source) {
		List<Expression> loadIndex = new ArrayList<Expression>(1);
		loadIndex.add(irFactory.createExprBinary(
						irFactory.createExprVar(loopVar), OpBinary.PLUS,
				irFactory.createExprInt(0), irFactory.createTypeInt(32)));
		InstLoad load = irFactory.createInstLoad(0, tmpToken,
				source, loadIndex);
		return load;
	}

	private InstStore createInputCopyLoopStore(Var loopVar, Var tmpToken, Var target) {
		List<Expression> storeIndex = new ArrayList<Expression>(1);
		storeIndex.add(irFactory.createExprVar(loopVar));
		InstStore store = irFactory.createInstStore(0,
				target, storeIndex, irFactory.createExprVar(tmpToken));
		return store;
	}

	private Instruction createOutputCopyLoopLoad(Var loopVar, Var tmpToken, Var target) {
		List<Expression> storeIndex = new ArrayList<Expression>(1);
		storeIndex.add(irFactory.createExprVar(loopVar));
		InstLoad load = irFactory.createInstLoad(0, tmpToken,
				target, storeIndex);
		return load;
	}

	private Instruction createOutputCopyLoopStore(Var loopVar, Var tmpToken, Var source) {
		List<Expression> loadIndex = new ArrayList<Expression>(1);
		loadIndex.add(irFactory.createExprBinary(
						irFactory.createExprVar(loopVar), OpBinary.PLUS,
				irFactory.createExprInt(0), irFactory.createTypeInt(32)));
		InstStore store = irFactory.createInstStore(0,
				source, loadIndex, irFactory.createExprVar(tmpToken));
		return store;
	}

	private void createCopyLoop(Procedure body, int rate, Var loopVar, Instruction load, Instruction store) {
		BlockBasic block = irFactory.createBlockBasic();
		body.getLast().add(irFactory.createInstAssign(loopVar, irFactory.createExprInt(0)));
		block.add(load);
		block.add(store);
		InstAssign assign = irFactory.createInstAssign(loopVar,
				irFactory.createExprInt(0));
		assign = irFactory.createInstAssign(loopVar, irFactory
				.createExprBinary(irFactory.createExprVar(loopVar),
						OpBinary.PLUS, irFactory.createExprInt(1),
						loopVar.getType()));
		block.add(assign);
		Expression condition = irFactory
				.createExprBinary(irFactory.createExprVar(loopVar),
						OpBinary.LT, irFactory.createExprInt(rate),
						irFactory.createTypeBool());
		List<Block> blocks = new ArrayList<Block>(1);
		blocks.add(block);
		BlockWhile copyLoop = irFactory.createBlockWhile();
		copyLoop.setJoinBlock(irFactory.createBlockBasic());
		copyLoop.setCondition(condition);
		copyLoop.getBlocks().addAll(blocks);
		body.getBlocks().add(copyLoop);
	}

	private void createInputBufferCopies(Procedure body, Pattern inputPattern) {
		for (Port port : inputPattern.getPorts()) {
			Var loopVar = body.newTempLocalVariable(
					irFactory.createTypeInt(32),
					port.getName() + "_copyIdx");
			Var tmpToken = body.newTempLocalVariable(
					EcoreUtil.copy(port.getType()),
					port.getName() + "_token");
			createCopyLoop(body, inputPattern.getNumTokens(port), loopVar,
					createInputCopyLoopLoad(loopVar, tmpToken,
					inputPattern.getVariable(port)), createInputCopyLoopStore(
					loopVar, tmpToken, findVariable(body.getLocals(),
					port.getName() + "_tmp")));
		}
	}

	private void createOutputBufferCopies(Procedure body, Pattern outputPattern) {
		for (Port port : outputPattern.getPorts()) {
			Var loopVar = body.newTempLocalVariable(
					irFactory.createTypeInt(32),
					port.getName() + "_copyIdx");
			Var tmpToken = body.newTempLocalVariable(
					EcoreUtil.copy(port.getType()),
					port.getName() + "_token");
			createCopyLoop(body, outputPattern.getNumTokens(port), loopVar,
					createOutputCopyLoopLoad(loopVar, tmpToken,
					findVariable(body.getLocals(), port.getName() + "_tmp")),
					createOutputCopyLoopStore(loopVar, tmpToken,
					outputPattern.getVariable(port)));
		}
	}

	private Pattern createInputPattern(Pattern actionInputPattern) {
		Pattern inputPattern = dfFactory.createPattern();
		for (Port port : superActor.getInputs()) {
			port.setNumTokensConsumed(createPortPattern(inputPattern, 
					actionInputPattern, port, "_r"));
		}
		return inputPattern;
	}

	private Pattern createOutputPattern(Pattern actionOutputPattern) {
		Pattern outputPattern = dfFactory.createPattern();
		for (Port port : superActor.getOutputs()) {
			port.setNumTokensProduced(createPortPattern(outputPattern, 
					actionOutputPattern, port, "_w"));
		}
		return outputPattern;
	}

	private int createPortPattern(Pattern targetPattern, Pattern sourcePattern,
			Port port, String attrName) {
		int portIndex = MergerUtil.findPort(sourcePattern.getPorts(), port.getName());
		if (portIndex >= 0) {
			Port sourcePort = sourcePattern.getPorts().get(portIndex);
			sourcePort.setAttribute(attrName, Integer.valueOf(0));
			int prd = sourcePattern.getNumTokens(sourcePort);
			targetPattern.setNumTokens(port, prd);
			targetPattern.setVariable(port, irFactory.createVar(0, irFactory.createTypeList(prd,
					EcoreUtil.copy(port.getType())), port.getName(), true));
			return prd;
		} else {
			return 0;
		}
	}
	
	/**
	 * Create the procedural code of a static schedule.
	 * 
	 * @param procedure
	 *            the associated procedure
	 * @param schedule
	 *            the current schedule
	 */
	private void createStaticSchedule(Procedure procedure, Schedule schedule) {
		for (Iterand iterand : schedule.getIterands()) {
			List<Expression> procParams = new ArrayList<Expression>();
			processInputs(iterand.getAction(), procParams,
					procedure.getLocals());
			processOutputs(iterand.getAction(), procParams,
					procedure.getLocals());
			Instruction instruction = irFactory.createInstCall(
					null, correspondences.getProcedure(iterand.getAction()),
					procParams);
			procedure.getLast().add(instruction);
		}
	}

	private void processInputs(Action action, List<Expression> procParams,
			List<Var> locals) {
		for(Port port : action.getInputPattern().getPorts()) {
			processPort(procParams, port, "_r",
					action.getInputPattern().getNumTokens(port), locals);
		}
	}

	private void processOutputs(Action action, List<Expression> procParams,
			List<Var> locals) {
		for(Port source : action.getOutputPattern().getPorts()) {
			processPort(procParams, source, "_w",
					action.getOutputPattern().getNumTokens(source), locals);
		}
	}
	
	private Var findVariable(List<Var> varlist, String name) {
		for (Var var : varlist) {
			if (var.getName().equals(name)) {
				return var;
			}
		}
		OrccLogger.warnln("ActorMergerQS::findVariable() could not find " + name);
		return null;
	}
	
	private void processPort(List<Expression> procParams, Port port,
			String idxName, int tokenRate, List<Var> locals) {
		if (buffersMap.containsKey(port)) {
			Var memVar = buffersMap.get(port);
			procParams.add(irFactory.createExprVar(memVar));
			int val = ((Integer)memVar.getValueAsObject(idxName)).intValue();
			procParams.add(irFactory.createExprInt(val));
			memVar.setAttribute(idxName, Integer.valueOf((val + tokenRate)));
		} else {
			Var buffer = findVariable(locals,  port.getName() + "_tmp");
			if (buffer != null) {
				procParams.add(irFactory.createExprVar(buffer));
				int val = ((Integer)buffer.getValueAsObject(idxName)).intValue();
				procParams.add(irFactory.createExprInt(val));
				buffer.setAttribute(idxName, Integer.valueOf((val + tokenRate)));
			}
		}
	}
}


