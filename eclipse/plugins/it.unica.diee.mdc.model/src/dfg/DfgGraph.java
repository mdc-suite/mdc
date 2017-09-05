/**
 */
package dfg;

import org.eclipse.emf.common.util.EList;

import org.eclipse.emf.ecore.EObject;

/**
 * <!-- begin-user-doc -->
 * A representation of the model object '<em><b>Graph</b></em>'.
 * <!-- end-user-doc -->
 *
 * <p>
 * The following features are supported:
 * <ul>
 *   <li>{@link dfg.DfgGraph#getVertices <em>Vertices</em>}</li>
 *   <li>{@link dfg.DfgGraph#getEdges <em>Edges</em>}</li>
 * </ul>
 * </p>
 *
 * @see dfg.DfgPackage#getDfgGraph()
 * @model
 * @generated
 */
public interface DfgGraph extends EObject {
	/**
	 * Returns the value of the '<em><b>Vertices</b></em>' containment reference list.
	 * The list contents are of type {@link dfg.DfgVertex}.
	 * <!-- begin-user-doc -->
	 * <p>
	 * If the meaning of the '<em>Vertices</em>' containment reference list isn't clear,
	 * there really should be more of a description here...
	 * </p>
	 * <!-- end-user-doc -->
	 * @return the value of the '<em>Vertices</em>' containment reference list.
	 * @see dfg.DfgPackage#getDfgGraph_Vertices()
	 * @model containment="true"
	 * @generated
	 */
	EList<DfgVertex> getVertices();

	/**
	 * Returns the value of the '<em><b>Edges</b></em>' reference list.
	 * The list contents are of type {@link dfg.DfgEdge}.
	 * <!-- begin-user-doc -->
	 * <p>
	 * If the meaning of the '<em>Edges</em>' reference list isn't clear,
	 * there really should be more of a description here...
	 * </p>
	 * <!-- end-user-doc -->
	 * @return the value of the '<em>Edges</em>' reference list.
	 * @see dfg.DfgPackage#getDfgGraph_Edges()
	 * @model resolveProxies="false"
	 * @generated
	 */
	EList<DfgEdge> getEdges();

} // DfgGraph
