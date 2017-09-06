package it.mdc.tool.profiling;

import static it.mdc.tool.profiling.Profiler.DONT_MERGE;

import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import net.sf.orcc.df.Network;

/**
 * Calculate the combinations of the input dataflow networks
 * to generate the Multi-Dataflow Composer design space.
 * 
 * @author Carlo
 *
 */
public class CombinationsGenerator {

	/**
	 * Calculate the design space for the given input list of networks.
	 * It is composed by not merged (D_notMer), partially merged (D_partMer)
	 * and fully merged (D_mer) combinations.
	 * The number of merged networks is less than 9 (no heuristic).
	 * 
	 * @param networks
	 * 		the givent input list of networks
	 * @return
	 * 		the list of the design space points
	 */
	public List<Map<Network, Integer>> calculateCombinations(List<Network> networks) {
		
		createComb(networks);
		int indx =0;
		List<Map<Network,Integer>> result = new ArrayList<Map<Network,Integer>>();
	
		
		// initial permutation
		Map<Network,Integer> initElem = new HashMap<Network,Integer>();
		for(Network dontMergeNet : networks) {
			initElem.put(dontMergeNet, DONT_MERGE);
		}
		result.add(initElem);
		
		// intermediate permutations
		if(networks.size() != 2) {	
			Map<Integer,List<List<Network>>> intermediateMap = createComb(networks);
			
			Combinations trial = new Combinations(networks);			
	        trial.createComb();
	        intermediateMap=trial.getMap();
	        trial.removeALL();
	        intermediateMap=trial.getMap_NR();
	        trial.removeALL();
	
	        for(int i: intermediateMap.keySet()) {
				if(intermediateMap.get(i) != null) {				
					Map<Network,Integer> interElem = new HashMap<Network,Integer>();
					indx = 1;
					
					List<Network> dontMergeList = intermediateMap.get(i).get(0);
					for(Network dontMergeNet : dontMergeList) {
						interElem.put(dontMergeNet,DONT_MERGE);
					}
				
					List<Network> mergeList = intermediateMap.get(i).get(1);
					for(Network mergeNet : mergeList) {
						interElem.put(mergeNet,indx);
						indx++;
					}
					
					result.add(interElem);
				}
			}
			intermediateMap.clear();
						
		}
		
		// final permutations
		Permutations<Network> permutator = new Permutations<Network>();
	    Collection<Network> netsToPermute = new ArrayList<Network>();
	    netsToPermute.addAll(networks);
	    Collection<List<Network>> netsPermutations = permutator.permute(netsToPermute);
	    for(List<Network> netsPermutation : netsPermutations) {
	    	indx = 1;
	    	Map<Network,Integer> finalElem = new HashMap<Network,Integer>();
	    	for(Network mergeNet : netsPermutation) {
	    		finalElem.put(mergeNet,indx);
	    		indx++;
	    	}
	    	result.add(finalElem);
	    }
	    netsToPermute.clear();
	    netsPermutations.clear();
		return result;
	}

	/**
	 * Calculate the design space for the given input list of networks.
	 * It is composed by not merged (D_notMer), partially merged (D_partMer)
	 * and fully merged (D_mer) combinations.
	 * The number of merged networks is more than 9 (heuristic).
	 * 
	 * @param networks
	 * 		the givent input list of networks
	 * @return
	 * 		the list of the design space points
	 */
	public List<Map<Network, Integer>> calculateCombinationsEff(List<Network> networks) {
		
		List<Map<Network,Integer>> result = new ArrayList<Map<Network,Integer>>();
	
		List<Network> mergingList = new ArrayList<Network>();
		List<Network> dontMergingList = new ArrayList<Network>();
		
		// create lists of networks to be merged or not
		for(Network net : networks) {
			if(net.hasAttribute("dontTouch"))
				dontMergingList.add(net);
			else
				mergingList.add(net);
		}
		//System.out.println("merging list " + mergingList);
		//System.out.println("dont merging list " + dontMergingList);
		
		// initial permutation
		Map<Network,Integer> initElem = new HashMap<Network,Integer>();
		for(Network dontMergeNet : networks) {
			initElem.put(dontMergeNet, DONT_MERGE);
		}
		result.add(initElem);
			
		// intermediate permutations
		if(networks.size() != 2) {	
			result.addAll(createCombEff(mergingList,dontMergingList));				
		}
		
		// final permutations
		result.addAll(createCombFinalEff(mergingList,dontMergingList));
		
		return result;
	}

