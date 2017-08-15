package it.mdc.tool.utility;


import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import it.mdc.tool.core.multiDataflowGenerator.Matcher;
import it.mdc.tool.core.multiDataflowGenerator.Unifier;
import it.mdc.tool.core.sboxManagement.SboxLut;
import it.mdc.tool.core.sboxManagement.*;
import net.sf.orcc.df.Actor;
import net.sf.orcc.df.Connection;
import net.sf.orcc.df.Instance;
import net.sf.orcc.df.Network;
import net.sf.orcc.df.Port;
import net.sf.orcc.graph.Vertex;

/**
 * Search matching existing network elements in a network.
 * 
 * @author Carlo Sau
 *
 */
public class SearcherOld {
	
	/**
	 * The unifier
	 */
	private Unifier unifier;
	
	/**
	 * The matcher
	 */
	private Matcher matcher;
	
	/**
	 * Initial direction for searching existing connection when source or 
	 * target can be sboxes
	 */
	public static final int INIT_SEARCH = 0;
	
	/**
	 * Initial size for searching best existing connection
	 */
	public static final int INIT_SIZE = 1000;
	
	
	/**
	 * The constructor 
	 * 
	 * @param unifier
	 * 				the unifier instance
	 * @param matcher
	 * 				the matcher instance
	 */
	public SearcherOld(Unifier unifier, Matcher matcher) {
		this.unifier = unifier;
		this.matcher = matcher;
	}
	
	/**
	 * This method searches an existing vertex that matches the vertex passed as argument and return it.
	 * If no vertex matches returns null. Multiple instances of the same actor aren't preserved.
	 * 
	 * @param vertex
	 * @return the existing vertex that matches candidate 
	 */
	public Vertex searchExistingVertex(Vertex vertex, Network network){
		
		// vertex is a port
		if(vertex.getAdapter(Port.class) != null){
			for(Port nextInput : network.getInputs())
				if(unifier.canUnify(vertex.getAdapter(Port.class), nextInput)) {
					return nextInput;
				}
			for(Port nextOutput : network.getOutputs())
				if(unifier.canUnify(vertex.getAdapter(Port.class), nextOutput)) {
					return nextOutput;
				}
			return null;
		
		// vertex is an instance
		} else if (vertex.getAdapter(Instance.class) != null) {
			if(vertex.getAdapter(Actor.class).hasAttribute("sbox"))
				return vertex;
			for(Instance instance : network.getInstancesOf(vertex.getAdapter(Actor.class)))
				if(unifier.canUnify(instance,vertex.getAdapter(Instance.class)))
					return instance;
			return null;
		} else {
			return null;
		}
	}
	
	/**
	 * This method searches an existing vertex that matches the vertex passed as argument and return it.
	 * If no vertex matches returns null. Multiple instances of the same actor are preserved.
	 * 
	 * @param vertex
	 * @return the existing vertex that matches candidate 
	 */
	public Vertex searchExistingVertexMultiple(Vertex vertex, Network network){
		
		// vertex is a port
		if(vertex.getAdapter(Port.class) != null){
			for(Port nextInput : network.getInputs()){
				if(unifier.canUnifyMultiple(vertex.getAdapter(Port.class), nextInput)) {
					//System.out.println("Vertex " + vertex.getAdapter(Port.class) + "," + vertex.getAdapter(Port.class).getType()
					//		+ " candidate " + nextInput + "," + nextInput.getType());
					return nextInput;
				}
			}
			for(Port nextOutput : network.getOutputs())
				if(unifier.canUnifyMultiple(vertex.getAdapter(Port.class), nextOutput)) {
					return nextOutput;
				}
			return null;
			
		// vertex is an instance
		} else if (vertex.getAdapter(Instance.class) != null) {
			if(vertex.getAdapter(Actor.class).hasAttribute("sbox"))
				return vertex;
			for(Vertex nextChild : network.getChildren()) {
				if(unifier.canUnifyMultiple(vertex, nextChild)) {
					return nextChild;
				}
			}
			return null;
		} else {
			return null;
		}
	}
	
	/**
	 * This method searches an existing connection that matches the candidate and return it.
	 * If no connection matches return null. Multiple instances of the same actor aren't preserved.
	 * 
	 * @param candidate
	 * 				the candidate connection
	 * @return the existing connection that matches candidate
	 */
	public Connection searchExistingConnection (Connection candidate, Network network) {

		Map <Connection, Map<Instance,Boolean>> existingConnections = new HashMap<Connection, Map<Instance,Boolean>>();

		// searching all connections that match candidate connection in the network
		if(!(candidate == null)) {
			for (Connection existing : network.getConnections()) {
				if(matcher.matchConnectionSbox(candidate,existing,INIT_SEARCH)) {
					existingConnections.put(existing,matcher.getLuts());
					matcher.deleteLuts();
				}
			}
		}
		
		Connection bestConnection = null;
		int bestSize = INIT_SIZE;
		
		// finding the best matching connection
		if(!existingConnections.isEmpty())
			for(Connection connection : existingConnections.keySet())
				if(existingConnections.get(connection).size()<bestSize) {
					bestSize = existingConnections.get(connection).size();
					bestConnection = connection;
				}
		
		// setting luts and returning the connection
		if(bestConnection != null) {
			matcher.setLuts(existingConnections.get(bestConnection));
			return bestConnection;
		} else {
			return null;
		}
	}
	
