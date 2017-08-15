/**
 */
package dfg;

import org.eclipse.emf.ecore.EAttribute;
import org.eclipse.emf.ecore.EClass;
import org.eclipse.emf.ecore.EPackage;
import org.eclipse.emf.ecore.EReference;

/**
 * <!-- begin-user-doc -->
 * The <b>Package</b> for the model.
 * It contains accessors for the meta objects to represent
 * <ul>
 *   <li>each class,</li>
 *   <li>each feature of each class,</li>
 *   <li>each operation of each class,</li>
 *   <li>each enum,</li>
 *   <li>and each data type</li>
 * </ul>
 * <!-- end-user-doc -->
 * @see dfg.DfgFactory
 * @model kind="package"
 * @generated
 */
public interface DfgPackage extends EPackage {
	/**
	 * The package name.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	String eNAME = "dfg";

	/**
	 * The package namespace URI.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	String eNS_URI = "http://it/diee/unica/mdc/model";

	/**
	 * The package namespace name.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	String eNS_PREFIX = "it.diee.unica.mdc.model";

	/**
	 * The singleton instance of the package.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	DfgPackage eINSTANCE = dfg.impl.DfgPackageImpl.init();

	/**
	 * The meta object id for the '{@link dfg.impl.DfgGraphImpl <em>Graph</em>}' class.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @see dfg.impl.DfgGraphImpl
	 * @see dfg.impl.DfgPackageImpl#getDfgGraph()
	 * @generated
	 */
	int DFG_GRAPH = 0;

	/**
	 * The feature id for the '<em><b>Vertices</b></em>' containment reference list.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 * @ordered
	 */
	int DFG_GRAPH__VERTICES = 0;

	/**
	 * The feature id for the '<em><b>Edges</b></em>' reference list.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 * @ordered
	 */
	int DFG_GRAPH__EDGES = 1;

	/**
	 * The number of structural features of the '<em>Graph</em>' class.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 * @ordered
	 */
	int DFG_GRAPH_FEATURE_COUNT = 2;

	/**
	 * The number of operations of the '<em>Graph</em>' class.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 * @ordered
	 */
	int DFG_GRAPH_OPERATION_COUNT = 0;

	/**
	 * The meta object id for the '{@link dfg.impl.DfgVertexImpl <em>Vertex</em>}' class.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @see dfg.impl.DfgVertexImpl
	 * @see dfg.impl.DfgPackageImpl#getDfgVertex()
	 * @generated
	 */
	int DFG_VERTEX = 1;

	/**
	 * The feature id for the '<em><b>Mappings</b></em>' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 * @ordered
	 */
	int DFG_VERTEX__MAPPINGS = 0;

	/**
	 * The feature id for the '<em><b>Neighbors</b></em>' reference list.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 * @ordered
	 */
	int DFG_VERTEX__NEIGHBORS = 1;

	/**
	 * The feature id for the '<em><b>Connecting</b></em>' reference list.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 * @ordered
	 */
	int DFG_VERTEX__CONNECTING = 2;

	/**
	 * The number of structural features of the '<em>Vertex</em>' class.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 * @ordered
	 */
	int DFG_VERTEX_FEATURE_COUNT = 3;

	/**
	 * The number of operations of the '<em>Vertex</em>' class.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 * @ordered
	 */
	int DFG_VERTEX_OPERATION_COUNT = 0;

	/**
	 * The meta object id for the '{@link dfg.impl.DfgEdgeImpl <em>Edge</em>}' class.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @see dfg.impl.DfgEdgeImpl
	 * @see dfg.impl.DfgPackageImpl#getDfgEdge()
	 * @generated
	 */
	int DFG_EDGE = 2;

	/**
	 * The feature id for the '<em><b>Label</b></em>' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 * @ordered
	 */
	int DFG_EDGE__LABEL = 0;

	/**
	 * The feature id for the '<em><b>Vertex1</b></em>' reference.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 * @ordered
	 */
	int DFG_EDGE__VERTEX1 = 1;

	/**
	 * The feature id for the '<em><b>Vertex2</b></em>' reference.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 * @ordered
	 */
	int DFG_EDGE__VERTEX2 = 2;