	/**
	 * Calculate all the combinations of the design space.
	 * The number of merged networks is less than 9 (no heuristic).
	 * 
	 * @param inputNetworks
	 * 		list of input network
	 * @return
	 * 		the list of the design space points
	 */
	private Map<Integer,List<List<Network>>> createComb(List<Network> inputNetworks){
		
		Map<Integer,List<List<Network>>> combinationsMap = new HashMap<Integer,List<List<Network>>>();
		
		Integer key=1;
		
		for (int i=0; i<inputNetworks.size(); i++){
			
			List<Network> list = new ArrayList<Network>(inputNetworks);
			
			// dontMergeNet is a network to be placed in parallel
			Network dontMergeNet = list.get(i);
			list.clear();
			
			// list of nets to be placed in parallel (one net at first step)
			List<Network> dontMergeList = new ArrayList<Network>();
			dontMergeList.add(dontMergeNet);
	        
	        // make list of merging nets to permute removing the firstNet
	        Collection<Network> mergingNetsToPermute = new ArrayList<Network>();
	        mergingNetsToPermute.addAll(inputNetworks);
	        mergingNetsToPermute.remove(dontMergeNet);
	        
	        // make the permutation of all the input networks except the first one
	        Permutations<Network> permutator = new Permutations<Network>();            
	        Collection<List<Network>> mergingNetsPermutations = permutator.permute(mergingNetsToPermute);
	        mergingNetsToPermute.clear();
	        	        
	        Iterator<List<Network>> iterator = mergingNetsPermutations.iterator();
	
	        while(iterator.hasNext()) {
	        	
	        	// analyze each combination
	        	List<Network> currentMergingPermutation = iterator.next();
	        	
	        	// associate each combination list to the first list
	            List<List<Network>> permutationList = new ArrayList<List<Network>>();
	            permutationList.add(dontMergeList);							// add parallel (don't merge) nets to the element
	            permutationList.add((List<Network>) currentMergingPermutation);	// add merging nets to the element
	            
	            // add the double list (a combination) to the output map
	            combinationsMap.put(key, permutationList);
	            permutationList.clear();
	            key ++;
	            
	            // make a copy of the current combination list
	            List<Network> mergingPermutationCopy = new ArrayList<Network>();
	            mergingPermutationCopy.addAll((List<Network>) currentMergingPermutation);
	
	            iterator.remove();
	            currentMergingPermutation.clear();
	            
	            List<Network> firstList = new ArrayList<Network>();
	                            
	            // LOOP: iterate while the number of networks to not merge is lower than N-1
	            while(mergingPermutationCopy.size() > 9){
	            	// currentDontMergeNet is the index an additional network (till N-2) to be placed in parallel
	            	Network currentDontMergeNet = mergingPermutationCopy.get(0);
	
	            	// remove the currentDontMergeNet from the currentPermutationCopy
	            	mergingPermutationCopy.remove(currentDontMergeNet);
	            	
	            	// calculate the currentDontMergeList
	            	List<Network> currentDontMergeList = new ArrayList<Network>();
	            	currentDontMergeList.addAll(dontMergeList);
	            	currentDontMergeList.addAll(firstList);
	            	currentDontMergeList.add(currentDontMergeNet); //add the new parallel (don't merge) net to the previous firstItNet list
	
	                // make list of the current merging nets removing the currentDontMergeNet
	                List<Network> currentMergingList = new ArrayList<Network>();
	                currentMergingList.addAll(mergingPermutationCopy);
	                    
	                // make a new element of the permutationsMap
	                List<List<Network>> currentPermutationList = new ArrayList<List<Network>>();
	                currentPermutationList.add(currentDontMergeList);
	                currentPermutationList.add(currentMergingList);
	                
	                currentDontMergeList.clear();
	                currentMergingList.clear();
	                    
	                combinationsMap.put(key, currentPermutationList);
	                currentPermutationList.clear();
	                key=key+1;
	
	                firstList.add(currentDontMergeNet);
	                
	            }
	           
	            mergingPermutationCopy.clear();
	            
	        }            
	        mergingNetsPermutations.clear();
		}
		return combinationsMap;
	}

