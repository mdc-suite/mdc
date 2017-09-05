/**
 */
package dfg.impl;

import dfg.DfgEdge;
import dfg.DfgPackage;
import dfg.DfgVertex;
import java.util.Collection;
import java.util.Map;
import org.eclipse.emf.common.notify.Notification;
import org.eclipse.emf.common.util.EList;
import org.eclipse.emf.ecore.EClass;
import org.eclipse.emf.ecore.impl.ENotificationImpl;
import org.eclipse.emf.ecore.impl.MinimalEObjectImpl;
import org.eclipse.emf.ecore.util.EObjectResolvingEList;

/**
 * <!-- begin-user-doc -->
 * An implementation of the model object '<em><b>Vertex</b></em>'.
 * <!-- end-user-doc -->
 * <p>
 * The following features are implemented:
 * <ul>
 *   <li>{@link dfg.impl.DfgVertexImpl#getMappings <em>Mappings</em>}</li>
 *   <li>{@link dfg.impl.DfgVertexImpl#getNeighbors <em>Neighbors</em>}</li>
 *   <li>{@link dfg.impl.DfgVertexImpl#getConnecting <em>Connecting</em>}</li>
 * </ul>
 * </p>
 *
 * @generated
 */
public class DfgVertexImpl extends MinimalEObjectImpl.Container implements DfgVertex {
	/**
	 * The cached value of the '{@link #getMappings() <em>Mappings</em>}' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @see #getMappings()
	 * @generated
	 * @ordered
	 */
	protected Map<?, ?> mappings;

	/**
	 * The cached value of the '{@link #getNeighbors() <em>Neighbors</em>}' reference list.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @see #getNeighbors()
	 * @generated
	 * @ordered
	 */
	protected EList<DfgVertex> neighbors;

	/**
	 * The cached value of the '{@link #getConnecting() <em>Connecting</em>}' reference list.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @see #getConnecting()
	 * @generated
	 * @ordered
	 */
	protected EList<DfgEdge> connecting;

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected DfgVertexImpl() {
		super();
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	protected EClass eStaticClass() {
		return DfgPackage.Literals.DFG_VERTEX;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public Map<?, ?> getMappings() {
		return mappings;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public void setMappings(Map<?, ?> newMappings) {
		Map<?, ?> oldMappings = mappings;
		mappings = newMappings;
		if (eNotificationRequired())
			eNotify(new ENotificationImpl(this, Notification.SET, DfgPackage.DFG_VERTEX__MAPPINGS, oldMappings, mappings));
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public EList<DfgVertex> getNeighbors() {
		if (neighbors == null) {
			neighbors = new EObjectResolvingEList<DfgVertex>(DfgVertex.class, this, DfgPackage.DFG_VERTEX__NEIGHBORS);
		}
		return neighbors;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public EList<DfgEdge> getConnecting() {
		if (connecting == null) {
			connecting = new EObjectResolvingEList<DfgEdge>(DfgEdge.class, this, DfgPackage.DFG_VERTEX__CONNECTING);
		}
		return connecting;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Object eGet(int featureID, boolean resolve, boolean coreType) {
		switch (featureID) {
			case DfgPackage.DFG_VERTEX__MAPPINGS:
				return getMappings();
			case DfgPackage.DFG_VERTEX__NEIGHBORS:
				return getNeighbors();
			case DfgPackage.DFG_VERTEX__CONNECTING:
				return getConnecting();
		}
		return super.eGet(featureID, resolve, coreType);
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@SuppressWarnings("unchecked")
	@Override
	public void eSet(int featureID, Object newValue) {
		switch (featureID) {
			case DfgPackage.DFG_VERTEX__MAPPINGS:
				setMappings((Map<?, ?>)newValue);
				return;
			case DfgPackage.DFG_VERTEX__NEIGHBORS:
				getNeighbors().clear();
				getNeighbors().addAll((Collection<? extends DfgVertex>)newValue);
				return;
			case DfgPackage.DFG_VERTEX__CONNECTING:
				getConnecting().clear();
				getConnecting().addAll((Collection<? extends DfgEdge>)newValue);
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
			case DfgPackage.DFG_VERTEX__MAPPINGS:
				setMappings((Map<?, ?>)null);
				return;
			case DfgPackage.DFG_VERTEX__NEIGHBORS:
				getNeighbors().clear();
				return;
			case DfgPackage.DFG_VERTEX__CONNECTING:
				getConnecting().clear();
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
			case DfgPackage.DFG_VERTEX__MAPPINGS:
				return mappings != null;
			case DfgPackage.DFG_VERTEX__NEIGHBORS:
				return neighbors != null && !neighbors.isEmpty();
			case DfgPackage.DFG_VERTEX__CONNECTING:
				return connecting != null && !connecting.isEmpty();
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
		result.append(" (mappings: ");
		result.append(mappings);
		result.append(')');
		return result.toString();
	}

} //DfgVertexImpl
