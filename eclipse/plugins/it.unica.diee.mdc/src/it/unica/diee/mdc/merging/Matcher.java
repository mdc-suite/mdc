package it.unica.diee.mdc.merging;

import java.util.List;
import java.util.Map;
import java.util.HashMap;
import java.util.ArrayList;

import net.sf.orcc.df.Connection;
import net.sf.orcc.df.Instance;
import net.sf.orcc.df.Port;
import net.sf.orcc.df.Actor;
import net.sf.orcc.graph.Vertex;

/**
 * Verify if two network connections are sharable
 * 
 * @author Carlo Sau
 *
 */
public class Matcher {
	
	/**
	 * The unifier instance
	 */
	private Unifier unifier;
	
	/**
	 * Initial direction for searching existing connection
	 */
	public static final int INIT_SEARCH = 0;
	
	/**
	 * Source searching direction for searching existing 
	 * connection involving sboxes
	 */
	public static final int SOURCE_SEARCH = 1;
	
	/**
	 * Target searching direction for searching existing
	 * connection involving sboxes
	 */
	public static final int TARGET_SEARCH = 2;
	
	/**
	 * List of all the connections on the path of the sharable connection 
	 * when the candidate connection is a broadcast.
	 */
	public List<Connection> pathConnections;
	
	/**
	 * Sbox Look-Up Tables of the current sharable connection path
	 */
	private Map<Instance,Boolean> luts;

	/**
	 * The constructor
	 */
	public Matcher() {
		unifier = new Unifier();
		luts = new HashMap<Instance,Boolean>();
		pathConnections = new ArrayList<Connection>();
	}
	
	/**
	 * Clear the Look-Up Tables of the current sharable 
	 * connection path
	 * 
	 */
	public void deleteLuts(){
		luts.clear();
	}

	/**
	 * Return the broadcast size of the current sharable
	 * path. If no broadcast is involved in the path, the
	 * returned value is 0.
	 * 
	 * @return
	 * 		the broadcast size of the current connection sharable path
	 */
	public int getBroadSize() {
		
		int broadcastSize = 0;
		
		for(Connection pathC : pathConnections)
			if(pathC.hasAttribute("broadcast")) {
				broadcastSize = Integer.parseInt(pathC.getAttribute("broadcastSize").getStringValue());
			}
			
		return broadcastSize;
	}

	/**
	 * Returns the Look-Up Tables of the current sharable 
	 * connection path.
	 * 
	 * @return
	 * 		the current LUTs value
	 */
	public Map<Instance,Boolean> getLuts(){
		Map<Instance,Boolean> result = new HashMap<Instance,Boolean>();
		for(Instance sboxInstance : luts.keySet())
			result.put(sboxInstance, luts.get(sboxInstance));
		return result;
	}
	
	/**
	 * Return the current sharable connection path.
	 * 
	 * @return
	 * 		the current sharable connection path
	 */
	public List<Connection> getPathConns() {
		List<Connection> result = pathConnections;
		return result;
	}
	
	/**
	 * Verify if the current sharable connection path involves a broadcast.
	 * 
	 * @return
	 * 		if the current sharable connection path involves a broadcast
	 */
	public boolean hasBroadOnPath() {
		for(Connection pathC : pathConnections)
			if(pathC.hasAttribute("broadcast")) {
				return true;
			}
			
		return false;
	}
	
	/**
	 * Verify if the existing connection is sharable with the candidate one.
	 * (useful for future works on networks internal reconfiguration)
	 * 
	 * @param candidate
	 * 				the candidate connection
	 * @param existing
	 * 				the existing connection
	 * @return
	 * 		if the existing connection is sharable with the candidate one
	 */
	public boolean matchConnection(Connection candidate, Connection existing) {
		return (matchSources(candidate,existing) && matchTargets(candidate,existing));
	}
	
	/**
	 * Verify if the existing connection is sharable with the candidate one.
	 * 
	 * @param candidate
	 * 				the candidate connection
	 * @param existing
	 * 				the existing connection
	 * @return
	 * 		if the existing connection is sharable with the candidate one
	 */
	public boolean matchConnectionMultiple(Connection candidate, Connection existing) {
		return (matchSourcesMultiple(candidate,existing) && matchTargetsMultiple(candidate,existing));
	}
	
