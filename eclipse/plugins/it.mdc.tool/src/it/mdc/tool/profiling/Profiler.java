package it.mdc.tool.profiling;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.text.DecimalFormat;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import it.mdc.tool.merging.Unifier;
import net.sf.orcc.df.Actor;
import net.sf.orcc.df.Instance;
import net.sf.orcc.df.Network;
import net.sf.orcc.graph.Vertex;
import net.sf.orcc.ir.Expression;
import net.sf.orcc.ir.util.ExpressionEvaluator;

/**
 * The Mutli-Dataflow Composer profiler
 * 
 * @author Carlo
 *
 */
public class Profiler {
	
	/**
	 * The profiling area file
	 */
	private String areaFile;
	
	/**
	 * The profiling power file
	 */
	private String powerFile;
	
	/**
	 * The profiling timing file
	 */
	private String timingFile;
		
	/**
	 * The map of area values for each actor
	 */
	private Map<String,Double> areaMap;
	
	/**
	 * The map of power values for each actor
	 */
	private Map<String,Double> staticPowerMap;
	private Map<String,Double> dynamicPowerMap; // dyn
	private Map<String,Double> totalPowerMap; // tot
	
	/**
	 * The map of timing values for each actor
	 */
	private Map<String,Double> timingMap;
	
	/**
	 * Maximum Critical Path (CP) related to the isolated
	 * input dataflow networks
	 */
	private Double staticCP;
	
	
	/**
	 * Writer for the profiling output files
	 */
	private FileWriter writer;

	/**
	 * Do not merge flag
	 */
	public final static int DONT_MERGE = 0;
	
	/**
	 * Area flag
	 */
	public int AREA = 0;
	
	/**
	 * Power flag
	 */
	public int POWER = 1;
	
	/**
	 * Frequency flag
	 */
	public int FREQ = 2;
	
	/**
	 * Map of the percentages of sharable actors of each 
	 * input network with all the other ones
	 */
	private Map<Network,Map<Network,Float>> percMap;
	
	/**
	 * Map of the percentages of sharable actors of each 
	 * input network with an all merged multi-dataflow
	 * one
	 */
	private Map<Network,Float> percNet;

	/**
	 * The profiling output files path 
	 */
	private String outPath;

	/**
	 * Acquire profiling data from the specified files.
	 */
	private void acquireProfilingData() {
		try{
			
			BufferedReader fileArea = new BufferedReader(new FileReader(areaFile));
			BufferedReader filePower = new BufferedReader(new FileReader(powerFile));
			BufferedReader fileTiming = new BufferedReader(new FileReader(timingFile));
			String linea;
	
			// acquire area data
			while ( (linea = fileArea.readLine()) != null){		
				areaMap.put(linea.split(" ")[0], Double.parseDouble( linea.split(" ")[1]) );
			}
			fileArea.close();
			
			// acquire power data
			while ( (linea = filePower.readLine()) != null){		
				staticPowerMap.put(linea.split(" ")[0], Double.parseDouble( linea.split(" ")[1]) );
			}
			filePower.close();
			
			// acquire timing data
			while ((linea = fileTiming.readLine()) != null){
				timingMap.put(linea.split(" ")[0], Double.parseDouble( linea.split(" ")[1]) );
			}
			fileTiming.close();
			
		} catch (Exception e) {
			System.out.println("Exception on the area calculation phase!");
			e.printStackTrace();
		} 
	}
	
