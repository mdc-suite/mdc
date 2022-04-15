/**
 * <copyright>
 * </copyright>
 *
 * $Id$
 */
package net.sf.orcc.graph;

import net.sf.orcc.util.Adaptable;
import java.util.List;

import net.sf.orcc.util.Attributable;

import org.eclipse.emf.common.util.EList;

/**
 * <!-- begin-user-doc -->This class defines a vertex. A vertex has incoming
 * edges and outgoing edges. It also has a list of attributes. The
 * predecessor/successor information is actually deduced from the
 * incoming/outgoing edges.<!-- end-user-doc -->
 *
 * <p>
 * The following features are supported:
 * <ul>
 *   <li>{@link net.sf.orcc.graph.Vertex#getLabel <em>Label</em>}</li>
 *   <li>{@link net.sf.orcc.graph.Vertex#getNumber <em>Number</em>}</li>
 *   <li>{@link net.sf.orcc.graph.Vertex#getIncoming <em>Incoming</em>}</li>
 *   <li>{@link net.sf.orcc.graph.Vertex#getOutgoing <em>Outgoing</em>}</li>
 *   <li>{@link net.sf.orcc.graph.Vertex#getConnecting <em>Connecting</em>}</li>
 *   <li>{@link net.sf.orcc.graph.Vertex#getPredecessors <em>Predecessors</em>}</li>
 *   <li>{@link net.sf.orcc.graph.Vertex#getSuccessors <em>Successors</em>}</li>
 *   <li>{@link net.sf.orcc.graph.Vertex#getNeighbors <em>Neighbors</em>}</li>
 * </ul>
 * </p>
 *
 * @see net.sf.orcc.graph.GraphPackage#getVertex()
 * @model
 * @generated
 */
public interface Vertex extends Attributable, Adaptable {

	/**
	 * Returns the graph in which this vertex is contained, or <code>null</code>
	 * if it is not contained in a graph. This is equivalent to
	 * <code>(Graph) eContainer()</code>.
	 * 
	 * @return the graph that contains this vertex
	 */
	Graph getGraph();

	/**
	 * Returns the hierarchy of this vertex as a list of graphs.
	 * 
	 * @return the hierarchy of this vertex
	 */
	List<Graph> getHierarchy();

	/**
	 * Returns the value of the '<em><b>Incoming</b></em>' reference list. The
	 * list contents are of type {@link net.sf.orcc.graph.Edge}. It is
	 * bidirectional and its opposite is '
	 * {@link net.sf.orcc.graph.Edge#getTarget <em>Target</em>}'. <!--
	 * begin-user-doc --><!-- end-user-doc -->
	 * 
	 * @return the value of the '<em>Incoming</em>' reference list.
	 * @see net.sf.orcc.graph.GraphPackage#getVertex_Incoming()
	 * @see net.sf.orcc.graph.Edge#getTarget
	 * @model opposite="target"
	 * @generated
	 */
	EList<Edge> getIncoming();

	/**
	 * Returns the value of the '<em><b>Label</b></em>' attribute. <!--
	 * begin-user-doc --><!-- end-user-doc -->
	 * 
	 * @return the value of the '<em>Label</em>' attribute.
	 * @see #setLabel(String)
	 * @see net.sf.orcc.graph.GraphPackage#getVertex_Label()
	 * @model
	 * @generated
	 */
	String getLabel();

	/**
	 * Returns the value of the '<em><b>Number</b></em>' attribute. <!--
	 * begin-user-doc -->Returns the number associated with this vertex. If the
	 * vertex has not been assigned a number, this returns 0. This field is
	 * filled by visit algorithms.<!-- end-user-doc -->
	 * 
	 * @return the value of the '<em>Number</em>' attribute.
	 * @see #setNumber(int)
	 * @see net.sf.orcc.graph.GraphPackage#getVertex_Number()
	 * @model transient="true"
	 * @generated
	 */
	int getNumber();

