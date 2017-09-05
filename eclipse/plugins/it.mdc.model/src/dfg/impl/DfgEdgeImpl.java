/**
 */
package dfg.impl;

import dfg.DfgEdge;
import dfg.DfgPackage;
import dfg.DfgVertex;

import org.eclipse.emf.common.notify.Notification;

import org.eclipse.emf.ecore.EClass;
import org.eclipse.emf.ecore.InternalEObject;

import org.eclipse.emf.ecore.impl.ENotificationImpl;
import org.eclipse.emf.ecore.impl.MinimalEObjectImpl;

/**
 * <!-- begin-user-doc -->
 * An implementation of the model object '<em><b>Edge</b></em>'.
 * <!-- end-user-doc -->
 * <p>
 * The following features are implemented:
 * <ul>
 *   <li>{@link dfg.impl.DfgEdgeImpl#getLabel <em>Label</em>}</li>
 *   <li>{@link dfg.impl.DfgEdgeImpl#getVertex1 <em>Vertex1</em>}</li>
 *   <li>{@link dfg.impl.DfgEdgeImpl#getVertex2 <em>Vertex2</em>}</li>
 * </ul>
 * </p>
 *
 * @generated
 */
public class DfgEdgeImpl extends MinimalEObjectImpl.Container implements DfgEdge {
	/**
	 * The default value of the '{@link #getLabel() <em>Label</em>}' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @see #getLabel()
	 * @generated
	 * @ordered
	 */
	protected static final String LABEL_EDEFAULT = null;

	/**
	 * The cached value of the '{@link #getLabel() <em>Label</em>}' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @see #getLabel()
	 * @generated
	 * @ordered
	 */
	protected String label = LABEL_EDEFAULT;

	/**
	 * The cached value of the '{@link #getVertex1() <em>Vertex1</em>}' reference.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @see #getVertex1()
	 * @generated
	 * @ordered
	 */
	protected DfgVertex vertex1;

	/**
	 * The cached value of the '{@link #getVertex2() <em>Vertex2</em>}' reference.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @see #getVertex2()
	 * @generated
	 * @ordered
	 */
	protected DfgVertex vertex2;

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected DfgEdgeImpl() {
		super();
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	protected EClass eStaticClass() {
		return DfgPackage.Literals.DFG_EDGE;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public String getLabel() {
		return label;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public void setLabel(String newLabel) {
		String oldLabel = label;
		label = newLabel;
		if (eNotificationRequired())
			eNotify(new ENotificationImpl(this, Notification.SET, DfgPackage.DFG_EDGE__LABEL, oldLabel, label));
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public DfgVertex getVertex1() {
		if (vertex1 != null && vertex1.eIsProxy()) {
			InternalEObject oldVertex1 = (InternalEObject)vertex1;
			vertex1 = (DfgVertex)eResolveProxy(oldVertex1);
			if (vertex1 != oldVertex1) {
				if (eNotificationRequired())
					eNotify(new ENotificationImpl(this, Notification.RESOLVE, DfgPackage.DFG_EDGE__VERTEX1, oldVertex1, vertex1));
			}
		}
		return vertex1;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public DfgVertex basicGetVertex1() {
		return vertex1;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public void setVertex1(DfgVertex newVertex1) {
		DfgVertex oldVertex1 = vertex1;
		vertex1 = newVertex1;
		if (eNotificationRequired())
			eNotify(new ENotificationImpl(this, Notification.SET, DfgPackage.DFG_EDGE__VERTEX1, oldVertex1, vertex1));
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public DfgVertex getVertex2() {
		if (vertex2 != null && vertex2.eIsProxy()) {
			InternalEObject oldVertex2 = (InternalEObject)vertex2;
			vertex2 = (DfgVertex)eResolveProxy(oldVertex2);
			if (vertex2 != oldVertex2) {
				if (eNotificationRequired())
					eNotify(new ENotificationImpl(this, Notification.RESOLVE, DfgPackage.DFG_EDGE__VERTEX2, oldVertex2, vertex2));
			}
		}
		return vertex2;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public DfgVertex basicGetVertex2() {
		return vertex2;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public void setVertex2(DfgVertex newVertex2) {
		DfgVertex oldVertex2 = vertex2;
		vertex2 = newVertex2;
		if (eNotificationRequired())
			eNotify(new ENotificationImpl(this, Notification.SET, DfgPackage.DFG_EDGE__VERTEX2, oldVertex2, vertex2));
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Object eGet(int featureID, boolean resolve, boolean coreType) {
		switch (featureID) {
			case DfgPackage.DFG_EDGE__LABEL:
				return getLabel();
			case DfgPackage.DFG_EDGE__VERTEX1:
				if (resolve) return getVertex1();
				return basicGetVertex1();
			case DfgPackage.DFG_EDGE__VERTEX2:
				if (resolve) return getVertex2();
				return basicGetVertex2();
		}
		return super.eGet(featureID, resolve, coreType);
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public void eSet(int featureID, Object newValue) {
		switch (featureID) {
			case DfgPackage.DFG_EDGE__LABEL:
				setLabel((String)newValue);
				return;
			case DfgPackage.DFG_EDGE__VERTEX1:
				setVertex1((DfgVertex)newValue);
				return;
			case DfgPackage.DFG_EDGE__VERTEX2:
				setVertex2((DfgVertex)newValue);
				return;
		}
		super.eSet(featureID, newValue);
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public void eUnset(int featureID) {
		switch (featureID) {
			case DfgPackage.DFG_EDGE__LABEL:
				setLabel(LABEL_EDEFAULT);
				return;
			case DfgPackage.DFG_EDGE__VERTEX1:
				setVertex1((DfgVertex)null);
				return;
			case DfgPackage.DFG_EDGE__VERTEX2:
				setVertex2((DfgVertex)null);
				return;
		}
		super.eUnset(featureID);
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public boolean eIsSet(int featureID) {
		switch (featureID) {
			case DfgPackage.DFG_EDGE__LABEL:
				return LABEL_EDEFAULT == null ? label != null : !LABEL_EDEFAULT.equals(label);
			case DfgPackage.DFG_EDGE__VERTEX1:
				return vertex1 != null;
			case DfgPackage.DFG_EDGE__VERTEX2:
				return vertex2 != null;
		}
		return super.eIsSet(featureID);
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public String toString() {
		if (eIsProxy()) return super.toString();

		StringBuffer result = new StringBuffer(super.toString());
		result.append(' ');
		result.append(vertex1);
		result.append(" -> ");
		result.append(vertex2);
		return result.toString();
	}

} //DfgEdgeImpl