	/**
	 * Acquire profiling data from the specified files.
	 */
	private void acquireProfilingDataFromReport() {
		try{
			
			BufferedReader fileArea = new BufferedReader(new FileReader(areaFile));
			BufferedReader filePower = new BufferedReader(new FileReader(powerFile));
			BufferedReader fileTiming = new BufferedReader(new FileReader(timingFile));
			String line;
			boolean acquire;
			
			// acquire area data
			acquire = false;
			Map<String,Integer> actorOcc = new HashMap<String,Integer>();
			while ( (line = fileArea.readLine()) != null){
				if(line.contains("------------------------------------------------------------------------")){
					acquire = true;
				} else if(line.equals("")) {
					acquire = false;
				}
				if(acquire) {
					String actor = "";
					String area = "";
					if(line.split("  ")[0].equals("")) {
						if(!line.split("  ")[1].equals("")) {
							actor = line.split("  ")[1].substring(0, line.split("  ")[1].lastIndexOf("_"));
							area = line.substring(39,50).replace(" ", "");
							if(!areaMap.containsKey(actor)) {
								areaMap.put(actor, Double.parseDouble(area));
							} else {
								areaMap.put(actor, (areaMap.get(actor)+Double.parseDouble(area)));
								if(!actorOcc.containsKey(actor)) {
									actorOcc.put(actor, 2);
								} else {
									actorOcc.put(actor,actorOcc.get(actor)+1);
								}
							}
						}
					}
				}
				
			}
			for(String actor : actorOcc.keySet()) {
				areaMap.put(actor,areaMap.get(actor)/actorOcc.get(actor));
			}	
			//areaMap.put("memory",0.0);
			//areaMap.put("dummy_cubic",0.0);
			fileArea.close();
			//OrccLogger.traceln("areaMap " + areaMap);
			
			// acquire power data
			actorOcc = new HashMap<String,Integer>();
			acquire = false;
			while ( (line = filePower.readLine()) != null){	
				if(line.contains("------------------------------------------------------------------------")){
					acquire = true;
				} else if(line.equals("")) {
					acquire = false;
				}
				if(acquire) {
					String actor = "";
					String power = "";
					if(line.split("  ")[0].equals("")) {
						if(!line.split("  ")[1].equals("")) {
							actor = line.split("  ")[1].substring(0, line.split("  ")[1].lastIndexOf("_"));
							power = line.substring(38,48).replace(" ", "");
							if(!staticPowerMap.containsKey(actor)) {
								staticPowerMap.put(actor, Double.parseDouble(power));
							} else {
								staticPowerMap.put(actor, (staticPowerMap.get(actor)+Double.parseDouble(power)));
								if(!actorOcc.containsKey(actor)) {
									actorOcc.put(actor, 2);
								} else {
									actorOcc.put(actor,actorOcc.get(actor)+1);
								}
							}
						}
					}
				}
			}
			for(String actor : actorOcc.keySet()) {
				staticPowerMap.put(actor,staticPowerMap.get(actor)/actorOcc.get(actor));
			}
			//staticPowerMap.put("memory",0.0);
			//staticPowerMap.put("dummy_cubic",0.0);
			filePower.close();
			//OrccLogger.traceln("powerMap " + powerMap);
			
			filePower = new BufferedReader(new FileReader(powerFile));
			// acquire power data
						actorOcc = new HashMap<String,Integer>();
						acquire = false;
						while ( (line = filePower.readLine()) != null){	
							if(line.contains("------------------------------------------------------------------------")){
								acquire = true;
							} else if(line.equals("")) {
								acquire = false;
							}
							if(acquire) {
								String actor = "";
								String power = "";
								if(line.split("  ")[0].equals("")) {
									if(!line.split("  ")[1].equals("")) {
										actor = line.split("  ")[1].substring(0, line.split("  ")[1].lastIndexOf("_"));
										power = line.substring(49,61).replace(" ", "");
										if(!dynamicPowerMap.containsKey(actor)) {
											dynamicPowerMap.put(actor, Double.parseDouble(power));
										} else {
											dynamicPowerMap.put(actor, (dynamicPowerMap.get(actor)+Double.parseDouble(power)));
											if(!actorOcc.containsKey(actor)) {
												actorOcc.put(actor, 2);
											} else {
												actorOcc.put(actor,actorOcc.get(actor)+1);
											}
										}
									}
								}
							}
						}
						for(String actor : actorOcc.keySet()) {
							dynamicPowerMap.put(actor,dynamicPowerMap.get(actor)/actorOcc.get(actor));
						}
						//dynamicPowerMap.put("memory",0.0);
						//dynamicPowerMap.put("dummy_cubic",0.0);
						filePower.close();
						filePower = new BufferedReader(new FileReader(powerFile));
						// acquire power data
						actorOcc = new HashMap<String,Integer>();
						acquire = false;
						while ( (line = filePower.readLine()) != null){	
							if(line.contains("------------------------------------------------------------------------")){
								acquire = true;
							} else if(line.equals("")) {
								acquire = false;
							}
							if(acquire) {
								String actor = "";
								String power = "";
								if(line.split("  ")[0].equals("")) {
									if(!line.split("  ")[1].equals("")) {
										actor = line.split("  ")[1].substring(0, line.split("  ")[1].lastIndexOf("_"));
										power = line.substring(62,74).replace(" ", "");
										if(!totalPowerMap.containsKey(actor)) {
											totalPowerMap.put(actor, Double.parseDouble(power));
										} else {
											totalPowerMap.put(actor, (totalPowerMap.get(actor)+Double.parseDouble(power)));
											if(!actorOcc.containsKey(actor)) {
												actorOcc.put(actor, 2);
											} else {
												actorOcc.put(actor,actorOcc.get(actor)+1);
											}
										}
									}
								}
							}
						}
						for(String actor : actorOcc.keySet()) {
							totalPowerMap.put(actor,totalPowerMap.get(actor)/actorOcc.get(actor));
						}
						//totalPowerMap.put("memory",0.0);
						//totalPowerMap.put("dummy_cubic",0.0);
						filePower.close();
			
			// acquire timing data
			while ((line = fileTiming.readLine()) != null){
				timingMap.put(line.split(" ")[0], Double.parseDouble( line.split(" ")[1]) );
			}
			fileTiming.close();
			
			writeProfilingOut();
			
		} catch (Exception e) {
			System.out.println("Exception on the area calculation phase!");
			e.printStackTrace();
		} 
	}
	
