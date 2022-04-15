/**
 * <copyright>
 * Copyright (c) 2009-2012, IETR/INSA of Rennes
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
 * </copyright>
 */
package net.sf.orcc.backends.llvm.tta.architecture;

import java.util.Map;

import net.sf.orcc.graph.Vertex;

import org.eclipse.emf.common.util.EList;

/**
 * <!-- begin-user-doc --> A representation of the model object '
 * <em><b>Component</b></em>'. <!-- end-user-doc -->
 *
 * <p>
 * The following features are supported:
 * <ul>
 *   <li>{@link net.sf.orcc.backends.llvm.tta.architecture.Component#getName <em>Name</em>}</li>
 *   <li>{@link net.sf.orcc.backends.llvm.tta.architecture.Component#getInputs <em>Inputs</em>}</li>
 *   <li>{@link net.sf.orcc.backends.llvm.tta.architecture.Component#getOutputs <em>Outputs</em>}</li>
 * </ul>
 * </p>
 *
 * @see net.sf.orcc.backends.llvm.tta.architecture.ArchitecturePackage#getComponent()
 * @model
 * @generated
 */
public interface Component extends Vertex {

	void addInput(Port port);

	void addOutput(Port port);

	Map<Port, Link> getIncomingPortMap();

	/**
	 * Returns the value of the '<em><b>Inputs</b></em>' containment reference
	 * list. The list contents are of type
	 * {@link net.sf.orcc.backends.llvm.tta.architecture.Port}. <!--
	 * begin-user-doc -->
	 * <p>
	 * If the meaning of the '<em>Inputs</em>' containment reference list isn't
	 * clear, there really should be more of a description here...
	 * </p>
	 * <!-- end-user-doc -->
	 * 
	 * @return the value of the '<em>Inputs</em>' containment reference list.
	 * @see net.sf.orcc.backends.llvm.tta.architecture.ArchitecturePackage#getComponent_Inputs()
	 * @model containment="true"
	 * @generated
	 */
	EList<Port> getInputs();

	/**
	 * Returns the value of the '<em><b>Name</b></em>' attribute. <!--
	 * begin-user-doc -->
	 * <p>
	 * If the meaning of the '<em>Name</em>' attribute isn't clear, there really
	 * should be more of a description here...
	 * </p>
	 * <!-- end-user-doc -->
	 * 
	 * @return the value of the '<em>Name</em>' attribute.
	 * @see #setName(String)
	 * @see net.sf.orcc.backends.llvm.tta.architecture.ArchitecturePackage#getComponent_Name()
	 * @model
	 * @generated
	 */
	String getName();

	Map<Port, Link> getOutgoingPortMap();

	/**
	 * Returns the value of the '<em><b>Outputs</b></em>' containment reference
	 * list. The list contents are of type
	 * {@link net.sf.orcc.backends.llvm.tta.architecture.Port}. <!--
	 * begin-user-doc -->
	 * <p>
	 * If the meaning of the '<em>Outputs</em>' containment reference list isn't
	 * clear, there really should be more of a description here...
	 * </p>
	 * <!-- end-user-doc -->
	 * 
	 * @return the value of the '<em>Outputs</em>' containment reference list.
	 * @see net.sf.orcc.backends.llvm.tta.architecture.ArchitecturePackage#getComponent_Outputs()
	 * @model containment="true"
	 * @generated
	 */
	EList<Port> getOutputs();

	boolean isProcessor();

	/**
	 * Sets the value of the '{@link net.sf.orcc.backends.llvm.tta.architecture.Component#getName <em>Name</em>}' attribute.
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @param value the new value of the '<em>Name</em>' attribute.
	 * @see #getName()
	 * @generated
	 */
	void setName(String value);

} // Component
