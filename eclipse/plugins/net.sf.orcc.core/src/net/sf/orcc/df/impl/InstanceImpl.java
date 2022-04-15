/*
 * Copyright (c) 2009-2011, IETR/INSA of Rennes
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 *   * Redistributions of source code must retain the above copyright notice,
 *     this list of conditions and the following disclaimer.
 *   * Redistributions in binary form must reproduce the above copyright notice,
 *     this list of conditions and the following disclaimer in the documentation
 *     and/or other materials provided with the distribution.
 *   * Neither the name of the IETR/INSA of Rennes nor the names of its
 *     contributors may be used to endorse or promote products derived from this
 *     software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 * WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */
package net.sf.orcc.df.impl;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.Map;

import net.sf.orcc.df.Actor;
import net.sf.orcc.df.Argument;
import net.sf.orcc.df.Connection;
import net.sf.orcc.df.DfPackage;
import net.sf.orcc.df.Entity;
import net.sf.orcc.df.Instance;
import net.sf.orcc.df.Network;
import net.sf.orcc.df.Port;
import net.sf.orcc.df.util.DfUtil;
import net.sf.orcc.graph.Graph;
import net.sf.orcc.graph.impl.VertexImpl;
import net.sf.orcc.ir.Var;
import net.sf.orcc.moc.MoC;
import net.sf.orcc.util.Adaptable;

import org.eclipse.emf.common.notify.Notification;
import org.eclipse.emf.common.notify.NotificationChain;
import org.eclipse.emf.common.notify.impl.AdapterImpl;
import org.eclipse.emf.common.util.EList;
import org.eclipse.emf.ecore.EClass;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.InternalEObject;
import org.eclipse.emf.ecore.impl.ENotificationImpl;
import org.eclipse.emf.ecore.util.EObjectContainmentEList;
import org.eclipse.emf.ecore.util.InternalEList;

/**
 * This class defines an instance. An instance has an id, a class, parameters
 * and attributes. The class of the instance points to an actor or a network.
 * 
 * @author Matthieu Wipliez
 * @generated
 */
public class InstanceImpl extends VertexImpl implements Instance {

	/**
	 * This class clears the value of cachedAdaptedEntity when a new entity is
	 * set on the instance it listens to.
	 * 
	 * @author Matthieu Wipliez
	 * 
	 */
	private static class EntityAdapterImpl extends AdapterImpl {

		@Override
		public void notifyChanged(Notification msg) {
			InstanceImpl inst = (InstanceImpl) target;
			if (inst.cachedAdaptedEntity != null) {
				if (msg.getEventType() == Notification.SET
						&& msg.getFeature() == DfPackage.Literals.INSTANCE__ENTITY) {
					inst.cachedAdaptedEntity = null;
				}
			}
		}

	}

	/**
	 * The cached value of the '{@link #getArguments() <em>Arguments</em>}'
	 * containment reference list. <!-- begin-user-doc --> <!-- end-user-doc -->
	 * 
	 * @see #getArguments()
	 * @ordered
	 */
	protected EList<Argument> arguments;

	/**
	 * when this Instance is adapted as an Entity, this field holds the adapted
	 * entity until the method setEntity is called.
	 */
	private Entity cachedAdaptedEntity;

	/**
	 * The cached value of the '{@link #getEntity() <em>Entity</em>}' reference.
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @see #getEntity()
	 * @generated
	 * @ordered
	 */
	protected EObject entity;