	/**
	 * Write the profiling output file for the given network.
	 * 
	 * @param network
	 * 		the given network
	 * @return
	 * 		the network profiling estimations
	 */
	private void writeProfilingOut(){
		
		try {

			FileWriter pWriter = new FileWriter(new File (outPath + File.separator + "out_area.csv"));
			for(String actor : areaMap.keySet()){
				pWriter.write(actor + " " + areaMap.get(actor) + "\n");
			}
			pWriter.close();
			
			pWriter = new FileWriter(new File (outPath + File.separator + "out_pwr.csv"));
			for(String actor : staticPowerMap.keySet()){
				pWriter.write(actor + " " + staticPowerMap.get(actor) + " " + dynamicPowerMap.get(actor) + " " + totalPowerMap.get(actor) + "\n");
			}
			pWriter.close();
			
		} catch (IOException ioe) {
			System.out.println("Exception on opening profiling file! " + ioe);
			for(StackTraceElement se : ioe.getStackTrace())
				System.out.println("" + se);
		}
		 
	}

	
	
	@Deprecated
	/**
	 * Tentative of heuristic method definition
	 * 
	 * @param map
	 */
	public void calculateAffinity(Map<Network, Map<Network, Integer>> map) {
		
		Map<Network,List<Network>> affinityMap = new HashMap<Network,List<Network>>();
		List<Network> affinityList = new ArrayList<Network>();
		List<Integer> affinityValues = new ArrayList<Integer>();
		
		for(Network net : map.keySet()) {
			List<Network> netList = new ArrayList<Network>();
			for(Network associatedNet : map.get(net).keySet())
				if(map.get(net).get(associatedNet)!=0)
					netList.add(associatedNet);
			affinityMap.put(net, netList);
		}
		
		int indx = 0;
		while(affinityMap.size()>0) {
			Integer minSize = null;
			Network minNet = null;
			for(Network net : affinityMap.keySet()) {
				if(minSize == null) {
					minSize = affinityMap.get(net).size();
					minNet = net;
				} else {
					if(affinityMap.get(net).size()<minSize) {
						minSize = affinityMap.get(net).size();
						minNet = net;
					}
				}
			}
			affinityList.add(indx,minNet);
			affinityValues.add(indx,minSize);
			affinityMap.remove(minNet);
			indx++;
		}
		
		
		System.out.println("Affinity list: \n");	
		for(Network net : affinityList)
			System.out.println(net.getSimpleName() + "(" + affinityValues.get(affinityList.indexOf(net)) + ")");	
		
	}



	/**
	 * Calculate and return area estimation of the given network.
	 * 
	 * @param nework
	 * 		the given network
	 */
	private Double calculateArea(Network network) {
		
		Double area=0.0;
	
		for(Vertex vertex: network.getChildren()){
				if(vertex.getAdapter(Instance.class)!=null){
					if(!vertex.getAdapter(Actor.class).hasAttribute("sbox")) {
						area += areaMap.get(vertex.getAdapter(Actor.class).getSimpleName());
					} else {
						ExpressionEvaluator evaluator = new ExpressionEvaluator();
						int size =evaluator.evaluateAsInteger((Expression) vertex.getAdapter(Instance.class).getArgument("SIZE").getValue());
						// TODO it depends on the area values per sbox
						area += areaMap.get("sbox");
						/*if(size == 10)
								area += areaMap.get(vertex.getAdapter(Actor.class).getSimpleName().split("int")[0]);// + "_10");//(vertex.getAdapter(Actor.class).getSimpleName() + "_10");
							else
								area += areaMap.get(vertex.getAdapter(Actor.class).getSimpleName().split("int")[0]);// + "_32");*/
					}
					
				}
			}
			
		return area;
	}

	/**
	 * Calculate the static CP estimation of the given set of networks.
	 * 
	 * @param networks
	 * 		the given set of networks
	 */
	public void calculateCriticalPath(Set<Network> networks) {
		
		Double longerPath=0.0;
		
		for(Network net: networks){
			Double path = timingMap.get(net.getSimpleName());
			if(path!=null)
				if(path > longerPath)
					longerPath = path;
		}
		
		staticCP = longerPath;
	}
	