	/**
	 * Verify if the existing connection is sharable with the candidate one.
	 * Sboxes can be included in the sharable path.
	 * (useful for future works on networks internal reconfiguration)
	 * 
	 * @param candidate
	 * 				the candidate connection
	 * @param existing
	 * 				the existing connection
	 * @param flag
	 * 		the searching direction
	 * @return
	 * 		if the existing connection is sharable with the candidate one
	 */
	public boolean matchConnectionSbox(Connection candidate, Connection existing, int flag) {

		if((existing.getSource().getAdapter(Port.class) != null) 
				&& (existing.getTarget().getAdapter(Port.class) != null)){
			// source and target of existing connection are ports
			return matchConnection(candidate, existing);
		} else {
			if(flag!=TARGET_SEARCH)
				if(existing.getSource().getAdapter(Port.class) == null)
					if (existing.getSource().getAdapter(Actor.class).hasAttribute("sbox")) {
						// source of existing connection is a sbox
						if((flag==SOURCE_SEARCH) || ((flag==INIT_SEARCH) 
								&& matchTargets(candidate,existing))) {
							if((flag==INIT_SEARCH) && matchTargets(candidate,existing)) {
								resetPathConns();
							}
							for(Connection c : (existing.getSource().getAdapter(Instance.class))
									.getIncomingPortMap().values())
								if(matchConnectionSbox(candidate, c, SOURCE_SEARCH)){		// searching matching source through sbox
									if( ((c.getTargetPort().getName().equals("in1")) 
											&& c.getTarget().getAdapter(Actor.class).getAttribute("type").getStringValue().equals("2x1")) 
											|| ((existing.getSourcePort().getName().equals("out1"))
											&& existing.getSource().getAdapter(Actor.class).getAttribute("type").getStringValue().equals("1x2")) ) {
										luts.put((existing.getSource().getAdapter(Instance.class)), false);
									} else if ( ((c.getTargetPort().getName().equals("in2")) 
											&& c.getTarget().getAdapter(Actor.class).getAttribute("type").getStringValue().equals("2x1"))
											|| ((existing.getSourcePort().getName().equals("out2")) 
											&& existing.getSource().getAdapter(Actor.class).getAttribute("type").getStringValue().equals("1x2")) ) {
										luts.put((existing.getSource().getAdapter(Instance.class)), true);
									}
									pathConnections.add(existing);
									return true;
								}
						}
					} else {
						if(flag==SOURCE_SEARCH)
							if(matchSources(candidate,existing)) {		// end of sbox source searching
								pathConnections.add(existing);
								return true;
							}
					}
			if(flag!=SOURCE_SEARCH)
				if(existing.getTarget().getAdapter(Port.class) == null)
					if (existing.getTarget().getAdapter(Actor.class).hasAttribute("sbox")){
						if((flag==TARGET_SEARCH) || ((flag==INIT_SEARCH) 
								&& matchSources(candidate,existing))) {
							if((flag==INIT_SEARCH) && matchSources(candidate,existing)) {
									resetPathConns();
							}
							// target of existing connection is a sbox
							for(List<Connection> lc : (existing.getTarget().getAdapter(Instance.class)).getOutgoingPortMap().values())
								for(Connection c : lc)
									if(matchConnectionSbox(candidate, c, TARGET_SEARCH)) {		// searching matching target through sbox
										if( ((c.getSourcePort().getName().equals("out1")) 
												&& c.getSource().getAdapter(Actor.class).getAttribute("type").getStringValue().equals("1x2")) 
												|| ((existing.getTargetPort().getName().equals("in1")) 
												&& existing.getTarget().getAdapter(Actor.class).getAttribute("type").getStringValue().equals("2x1")) ) {
											luts.put((existing.getTarget().getAdapter(Instance.class)), false);
										} else if ( ((c.getSourcePort().getName().equals("out2")) 
												&& c.getSource().getAdapter(Actor.class).getAttribute("type").getStringValue().equals("1x2")) 
												|| ((existing.getTargetPort().getName().equals("in2")) 
												&& existing.getTarget().getAdapter(Actor.class).getAttribute("type").getStringValue().equals("2x1")) ) {
											luts.put((existing.getTarget().getAdapter(Instance.class)), true);
										}
										pathConnections.add(existing);
										return true;
									}
						}
				} else {
					if(flag==TARGET_SEARCH)
						if(matchTargets(candidate,existing)) {		// end of sbox target searching
							pathConnections.add(existing);
							return true;
						}
				}
			// the existing connection vertex are not sbox
			if(matchConnection(candidate, existing)) {
				resetPathConns();	
				pathConnections.add(existing);
				return true;
			} else {
				return false;
			}			
		}
	}
	
