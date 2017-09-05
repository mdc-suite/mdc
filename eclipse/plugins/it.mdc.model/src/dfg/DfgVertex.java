/**
 */
package dfg;

import java.util.Map;
import org.eclipse.emf.common.util.EList;
import org.eclipse.emf.ecore.EObject;

/**
 * <!-- begin-user-doc -->
 * A representation of the model object '<em><b>Vertex</b></em>'.
 * <!-- end-user-doc -->
 *
 * <p>
 * The following features are supported:
 * <ul>
 *   <li>{@link dfg.DfgVertex#getMappings <em>Mappings</em>}</li>
 *   <li>{@link dfg.DfgVertex#getNeighbors <em>Neighbors</em>}</li>
 *   <li>{@link dfg.DfgVertex#getConnecting <em>Connecting</em>}</li>
 * </ul>
 * </p>
 *
 * @see dfg.DfgPackage#getDfgVertex()
 * @model
 * @generated
 */
public interface DfgVertex extends EObject {
	/**
	 * Returns the value of the '<em><b>Mappings</b></em>' attribute.
	 * <!-- begin-user-doc -->
	 * <p>
	 * If the meaning of the '<em>Mappings</em>' attribute isn't clear,
	 * there really should be more of a description here...
	 * </p>
	 * <!-- end-user-doc -->
	 * @return the value of the '<em>Mappings</em>' attribute.
	 * @see #setMappings(Map)
	 * @see dfg.DfgPackage#getDfgVertex_Mappings()
	 * @model transient="true"
	 * @generated
	 */
	Map<?, ?> getMappings();

	/**
	 * Sets the value of the '{@link dfg.DfgVertex#getMappings <em>Mappings</em>}' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @param value the new value of the '<em>Mappings</em>' attribute.
	 * @see #getMappings()
	 * @generated
	 */
	void setMappings(Map<?, ?> value);

	/**
	 * Returns the value of the '<em><b>Neighbors</b></em>' reference list.
	 * The list contents are of type {@link dfg.DfgVertex}.
	 * <!-- begin-user-doc -->
	 * <p>
	 * If the meaning of the '<em>Neighbors</em>' reference list isn't clear,
	 * there really should be more of a description here...
	 * </p>
	 * <!-- end-user-doc -->
	 * @return the value of the '<em>Neighbors</em>' reference list.
	 * @see dfg.DfgPackage#getDfgVertex_Neighbors()
	 * @model
	 * @generated
	 */
	EList<DfgVertex> getNeighbors();

	/**
	 * Returns the value of the '<em><b>Connecting</b></em>' reference list.
	 * The list contents are of type {@link dfg.DfgEdge}.
	 * <!-- begin-user-doc -->
	 * <p>
	 * If the meaning of the '<em>Connecting</em>' reference list isn't clear,
	 * there really should be more of a description here...
	 * </p>
	 * <!-- end-user-doc -->
	 * @return the value of the '<em>Connecting</em>' reference list.
	 * @see dfg.DfgPackage#getDfgVertex_Connecting()
	 * @model
	 * @generated
	 */
	EList<DfgEdge> getConnecting();

} // DfgVertex