	/**
	 * Calculate and return frequency estimation of the given network.
	 * 
	 * @param nework
	 * 		the given network
	 */
	@Deprecated
	private Double calculateFrequency_old(Network network) {//old one modified
		
		Double pathSbox2x1 = 0.0;
		Double pathSbox1x2 = 0.0;
		Double path = 0.0;
		
		Map<Integer, Integer> sboxChain = countSwitch_old(network);
		int longerChain = Collections.max(sboxChain.keySet());
		int nrSbox1x2 = sboxChain.get(longerChain);
		
				
		pathSbox2x1 = (90/1000) * Math.log(longerChain) + timingMap.get("Sbox2x1"); 
		pathSbox1x2 = (70/1000)* Math.log(longerChain) + timingMap.get("Sbox1x2");
		
		path = ( (nrSbox1x2 * pathSbox1x2) + ((longerChain - nrSbox1x2) * pathSbox2x1) ) / longerChain;
		
		// frequency in kHz
		if(path > staticCP) {
			return 1/path*1000000;
		} else {
			return 1/staticCP*1000000;
		}
	}
	
	private Double calculateFrequency(Network network) { //the new one

		Double pathSbox2x1 = 0.0;
		Double pathSbox1x2 = 0.0;
		Double path = 0.0;
		
		Map<Integer, List<Integer>> sboxChain = countSwitch(network);
		int longerChain = Collections.max(sboxChain.keySet());
		int nrSbox2x1 = sboxChain.get(longerChain).get(1);
		int bitSize =  sboxChain.get(longerChain).get(0);
				
		pathSbox2x1 = ((0.114 * bitSize + 87.70)/1000) * Math.log(longerChain) + timingMap.get("Sbox2x1"); 
		pathSbox1x2 = ((0.268 * bitSize + 59.85)/1000) * Math.log(longerChain) + timingMap.get("Sbox1x2");
		
		path = ( (nrSbox2x1 * pathSbox2x1) + ((longerChain - nrSbox2x1) * pathSbox1x2) ) / longerChain;
		
		//OrccLogger.traceln("SBox maximum length chain resulting frequency [kHz]: " + 1/path*1000000);
		
		// frequency in kHz
		if(path > staticCP) {
			return 1/path*1000000;
		} else {
			return 1/staticCP*1000000;
		}
	}
	
	
	/**
	 * Calculate and return power estimation of the given network.
	 * 
	 * @param nework
	 * 		the given network
	 */
	private Double calculatePower(Network network) {
		Double power=0.0;
	
		for(Vertex vertex: network.getChildren()){
				if(vertex.getAdapter(Instance.class)!=null){
					if(!vertex.getAdapter(Actor.class).hasAttribute("sbox")) {
						power += staticPowerMap.get(vertex.getAdapter(Actor.class).getSimpleName());
					} else {
						ExpressionEvaluator evaluator = new ExpressionEvaluator();
						int size =evaluator.evaluateAsInteger((Expression) vertex.getAdapter(Instance.class).getArgument("SIZE").getValue());
						// TODO it depends on the power values per sbox
						power += staticPowerMap.get("sbox");
						/*if(size == 10)
							power += powerMap.get(vertex.getAdapter(Actor.class).getSimpleName().split("int")[0]);// + "_10");
						else
							power += powerMap.get(vertex.getAdapter(Actor.class).getSimpleName().split("int")[0]);// + "_32");*/
					}
				}
			}
			
		return power;
	}
	