	/**
	 * Calculate the partially merged (D_partMer) combinations of the 
	 * design space.
	 * The number of merged networks is more than 9 (heuristic).
	 * 
	 * @param mergingNetworks
	 * 		the networks to be merged together
	 * @param dontMergeNetworks
	 * 		the networks to be kept in parallel
	 * @return
	 * 		the list of the partially merged design space points
	 */
	private List<Map<Network,Integer>> createCombEff(List<Network> mergingNetworks, List<Network> dontMergeNetworks){
				
		List<Map<Network,Integer>> result = new ArrayList<Map<Network,Integer>>();
		
		// the permutator
		Permutations<Network> permutator = new Permutations<Network>();
		
		//Integer key=1;
		
		// list of merging networks
		List<Network> mergingNets = new ArrayList<Network>(mergingNetworks);
		
		
		for(int i=1; i<mergingNets.size(); i++) {
	
				// create all the lists with i don't merge networks
				List<List<Network>> dontMergeLists = findCnotP(mergingNets,i);
			
				for(List<Network> dontMergeList : dontMergeLists){
					
					// create the list of merging networks for the selected dont merge list
					List<Network> currMergingNets = new ArrayList<Network>(mergingNets);
					currMergingNets.removeAll(dontMergeList);
						
					// find all the permutations of the current merging networks
					Collection<List<Network>> mergingPermutations = permutator.permute(currMergingNets);
										
					for(List<Network> mergingList : mergingPermutations) {
						Map<Network,Integer> map = new HashMap<Network,Integer>();
						for(Network net: dontMergeList)
							map.put(net, DONT_MERGE);
						for(Network net: dontMergeNetworks)
							map.put(net, DONT_MERGE);
						int indx=1;
						for(Network net:mergingList) {
							map.put(net, indx);
							indx++;
						}
						result.add(map);
						map.clear();
					}
					currMergingNets.clear();
					mergingPermutations.clear();
				}
				dontMergeLists.clear();
		}
		return result;
	}

	/**
	 * Calculate the fully merged (D_mer) combinations of the 
	 * design space.
	 * The number of merged networks is more than 9 (heuristic).
	 * 
	 * @param mergingNetworks
	 * 		the networks to be merged together
	 * @param dontMergeNetworks
	 * 		the networks to be kept in parallel
	 * @return
	 * 		the list of the fully merged design space points
	 */
	private List<Map<Network,Integer>> createCombFinalEff(List<Network> mergingNetworks, List<Network> dontMergeNetworks){
		
		List<Map<Network,Integer>> result = new ArrayList<Map<Network,Integer>>();
	
		// the permutator
		Permutations<Network> permutator = new Permutations<Network>();
				
		// list of merging networks
		List<Network> mergingNets = new ArrayList<Network>(mergingNetworks);
		
		
		for(int i=1; i<2; i++) {
	
				// create all the lists with i don't merge networks
				List<List<Network>> dontMergeLists = findCnotP(mergingNets,i);
			
				for(List<Network> dontMergeList : dontMergeLists){
	
					// create the list of merging networks for the selected dont merge list
					List<Network> currMergingNets = new ArrayList<Network>(mergingNets);
					currMergingNets.removeAll(dontMergeList);
						
					// find all the permutations of the current merging networks
					Collection<List<Network>> mergingPermutations = permutator.permute(currMergingNets);
										
					for(List<Network> mergingList : mergingPermutations) {
						Map<Network,Integer> map = new HashMap<Network,Integer>();
						for(Network net: dontMergeList)
							map.put(net, 1);
						int indx=2;
						for(Network net: dontMergeNetworks)
							map.put(net, DONT_MERGE);
						for(Network net:mergingList) {
							map.put(net, indx);
							indx++;
						}
						result.add(map);
						map.clear();
					}
					currMergingNets.clear();
					mergingPermutations.clear();
				}
				dontMergeLists.clear();
		}		
		return result;
	}

	/**
	 *	Find all the i-size sublist in the given merging networks list.
	 * The number of merged networks is more than 9 (heuristic).
	 * 
	 * @param mergingNets
	 * 		the list of merging networks
	 * @param i
	 * 		the size of the networks sublists
	 * @return
	 * 		the list of the i-size sublists
	 */
	private List<List<Network>> findCnotP(List<Network> mergingNets, int i) {
		List<List<Network>> result = new ArrayList<List<Network>>();
		boolean alreadyPresent = false;
		if(i>1) {
			List<List<Network>> lowOrderCnotP = findCnotP(mergingNets,i-1);
			for(List<Network> netList : lowOrderCnotP) {
				for(Network net : mergingNets) {
					if(!netList.contains(net)) {
						alreadyPresent = false;
						List<Network> newNetList = new ArrayList<Network>(netList);
						newNetList.add(net);
						for(List<Network> ln : result)
							if(ln.containsAll(newNetList))
								alreadyPresent = true;
						if(!alreadyPresent)
							result.add(newNetList);
					}
				}
			}
		}else{
			for(Network net : mergingNets) {
				List<Network> singleNetList = new ArrayList<Network>();
				singleNetList.add(net);
				result.add(singleNetList);
			}
		}
		return result;
	}
	
}