	/**
	 * Verify if the existing connection is sharable with the candidate one,
	 * that is specified as source, source port, target and target port.
	 * Sboxes can be included in the sharable path.
	 * (useful for future works on networks internal reconfiguration)
	 * 
	 * @param source
	 * 				the candidate connection source
	 * @param sourcePort
	 * 				the candidate connection source port
	 * @param target
	 * 				the candidate connection target
	 * @param targetPort
	 * 				the candidate connection target port
	 * @param existing
	 * 				the existing connection
	 * @param flag
	 * 		the searching direction
	 * @return
	 * 		if the existing connection is sharable with the candidate one
	 */
	public boolean matchConnectionSboxCompl(Vertex source, Port sourcePort, 
											Vertex target, Port targetPort,
											Connection existing, int flag) {
	
		if((existing.getSource().getAdapter(Port.class) != null) 
				&& (existing.getTarget().getAdapter(Port.class) != null)){
			return (matchVertices(source,existing.getSource()))
					&&(matchVertices(target,existing.getTarget()));
		} else {
			if(flag!=TARGET_SEARCH)
				if(existing.getSource().getAdapter(Port.class) == null)
					if ((existing.getSource().getAdapter(Actor.class).hasAttribute("sbox"))) {
						// source of existing connection is a sbox
						if((flag==SOURCE_SEARCH) || ((flag==INIT_SEARCH) 
								&& (matchVertices(target,existing.getTarget()) 
										&& matchVertices(targetPort,existing.getTargetPort())))) {
							if((flag==INIT_SEARCH) && (matchVertices(target,existing.getTarget()) 
									&& matchVertices(targetPort,existing.getTargetPort())))
								resetPathConns();
							for(Connection c : (existing.getSource().getAdapter(Instance.class)).getIncomingPortMap().values())
								if(matchConnectionSboxCompl(source,sourcePort,target,targetPort, c, SOURCE_SEARCH)) {		// searching matching source through sbox
									if( ((c.getTargetPort().getName().equals("in1")) 
											&& c.getTarget().getAdapter(Actor.class).getAttribute("type").getStringValue().equals("2x1")) 
											|| ((existing.getSourcePort().getName().equals("out1")) 
											&& existing.getSource().getAdapter(Actor.class).getAttribute("type").getStringValue().equals("1x2")) ) {
										luts.put((existing.getSource().getAdapter(Instance.class)), false);
									} else if ( ((c.getTargetPort().getName().equals("in2")) 
											&& c.getTarget().getAdapter(Actor.class).getAttribute("type").getStringValue().equals("2x1"))
											|| ((existing.getSourcePort().getName().equals("out2")) 
											&& existing.getSource().getAdapter(Actor.class).getAttribute("type").getStringValue().equals("1x2")) ) {
										luts.put((existing.getSource().getAdapter(Instance.class)), true);
									}
									pathConnections.add(existing);
									return true;
								}
						}
					} else {
						if(flag==SOURCE_SEARCH)
							if(matchVertices(source,existing.getSource())
									&& matchVertices(sourcePort,existing.getSourcePort())) {		// end of sbox source searching
								pathConnections.add(existing);
								return true;
							}
					}
			if(flag!=SOURCE_SEARCH)
				if(existing.getTarget().getAdapter(Port.class) == null)
					if (existing.getTarget().getAdapter(Actor.class).hasAttribute("sbox")){
						if((flag==TARGET_SEARCH) || ((flag==INIT_SEARCH) 
								&& (matchVertices(source,existing.getSource()) 
								&& (matchVertices(sourcePort,existing.getSourcePort()))))) {
							if((flag==INIT_SEARCH) && (matchVertices(source,existing.getSource()) 
									&& (matchVertices(sourcePort,existing.getSourcePort()))))
								resetPathConns();
							// target of existing connection is a sbox
							for(List<Connection> lc : (existing.getTarget().getAdapter(Instance.class)).getOutgoingPortMap().values())
								for(Connection c : lc)
									if(matchConnectionSboxCompl(source,sourcePort,target,targetPort, c, TARGET_SEARCH)) {		// searching matching target through sbox
										if( ((c.getSourcePort().getName().equals("out1")) 
												&& c.getSource().getAdapter(Actor.class).getAttribute("type").getStringValue().equals("1x2")) 
												|| ((existing.getTargetPort().getName().equals("in1")) 
												&& existing.getTarget().getAdapter(Actor.class).getAttribute("type").getStringValue().equals("2x1")) ) {
											luts.put((existing.getTarget().getAdapter(Instance.class)), false);
										} else if ( ((c.getSourcePort().getName().equals("out2")) 
												&& c.getSource().getAdapter(Actor.class).getAttribute("type").getStringValue().equals("1x2")) 
												|| ((existing.getTargetPort().getName().equals("in2")) 
												&& existing.getTarget().getAdapter(Actor.class).getAttribute("type").getStringValue().equals("2x1")) ) {
											luts.put((existing.getTarget().getAdapter(Instance.class)), true);
										}
										pathConnections.add(existing);
										return true;
									}
						}
				} else {
					if(flag==TARGET_SEARCH)
						if(matchVertices(target,existing.getTarget())
								&&matchVertices(targetPort,existing.getTargetPort())) {		// end of sbox target searching
							pathConnections.add(existing);
							return true;
						}
				}
			// the existing connection vertex are not sbox
			if(matchVertices(source,existing.getSource())
					&& matchVertices(sourcePort,existing.getSourcePort())
					&& matchVertices(target,existing.getTarget())
					&& matchVertices(targetPort,existing.getTargetPort())) {
				resetPathConns();
				pathConnections.add(existing);
				return true;
			} else {
				return false;
			}
		}
	}