	/**
	 * Calculate the sboxes chains on the given list of source chain
	 * sbox vertices along with the number of involved 1x2 sboxes.
	 * 
	 * @param chainRoots
	 * 		the given list of source chain sbox vertices
	 * @return
	 * 		the map of 1x2 sboxes actor for each chain length
	 */
	@Deprecated
	private Map<Integer,Integer> calculateSwitchPath_old(List<Vertex> chainRoots) {
		
		Map<Integer,Integer> countMap = new HashMap<Integer,Integer>();
		
		for(Vertex vertex: chainRoots){
			if(vertex.getAdapter(Actor.class)!=null){
				if(vertex.getAdapter(Actor.class).hasAttribute("sbox")) {
					Map<Integer,Integer> currMap = calculateSwitchPath_old(vertex.getSuccessors());
					for(int i : currMap.keySet())
						if(countMap.containsKey(i+1)) {
							if(currMap.get(i) > countMap.get(i+1))
								if(vertex.getAdapter(Actor.class).getAttribute("type").getStringValue().equals("1x2"))
									countMap.put(i+1, currMap.get(i)+1);
								else
									countMap.put(i+1, currMap.get(i));
						} else {
							if(vertex.getAdapter(Actor.class).getAttribute("type").getStringValue().equals("1x2")) //.getInputs().get(0).getType().getSizeInBits()
								countMap.put(i+1, currMap.get(i)+1);
							else
								countMap.put(i+1, currMap.get(i));
						}
				}
			}
		}
		if(countMap.isEmpty())
			countMap.put(0,0);
		return countMap;
	}
	
private Map<Integer,List<Integer>> calculateSwitchPath(List<Vertex> chainRoots) {
		
		Map<Integer,List<Integer>> countMap = new HashMap<Integer,List<Integer>>();
		List<Integer> mapItemsList = new ArrayList<Integer>();
		mapItemsList.add(0,0);
		mapItemsList.add(1,0);
		
		for(Vertex vertex: chainRoots){
			if(vertex.getAdapter(Actor.class)!=null){
				if(vertex.getAdapter(Actor.class).hasAttribute("sbox")) {
					Map<Integer, List<Integer>> currMap = calculateSwitchPath(vertex.getSuccessors());
					for(int i : currMap.keySet())
						if(countMap.containsKey(i+1)) {
							if(currMap.get(i).get(1) > countMap.get(i+1).get(1))
								if(vertex.getAdapter(Actor.class).getAttribute("type").getStringValue().equals("2x1")){
									mapItemsList.set(1, currMap.get(i).get(1)+1);
									countMap.put(i+1, mapItemsList);
								}else{
									mapItemsList.set(1, currMap.get(i).get(1));
									countMap.put(i+1, mapItemsList);
								}
						} else {
							mapItemsList.set(0, vertex.getAdapter(Actor.class).getInputs().get(0).getType().getSizeInBits());
							if(vertex.getAdapter(Actor.class).getAttribute("type").getStringValue().equals("2x1")){							
								mapItemsList.set(1, currMap.get(i).get(1)+1);
								countMap.put(i+1, mapItemsList);
							}else{
								mapItemsList.set(1, currMap.get(i).get(1));
								countMap.put(i+1, mapItemsList);
							}
						}
				    
			    }
		    }
		}
		if(countMap.isEmpty()){
			List<Integer> list = new ArrayList<Integer>();
			list.add(0,0);
			list.add(1,0);
			countMap.put(0, list);
		}
			
			
		return countMap;
	}
	
	
	
	/**
	 * Close the open output profiling file
	 */
	public void closeFile(){
		try{
			writer.close();
		} catch (IOException ioe) {
			System.out.println("Exception on opening profiling file! " + ioe);
			for(StackTraceElement se : ioe.getStackTrace())
				System.out.println("" + se);
		}
	}
	