	/**
	 * This method searches an existing connection that matches the candidate and return it.
	 * If no connection matches return null. Multiple instances for the same actor are preserved.
	 * 
	 * @param candiadate	
	 * 				the candidate connection
	 * @return the existing connection that matches candidate
	 */
	public Connection searchExistingConnectionMultiple (Connection candidate, Network network, List<SboxLut> luts, Network currentNetwork) {
		
		Map <Connection, Map<Instance,Boolean>> existingConnections = new HashMap<Connection, Map<Instance,Boolean>>();
		
		// searching all connections that match candidate connection in the network
		if(!(candidate == null))
			for (Connection existing : network.getConnections()) 
				if(matcher.matchConnectionSboxMultiple(candidate,existing,INIT_SEARCH)) 
					if(!matcher.hasBroadOnPath()) {
						existingConnections.put(existing,matcher.getLuts());
						matcher.deleteLuts();	
					}
		
		
		Connection bestConnection = null;
		int bestSize = INIT_SIZE;
		
		// finding the best matching connection
		if(!existingConnections.isEmpty())
			for(Connection connection : existingConnections.keySet())
				if(existingConnections.get(connection).size()<bestSize) {
					bestSize = existingConnections.get(connection).size();
					bestConnection = connection;
				}
		
		// setting luts and returning the connection
		if(bestConnection != null) {
			matcher.setLuts(existingConnections.get(bestConnection));
			return bestConnection;
		} else {
			return null;
		}
	}

	/*private Connection searchExistingBroadcastMultiple(Connection candidate, Network network, Network currentNetwork){
		
		List <Connection> candBroadConns = new ArrayList<Connection>();
		List <Connection> existBroadConns = new ArrayList<Connection>();
		List <Connection> matchBroadConns = new ArrayList<Connection>();
		
		for(Connection nextCandC : currentNetwork.getConnections())
			if(nextCandC.hasAttribute("broadcast") && matcher.matchSourcesMultiple(candidate, nextCandC))
				candBroadConns.add(nextCandC);
		candBroadConns.add(candidate);
		
		for(Connection nextExistC : network.getConnections())
			if(nextExistC.hasAttribute("broadcast") && matcher.matchSourcesMultiple(candidate, nextExistC))
				existBroadConns.add(nextExistC);
		
		for(Connection candC : candBroadConns)
			for(Connection existC : existBroadConns) {
				if(matcher.matchConnectionMultiple(candC, existC)) {
					matchBroadConns.add(candC);
				} else {
					break;
				}
				existBroadConns.remove(existC);
			}
		
		if(candBroadConns.equals(matchBroadConns))
			if(existBroadConns.isEmpty())
				return candidate;
		return null;
	}*/
	
	/**
	 * This method searches the best vertex that matches the candidate and return it.
	 * If no vertex matches return null.
	 * 
	 * @param candiadate	
	 * 				the candidate vertex
	 * @param unifiables
	 * 				all the vertices of the network that match candidate
	 * @return the existing vertex that matches candidate
	 */
	public Vertex searchBestVertex(Vertex candidate, List<Vertex> unifiables) {
		
		int matchingConnections = 0;
		int bestMatchingConnections = 0;
		Vertex bestVertex = null;
		
		// searching matching input connections of the vertex in the network with the input connections of the candidate
		for(Vertex unifiable : unifiables) {
			matchingConnections = 0;
			for(Connection connection : candidate.getAdapter(Instance.class).getIncomingPortMap().values()) 
				for(Connection unifiableConnection : unifiable.getAdapter(Instance.class).getIncomingPortMap().values()){
					
					if(matcher.matchConnectionSboxMultiple(connection,unifiableConnection,INIT_SEARCH)){
						matchingConnections += 1;
						break;
					}
				}
			// searching matching output connections of the vertex in the network with the output connections of the candidate
			for(List<Connection> connectionList : candidate.getAdapter(Instance.class).getOutgoingPortMap().values())
				for(Connection connection : connectionList)
					for(List<Connection> unifiableConnectionList : unifiable.getAdapter(Instance.class).getOutgoingPortMap().values())
						for(Connection unifiableConnection : unifiableConnectionList){
							
							if(matcher.matchConnectionSboxMultiple(connection,unifiableConnection,INIT_SEARCH)){
								matchingConnections += 1;
								break;
							}
						}
			// assigning new best vertex
			if(matchingConnections >= bestMatchingConnections) {
				bestMatchingConnections = matchingConnections;
				bestVertex = unifiable;
			}	
		}
				
		return bestVertex;
	}
	
	public Set<Instance> searchSameInstanceSet(Set<Instance> s1, Set<Instance> s2) {
		
		Set<Instance> result = new HashSet<Instance>();
		
		for(Instance inst1 : s1)
			for(Instance inst2 : s2) {
				if(unifier.canUnifyMultiple(inst1,inst2)){
					result.add(inst1);
				}
			}
		
		return result;
	}
	
	public Set<Instance> searchOutInstanceSet(Set<Instance> set, Map<Integer,Set<Instance>> setMap) {
		
		boolean presInst = false;
		Set<Instance> result = new HashSet<Instance>();
		
		for(Instance inst1 : set) {
			presInst = false;
			cycle : for(Set<Instance> placedSet : setMap.values()) {
				for(Instance inst2 : placedSet)
					if(unifier.canUnifyMultiple(inst1,inst2))
						presInst = true;
						break cycle;
			}
			if(!presInst)
				result.add(inst1);	
		}
		
		return result;
	}

}
