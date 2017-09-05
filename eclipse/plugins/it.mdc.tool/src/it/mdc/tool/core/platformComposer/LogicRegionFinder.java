package it.mdc.tool.core.platformComposer;


import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

/**
 * Find the sets of instances that are always
 * active at the same time (Logic Regions,
 * LRs) in the multi-dataflow network
 * 
 * @author Carlo Sau
 *
 */
public class LogicRegionFinder {
	
	/**
	 * Map of instances for each Logic Region (LR) index
	 */
	private Map<String,Set<String>> logicRegions;
	
	/**
	 * Map of Logic Regions (LRs) indices for each network
	 * (reference list map)
	 */
	private Map<String,Set<String>> networkLogicRegions;
	
	/**
	 * The constructor
	 */
	public LogicRegionFinder() {
		logicRegions = new HashMap<String,Set<String>>();
		networkLogicRegions = new HashMap<String,Set<String>>();
	}
	
	/**
	 * Find the Logic Regions (LRs)
	 * 
	 * @param networksInstances
	 *		the map of the instances of the multi-dataflow
	 *		involved in each network
	 */
	public void findRegions(Map<String,Set<String>> networksInstances){
					
		// initialize index
		int index = 0;
		Set<String> sharedRegion = new HashSet<String>();
		
		// start iteration
		for(String network : networksInstances.keySet()) {			// analyze all nets
						
			// create a copy of the region of next net
			Set<String> nextRegion = new HashSet<String>();
			nextRegion.addAll(networksInstances.get(network));										
			
			// initialize toUpdate map
			Map<String, Set<String>> toUpdate = new HashMap<String,Set<String>>();	
			
			// first iteration assignment
			if (logicRegions.isEmpty()) {	
				logicRegions.put(String.valueOf(index), nextRegion);												
				updateNetRegionsByNetwork(network,String.valueOf(index));
				index++;
			
			} else {
				
				// analyze all indices of the already analyzed regions
				for(String regionIndex : logicRegions.keySet()) {			
					
					// get the region corresponding to the current index
					Set<String> region = logicRegions.get(regionIndex);
					
					// remove all instances of previously shared regions
					nextRegion.removeAll(sharedRegion);
					sharedRegion.clear();
										
					// if next region is empty break
					if(nextRegion.isEmpty())
						break;
					
					// try to unify the regions entirely
					if(region.equals(nextRegion)) {
						//TODO possible problem --old--> unifier.canUnifySets(set, nextSet)) {							
						updateNetRegionsByNetwork(network, regionIndex);
						nextRegion.clear();
						break;
					}
					
					// analyze all instances of the instance region
					forLoop : for(String nextInst : nextRegion) {
						// analyze all instances of the already analyzed regions				
						for(String inst : region) { 							
							
							// the regions have at least an instance in common
							if(nextInst.equals(inst)) {
								//TODO possible problem --old--> unifier.canUnifyMultiple(nextInst, inst)) {
								
								// create sharing set of instances between the two networks
								sharedRegion = getIntersection(nextRegion,region);//searcher.searchSameInstanceSet(nextSet,set);
								
								// create a region with instances to be deleted by already analyzed regions
								Set<String> updRegion = new HashSet<String>();
								updRegion.addAll(sharedRegion);
								String indx = regionIndex;
								
								// updating toUpdate map
								toUpdate.put(indx, updRegion);
								break forLoop;
							}
						}

					}
					
				}
				
				// if some instances are shared update regions output map
				if(!toUpdate.isEmpty()) {
									
					// remove instances of the shared region
					for(String i : toUpdate.keySet()) {
						logicRegions.get(i).removeAll(toUpdate.get(i));
						updateNetRegionsByIndex(i,String.valueOf(index));
						
						// if already analyzed region is empty remove it
						if(logicRegions.get(i).isEmpty()) {										
							logicRegions.remove(i);
							removeNetRegions(i);
						}
						
						// update nets references
						logicRegions.put(String.valueOf(index), toUpdate.get(i));
						updateNetRegionsByNetwork(network, String.valueOf(index));
						index++;
					}
				}
				
				// remove all instances of eventually precedent shared region
				nextRegion.removeAll(sharedRegion);
				sharedRegion.clear();
				
				// there is a disjointed region
				if(!nextRegion.isEmpty()) {													
					
					// create and add a disjointed region
					Set<String> newDisjRegion = new HashSet<String>();						
					newDisjRegion = getDisjunction(nextRegion);
					logicRegions.put(String.valueOf(index), newDisjRegion);
					updateNetRegionsByNetwork(network, String.valueOf(index));
					index++;
					
				}
			}
		}
		
		removeSBoxRegions();
		
		
		return;
					
	}
	
