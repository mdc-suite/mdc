package it.mdc.tool.sboxManagement;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import net.sf.orcc.df.Instance;
import net.sf.orcc.df.Network;

/**
 * Manage the LUT of the sboxes in the network
 * 
 * @author Carlo Sau
 *
 */
public class SboxLutManager {

	/**
	 * List of sbox LUTs in the network
	 */
	private List<SboxLut> sboxLuts;
		
	/**
	 * Flag value that represent all section of the network
	 */
	public final static int ALL_SECTIONS = 0;

	/**
	 * Constructor
	 */
	public SboxLutManager() {
		sboxLuts = new ArrayList<SboxLut>();
	}
	
	/**
	 * Get all sbox LUTs of the result network
	 * 
	 * @return
	 */
	public List<SboxLut> getLuts () {
		return sboxLuts;
	}
	
	/**
	 * Get the LUTs of the given sbox instance
	 * 
	 * @param instance
	 * @return
	 */
	public SboxLut getLut (Instance instance) {
		for(SboxLut lut : sboxLuts)
			if(lut.getSboxInstance().equals(instance))
				return lut;
		return null;
	}
	
	/**
	 * Set to true the value of sbox LUT for the given network and the given section
	 * 
	 * @param instance
	 * @param network
	 * @param section
	 */
	public void setLutValue(Instance instance, Network network, int section) {
		SboxLut lut = getLut(instance);
		if (lut == null) {
			lut = new SboxLut(instance);
			sboxLuts.add(lut);
		}
		lut.setLutValue(network, section, true);
	}
	
	/**
	 * Reset to false the value of sbox LUT for the given network and the given section 
	 * 
	 * @param instance
	 * @param network
	 * @param section
	 */
	public void resetLutValue(Instance instance, Network network, int section) {
		SboxLut lut = getLut(instance);
		if (lut == null) {
			lut = new SboxLut(instance);
			sboxLuts.add(lut);
		}
		lut.setLutValue(network, section, false);
	}
	
	/**
	 * Reset the sbox LUT value of the given network for the previous section respect 
	 * to the section passed
	 * 
	 * @param instance
	 * @param network
	 * @param currentSection
	 */
	public void resetPrevSectionsLut (Instance instance, Network network, int currentSection) {
		for(int i=1; i<currentSection; i++)
			resetLutValue(instance,network,i);
	}

	/**
	 * Flatten the given network sbox LUT values to an unique value with section 
	 * <ALL_SECTION> when are preserved multiple instances for the same actor
	 * 
	 * @param network
	 */
	public void flatLuts (Network network) {
		for(SboxLut lut : sboxLuts) {
			boolean value = lut.isSetAnySection(network);
			lut.clearNetworkValues(network);
			lut.setLutValue(network, ALL_SECTIONS, value);
		}
	}
	
	/**
	 * Adds new sbox LUT values to existing sbox LUT for the passed network
	 * and the passed section
	 * 
	 * @param luts
	 * @param currentNetwork
	 * @param currentSection
	 */
	public void addLutsExistingSboxes(Map<Instance,Boolean> luts, Network currentNetwork, int currentSection){
		if(luts.isEmpty()) {
			return;
		}
		for(Instance sboxInstance : luts.keySet()){
			for(SboxLut sboxLut: sboxLuts){
				if(sboxLut.getSboxInstance().equals(sboxInstance)) {
					sboxLut.setLutValue(currentNetwork, currentSection, luts.get(sboxInstance));
				}
			}
		}
	}
	
	/**
	 * Complete sbox LUT of the result network if there is
	 * any sbox LUT of any sbox instance with any value that's not set.
	 * Multiple instances for the same actor are not preserved
	 * 
	 * @param sectionMap
	 */
	public void completeLuts(Map <Network, Integer> sectionMap) {
		for(SboxLut lut : sboxLuts)
			lut.completeLut(sectionMap);
	}
	

	/**
	 * Complete sbox LUT of the result network if there is
	 * any sbox LUT of any sbox instance with any value that's not set.
	 * Multiple instances for the same actor are not preserved
	 * 
	 * @param sectionMap
	 */
	public void completeLutsMultiple(Map <Network, Integer> sectionMap) {
		for(SboxLut lut : sboxLuts) {
			lut.completeLutMultiple(sectionMap);
		}
	}
	
}
