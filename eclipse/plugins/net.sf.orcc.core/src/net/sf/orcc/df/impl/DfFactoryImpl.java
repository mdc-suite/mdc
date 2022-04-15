/**
 * <copyright>
 * </copyright>
 *
 * $Id$
 */
package net.sf.orcc.df.impl;

import java.util.Collection;
import java.util.List;
import java.util.Map;

import net.sf.orcc.df.Action;
import net.sf.orcc.df.Actor;
import net.sf.orcc.df.Argument;
import net.sf.orcc.df.Connection;
import net.sf.orcc.df.DfFactory;
import net.sf.orcc.df.DfPackage;
import net.sf.orcc.df.Entity;
import net.sf.orcc.df.FSM;
import net.sf.orcc.df.Instance;
import net.sf.orcc.df.Network;
import net.sf.orcc.df.Pattern;
import net.sf.orcc.df.Port;
import net.sf.orcc.df.State;
import net.sf.orcc.df.Tag;
import net.sf.orcc.df.Transition;
import net.sf.orcc.df.Unit;
import net.sf.orcc.graph.Vertex;
import net.sf.orcc.ir.Expression;
import net.sf.orcc.ir.IrFactory;
import net.sf.orcc.ir.Procedure;
import net.sf.orcc.ir.Type;
import net.sf.orcc.ir.Var;
import net.sf.orcc.util.Attribute;

import org.eclipse.emf.ecore.EClass;
import org.eclipse.emf.ecore.EDataType;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.EPackage;
import org.eclipse.emf.ecore.impl.EFactoryImpl;
import org.eclipse.emf.ecore.plugin.EcorePlugin;
import org.eclipse.emf.ecore.util.EcoreUtil;

/**
 * <!-- begin-user-doc --> An implementation of the model <b>Factory</b>. <!--
 * end-user-doc -->
 * @generated
 */
public class DfFactoryImpl extends EFactoryImpl implements DfFactory {
	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @deprecated
	 * @generated
	 */
	@Deprecated
	public static DfPackage getPackage() {
		return DfPackage.eINSTANCE;
	}

	/**
	 * Creates the default factory implementation.
	 * <!-- begin-user-doc --> <!--
	 * end-user-doc -->
	 * @generated
	 */
	public static DfFactory init() {
		try {
			DfFactory theDfFactory = (DfFactory) EPackage.Registry.INSTANCE
					.getEFactory("http://orcc.sf.net/model/2011/Df");
			if (theDfFactory != null) {
				return theDfFactory;
			}
		} catch (Exception exception) {
			EcorePlugin.INSTANCE.log(exception);
		}
		return new DfFactoryImpl();
	}