	/**
	 * Returns the value of the '<em><b>Outgoing</b></em>' reference list. The
	 * list contents are of type {@link net.sf.orcc.graph.Edge}. It is
	 * bidirectional and its opposite is '
	 * {@link net.sf.orcc.graph.Edge#getSource <em>Source</em>}'. <!--
	 * begin-user-doc --><!-- end-user-doc -->
	 * 
	 * @return the value of the '<em>Outgoing</em>' reference list.
	 * @see net.sf.orcc.graph.GraphPackage#getVertex_Outgoing()
	 * @see net.sf.orcc.graph.Edge#getSource
	 * @model opposite="source"
	 * @generated
	 */
	EList<Edge> getOutgoing();

	/**
	 * Returns the value of the '<em><b>Connecting</b></em>' reference list.
	 * The list contents are of type {@link net.sf.orcc.graph.Edge}.
	 * <!-- begin-user-doc -->
	 * <p>
	 * If the meaning of the '<em>Connecting</em>' reference list isn't clear,
	 * there really should be more of a description here...
	 * </p>
	 * <!-- end-user-doc -->
	 * @return the value of the '<em>Connecting</em>' reference list.
	 * @see net.sf.orcc.graph.GraphPackage#getVertex_Connecting()
	 * @model resolveProxies="false" transient="true" changeable="false" derived="true"
	 * @generated
	 */
	EList<Edge> getConnecting();

	/**
	 * Returns the value of the '<em><b>Predecessors</b></em>' reference list.
	 * The list contents are of type {@link net.sf.orcc.graph.Vertex}.
	 * <!-- begin-user-doc -->
	 * <p>
	 * If the meaning of the '<em>Predecessors</em>' reference list isn't clear,
	 * there really should be more of a description here...
	 * </p>
	 * <!-- end-user-doc -->
	 * @return the value of the '<em>Predecessors</em>' reference list.
	 * @see net.sf.orcc.graph.GraphPackage#getVertex_Predecessors()
	 * @model resolveProxies="false" transient="true" changeable="false" derived="true"
	 * @generated
	 */
	EList<Vertex> getPredecessors();

	/**
	 * Returns the value of the '<em><b>Successors</b></em>' reference list.
	 * The list contents are of type {@link net.sf.orcc.graph.Vertex}.
	 * <!-- begin-user-doc -->
	 * <p>
	 * If the meaning of the '<em>Successors</em>' reference list isn't clear,
	 * there really should be more of a description here...
	 * </p>
	 * <!-- end-user-doc -->
	 * @return the value of the '<em>Successors</em>' reference list.
	 * @see net.sf.orcc.graph.GraphPackage#getVertex_Successors()
	 * @model resolveProxies="false" transient="true" changeable="false" derived="true"
	 * @generated
	 */
	EList<Vertex> getSuccessors();

	/**
	 * Returns the value of the '<em><b>Neighbors</b></em>' reference list.
	 * The list contents are of type {@link net.sf.orcc.graph.Vertex}.
	 * <!-- begin-user-doc -->
	 * <p>
	 * If the meaning of the '<em>Neighboors</em>' reference list isn't clear,
	 * there really should be more of a description here...
	 * </p>
	 * <!-- end-user-doc -->
	 * @return the value of the '<em>Neighbors</em>' reference list.
	 * @see net.sf.orcc.graph.GraphPackage#getVertex_Neighbors()
	 * @model resolveProxies="false" transient="true" changeable="false" derived="true"
	 * @generated
	 */
	EList<Vertex> getNeighbors();

	/**
	 * Sets the value of the '{@link net.sf.orcc.graph.Vertex#getLabel <em>Label</em>}' attribute.
	 * <!-- begin-user-doc --><!-- end-user-doc -->
	 * @param value the new value of the '<em>Label</em>' attribute.
	 * @see #getLabel()
	 * @generated
	 */
	void setLabel(String value);

	/**
	 * Sets the value of the '{@link net.sf.orcc.graph.Vertex#getNumber <em>Number</em>}' attribute.
	 * <!-- begin-user-doc --><!-- end-user-doc -->
	 * @param value the new value of the '<em>Number</em>' attribute.
	 * @see #getNumber()
	 * @generated
	 */
	void setNumber(int value);

}
