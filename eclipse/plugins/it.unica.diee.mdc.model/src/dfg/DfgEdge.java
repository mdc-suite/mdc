/**
 */
package dfg;

import org.eclipse.emf.ecore.EObject;

/**
 * <!-- begin-user-doc -->
 * A representation of the model object '<em><b>Edge</b></em>'.
 * <!-- end-user-doc -->
 *
 * <p>
 * The following features are supported:
 * <ul>
 *   <li>{@link dfg.DfgEdge#getLabel <em>Label</em>}</li>
 *   <li>{@link dfg.DfgEdge#getVertex1 <em>Vertex1</em>}</li>
 *   <li>{@link dfg.DfgEdge#getVertex2 <em>Vertex2</em>}</li>
 * </ul>
 * </p>
 *
 * @see dfg.DfgPackage#getDfgEdge()
 * @model
 * @generated
 */
public interface DfgEdge extends EObject {
	/**
	 * Returns the value of the '<em><b>Label</b></em>' attribute.
	 * <!-- begin-user-doc -->
	 * <p>
	 * If the meaning of the '<em>Label</em>' attribute isn't clear,
	 * there really should be more of a description here...
	 * </p>
	 * <!-- end-user-doc -->
	 * @return the value of the '<em>Label</em>' attribute.
	 * @see #setLabel(String)
	 * @see dfg.DfgPackage#getDfgEdge_Label()
	 * @model
	 * @generated
	 */
	String getLabel();

	/**
	 * Sets the value of the '{@link dfg.DfgEdge#getLabel <em>Label</em>}' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @param value the new value of the '<em>Label</em>' attribute.
	 * @see #getLabel()
	 * @generated
	 */
	void setLabel(String value);

	/**
	 * Returns the value of the '<em><b>Vertex1</b></em>' reference.
	 * <!-- begin-user-doc -->
	 * <p>
	 * If the meaning of the '<em>Vertex1</em>' reference isn't clear,
	 * there really should be more of a description here...
	 * </p>
	 * <!-- end-user-doc -->
	 * @return the value of the '<em>Vertex1</em>' reference.
	 * @see #setVertex1(DfgVertex)
	 * @see dfg.DfgPackage#getDfgEdge_Vertex1()
	 * @model
	 * @generated
	 */
	DfgVertex getVertex1();

	/**
	 * Sets the value of the '{@link dfg.DfgEdge#getVertex1 <em>Vertex1</em>}' reference.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @param value the new value of the '<em>Vertex1</em>' reference.
	 * @see #getVertex1()
	 * @generated
	 */
	void setVertex1(DfgVertex value);

	/**
	 * Returns the value of the '<em><b>Vertex2</b></em>' reference.
	 * <!-- begin-user-doc -->
	 * <p>
	 * If the meaning of the '<em>Vertex2</em>' reference isn't clear,
	 * there really should be more of a description here...
	 * </p>
	 * <!-- end-user-doc -->
	 * @return the value of the '<em>Vertex2</em>' reference.
	 * @see #setVertex2(DfgVertex)
	 * @see dfg.DfgPackage#getDfgEdge_Vertex2()
	 * @model
	 * @generated
	 */
	DfgVertex getVertex2();

	/**
	 * Sets the value of the '{@link dfg.DfgEdge#getVertex2 <em>Vertex2</em>}' reference.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @param value the new value of the '<em>Vertex2</em>' reference.
	 * @see #getVertex2()
	 * @generated
	 */
	void setVertex2(DfgVertex value);

} // DfgEdge
