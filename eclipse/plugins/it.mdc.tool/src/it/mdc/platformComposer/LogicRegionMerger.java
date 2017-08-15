package it.unica.diee.mdc.platformComposer;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * This class merges together different Logic Regions
 * (LRs) when the number of LRs is greater than the 
 * available dedicated cells in the target device.
 */
public class LogicRegionMerger {
	
	/**
	 * The map of the power estimation for each actor
	 */
	private Map<String, Double> powerMap;
	
	/**
	 * Number of available dedicated cells
	 */
	private int DEDICATED_CELLS_NR;
	
	/**
	 * Map of the instances for each LR
	 */
	private Map<String, Set<String>> logicRegions;
	
	/**
	 * 
	 */
	private Map<String, Set<String>> regionsIndexMap;
	
	/**
	 * The constructor
	 * 
	 * @param inputMap
	 * @param max_cells
	 */
	public LogicRegionMerger(Map<String, Set<String>> inputMap, int max_cells) {
		// initialize the original input Map
		logicRegions = new HashMap<String,Set<String>>(inputMap);
		regionsIndexMap = new HashMap<String,Set<String>>();
		for(String index : logicRegions.keySet()) {
			Set<String> region = new HashSet<String>();
			region.add(String.valueOf(index));
			regionsIndexMap.put(String.valueOf(index),region);
		}

		DEDICATED_CELLS_NR = max_cells;
	
		powerMap = new HashMap<String,Double>();
	}
	
	/**
	 * Return the map of instances for each LR.
	 * 
	 * @return
	 * 		the map of instances for each LR
	 */
	public Map<String, Set<String>> getLogicRegions() {	
		return logicRegions;
	}
	
	/**
	 * Return the map of the index of the merged
	 * LRs.
	 * 
	 * @return
	 * 		the map of the index of the merged LRs
	 */
	public Map<String, Set<String>> getIndexMap() {	
		return regionsIndexMap;
	}

	/**
	 * Merge iteratively two LRs at a time in order to meet the 
	 * available dedicated cells number constraint.
	 * The considered metric is the LRs size.
	 */
	public void mergeRegions(){
		
		while (logicRegions.size() > DEDICATED_CELLS_NR) {
			
			//initialize the map of the original regions size
			LinkedHashMap<String,Integer> regionsSize = computeRegionsSize();
			
			//initialize the map of the sorted regions size
			sortRegionsBySize(regionsSize);
			
			mergeBestRegions();
		}

	}
	
	/**
	 * Merge iteratively two LRs at a time in order to meet the 
	 * available dedicated cells number constraint.
	 * The considered metric is the LRs (static) power.
	 */
	public void mergeRegions(Map<String,Double> powerMap){
		
		this.powerMap = powerMap;
		
		while (logicRegions.size() > DEDICATED_CELLS_NR) {
			
			//initialize the map of the original regions size
			LinkedHashMap<String,Double> regionsPower = computeRegionsPower();
			
			//initialize the map of the sorted regions size
			sortGatingSetsPower(regionsPower);
			
			mergeBestRegions();
		}

	}
		
	/**
	 * Compute the Logic Regions (LRs) size
	 * and put it into the related map
	 */
	private LinkedHashMap<String,Integer> computeRegionsSize() {

		LinkedHashMap<String,Integer> regionsSize = new LinkedHashMap<String,Integer>();
		
		//Iterate on all the different regions	
		for(String regionIndex : logicRegions.keySet()) { 					
			regionsSize.put(regionIndex, logicRegions.get(regionIndex).size());
		}
		return regionsSize;
	}
	
	
	/**
	 * Compute the Regions (LRs) power
	 * and put it into the related map
	 */
	private LinkedHashMap<String,Double> computeRegionsPower() {
		
		LinkedHashMap<String,Double> regionsPower = new LinkedHashMap<String,Double>();
		
		//Iterate on all the different regions	
		for(String regionIndex : logicRegions.keySet()) { 					
			
			double power = 0.0;
			
			for(String actor : logicRegions.get(regionIndex)) {
				power += powerMap.get(actor);
			}
			
			regionsPower.put(regionIndex, power);

		}
		return regionsPower;
	}
	
	/**
	 * Sort the LRs according with the given related sizes. 
	 * 
	 * @param setsSize
	 * 		the map of sizes for each LR
	 * @return
	 * 		the sorted map of sizes for each LR
	 */
	private void sortRegionsBySize(LinkedHashMap<String,Integer> regionsSize){
		
		// local copy of the input region of the sizes
		Map<String, Integer> map = new HashMap<String,Integer>(regionsSize);
		regionsSize = new LinkedHashMap<String,Integer>();
		
		// list of all the keys 	
		List<Integer> sizes = new ArrayList<Integer>(map.values());
		List<String> regions = new ArrayList<String>(map.keySet());
		
		// order the list of all the values in ascending order 
		Collections.sort(sizes); 		
		
		for(Integer size : sizes) {
			
			for(String region : regions) {
				
				if(size.equals(map.get(region))) {
					
					map.remove(region);
					regions.remove(region);

					regionsSize.put(region, size);
					break;
				}
			}
		}
		
	}
	
	/**
	 * Sort the LRs according with the given related power. 
	 * 
	 * @param setsSize
	 * 		the map of power for each LR
	 * @return
	 * 		the sorted map of power for each LR
	 */
	private void sortGatingSetsPower(LinkedHashMap<String,Double> regionsPower){
		
		// local copy of the input region of the sizes
		Map<String, Double> map = new HashMap<String,Double>(regionsPower);
		regionsPower = new LinkedHashMap<String,Double>();
		
		// list of all the keys 	
		List<Double> powers = new ArrayList<Double>(map.values());
		List<String> regions = new ArrayList<String>(map.keySet());
		
		// order the list of all the values in ascending order 
		Collections.sort(powers); 		
		
		for(Double power : powers) {
			
			for(String region : regions) {
				
				if(power.equals(map.get(region))) {
					
					map.remove(region);
					regions.remove(region);
					powers.remove(power);

					regionsPower.put(region,power);
					break;
				}
			}
		}
		
	}
	
	/**
	 * Merge the two LRs with the lower weights (size or power) 
	 * and return the new map of sorted LRs weights.
	 * 
	 * @return
	 * 		the new map of sorted LRs weights
	 */
	private void mergeBestRegions(){
		
		// define index for the new merged set
		List<Integer> indices = new ArrayList<Integer>();
		for(String index : logicRegions.keySet()) {
			indices.add(Integer.parseInt(index));
		}
		int newIndex = Collections.max(indices) + 1;
		
		Iterator<String> regionsIterator = logicRegions.keySet().iterator();
		
		String firstSetIdx = regionsIterator.next();
		String secondSetIdx = regionsIterator.next();
		
		Set<String> newRegion = logicRegions.get(firstSetIdx);
		newRegion.addAll(logicRegions.get(firstSetIdx));
		
		logicRegions.remove(firstSetIdx);
		logicRegions.remove(secondSetIdx);
		logicRegions.put(String.valueOf(newIndex), newRegion);
		
		Set<String> newRegionIndex = regionsIndexMap.get(firstSetIdx);
		newRegionIndex.addAll(regionsIndexMap.get(secondSetIdx));
		
		regionsIndexMap.remove(firstSetIdx);
		regionsIndexMap.remove(secondSetIdx);
		regionsIndexMap.put(String.valueOf(newIndex),newRegionIndex);
		
	}
	
}