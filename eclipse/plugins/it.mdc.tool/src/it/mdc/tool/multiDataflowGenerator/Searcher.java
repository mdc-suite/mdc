package it.mdc.tool.multiDataflowGenerator;


import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import it.mdc.tool.sboxManagement.*;
import net.sf.orcc.df.Actor;
import net.sf.orcc.df.Connection;
import net.sf.orcc.df.Instance;
import net.sf.orcc.df.Network;
import net.sf.orcc.df.Port;
import net.sf.orcc.graph.Vertex;
import net.sf.orcc.util.OrccLogger;

/**
 * Search sharable elements in a network.
 * 
 * @author Carlo Sau
 *
 */
public class Searcher {
	
	/**
	 * The unifier instance
	 */
	private Unifier unifier;
	
	/**
	 * The matcher instance
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
	public Searcher(Unifier unifier, Matcher matcher) {
		this.unifier = unifier;
		this.matcher = matcher;
	}
	
	/**
	 * Find the best sharable vertex that matches the candidate one.
	 * If no vertex matches return null.
	 * 
	 * @param candiadate	
	 * 				the candidate vertex
	 * @param sharables
	 * 				the list of sharable vertices
	 * @return 
	 * 		the best sharable vertex
	 */
	public Vertex findBestVertex(Vertex candidate, List<Vertex> sharables) {
		
		int matchingConnections = 0;
		int bestMatchingConnections = 0;
		Vertex bestVertex = null;
		
		// searching matching input connections of the vertex in the network with the input connections of the candidate
		for(Vertex unifiable : sharables) {
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
			OrccLogger.traceln("vertex " + unifiable + " match conn " + matchingConnections);	
		}
		return bestVertex;
	}

	/**
	 * Return a sharable connection in the given network according with the 
	 * desired source, source port, target, target port and broadcast size. 
	 * 
	 * @param source
	 * 		the desired source		
	 * @param sourcePort
	 * 		the desired source port
	 * @param target
	 * 		the desired target
	 * @param targetPort
	 * 		the desired target port
	 * @param network
	 * 		the given network
	 * @param broadcastSize
	 * 		the desired broadcast size
	 * @return
	 * 		the sharable connection
	 */
	public Connection getConnection(Vertex source, Port sourcePort,
			Vertex target, Port targetPort, Network network, int broadcastSize) {
		
		Map <Connection, Map<Instance,Boolean>> existingConnections = new HashMap<Connection, Map<Instance,Boolean>>();
		
		// searching all connections that match candidate connection in the network
		for (Connection existingConnection : network.getConnections()){
			//OrccLogger.traceln("exist pre " + existingConnection);
			if(matcher.matchConnectionSboxCompl(source,sourcePort,target,targetPort,existingConnection,INIT_SEARCH)) 
				if(broadcastSize == matcher.getBroadSize()) {
					existingConnections.put(existingConnection,matcher.getLuts());
					matcher.deleteLuts();	
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
	 * Search a connection in the given network sharable with the candidate one.
	 * (useful for future works about networks internal reconfiguration)
	 * 
	 * @param candidate
	 * 		the candidate connection
	 * @return 
	 * 		the existing sharable connection
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
	 * Search a connection in the given network sharable with the candidate one.
	 * (useful for future works about networks internal reconfiguration)
	 * 
	 * @param candidate
	 * 		the candidate connection
	 * @return 
	 * 		the existing sharable connection
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

	/**
	 * Search a vertex in the given network sharable with the candidate one.
	 * (useful for future works about networks internal reconfiguration)
	 * 
	 * @param candidate
	 * 		the candidate vertex
	 * @return 
	 * 		the existing sharable vertex
	 */
	public Vertex searchExistingVertex(Vertex candidate, Network network){
		
		// vertex is a port
		if(candidate.getAdapter(Port.class) != null){
			for(Port nextInput : network.getInputs())
				if(unifier.canUnify(candidate.getAdapter(Port.class), nextInput)) {
					return nextInput;
				}
			for(Port nextOutput : network.getOutputs())
				if(unifier.canUnify(candidate.getAdapter(Port.class), nextOutput)) {
					return nextOutput;
				}
			return null;
		
		// vertex is an instance
		} else if (candidate.getAdapter(Instance.class) != null) {
			if(candidate.getAdapter(Actor.class).hasAttribute("sbox"))
				return candidate;
			for(Instance instance : network.getInstancesOf(candidate.getAdapter(Actor.class)))
				if(unifier.canUnify(instance,candidate.getAdapter(Instance.class)))
					return instance;
			return null;
		} else {
			return null;
		}
	}
	
	/**
	 * Search a vertex in the given network sharable with the candidate one.
	 * 
	 * @param candidate
	 * 		the candidate vertex
	 * @return 
	 * 		the existing sharable vertex
	 */
	public Vertex searchExistingVertexMultiple(Vertex candidate, Network network){
		
		// vertex is a port
		if(candidate.getAdapter(Port.class) != null){
			for(Port nextInput : network.getInputs()){
				if(unifier.canUnifyMultiple(candidate.getAdapter(Port.class), nextInput)) {
					return nextInput;
				}
			}
			for(Port nextOutput : network.getOutputs())
				if(unifier.canUnifyMultiple(candidate.getAdapter(Port.class), nextOutput)) {
					return nextOutput;
				}
			return null;
			
		// vertex is an instance
		} else if (candidate.getAdapter(Instance.class) != null) {
			if(candidate.getAdapter(Actor.class).hasAttribute("sbox"))
				return candidate;
			for(Vertex nextChild : network.getChildren()) {
				if(unifier.canUnifyMultiple(candidate, nextChild)) {
					return nextChild;
				}
			}
			return null;
		} else {
			return null;
		}
		
	}
	
	/**
	 * Search the set of actor instances in common between
	 * the two given sets.
	 * 
	 * @param firstSet
	 * 		the first actor instance set
	 * @param secondSet
	 * 		the second actor instance set
	 * @return 
	 * 		the set of common instances between the two sets
	 */
	public Set<Instance> searchSameInstanceSet(Set<Instance> firstSet, Set<Instance> secondSet) {
		
		Set<Instance> result = new HashSet<Instance>();
		
		for(Instance inst1 : firstSet)
			for(Instance inst2 : secondSet) {
				if(unifier.canUnifyMultiple(inst1,inst2)){
					result.add(inst1);
				}
			}
		
		return result;
	}

}