	/**
	 * Verify if the existing connection is sharable with the candidate one.
	 * Sboxes can be included in the sharable path.
	 * (useful for future works on networks internal reconfiguration)
	 * 
	 * @param candidate
	 * 				the candidate connection
	 * @param existing
	 * 				the existing connection
	 * @param flag
	 * 		the searching direction
	 * @return
	 * 		if the existing connection is sharable with the candidate one
	 */
	public boolean matchConnectionSboxMultiple(Connection candidate, Connection existing, int flag) {
		
		if((existing.getSource().getAdapter(Port.class) != null) && (existing.getTarget().getAdapter(Port.class) != null)){
			// source and target of existing connection are ports
			return matchConnectionMultiple(candidate, existing);	
		} else {
			if(flag!=TARGET_SEARCH)
				if(existing.getSource().getAdapter(Port.class) == null)
					if ((existing.getSource().getAdapter(Actor.class).hasAttribute("sbox"))) {
						// source of existing connection is a sbox
						if((flag==SOURCE_SEARCH) || ((flag==INIT_SEARCH) 
								&& matchTargetsMultiple(candidate,existing))) {
							if((flag==INIT_SEARCH) && matchTargetsMultiple(candidate,existing))
								resetPathConns();
							for(Connection c : (existing.getSource().getAdapter(Instance.class)).getIncomingPortMap().values())
								if(matchConnectionSboxMultiple(candidate, c, SOURCE_SEARCH)) {		// searching matching source through sbox
									if( ((c.getTargetPort().getName().equals("in1")) 
											&& c.getTarget().getAdapter(Actor.class).getAttribute("type").getStringValue().equals("2x1")) 
											|| ((existing.getSourcePort().getName().equals("out1")) 
											&& existing.getSource().getAdapter(Actor.class).getAttribute("type").getStringValue().equals("1x2")) ) {
										luts.put((existing.getSource().getAdapter(Instance.class)), false);
									} else if ( ((c.getTargetPort().getName().equals("in2")) 
											&& c.getTarget().getAdapter(Actor.class).getAttribute("type").getStringValue().equals("2x1"))
											|| ((existing.getSourcePort().getName().equals("out2")) 
											&& existing.getSource().getAdapter(Actor.class).getAttribute("type").getStringValue().equals("1x2")) ) {
										luts.put((existing.getSource().getAdapter(Instance.class)), true);
									}
									pathConnections.add(existing);
									return true;
								}
						}
					} else {
						if(flag==SOURCE_SEARCH)
							if(matchSourcesMultiple(candidate,existing)) {		// end of sbox source searching
								pathConnections.add(existing);
								return true;
							}
					}
			if(flag!=SOURCE_SEARCH)
				if(existing.getTarget().getAdapter(Port.class) == null)
					if (existing.getTarget().getAdapter(Actor.class).hasAttribute("sbox")){
						if((flag==TARGET_SEARCH) || ((flag==INIT_SEARCH) 
								&& matchSourcesMultiple(candidate,existing))) {
							if((flag==INIT_SEARCH) && matchSourcesMultiple(candidate,existing))
								resetPathConns();
							// target of existing connection is a sbox
							for(List<Connection> lc : (existing.getTarget().getAdapter(Instance.class)).getOutgoingPortMap().values())
								for(Connection c : lc)
									if(matchConnectionSboxMultiple(candidate, c, TARGET_SEARCH)) {		// searching matching target through sbox
										if( ((c.getSourcePort().getName().equals("out1")) 
												&& c.getSource().getAdapter(Actor.class).getAttribute("type").getStringValue().equals("1x2")) 
												|| ((existing.getTargetPort().getName().equals("in1")) 
												&& existing.getTarget().getAdapter(Actor.class).getAttribute("type").getStringValue().equals("2x1")) ) {
											luts.put((existing.getTarget().getAdapter(Instance.class)), false);
										} else if ( ((c.getSourcePort().getName().equals("out2")) 
												&& c.getSource().getAdapter(Actor.class).getAttribute("type").getStringValue().equals("1x2")) 
												|| ((existing.getTargetPort().getName().equals("in2")) 
												&& existing.getTarget().getAdapter(Actor.class).getAttribute("type").getStringValue().equals("2x1")) ) {
											luts.put((existing.getTarget().getAdapter(Instance.class)), true);
										}
										pathConnections.add(existing);
										return true;
									}
						}
				} else {
					if(flag==TARGET_SEARCH)
						if(matchTargetsMultiple(candidate,existing)) {		// end of sbox target searching
							pathConnections.add(existing);
							return true;
						}
				}
			// the existing connection vertex are not sbox
			if(matchConnectionMultiple(candidate, existing)) {
				resetPathConns();
				pathConnections.add(existing);
				return true;
			} else {
				return false;
			}
		}
	}
	