	/**
	 * The number of structural features of the '<em>Edge</em>' class.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 * @ordered
	 */
	int DFG_EDGE_FEATURE_COUNT = 3;

	/**
	 * The number of operations of the '<em>Edge</em>' class.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 * @ordered
	 */
	int DFG_EDGE_OPERATION_COUNT = 0;

	/**
	 * Returns the meta object for class '{@link dfg.DfgGraph <em>Graph</em>}'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the meta object for class '<em>Graph</em>'.
	 * @see dfg.DfgGraph
	 * @generated
	 */
	EClass getDfgGraph();

	/**
	 * Returns the meta object for the containment reference list '{@link dfg.DfgGraph#getVertices <em>Vertices</em>}'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the meta object for the containment reference list '<em>Vertices</em>'.
	 * @see dfg.DfgGraph#getVertices()
	 * @see #getDfgGraph()
	 * @generated
	 */
	EReference getDfgGraph_Vertices();

	/**
	 * Returns the meta object for the reference list '{@link dfg.DfgGraph#getEdges <em>Edges</em>}'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the meta object for the reference list '<em>Edges</em>'.
	 * @see dfg.DfgGraph#getEdges()
	 * @see #getDfgGraph()
	 * @generated
	 */
	EReference getDfgGraph_Edges();

	/**
	 * Returns the meta object for class '{@link dfg.DfgVertex <em>Vertex</em>}'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the meta object for class '<em>Vertex</em>'.
	 * @see dfg.DfgVertex
	 * @generated
	 */
	EClass getDfgVertex();

	/**
	 * Returns the meta object for the attribute '{@link dfg.DfgVertex#getMappings <em>Mappings</em>}'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the meta object for the attribute '<em>Mappings</em>'.
	 * @see dfg.DfgVertex#getMappings()
	 * @see #getDfgVertex()
	 * @generated
	 */
	EAttribute getDfgVertex_Mappings();

	/**
	 * Returns the meta object for the reference list '{@link dfg.DfgVertex#getNeighbors <em>Neighbors</em>}'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the meta object for the reference list '<em>Neighbors</em>'.
	 * @see dfg.DfgVertex#getNeighbors()
	 * @see #getDfgVertex()
	 * @generated
	 */
	EReference getDfgVertex_Neighbors();

	/**
	 * Returns the meta object for the reference list '{@link dfg.DfgVertex#getConnecting <em>Connecting</em>}'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the meta object for the reference list '<em>Connecting</em>'.
	 * @see dfg.DfgVertex#getConnecting()
	 * @see #getDfgVertex()
	 * @generated
	 */
	EReference getDfgVertex_Connecting();

	/**
	 * Returns the meta object for class '{@link dfg.DfgEdge <em>Edge</em>}'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the meta object for class '<em>Edge</em>'.
	 * @see dfg.DfgEdge
	 * @generated
	 */
	EClass getDfgEdge();

	/**
	 * Returns the meta object for the attribute '{@link dfg.DfgEdge#getLabel <em>Label</em>}'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the meta object for the attribute '<em>Label</em>'.
	 * @see dfg.DfgEdge#getLabel()
	 * @see #getDfgEdge()
	 * @generated
	 */
	EAttribute getDfgEdge_Label();

	/**
	 * Returns the meta object for the reference '{@link dfg.DfgEdge#getVertex1 <em>Vertex1</em>}'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the meta object for the reference '<em>Vertex1</em>'.
	 * @see dfg.DfgEdge#getVertex1()
	 * @see #getDfgEdge()
	 * @generated
	 */
	EReference getDfgEdge_Vertex1();

	/**
	 * Returns the meta object for the reference '{@link dfg.DfgEdge#getVertex2 <em>Vertex2</em>}'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the meta object for the reference '<em>Vertex2</em>'.
	 * @see dfg.DfgEdge#getVertex2()
	 * @see #getDfgEdge()
	 * @generated
	 */
	EReference getDfgEdge_Vertex2();

	/**
	 * Returns the factory that creates the instances of the model.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the factory that creates the instances of the model.
	 * @generated
	 */
	DfgFactory getDfgFactory();