	/**
	 * Read the output profiling file to generate a
	 * compressed version.
	 * 
	 * @param path
	 * 		the output path
	 */
	public void compressProfilingFile(String path) {
		try{
			
			
			// read profiling file and acquire equal values and references			
			BufferedReader reader = new BufferedReader(new FileReader(new File (path + File.separator + "profiling.csv")));
			Map<Integer,List<String>> map = new HashMap <Integer,List<String>>();
			Map<Integer,List<String>> mapRef = new HashMap <Integer,List<String>>();
			String linea;
			Integer index=0;
			boolean isPresent = false;
			
			for (int i = 1; i<10; i++){
				reader.readLine(); //inserted to skip the header
			}

			while((linea=reader.readLine())!=null) {
				
				if(linea!=""){
					
					isPresent = false;
					
					List<String> stringElem = new ArrayList<String>();
					
					for(int i=1; i<4; i++) {
						stringElem.add(linea.split(";")[i]);
					}
					
					for(int i : map.keySet()) {
						if(map.get(i).equals(stringElem)) {
							mapRef.get(i).add(linea.split(" ")[0]);
							isPresent = true;
						}
					}
					
					if(!isPresent) {
						map.put(index, stringElem);
						List<String> strList = new ArrayList<String>();
						strList.add(linea.split(";")[0]);
						mapRef.put(index, strList);
						index++;
					}
				}
			}
			reader.close();
			
			
			// write compress profiling file and related references file
			writer = new FileWriter(new File (path + File.separator + "profiling_compr.csv"));
			writer.write(" List of the all the nets with the same operating point\n\n");
			writer.write(" ID: identifier of the overlapping points\n\n");
			writer.write("ID" + ";" + "area [um^2]" + ";" + "power [nW]" + ";" + "frequency [kHz]\n\n");
			
			FileWriter writerRef = new FileWriter(new File (path + File.separator + "profiling_compr_ref.txt"));
			
			
			for(int i : map.keySet()) {
				writer.write(i + ";" + map.get(i).get(0) + ";" + map.get(i).get(1) + ";" + map.get(i).get(2) + "\n");
				writerRef.write(i + " references: " );
				
				for(String s : mapRef.get(i)) {
					
					// acquire number of contained ones and zeros by the name of the permutation
					int zeros = s.split("0").length - 1;
					int ones = s.split("1").length - 1;														
					if(s.toCharArray()[s.length()-1]=='0')
						zeros++;
					else if(s.toCharArray()[s.length()-1]=='1')
						ones++;

					// remove the zeros of the reference id
					String dontMergeList="";
					if(s.split("_")[0].contains("0")) {
						for(char c : s.split("_")[0].toCharArray())
							if(c == '0')
								zeros--;
					}
					
					// remove the ones of the reference id
					if(s.split("_")[0].contains("1"))
						for(char c : s.split("_")[0].toCharArray())
							if(c == '1')
								ones--;
					
					//  acquire don't merge list of networks
					String sl[]=s.split("_");
					String string = "";
					for(int k=1;k<sl.length;k++)
						string += sl[k] + "_";
					for(int j=0; j<string.split("0").length-1; j++) {
						dontMergeList += string.split("0")[j] + ",";
					}
					
					// insert the final char of the don't merge list
					if(!dontMergeList.equals("")) {
						String newDml = "";
						for(String ss : dontMergeList.split(",")) {
							if(ss.equals(dontMergeList.split(",")[dontMergeList.split(",").length-1])) {
								newDml += ss + ";";
							} else {
								newDml += ss + ",";
							}
						}
						dontMergeList = newDml;
					}
					
					// write the references file
					writerRef.write("\n" + s + " (not-merged_nets=" + zeros + ",merged_nets=" + ones + ")" + dontMergeList );
				}
				
				writerRef.write("\n\n");
			}
			writerRef.close();
			writer.close();
			
			
			// write a short compress profiling references file
			int key=0;
			reader = new BufferedReader(new FileReader(new File (path + File.separator + "profiling_compr_ref.txt"))); 
			writer = new FileWriter(new File (path + File.separator + "profiling_compr_ref_short.txt"));
			Map<Integer,List<String>> mapRefShort = new HashMap<Integer,List<String>>();
						
			while((linea=reader.readLine())!=null) {
				if(linea.contains("references:")) {
					key = Integer.parseInt(linea.split(" ")[0]);
					List<String> value = new ArrayList<String>();
					mapRefShort.put(key, value);
				} else if(!linea.equals("")) {
					if(!mapRefShort.get(key).contains(linea.split(" ")[1]))
						mapRefShort.get(key).add(linea.split(" ")[1]);
				}

			}
			reader.close();
			
			for(int i : mapRefShort.keySet())
				writer.write(i + " references: " + mapRefShort.get(i) + "\n\n");
			
			writer.close();
					
			
		} catch (IOException ioe) {
			System.out.println("Exception on opening profiling file! " + ioe);
			for(StackTraceElement se : ioe.getStackTrace())
				System.out.println("" + se);
		}
	}

	/**
	 * Calculate the sboxes chains on the given network
	 * along with the number of involved 1x2 sboxes.
	 * 
	 * @param network
	 * 		the given network
	 * @return
	 * 		the map of 1x2 sboxes actor for each chain length
	 */
	@Deprecated
	private Map<Integer,Integer> countSwitch_old(Network network) {
		
		Boolean isRoot = true;
		List<Vertex> rootList = new ArrayList<Vertex>();	
		
		for(Vertex vertex: network.getChildren()){
			isRoot=true;
			if(vertex.getAdapter(Actor.class).hasAttribute("sbox")){
				for(Vertex vertexPre: vertex.getPredecessors()){
					if(vertexPre.getAdapter(Instance.class)!=null){
						isRoot &= !vertexPre.getAdapter(Actor.class).hasAttribute("sbox");
					}
				}
				if(isRoot)					
					rootList.add(vertex);
			}
		}
		return calculateSwitchPath_old(rootList);
	}
	
private Map<Integer, List<Integer>> countSwitch(Network network) {
		
		Boolean isRoot = true;
		List<Vertex> rootList = new ArrayList<Vertex>();	
		
		for(Vertex vertex: network.getChildren()){
			isRoot=true;
			if(vertex.getAdapter(Actor.class).hasAttribute("sbox")){
				for(Vertex vertexPre: vertex.getPredecessors()){
					if(vertexPre.getAdapter(Instance.class)!=null){
						isRoot &= !vertexPre.getAdapter(Actor.class).hasAttribute("sbox");
					}
				}
				if(isRoot)					
					rootList.add(vertex);
			}
		}
		return calculateSwitchPath(rootList);
	}

	/**
	 * Set do not touch flag to the networks with a insufficient
	 * percentage of shared actors (overlapping)
	 * 
	 * @param networks
	 */
	public void flagNetworks(List<Network> networks) {
		
		for(Network net : networks)
			if(percNet.get(net)<10.00)
				net.setAttribute("dontTouch", "");
		
	}



