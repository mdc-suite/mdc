/**
 * <copyright>
 * </copyright>
 *
 * $Id$
 */
package net.sf.orcc.backends.ir;

import net.sf.orcc.ir.Def;
import net.sf.orcc.ir.Instruction;
import net.sf.orcc.ir.Use;

/**
 * <!-- begin-user-doc --> A representation of the model object '
 * <em><b>Inst Cast</b></em>'. <!-- end-user-doc -->
 * 
 * <p>
 * The following features are supported:
 * <ul>
 * <li>{@link net.sf.orcc.backends.ir.InstCast#getTarget <em>Target</em>}</li>
 * <li>{@link net.sf.orcc.backends.ir.InstCast#getSource <em>Source</em>}</li>
 * </ul>
 * </p>
 * 
 * @see net.sf.orcc.backends.ir.IrSpecificPackage#getInstCast()
 * @model
 * @generated
 */
public interface InstCast extends Instruction {
	/**
	 * Returns the value of the '<em><b>Target</b></em>' containment reference.
	 * <!-- begin-user-doc -->
	 * <p>
	 * If the meaning of the '<em>Target</em>' containment reference isn't
	 * clear, there really should be more of a description here...
	 * </p>
	 * <!-- end-user-doc -->
	 * 
	 * @return the value of the '<em>Target</em>' containment reference.
	 * @see #setTarget(Def)
	 * @see net.sf.orcc.backends.ir.IrSpecificPackage#getInstCast_Target()
	 * @model containment="true"
	 * @generated
	 */
	Def getTarget();

	/**
	 * Return <code>true</code> if the target type is different from the source
	 * type.
	 * 
	 * @return <code>true</code> if target type is different from the source
	 *         type
	 */
	public boolean isDifferent();

	/**
	 * Return <code>true</code> if the target type is extended from the source
	 * type.
	 * 
	 * @return <code>true</code> if target type is extended from the source type
	 */
	public boolean isExtended();

	/**
	 * Return <code>true</code> if the source type is signed
	 * 
	 * @return <code>true</code> if source is signed type
	 */
	public boolean isSigned();

	/**
	 * Return <code>true</code> if the target type is trunced from the source
	 * type.
	 * 
	 * @return <code>true</code> if target type is trunced from the source type
	 */
	public boolean isTrunced();

	/**
	 * Sets the value of the '{@link net.sf.orcc.backends.ir.InstCast#getTarget
	 * <em>Target</em>}' containment reference. <!-- begin-user-doc --> <!--
	 * end-user-doc -->
	 * 
	 * @param value
	 *            the new value of the '<em>Target</em>' containment reference.
	 * @see #getTarget()
	 * @generated
	 */
	void setTarget(Def value);

	/**
	 * Returns the value of the '<em><b>Source</b></em>' containment reference.
	 * <!-- begin-user-doc -->
	 * <p>
	 * If the meaning of the '<em>Source</em>' containment reference isn't
	 * clear, there really should be more of a description here...
	 * </p>
	 * <!-- end-user-doc -->
	 * 
	 * @return the value of the '<em>Source</em>' containment reference.
	 * @see #setSource(Use)
	 * @see net.sf.orcc.backends.ir.IrSpecificPackage#getInstCast_Source()
	 * @model containment="true"
	 * @generated
	 */
	Use getSource();

	/**
	 * Sets the value of the '{@link net.sf.orcc.backends.ir.InstCast#getSource
	 * <em>Source</em>}' containment reference. <!-- begin-user-doc --> <!--
	 * end-user-doc -->
	 * 
	 * @param value
	 *            the new value of the '<em>Source</em>' containment reference.
	 * @see #getSource()
	 * @generated
	 */
	void setSource(Use value);

} // InstCast