	/**
	 * Verify if the existing connection source is sharable with the candidate one.
	 * (useful for future works on networks internal reconfiguration)
	 * 
	 * @param candidate
	 * 				the candidate connection
	 * @param existing
	 * 				the existing connection
	 * @return
	 * 		if the existing connection source is sharable with the candidate one
	 */
	public boolean matchSources(Connection candidate, Connection existing){
		return (unifier.canUnify(candidate.getSource(),existing.getSource()) 
				&& unifier.canUnify(candidate.getSourcePort(),existing.getSourcePort()));
	}

	/**
	 * Verify if the existing connection source is sharable with the candidate one.
	 * 
	 * @param candidate
	 * 				the candidate connection
	 * @param existing
	 * 				the existing connection
	 * @return
	 * 		if the existing connection source is sharable with the candidate one
	 */
	public boolean matchSourcesMultiple(Connection candidate, Connection existing){
		return (unifier.canUnifyMultiple(candidate.getSource(),existing.getSource()) 
				&& unifier.canUnify(candidate.getSourcePort(),existing.getSourcePort()));
	}

	/**
	 * Verify if the existing connection source is sharable with the candidate one.
	 * Sboxes can be included in the sharable path.
	 * 
	 * @param candidate
	 * 				the candidate connection
	 * @param existing
	 * 				the existing connection
	 * @return
	 * 		if the existing connection source is sharable with the candidate one
	 */
	public boolean matchSourcesMultipleSbox(Connection candidate, Connection existing){
		if(existing.getSource().hasAttribute("sbox"))
			for(Connection inputSboxConnection : 
					existing.getSource().getAdapter(Instance.class).getIncomingPortMap().values())
				return (matchSourcesMultipleSbox(candidate,inputSboxConnection));
		return (unifier.canUnifyMultiple(candidate.getSource(),existing.getSource()) 
				&& unifier.canUnify(candidate.getSourcePort(),existing.getSourcePort()));
	}

