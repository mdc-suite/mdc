package it.mdc.tool.core.multiDataflowGenerator;

import java.io.IOException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.eclipse.emf.ecore.EObject;

import net.sf.orcc.df.Connection;
import net.sf.orcc.df.Network;
import net.sf.orcc.ir.Expression;
import net.sf.orcc.ir.util.ExpressionEvaluator;
import net.sf.orcc.util.OrccLogger;
import it.mdc.tool.core.sboxManagement.SboxLut;
import it.mdc.tool.core.sboxManagement.SboxLutManager;

/**
 * 
 * Combine a set of input dataflow network within the 
 * multi-dataflow network
 * 
 * @author Carlo Sau
 * 
 * @see it.unica.diee.mdc package
 */
abstract public class Merger {
	
	/**
	 * Expression evaluator
	 */
	private ExpressionEvaluator evaluator;
	
	/**
	 * Sbox Look-Up Table manager instance
	 */
	protected SboxLutManager sboxLutManager;	
	
	/**
	 * Map of the vertex mapping of each merged network
	 * within the multi-dataflow one.
	 */
	protected Map <String,Map<String,String>> networkVertexMap;
	
	/**
	 * The constructor
	 */
	public Merger() {
		evaluator = new ExpressionEvaluator();
		sboxLutManager = new SboxLutManager();
		networkVertexMap = new HashMap<String,Map<String,String>>();
	}


	/**
	 * Return the map of the sequential (not combinational) instances 
	 * in the multi-dataflow network for each input dataflow network.
	 * 
	 * @return
	 * 		the map of the input network sequential instances
	 */
	abstract public Map<String,Set<String>> getNetworksClkInstances();


	/**
	 * Return the map of the sequential (not combinational) instances 
	 * in the multi-dataflow network for each input dataflow network.
	 * 
	 * @return
	 * 		the map of the input network sequential instances
	 */
	abstract public Map<String,Set<String>> getNetworksInstances();

	/**
	 * Return the map of the vertex mapping of each merged network
	 * within the multi-dataflow one.
	 * 
	 * @return
	 * 		the map of the input network instances
	 */
	public Map<String,Map<String,String>> getNetworksVertexMap() {
		return networkVertexMap;
	}

	/**
	 * Return the sbox Look-Up Tables list.
	 * 
	 * @return
	 * 		the sbox LUTs list
	 */
	public List<SboxLut> getSboxLuts() {
		return sboxLutManager.getLuts();
	}
	
	/**
	 * 
	 */
	protected Boolean hasBufferSize(Connection connection) {
		return connection.hasAttribute("bufferSize");
	}

	/**
	 * 
	 */
	protected EObject getBufferSizeValue(Connection connection) {
		if(hasBufferSize(connection)) {
			if(connection.getAttribute("bufferSize").getContainedValue() != null) {
				return connection.getAttribute("bufferSize").getContainedValue();
			} else { 
				if (connection.getAttribute("bufferSize").getReferencedValue() != null) {
					return connection.getAttribute("bufferSize").getReferencedValue();
				} else {
					OrccLogger.debugln("CCCH " + connection + "   " + connection.getAttributes());
					return (EObject) connection.getAttribute("bufferSize").getObjectValue();
				}
			}
		} else {
			return null;
		}
	}
	
	/**
	 * 
	 */
	protected Integer getBufferSizeIntegerValue(Connection connection) {
		if(hasBufferSize(connection)) {
			if(connection.getAttribute("bufferSize").getContainedValue() != null) {
				return evaluator.evaluateAsInteger((Expression) connection.getAttribute("bufferSize").getContainedValue());
			} else { 
				if (connection.getAttribute("bufferSize").getReferencedValue() != null) {
					return evaluator.evaluateAsInteger((Expression) connection.getAttribute("bufferSize").getReferencedValue());
				} else {
					OrccLogger.debugln("CCC " + connection + "   " + connection.getAttributes());
					return evaluator.evaluateAsInteger((Expression) connection.getAttribute("bufferSize").getObjectValue());
				}
			}
		} else {
			return null;
		}
	}
	
	/**
	 * Iterate on the input list of dataflow networks
	 * to compose the multi-dataflow network.
	 * 
	 * @param mergingNetworks
	 * 		the list of input dataflow networks
	 * @param path
	 * 		the backend output path (to set sbox CAL reference file)
	 * @return
	 * 		the mutli-dataflow network
	 */
	abstract public Network merge(List<Network> mergingNetworks, String path) throws IOException;

}
