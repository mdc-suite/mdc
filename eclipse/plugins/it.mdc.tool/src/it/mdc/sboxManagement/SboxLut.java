package it.unica.diee.mdc.sboxManagement;

import java.util.Map;
import java.util.Set;
import java.util.HashMap;

import net.sf.orcc.df.Network;
import net.sf.orcc.df.Instance;

/**
 * A SBox Look-Up Table (LUT)
 * 
 * @author Carlo Sau
 *
 */
public class SboxLut{
	
	/**
	 * Flag value that represent all section of the network
	 * (sections are useful for future works about networks
	 * internal reconfiguration)
	 */
	protected static final int ALL_SECTIONS = 0;
	
	
	/**
	 * The SBox instance to which is associated the LUT
	 */
	private Instance sboxInstance;
	
	/**
	 * Map with all the network sections boolean values
	 * (sections are useful for future works about networks
	 * internal reconfiguration)
	 */
	private Map<Network, Map<Integer,Boolean>> lutMap;
	
	
	/**
	 * The constructor
	 * 
	 * @param sboxInstance
	 * 		The SBox instance to which is associated the LUT
	 */
	public SboxLut(Instance sboxInstance){
		this.sboxInstance = sboxInstance;
		lutMap = new HashMap<Network, Map<Integer,Boolean>>();
	}
	
	/**
	 * Return the LUT SBox instance progressive count
	 * 
	 * @return
	 * 		the LUT SBox instance progressive count
	 */
	public Integer getCount(){
		if(sboxInstance.hasAttribute("count"))
			return ((Integer) sboxInstance.getAttribute("count").getObjectValue());
		return null;
	}
	
	/**
	 * Return the LUT SBox instance
	 * 
	 * @return
	 * 		the LUT SBox instance
	 */
	public Instance getSboxInstance(){
		return sboxInstance;
	}
	
	/**
	 * Return the LUT value for the given network and the given section.
	 * 
	 * @param network
	 * 		the given network
	 * @param section
	 * 		the given section
	 * @return
	 * 		the LUT value
	 */
	public boolean getLutValue(Network network, int section){

		if(lutMap.get(network).containsKey(ALL_SECTIONS))
				return lutMap.get(network).get(ALL_SECTIONS);
		
		return lutMap.get(network).get(section);
		
	}
	
	/**
	 * Return the LUT value for the given network name and for 
	 * all the sections.
	 * 
	 * @param networkName
	 * 		the given network name

	 * @return
	 * 		the LUT value
	 */
	public boolean getLutValue(String networkName){

		for(Network network : getNetworks()) {
			if(network.getSimpleName().equals(networkName)) {
				return lutMap.get(network).get(ALL_SECTIONS);
			}
		}
		
		return false;
		
	}
	
	/**
	 * Return the LUT values for all the sections of the given network.
	 * 
	 * @param network
	 * 		the given network
	 * @return
	 * 		the map of the values of each section
	 */
	public Map<Integer,Boolean> getAllNetworkValues(Network network){
		return lutMap.get(network);
	}
	
	/**
	 * Set the LUT value for the given section of the given network.
	 * 
	 * @param network
	 * 		the given network
	 * @param section
	 * 		the given section
	 * @param value
	 * 		the set value
	 */
	public void setLutValue(Network network, int section, boolean value){
		Map<Integer,Boolean> valueMap;
		if(lutMap.get(network)!= null) {
			valueMap = lutMap.get(network);
		} else {
			valueMap = new HashMap<Integer,Boolean>();
			lutMap.put(network, valueMap);
		}
			valueMap.put(section,value);
	}
	
	/**
	 * Complete the LUT of the given network, for all the sections before
	 * the current one, setting the missing LUT values to false. 
	 * 
	 * @param network
	 * 		the given network
	 * @param currentSection
	 * 		the given section
	 */
	public void completeLutCurrent(Network network, int currentSection){
		
		for(int i = 1; i < currentSection; i++ ){
			if(lutMap.get(network).get(i) == null)
				setLutValue(network, i , false);
		}
		
	}
	
	/**
	 * Verify if there is at least one set section for given network in
	 * the LUT.
	 * 
	 * @param network
	 * 		the given network
	 * @return
	 * 		if there is at least one set section for given network in the 
	 * 		LUT
	 */
	public boolean isSetAnySection (Network network) {
		
		boolean result = false;
		
		for(boolean value : lutMap.get(network).values())
			if(value)
				result = true;
		
		return result;
		
	}
	
	/**
	 * Remove all LUT values of the given network.
	 * 
	 * @param network
	 * 		the given network
	 */
	public void clearNetworkValues (Network network) {
		lutMap.get(network).clear();
	}
	
	/**
	 * Complete the LUT of the given networks, for all the sections before
	 * the given current ones, setting the missing LUT values to false. 
	 * 
	 * @param networkSections
	 * 		the map of the given networks with the current sections
	 */
	public void completeLut(Map<Network,Integer> networkSections){	
		for(Network  nextNet : networkSections.keySet()){
			Map<Integer,Boolean> valueMap = new HashMap<Integer,Boolean>();
			if(!lutMap.containsKey(nextNet)){
				for(int i = 1; i <= networkSections.get(nextNet); i++){				
					valueMap.put(i,false);
				}
				lutMap.put(nextNet, valueMap);
				break;
			}
			if(!lutMap.get(nextNet).containsKey(ALL_SECTIONS)) {
				Map<Integer,Boolean> existingValueMap = lutMap.get(nextNet);
				for(int i = 1; i <= networkSections.get(nextNet); i++){
					if(!lutMap.get(nextNet).containsKey(i)) {
						existingValueMap.put(i,false);
					}
				}
			}
		}
	}
	
	/**
	 * Complete the LUT of the given networks, for all the sections, setting 
	 * the missing LUT values to false. 
	 * 
	 * @param networkSections
	 * 		the map of the given networks with the current sections
	 */
	public void completeLutMultiple(Map<Network,Integer> networkSections){
		
		for(Network  nextNet : networkSections.keySet()){
			Map<Integer,Boolean> valueMap = new HashMap<Integer,Boolean>();
			if(!lutMap.containsKey(nextNet)){
				valueMap.put(0,false);
				lutMap.put(nextNet, valueMap);
			}
			
		}

	}
	
	/**
	 * Assign the all section value to the given network.
	 * The assigned value is true if there is at least one section that 
	 * has a true value, else it is false.
	 * 
	 * @param network
	 * 		the given network
	 * 		
	 */
	public void flatLut (Network network) {
		Boolean value = false;
		for(Integer section : lutMap.get(network).keySet())
			if(getLutValue(network,section))
				value = true;
		Map<Integer,Boolean> valueMap = new HashMap<Integer,Boolean>();
		valueMap.put(ALL_SECTIONS,value);
		lutMap.get(network).clear();
		lutMap.put(network, valueMap);			
	}
	
	/**
	 * Return all the networks that have an associated value in the LUT.
	 * 
	 * @return
	 * 		the set of networks that have an associated value in the LUT
	 */
	public Set<Network> getNetworks() {
		return lutMap.keySet();
	}
	
	/**
	 * Return a string with a simple description of the LUT.
	 * 
	 * @return
	 * 		a simple description of the tool
	 */
	@Override
	public String toString(){
		String result = "\nInstance: " + sboxInstance.getName(); 
		for(Network nextNet : lutMap.keySet()){
			result += "\n\tNetwork: " + nextNet + " values: " + lutMap.get(nextNet);
		}
		return result;
	}

}