	/**
	 * Verify if the existing connection source is sharable with the candidate one.
	 * Sboxes can be included in the sharable path.
	 * (useful for future works on networks internal reconfiguration)
	 * 
	 * @param candidate
	 * 				the candidate connection
	 * @param existing
	 * 				the existing connection
	 * @return
	 * 		if the existing connection source is sharable with the candidate one
	 */
	public boolean matchSourcesSbox(Connection candidate, Connection existing){
		if(existing.getSource().hasAttribute("sbox"))
			for(Connection inputSboxConnection : 
					existing.getSource().getAdapter(Instance.class).getIncomingPortMap().values())
				return (matchSourcesSbox(candidate,inputSboxConnection));
		return (unifier.canUnify(candidate.getSource(),existing.getSource()) 
				&& unifier.canUnify(candidate.getSourcePort(),existing.getSourcePort()));
	}

	/**
	 * Verify if the existing connection target is sharable with the candidate one.
	 * (useful for future works on networks internal reconfiguration)
	 * 
	 * @param candidate
	 * 				the candidate connection
	 * @param existing
	 * 				the existing connection
	 * @return
	 * 		if the existing connection target is sharable with the candidate one
	 */
	public boolean matchTargets(Connection candidate, Connection existing){
		return (unifier.canUnify(candidate.getTarget(),existing.getTarget()) 
				&& unifier.canUnify(candidate.getTargetPort(),existing.getTargetPort()));
	}

	/**
	 * Verify if the existing connection target is sharable with the candidate one.
	 * 
	 * @param candidate
	 * 				the candidate connection
	 * @param existing
	 * 				the existing connection
	 * @return
	 * 		if the existing connection target is sharable with the candidate one
	 */
	public boolean matchTargetsMultiple(Connection candidate, Connection existing){
		return (unifier.canUnifyMultiple(candidate.getTarget(),existing.getTarget()) 
				&& unifier.canUnify(candidate.getTargetPort(),existing.getTargetPort()));
	}

	/**
	 * Verify if the existing vertex is sharable with the candidate one.
	 * 
	 * @param candidate
	 * 				the candidate vertex
	 * @param existing
	 * 				the existing vertex
	 * @return
	 * 		if the existing vertex is sharable with the candidate one
	 */
	public boolean matchVertices(Vertex candidate, Vertex existing){
		return (unifier.canUnifyMultiple(candidate,existing));
	}

	/**
	 * Reset the current sharable connection path.
	 */
	public void resetPathConns() {
		pathConnections = new ArrayList<Connection>();
	}

	/**
	 * Set the Look-Up Tables of the current sharable 
	 * connection path.
	 * 
	 * @param newLuts
	 * 		the new value of the LUTs
	 */
	public void setLuts(Map<Instance,Boolean> newLuts){
		luts = newLuts;
	}
	
}