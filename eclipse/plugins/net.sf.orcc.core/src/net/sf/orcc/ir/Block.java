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
package net.sf.orcc.ir;

import net.sf.orcc.graph.Edge;
import net.sf.orcc.util.Attributable;

/**
 * <!-- begin-user-doc --> This class defines a block.<!-- end-user-doc -->
 *
 * <p>
 * The following features are supported:
 * <ul>
 *   <li>{@link net.sf.orcc.ir.Block#getCfgNode <em>Cfg Node</em>}</li>
 * </ul>
 * </p>
 *
 * @see net.sf.orcc.ir.IrPackage#getBlock()
 * @model abstract="true"
 * @generated
 */
public interface Block extends Attributable {

	/**
	 * Returns the value of the '<em><b>Cfg Node</b></em>' reference.
	 * It is bidirectional and its opposite is '{@link net.sf.orcc.ir.CfgNode#getNode <em>Node</em>}'.
	 * <!-- begin-user-doc --> Returns the CFG node associated with this block.
	 * <!-- end-user-doc -->
	 * @return the value of the '<em>Cfg Node</em>' reference.
	 * @see #setCfgNode(CfgNode)
	 * @see net.sf.orcc.ir.IrPackage#getBlock_CfgNode()
	 * @see net.sf.orcc.ir.CfgNode#getNode
	 * @model opposite="node"
	 * @generated
	 */
	CfgNode getCfgNode();

	/**
	 * Returns the first outgoing edge whose flag is false.
	 * 
	 * @return the first outgoing edge whose flag is false
	 */
	Edge getEdgeFalse();

	/**
	 * Returns the first outgoing edge whose flag is true.
	 * 
	 * @return the first outgoing edge whose flag is true
	 */
	Edge getEdgeTrue();

	/**
	 * Returns the procedure this block belongs to.
	 * 
	 * @return the procedure this block belongs to
	 */
	public Procedure getProcedure();

	/**
	 * Returns <code>true</code> if this block is a BlockBasic.
	 * 
	 * @return <code>true</code> if this block is a BlockBasic
	 */
	boolean isBlockBasic();

	/**
	 * Returns <code>true</code> if this block is an BlockIf.
	 * 
	 * @return <code>true</code> if this block is an BlockIf
	 */
	boolean isBlockIf();

	/**
	 * Returns <code>true</code> if this block is a BlockWhile.
	 * 
	 * @return <code>true</code> if this block is a BlockWhile
	 */
	boolean isBlockWhile();

	/**
	 * Sets the value of the '{@link net.sf.orcc.ir.Block#getCfgNode
	 * <em>Cfg Node</em>}' reference. <!-- begin-user-doc --> <!-- end-user-doc
	 * -->
	 * 
	 * @param value
	 *            the new value of the '<em>Cfg Node</em>' reference.
	 * @see #getCfgNode()
	 * @generated
	 */
	void setCfgNode(CfgNode value);

}
