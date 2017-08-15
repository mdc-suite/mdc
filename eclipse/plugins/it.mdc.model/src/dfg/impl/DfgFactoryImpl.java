/**
 */
package dfg.impl;

import dfg.*;

import org.eclipse.emf.ecore.EClass;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.EPackage;

import org.eclipse.emf.ecore.impl.EFactoryImpl;

import org.eclipse.emf.ecore.plugin.EcorePlugin;

/**
 * <!-- begin-user-doc -->
 * An implementation of the model <b>Factory</b>.
 * <!-- end-user-doc -->
 * @generated
 */
public class DfgFactoryImpl extends EFactoryImpl implements DfgFactory {
	/**
	 * Creates the default factory implementation.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public static DfgFactory init() {
		try {
			DfgFactory theDfgFactory = (DfgFactory)EPackage.Registry.INSTANCE.getEFactory(DfgPackage.eNS_URI);
			if (theDfgFactory != null) {
				return theDfgFactory;
			}
		}
		catch (Exception exception) {
			EcorePlugin.INSTANCE.log(exception);
		}
		return new DfgFactoryImpl();
	}

	/**
	 * Creates an instance of the factory.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public DfgFactoryImpl() {
		super();
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public EObject create(EClass eClass) {
		switch (eClass.getClassifierID()) {
			case DfgPackage.DFG_GRAPH: return createDfgGraph();
			case DfgPackage.DFG_VERTEX: return createDfgVertex();
			case DfgPackage.DFG_EDGE: return createDfgEdge();
			default:
				throw new IllegalArgumentException("The class '" + eClass.getName() + "' is not a valid classifier");
		}
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public DfgGraph createDfgGraph() {
		DfgGraphImpl dfgGraph = new DfgGraphImpl();
		return dfgGraph;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public DfgVertex createDfgVertex() {
		DfgVertexImpl dfgVertex = new DfgVertexImpl();
		return dfgVertex;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public DfgEdge createDfgEdge() {
		DfgEdgeImpl dfgEdge = new DfgEdgeImpl();
		return dfgEdge;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public DfgPackage getDfgPackage() {
		return (DfgPackage)getEPackage();
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @deprecated
	 * @generated
	 */
	@Deprecated
	public static DfgPackage getPackage() {
		return DfgPackage.eINSTANCE;
	}

} //DfgFactoryImpl