	/**
	 * This method identifies the set of actors, 
	 * in the given region, that are not already
	 * present in other regions.
	 * 
	 * @param nextRegion
	 * 			the region under analysis
	 * @return disjunction
	 * 			set of actors, in the given region, not present in any other region.
	 */
	private Set<String> getDisjunction(Set<String> nextRegion) {
		
		Set<String> disjunction = new HashSet<String>();
		
		loop: for(String actor : nextRegion) {
			for(Set<String> alreadyFoundRegion : logicRegions.values()) {
				if(alreadyFoundRegion.contains(actor)) {
					break loop;
				}
			}
			disjunction.add(actor);
		}
		
		return disjunction;
	}
	
	/**
	 * 
	 * This method identifies the set of actors, 
	 * present in both regions.
	 * 
	 * @param nextRegion
	 * 			the region under analysis.
	 * @param region
	 * 			the region to be compared with the region under analysis.
	 * @return	intersection
	 * 			set of actors, in the given region, present in any other region.
	 */
	private Set<String> getIntersection(Set<String> nextRegion, Set<String> region) {

		Set<String> intersection = new HashSet<String>();
		
		for(String actor : nextRegion) {
			if(region.contains(actor))
				intersection.add(actor);
		}
		
		return intersection;
	}

	/**
	 * Remove the LR with the passed index from the reference
	 * list of the network that contain it.
	 * 
	 * @param regionIndex
	 * 		the passed index
	 */
	private void removeNetRegions(String regionIndex) {
		for(String net : networkLogicRegions.keySet())
			if(networkLogicRegions.get(net).contains(regionIndex))
				networkLogicRegions.get(net).remove(regionIndex);
		
	}

	/**
	 * Update the reference list of the networks containing the given
	 * index adding a new index.
	 * 
	 * @param updIndex
	 * 		the index of the updating reference lists
	 * @param newIndex
	 * 		the new index to be added
	 */
	private void updateNetRegionsByIndex(String updIndex, String newIndex) {
		
		for(String network : networkLogicRegions.keySet())
			if(networkLogicRegions.get(network).contains(updIndex))
				networkLogicRegions.get(network).add(newIndex);
		
	}

	/**
	 * Update the reference list of the given network adding a new 
	 * index.
	 * 
	 * @param network
	 * 		the network whose reference list has to be updated
	 * @param newIndex
	 * 		the new index to be added
	 */
	private void updateNetRegionsByNetwork(String network, String newIndex) {
		
		if(!networkLogicRegions.containsKey(network)) {
			Set<String> newRegion = new HashSet<String>();
			newRegion.add(newIndex);
			networkLogicRegions.put(network, newRegion);
		} else {
			Set<String> region = networkLogicRegions.get(network);
			region.add(newIndex);
			networkLogicRegions.put(network, region);
		}
		
		return;
	}
	
	/**
	 * Update the given reference list map substituting the indices values
	 * of the map of indices with the corresponding keys. Return the updated
	 * reference list map.
	 * 
	 * @param oldNetRegions
	 * 		the reference list map to be updated
	 * @param indexMap
	 * 		the map of indices for the update
	 * @return
	 * 		the updated reference list map
	 */
	public Map<String,Set<String>> updateNetSets(Map<String,Set<String>> oldNetRegions, 
			Map<String,Set<String>> indexMap) {
		
		// instantiate result map
		Map<String,Set<String>> result = new HashMap<String,Set<String>>();
		for(String net : oldNetRegions.keySet()) {
			Set<String> newRegion = new HashSet<String>();
			newRegion.addAll(oldNetRegions.get(net));
			result.put(net,newRegion);
		}
		
		// iterate on the indices of old map
		for(String net : oldNetRegions.keySet())
			for(String index : oldNetRegions.get(net)) {
				
				// if an index is not on the keys of index map, it must be substitute
				if(!indexMap.keySet().contains(index))
					for(String indexMapped : indexMap.keySet())
						if(indexMap.get(indexMapped).contains(index)) {
							
							// substitute the index by the corresponding key on the result map
							result.get(net).remove(index);
							result.get(net).add(indexMapped);
						}
			}
		
		return result;
	}
	
	/**
	 * Return the map of instances for each LR
	 * 
	 * @return
	 * 		the map of instances for each LR
	 */
	public Map<String,Set<String>> getRegions() {
		return logicRegions;
	}
	
	/**
	 * Return the map of LRs for each network
	 * 
	 * @return
	 * 		the map of LRs for each network
	 */
	public Map<String,Set<String>> getNetRegions() {
		return networkLogicRegions;
	}
	
	/**
	 * Remove the LR with only Sboxes.
	 */
	private void removeSBoxRegions() {
		Set<String> removableLR = new HashSet<String>();
		for(String lr: logicRegions.keySet()){
			boolean sboxFlag = true;
			loop: for(String inst: logicRegions.get(lr)){
				if(!inst.split("_")[0].equals("sbox")){
					sboxFlag = false;
					break loop;
					}
				}
			if(sboxFlag){
				removableLR.add(lr);
			}
		}	
		for(String lr: removableLR){
			logicRegions.remove(lr);
			for(String net : networkLogicRegions.keySet())
				if(networkLogicRegions.get(net).contains(lr))
					networkLogicRegions.get(net).remove(lr);
		}
	}
	
	
}