	/**
	 * Return the map of power values for each actor
	 * 
	 * @return
	 *		the map of power values for each actor
	 */
	public Map<String,Double> getPowerMap() {
		Map<String,Double> map = new HashMap<String,Double>(staticPowerMap);
		return map;
	}
	
	/**
	 * Initialize profiler with the input files and the output path
	 * 
	 * @param outPath
	 * 		the output path
	 * @param areaFile
	 * 		the area file
	 * @param powerFile
	 * 		the power file
	 * @param timingFile
	 * 		the timing file
	 */
	public void initializeProfiler(String outPath, String areaFile, String powerFile, String timingFile){
		this.areaFile = areaFile;
		this.powerFile = powerFile;
		this.timingFile = timingFile;
		this.outPath = outPath;
		areaMap = new HashMap <String, Double>();
		staticPowerMap = new HashMap <String, Double>();
		dynamicPowerMap = new HashMap <String, Double>();
		totalPowerMap = new HashMap <String, Double>();
		timingMap = new HashMap <String, Double>();
		acquireProfilingDataFromReport();
		try{
			writer = new FileWriter(new File (outPath + File.separator + "profiling.csv"));
			writer.write("All the possible resulting merged network due to all the possible combinations\n\n" );	
			writer.write("ID_nameNUM\n" );
			writer.write("ID: identifier of the combination\n" );
			writer.write("name: name of the combination\n" );
			writer.write("NUM: if NUM = 0 the net has not been merged, if NUM = 1 the net has been merged\n\n" );
			
			writer.write("net_name" + ";" + "area[um^2]" + ";" + "power[nW]" + ";" + " frequency[kHz]\n\n" );
			
		} catch (IOException ioe) {
			System.out.println("Exception on opening profiling file! " + ioe);
			for(StackTraceElement se : ioe.getStackTrace())
				System.out.println("" + se);
		}
	}
	
	/**
	 * Pre-analyze the input set of networks in order to implement a 
	 * heuristic method (based on the networks shared actors percentage)
	 * reducing the design space size.
	 * 
	 * @param networks
	 * 		the input set of networks
	 * @param numInstances
	 * 		the number of instances of an all merged multi-dataflow
	 * @return
	 * 		the map of the sharable actors of each input network with 
	 * 		all the other ones (overlapping map)
	 */
	public Map<Network,Map<Network,Integer>> preAnalyze(List<Network> networks, int numInstances) {
	
		Map<Network,Map<Network,Integer>> overlappingMap = new HashMap<Network,Map<Network,Integer>>();
		percMap = new HashMap<Network,Map<Network,Float>>();
		percNet = new HashMap<Network,Float>();
		Unifier unifier = new Unifier();
		
		for(Network net : networks) {
			double netSharedPwr = 0.0;
			int netSharedInsts = 0;
			double onlyNetSharedPwr = 0.0;
			
			Map<Network,Integer> netMap = new HashMap<Network,Integer>();
			Map<Network,Float> percNetMap = new HashMap<Network,Float>();
			Set<Vertex> percNetSet = new HashSet<Vertex>();
			Map<String,Integer> instMap = new HashMap<String,Integer>();
			Map<String,Double> instPwrMap = new HashMap<String,Double>();
			
			for(Network otherNet : networks) {
				
				if(!otherNet.equals(net)) {	
					int numPotMergInst = 0;
					List<Vertex> alreadyAssociated = new ArrayList<Vertex>();
					for(Vertex vrtx : net.getChildren()) {						
						for(Vertex otherVrtx : otherNet.getChildren()) {							
							if((!alreadyAssociated.contains(otherVrtx)) && unifier.canUnify(vrtx,otherVrtx)) {
								alreadyAssociated.add(otherVrtx);
								percNetSet.add(vrtx);
								numPotMergInst++;
								netSharedInsts++;
								if(instMap.containsKey(vrtx.getLabel())) {
									instMap.put(vrtx.getLabel(), instMap.get(vrtx.getLabel())+1);
									instPwrMap.put(vrtx.getLabel(), instPwrMap.get(vrtx.getLabel())+
											staticPowerMap.get(vrtx.getAdapter(Actor.class).getSimpleName()));
									netSharedPwr += staticPowerMap.get(vrtx.getAdapter(Actor.class).getSimpleName());
								} else {
									instMap.put(vrtx.getLabel(), 1);
									instPwrMap.put(vrtx.getLabel(), staticPowerMap.get(vrtx.getAdapter(Actor.class).getSimpleName()));
									netSharedPwr += staticPowerMap.get(vrtx.getAdapter(Actor.class).getSimpleName());
									onlyNetSharedPwr += staticPowerMap.get(vrtx.getAdapter(Actor.class).getSimpleName());
								}
								break;
							}
						}
					}
					netMap.put(otherNet, numPotMergInst);
					percNetMap.put(otherNet, ((float) numPotMergInst/numInstances*100));
				}
			}
			
			DecimalFormat df = new DecimalFormat("##.##");
			/*OrccLogger.traceln("net " + net + " instSharOcc " + instMap);
			OrccLogger.traceln("\t maxSharOcc " + Collections.max(instMap.values()));			
			OrccLogger.traceln("\t pwrMap " + instPwrMap);
			OrccLogger.traceln("\t TOTshr " + netSharedInsts);
			OrccLogger.traceln("\t TOTpwr " + df.format(netSharedPwr));
			OrccLogger.traceln("\t TOTaddPwrNoShar " + df.format(onlyNetSharedPwr));
			*/
			instMap = new HashMap<String,Integer>();
			instPwrMap = new HashMap<String,Double>();
			
			overlappingMap.put(net, netMap);
			percMap.put(net, percNetMap);
			percNet.put(net, ((float) percNetSet.size()/numInstances*100));
		}
		return overlappingMap;
	}