	/**
	 * <!-- begin-user-doc -->
	 * Defines literals for the meta objects that represent
	 * <ul>
	 *   <li>each class,</li>
	 *   <li>each feature of each class,</li>
	 *   <li>each operation of each class,</li>
	 *   <li>each enum,</li>
	 *   <li>and each data type</li>
	 * </ul>
	 * <!-- end-user-doc -->
	 * @generated
	 */
	interface Literals {
		/**
		 * The meta object literal for the '{@link dfg.impl.DfgGraphImpl <em>Graph</em>}' class.
		 * <!-- begin-user-doc -->
		 * <!-- end-user-doc -->
		 * @see dfg.impl.DfgGraphImpl
		 * @see dfg.impl.DfgPackageImpl#getDfgGraph()
		 * @generated
		 */
		EClass DFG_GRAPH = eINSTANCE.getDfgGraph();

		/**
		 * The meta object literal for the '<em><b>Vertices</b></em>' containment reference list feature.
		 * <!-- begin-user-doc -->
		 * <!-- end-user-doc -->
		 * @generated
		 */
		EReference DFG_GRAPH__VERTICES = eINSTANCE.getDfgGraph_Vertices();

		/**
		 * The meta object literal for the '<em><b>Edges</b></em>' reference list feature.
		 * <!-- begin-user-doc -->
		 * <!-- end-user-doc -->
		 * @generated
		 */
		EReference DFG_GRAPH__EDGES = eINSTANCE.getDfgGraph_Edges();

		/**
		 * The meta object literal for the '{@link dfg.impl.DfgVertexImpl <em>Vertex</em>}' class.
		 * <!-- begin-user-doc -->
		 * <!-- end-user-doc -->
		 * @see dfg.impl.DfgVertexImpl
		 * @see dfg.impl.DfgPackageImpl#getDfgVertex()
		 * @generated
		 */
		EClass DFG_VERTEX = eINSTANCE.getDfgVertex();

		/**
		 * The meta object literal for the '<em><b>Mappings</b></em>' attribute feature.
		 * <!-- begin-user-doc -->
		 * <!-- end-user-doc -->
		 * @generated
		 */
		EAttribute DFG_VERTEX__MAPPINGS = eINSTANCE.getDfgVertex_Mappings();

		/**
		 * The meta object literal for the '<em><b>Neighbors</b></em>' reference list feature.
		 * <!-- begin-user-doc -->
		 * <!-- end-user-doc -->
		 * @generated
		 */
		EReference DFG_VERTEX__NEIGHBORS = eINSTANCE.getDfgVertex_Neighbors();

		/**
		 * The meta object literal for the '<em><b>Connecting</b></em>' reference list feature.
		 * <!-- begin-user-doc -->
		 * <!-- end-user-doc -->
		 * @generated
		 */
		EReference DFG_VERTEX__CONNECTING = eINSTANCE.getDfgVertex_Connecting();

		/**
		 * The meta object literal for the '{@link dfg.impl.DfgEdgeImpl <em>Edge</em>}' class.
		 * <!-- begin-user-doc -->
		 * <!-- end-user-doc -->
		 * @see dfg.impl.DfgEdgeImpl
		 * @see dfg.impl.DfgPackageImpl#getDfgEdge()
		 * @generated
		 */
		EClass DFG_EDGE = eINSTANCE.getDfgEdge();

		/**
		 * The meta object literal for the '<em><b>Label</b></em>' attribute feature.
		 * <!-- begin-user-doc -->
		 * <!-- end-user-doc -->
		 * @generated
		 */
		EAttribute DFG_EDGE__LABEL = eINSTANCE.getDfgEdge_Label();

		/**
		 * The meta object literal for the '<em><b>Vertex1</b></em>' reference feature.
		 * <!-- begin-user-doc -->
		 * <!-- end-user-doc -->
		 * @generated
		 */
		EReference DFG_EDGE__VERTEX1 = eINSTANCE.getDfgEdge_Vertex1();

		/**
		 * The meta object literal for the '<em><b>Vertex2</b></em>' reference feature.
		 * <!-- begin-user-doc -->
		 * <!-- end-user-doc -->
		 * @generated
		 */
		EReference DFG_EDGE__VERTEX2 = eINSTANCE.getDfgEdge_Vertex2();

	}

} //DfgPackage