	/**
	 * Creates an instance of the factory.
	 * <!-- begin-user-doc --> <!--
	 * end-user-doc -->
	 * @generated
	 */
	public DfFactoryImpl() {
		super();
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public EObject create(EClass eClass) {
		switch (eClass.getClassifierID()) {
		case DfPackage.UNIT:
			return createUnit();
		case DfPackage.PORT:
			return createPort();
		case DfPackage.INSTANCE:
			return createInstance();
		case DfPackage.ENTITY:
			return createEntity();
		case DfPackage.ACTOR:
			return createActor();
		case DfPackage.NETWORK:
			return createNetwork();
		case DfPackage.CONNECTION:
			return createConnection();
		case DfPackage.ACTION:
			return createAction();
		case DfPackage.FSM:
			return createFSM();
		case DfPackage.PATTERN:
			return createPattern();
		case DfPackage.STATE:
			return createState();
		case DfPackage.TAG:
			return createTag();
		case DfPackage.TRANSITION:
			return createTransition();
		case DfPackage.PORT_TO_EINTEGER_OBJECT_MAP_ENTRY:
			return (EObject) createPortToEIntegerObjectMapEntry();
		case DfPackage.PORT_TO_VAR_MAP_ENTRY:
			return (EObject) createPortToVarMapEntry();
		case DfPackage.VAR_TO_PORT_MAP_ENTRY:
			return (EObject) createVarToPortMapEntry();
		case DfPackage.ARGUMENT:
			return createArgument();
		default:
			throw new IllegalArgumentException("The class '" + eClass.getName()
					+ "' is not a valid classifier");
		}
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Object createFromString(EDataType eDataType, String initialValue) {
		switch (eDataType.getClassifierID()) {
		case DfPackage.MAP:
			return createMapFromString(eDataType, initialValue);
		case DfPackage.LIST:
			return createListFromString(eDataType, initialValue);
		default:
			throw new IllegalArgumentException("The datatype '"
					+ eDataType.getName() + "' is not a valid classifier");
		}
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public String convertToString(EDataType eDataType, Object instanceValue) {
		switch (eDataType.getClassifierID()) {
		case DfPackage.MAP:
			return convertMapToString(eDataType, instanceValue);
		case DfPackage.LIST:
			return convertListToString(eDataType, instanceValue);
		default:
			throw new IllegalArgumentException("The datatype '"
					+ eDataType.getName() + "' is not a valid classifier");
		}
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @generated
	 */
	public Action createAction() {
		ActionImpl action = new ActionImpl();
		return action;
	}

	@Override
	public Action createAction(String tagName, Pattern inputPattern,
			Pattern outputPattern, Pattern peekedPattern, Procedure scheduler,
			Procedure body) {
		ActionImpl action = new ActionImpl();
		action.setBody(body);
		action.setInputPattern(inputPattern);
		action.setOutputPattern(outputPattern);
		action.setPeekPattern(peekedPattern);
		action.setScheduler(scheduler);
		action.setTag(createTag(tagName));
		return action;
	}

	@Override
	public Action createAction(int lineNumber, String tag) {
		ActionImpl action = new ActionImpl();
		action.setTag(createTag(tag));

		Procedure body = IrFactory.eINSTANCE.createProcedure(tag, lineNumber,
				IrFactory.eINSTANCE.createTypeVoid());
		action.setBody(body);

		action.setInputPattern(createPattern());
		action.setOutputPattern(createPattern());
		action.setPeekPattern(createPattern());

		Procedure scheduler = IrFactory.eINSTANCE.createProcedure(
				"isSchedulable_" + tag, lineNumber,
				IrFactory.eINSTANCE.createTypeBool());
		action.setScheduler(scheduler);

		return action;
	}

	@Override
	public Action createAction(Tag tag, Pattern inputPattern,
			Pattern outputPattern, Pattern peekedPattern, Procedure scheduler,
			Procedure body) {
		ActionImpl action = new ActionImpl();
		action.setBody(body);
		action.setInputPattern(inputPattern);
		action.setOutputPattern(outputPattern);
		action.setPeekPattern(peekedPattern);
		action.setScheduler(scheduler);
		action.setTag(tag);
		return action;
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @generated
	 */
	public Actor createActor() {
		ActorImpl actor = new ActorImpl();
		return actor;
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @generated
	 */
	public Argument createArgument() {
		ArgumentImpl argument = new ArgumentImpl();
		return argument;
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @generated
	 */
	public Map<?, ?> createMapFromString(EDataType eDataType,
			String initialValue) {
		return (Map<?, ?>) super.createFromString(initialValue);
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @generated
	 */
	public String convertMapToString(EDataType eDataType, Object instanceValue) {
		return super.convertToString(instanceValue);
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @generated
	 */
	public List<?> createListFromString(EDataType eDataType, String initialValue) {
		return (List<?>) super.createFromString(initialValue);
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @generated
	 */
	public String convertListToString(EDataType eDataType, Object instanceValue) {
		return super.convertToString(instanceValue);
	}

	@Override
	public Argument createArgument(Var variable, Expression value) {
		ArgumentImpl argument = new ArgumentImpl();
		argument.setVariable(variable);
		argument.setValue(value);
		return argument;
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @generated
	 */
	public Connection createConnection() {
		ConnectionImpl connection = new ConnectionImpl();
		return connection;
	}

	@Override
	public Connection createConnection(Vertex source, Port sourcePort,
			Vertex target, Port targetPort) {
		ConnectionImpl connection = new ConnectionImpl();
		connection.setSource(source);
		connection.setSourcePort(sourcePort);
		connection.setTarget(target);
		connection.setTargetPort(targetPort);
		return connection;
	}

	@Override
	public Connection createConnection(Vertex source, Port sourcePort,
			Vertex target, Port targetPort, Collection<Attribute> attributes) {
		Connection connection = createConnection(source, sourcePort, target,
				targetPort);
		connection.getAttributes().addAll(EcoreUtil.copyAll(attributes));
		return connection;
	}

	@Override
	public Connection createConnection(Vertex source, Port sourcePort,
			Vertex target, Port targetPort, Integer size) {
		Connection connection = createConnection(source, sourcePort, target,
				targetPort);
		connection.setSize(size);
		return connection;
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @generated
	 */
	public FSM createFSM() {
		FSMImpl fsm = new FSMImpl();
		return fsm;
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @generated
	 */
	public Instance createInstance() {
		InstanceImpl instance = new InstanceImpl();
		return instance;
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @generated
	 */
	public Entity createEntity() {
		EntityImpl entity = new EntityImpl();
		return entity;
	}

	@Override
	public Instance createInstance(String id, EObject entity) {
		InstanceImpl instance = new InstanceImpl();
		instance.setName(id);
		instance.setEntity(entity);
		return instance;
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @generated
	 */
	public Network createNetwork() {
		NetworkImpl network = new NetworkImpl();
		return network;
	}

	@Override
	public Network createNetwork(String fileName) {
		NetworkImpl network = new NetworkImpl();
		network.setFileName(fileName);
		return network;
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @generated
	 */
	public Pattern createPattern() {
		PatternImpl pattern = new PatternImpl();
		return pattern;
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @generated
	 */
	public Port createPort() {
		PortImpl port = new PortImpl();
		return port;
	}

	@Override
	public Port createPort(Port port) {
		return EcoreUtil.copy(port);
	}

	@Override
	public Port createPort(Type type, String name) {
		PortImpl port = new PortImpl();
		port.setName(name);
		port.setType(type);
		return port;
	}

	@Override
	public Port createPort(Type type, String name, boolean isNative) {
		PortImpl port = new PortImpl();
		port.setName(name);
		port.setType(type);

		// only set the attribute when the port is native
		if (isNative) {
			port.addAttribute("native");
		}
		return port;
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @generated
	 */
	public Map.Entry<Port, Integer> createPortToEIntegerObjectMapEntry() {
		PortToEIntegerObjectMapEntryImpl portToEIntegerObjectMapEntry = new PortToEIntegerObjectMapEntryImpl();
		return portToEIntegerObjectMapEntry;
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @generated
	 */
	public Map.Entry<Port, Var> createPortToVarMapEntry() {
		PortToVarMapEntryImpl portToVarMapEntry = new PortToVarMapEntryImpl();
		return portToVarMapEntry;
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @generated
	 */
	public State createState() {
		StateImpl state = new StateImpl();
		return state;
	}

	@Override
	public State createState(String name) {
		StateImpl state = new StateImpl();
		state.setName(name);
		return state;
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @generated
	 */
	public Tag createTag() {
		TagImpl tag = new TagImpl();
		return tag;
	}

	@Override
	public Tag createTag(List<String> identifiers) {
		TagImpl tag = new TagImpl();
		tag.getIdentifiers().addAll(identifiers);
		return tag;
	}

	@Override
	public Tag createTag(String tagName) {
		TagImpl tag = new TagImpl();
		tag.getIdentifiers().add(tagName);
		return tag;
	}

	@Override
	public Tag createTag(Tag tag) {
		TagImpl newTag = new TagImpl();
		newTag.getIdentifiers().addAll(tag.getIdentifiers());
		return newTag;
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @generated
	 */
	public Transition createTransition() {
		TransitionImpl transition = new TransitionImpl();
		return transition;
	}

	@Override
	public Transition createTransition(State source, State target) {
		TransitionImpl transition = new TransitionImpl();
		transition.setSource(source);
		transition.setTarget(target);
		return transition;
	}

	@Override
	public Transition createTransition(State source, Action action, State target) {
		Transition transition = createTransition(source, target);
		transition.getActions().add(action);
		return transition;
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @generated
	 */
	public Unit createUnit() {
		UnitImpl unit = new UnitImpl();
		return unit;
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @generated
	 */
	public Map.Entry<Var, Port> createVarToPortMapEntry() {
		VarToPortMapEntryImpl varToPortMapEntry = new VarToPortMapEntryImpl();
		return varToPortMapEntry;
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @generated
	 */
	public DfPackage getDfPackage() {
		return (DfPackage) getEPackage();
	}

} // DfFactoryImpl