	/**
	 * Write the profiling output file for the given network.
	 * 
	 * @param network
	 * 		the given network
	 * @return
	 * 		the network profiling estimations
	 */
	public List<Float> writeFile(Network network){
		
		try {
			
			List<Float> values = new ArrayList<Float>();

			Float area = calculateArea(network).floatValue();

			Float power = calculatePower(network).floatValue();

			Float freq = calculateFrequency(network).floatValue();
			
			//OrccLogger.traceln("\t area: " + area + "\t power: " + power + "\t freq: " + freq);
			
			values.add(AREA,area);
			values.add(POWER,power);
			values.add(FREQ,freq);
			
					
			String string = network.getName() + 
					";" + area +
					";" + power +
					";" + freq +
					"\n";
			
			writer.write(string);
			return values;
			
		} catch (IOException ioe) {
			System.out.println("Exception on opening profiling file! " + ioe);
			for(StackTraceElement se : ioe.getStackTrace())
				System.out.println("" + se);
			return null;
		}
		 
	}

	/**
	 * Write the pre-analysis profiling output file for the given
	 * overlapping map
	 * 
	 * @param overlappingMap
	 * 		the given overlapping map
	 * @param path
	 */
	public void writePreAnalyzeTab(Map<Network,Map<Network,Integer>> overlappingMap) {
		
		try{
			FileWriter preAnalysisWriter = new FileWriter(new File (outPath + File.separator + "preAnalysis.txt"));
			int id = 0;
			Map<Integer,Map<Network,Integer>> idMap = new HashMap<Integer,Map<Network,Integer>>();
			Map<Integer,Network> idRef = new HashMap<Integer,Network>();
			DecimalFormat df = new DecimalFormat("##.##");
			
			// create id maps
			for(Network net : overlappingMap.keySet()) {
				idMap.put(id,overlappingMap.get(net));
				idRef.put(id, net);
				id++;
			}
			
			preAnalysisWriter.write("\t     ");
			for(int i : idMap.keySet())
				if(i<10)
					preAnalysisWriter.write("\t      " + i + "    ");
				else
					preAnalysisWriter.write("\t     " + i + "    ");
			
			preAnalysisWriter.write("\t |   tot\n\n");
						
			for(int i : idMap.keySet()) {
				//OrccLogger.traceln("net " + idRef.get(i) + " = " + idMap.get(i));
				if(i<10)
					preAnalysisWriter.write("\t " + i);
				else
					preAnalysisWriter.write("\t" + i);
				preAnalysisWriter.write(" |");
				for(int j : idMap.keySet()) {
					if(i==j)
						preAnalysisWriter.write("\t     --    ");
					else {
						String perc = df.format(percMap.get(idRef.get(i)).get(idRef.get(j)));
						if(perc.equals("0"))
							perc="00,00";
						if(idMap.get(i).get(idRef.get(j))<10)
							preAnalysisWriter.write("\t " + idMap.get(i).get(idRef.get(j)) +
									"(" + perc + " %)");
						else
							preAnalysisWriter.write("\t" + idMap.get(i).get(idRef.get(j)) +
									"(" + perc + " %)");
					}
				}
				preAnalysisWriter.write("\t |   " + df.format(percNet.get(idRef.get(i))) + " %");
				preAnalysisWriter.write("\n");
			}
			
			preAnalysisWriter.write("\n\nReferences: \n");
			for(int i : idRef.keySet())
				preAnalysisWriter.write("\t" + i + " = " + idRef.get(i).getSimpleName() + "\n");
					
			preAnalysisWriter.close();
			
		} catch (Exception e) {
			System.out.println("Exception in pre analysis! " + e);
			for(StackTraceElement se : e.getStackTrace())
				System.out.println("" + se);
		}
		
	}

}