	/**
	 * The default value of the '{@link #getName() <em>Name</em>}' attribute.
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @see #getName()
	 * @generated
	 * @ordered
	 */
	protected static final String NAME_EDEFAULT = null;

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 */
	protected InstanceImpl() {
		super();

		eAdapters().add(new EntityAdapterImpl());
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @generated
	 */
	public EObject basicGetEntity() {
		return entity;
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Object eGet(int featureID, boolean resolve, boolean coreType) {
		switch (featureID) {
		case DfPackage.INSTANCE__ARGUMENTS:
			return getArguments();
		case DfPackage.INSTANCE__ENTITY:
			if (resolve)
				return getEntity();
			return basicGetEntity();
		case DfPackage.INSTANCE__NAME:
			return getName();
		}
		return super.eGet(featureID, resolve, coreType);
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public NotificationChain eInverseRemove(InternalEObject otherEnd,
			int featureID, NotificationChain msgs) {
		switch (featureID) {
		case DfPackage.INSTANCE__ARGUMENTS:
			return ((InternalEList<?>) getArguments()).basicRemove(otherEnd,
					msgs);
		}
		return super.eInverseRemove(otherEnd, featureID, msgs);
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public boolean eIsSet(int featureID) {
		switch (featureID) {
		case DfPackage.INSTANCE__ARGUMENTS:
			return arguments != null && !arguments.isEmpty();
		case DfPackage.INSTANCE__ENTITY:
			return entity != null;
		case DfPackage.INSTANCE__NAME:
			return NAME_EDEFAULT == null ? getName() != null : !NAME_EDEFAULT
					.equals(getName());
		}
		return super.eIsSet(featureID);
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @generated
	 */
	@SuppressWarnings("unchecked")
	@Override
	public void eSet(int featureID, Object newValue) {
		switch (featureID) {
		case DfPackage.INSTANCE__ARGUMENTS:
			getArguments().clear();
			getArguments().addAll((Collection<? extends Argument>) newValue);
			return;
		case DfPackage.INSTANCE__ENTITY:
			setEntity((EObject) newValue);
			return;
		case DfPackage.INSTANCE__NAME:
			setName((String) newValue);
			return;
		}
		super.eSet(featureID, newValue);
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	protected EClass eStaticClass() {
		return DfPackage.Literals.INSTANCE;
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public void eUnset(int featureID) {
		switch (featureID) {
		case DfPackage.INSTANCE__ARGUMENTS:
			getArguments().clear();
			return;
		case DfPackage.INSTANCE__ENTITY:
			setEntity((EObject) null);
			return;
		case DfPackage.INSTANCE__NAME:
			setName(NAME_EDEFAULT);
			return;
		}
		super.eUnset(featureID);
	}

	@Override
	public Actor getActor() {
		return (Actor) getEntity();
	}

	@Override
	@SuppressWarnings("unchecked")
	public <T> T getAdapter(Class<T> type) {
		if (type == Entity.class) {
			// if there is no adapted entity that was cached
			// try to create it
			if (cachedAdaptedEntity == null) {
				EObject object = getEntity();
				if (object instanceof Adaptable) {
					Adaptable adaptable = (Adaptable) object;
					Entity entity = adaptable.getAdapter(Entity.class);
					if (entity != null) {
						// wraps the adapted entity into a new entity
						// which is associated with this instance
						// so it can be used to compute incoming/outgoing
						// port maps.
						cachedAdaptedEntity = new EntityImpl(this, entity);
					}
				}
			}

			// return the adapted entity, or null
			return (T) cachedAdaptedEntity;
		} else if (type == Actor.class) {
			EObject object = getEntity();
			if (object instanceof Actor) {
				return (T) object;
			}
			return null;
		} else if (type == Network.class) {
			EObject object = getEntity();
			if (object instanceof Network) {
				return (T) object;
			}
			return null;
		}
		return super.getAdapter(type);
	}

	@Override
	public Argument getArgument(String name) {
		for (Argument argument : getArguments()) {
			Var variable = argument.getVariable();
			if (variable != null && variable.getName().equals(name)) {
				return argument;
			}
		}
		return null;
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @generated
	 */
	public EList<Argument> getArguments() {
		if (arguments == null) {
			arguments = new EObjectContainmentEList<Argument>(Argument.class,
					this, DfPackage.INSTANCE__ARGUMENTS);
		}
		return arguments;
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @generated
	 */
	public EObject getEntity() {
		if (entity != null && entity.eIsProxy()) {
			InternalEObject oldEntity = (InternalEObject) entity;
			entity = eResolveProxy(oldEntity);
			if (entity != oldEntity) {
				if (eNotificationRequired())
					eNotify(new ENotificationImpl(this, Notification.RESOLVE,
							DfPackage.INSTANCE__ENTITY, oldEntity, entity));
			}
		}
		return entity;
	}

	@Override
	public List<String> getHierarchicalId() {
		List<String> ids = new ArrayList<String>();
		for (Graph graph : getHierarchy()) {
			ids.add(graph.getLabel());
		}
		ids.add(getName());
		return ids;
	}

	@Override
	public String getHierarchicalName() {
		StringBuilder builder = new StringBuilder();
		for (Graph graph : getHierarchy()) {
			builder.append(graph.getLabel());
			builder.append('_');
		}
		builder.append(getName());
		return builder.toString();
	}

	@Override
	public Map<Port, Connection> getIncomingPortMap() {
		return getAdapter(Entity.class).getIncomingPortMap();
	}

	@Override
	public MoC getMoC() {
		if (isActor()) {
			return getActor().getMoC();
		} else if (isNetwork()) {
			return getNetwork().getMoC();
		} else {
			return null;
		}
	}

	@Override
	public String getName() {
		return getLabel();
	}

	@Override
	public Network getNetwork() {
		return (Network) getEntity();
	}

	@Override
	public Map<Port, List<Connection>> getOutgoingPortMap() {
		return getAdapter(Entity.class).getOutgoingPortMap();
	}

	@Override
	public String getPackage() {
		return DfUtil.getPackage(getName());
	}

	@Override
	public String getSimpleName() {
		return DfUtil.getSimpleName(getName());
	}

	@Override
	public boolean isActor() {
		return getEntity() instanceof Actor;
	}

	public boolean isInstance() {
		return true;
	}

	@Override
	public boolean isNetwork() {
		return getEntity() instanceof Network;
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @generated
	 */
	public void setEntity(EObject newEntity) {
		EObject oldEntity = entity;
		entity = newEntity;
		if (eNotificationRequired())
			eNotify(new ENotificationImpl(this, Notification.SET,
					DfPackage.INSTANCE__ENTITY, oldEntity, entity));
	}

	@Override
	public void setName(String newName) {
		setLabel(newName);
	}

	@Override
	public String toString() {
		return getName() + ": " + getEntity();
	}

}
