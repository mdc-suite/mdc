package it.mdc.tool.utility;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.List;
import java.util.Map;
import java.util.HashMap;
import java.util.Set;

import net.sf.orcc.df.Actor;
import net.sf.orcc.df.Connection;
import net.sf.orcc.df.Instance;
import net.sf.orcc.df.Network;
import net.sf.orcc.df.Port;
import net.sf.orcc.df.transform.Instantiator;
import net.sf.orcc.df.transform.NetworkFlattener;
import net.sf.orcc.graph.Vertex;
import net.sf.orcc.util.OrccLogger;

public class Printer {
	

	private final static int DONT_MERGE = 0;
	
	/**
	 * Print the given network on ORCC logger
	 *
	 * @param map
	 */
	public void printPermutations(Map<Integer,List<List<Network>>> map){
		
		OrccLogger.traceln("Permutations:\n");
		
		for(int i : map.keySet())
			OrccLogger.traceln("\t" + map.get(i).get(0) + " " + map.get(i).get(1));
		
	}

	/**
	 * Print the given network on ORCC logger
	 *
	 * @param network
	 */
	public void printActorsNumber(Network network){
		
		OrccLogger.traceln("Network " + network + " actors number:");
		
		// print inputs
		//OrccLogger.traceln("Number of instances*: " + network.getChildren().size());
		OrccLogger.traceln("Number of vertex: " + network.getChildren().size());
		OrccLogger.traceln("Number of actors: " + network.getAllActors().size());
		
	}	
	
	/**
	 * Prints the Multi-Dataflow Composer report
	 *
	 * @param inputNets
	 * 		map of the input networks with the related merging order
	 * @param multiDataflowNet
	 * 		the generated multi-dataflow network
	 * @param outPath
	 * 		the path of the report file to be generated
	 * @param genCopr
	 * @param coprType
	 * @param coprEnv
	 */
	public void printReport(Map<Network,Integer> inputNets, Network multiDataflowNet, String outPath, boolean genCopr, String coprType){
		
		File outDir = new File(outPath);
		if (!outDir.exists()) {
			outDir.mkdirs();
		}
		
		int inputActorInsts = 0;
		int outputActorInsts = 0;
		int sboxActorInsts = 0;
		int notMergedNets = 0;
		
		for(Network inputNet : inputNets.keySet()) {
			
			if(inputNets.get(inputNet).equals(DONT_MERGE))
				notMergedNets++;
			
			new Instantiator(false).doSwitch(inputNet);
			new NetworkFlattener().doSwitch(inputNet);
			for(Vertex vertex : inputNet.getChildren())
				if(vertex.getAdapter(Instance.class) != null)
					inputActorInsts ++;
		}
		
		for(Vertex vertex : multiDataflowNet.getChildren())
			if(vertex.getAdapter(Instance.class) != null) {
				outputActorInsts ++;
				if(vertex.getAdapter(Instance.class).getActor().hasAttribute("sbox"))
					sboxActorInsts ++;
		}
		
		
		
		if(outPath!=null){
		
			try{

				FileWriter writer;
				if(!genCopr) {
					writer = new FileWriter(new File ( outPath + 
							File.separator + "report.txt"));
				} else {
					File path;
					if(coprType.equals("STREAM")) {
						path = new File( outPath + File.separator + "s_accelerator");
					} else {
						path = new File( outPath + File.separator + "mm_accelerator");
					}
					if(!path.exists()) {
						path.mkdir();
					}
					writer = new FileWriter(new File ( path + File.separator + "report.txt"));
				}
				
				writer.write("###########################################################################\n");
				writer.write("# Multi-Dataflow Composer report ##########################################\n");
				writer.write("###########################################################################\n");
				
				writer.write("\n# input networks composition");
				for(Network network : inputNets.keySet()) {
					int instances = 0;
					writer.write("\n - network " + network.getSimpleName() + " number of actors: ");
					for(Vertex vertex : network.getChildren())
						if(vertex.getAdapter(Instance.class) != null)
							instances ++;
					writer.write("" + instances);
				}
				writer.write("\n --> input networks total number of actors: " + inputActorInsts);
				
				int originalActors = (outputActorInsts-sboxActorInsts);
				int sharedActors = inputActorInsts-(outputActorInsts-sboxActorInsts);
				writer.write("\n\n# multi-dataflow network composition: " + multiDataflowNet.getSimpleName());
				writer.write("\n - number of merged networks: " + (inputNets.size()-notMergedNets) + "," + notMergedNets);
				writer.write("\n - number of actors: " + outputActorInsts);
				writer.write("\n -- original actors: " + originalActors + 
						" (" + (((float)originalActors/outputActorInsts)*100) +"%)*");
				writer.write("\n -- sbox actors: " + sboxActorInsts + " (" + (((float)sboxActorInsts/outputActorInsts)*100) + "%)*");
				writer.write("\n -- shared actors " + sharedActors + 
						" (" + (((float)sharedActors/inputActorInsts)*100) + "%)**");
				writer.write("\n * with respect to the multi-dataflow network number of actors");
				writer.write("\n** with respect to the input networks total number of actors");
				writer.write("\n\n###########################################################################");
				writer.close();	
				
				
			} catch (IOException e) {
				System.out.println("Exception catched on MDC report printing!\n\t" + e);
				for(StackTraceElement se : e.getStackTrace())
					System.out.println("" + se);
			}
		} else {
			
			OrccLogger.traceln("*\tMDC report:");
			OrccLogger.traceln("*\t\t input networks composition");
			for(Network network : inputNets.keySet()) {
				int instances = 0;
				for(Vertex vertex : network.getChildren())
					if(vertex.getAdapter(Instance.class) != null)
						instances ++;
				OrccLogger.traceln("*\t\t\t - network " + network.getSimpleName() + " number of actors: "+ instances);
				
			}
			OrccLogger.traceln("*\t\t\t --> input networks total number of actors: " + inputActorInsts);
			
			int originalActors = (outputActorInsts-sboxActorInsts);
			int sharedActors = inputActorInsts-(outputActorInsts-sboxActorInsts);
			OrccLogger.traceln("*\t\t multi-dataflow network composition");
			OrccLogger.traceln("*\t\t\t - number of merged networks: " + inputNets.size());
			OrccLogger.traceln("*\t\t\t - number of actors: " + outputActorInsts);
			OrccLogger.traceln("*\t\t\t -- original actors: " + originalActors + 
					" (" + (((float)originalActors/outputActorInsts)*100) +"%)*");
			OrccLogger.traceln("*\t\t\t -- sbox actors: " + sboxActorInsts + " (" + (((float)sboxActorInsts/outputActorInsts)*100) + "%)*");
			OrccLogger.traceln("*\t\t\t -- shared actors " + sharedActors + 
					" (" + (((float)sharedActors/inputActorInsts)*100) + "%)**");
			OrccLogger.traceln("*\t\t\t * with respect to the multi-dataflow network number of actors");
			OrccLogger.traceln("*\t\t\t** with respect to the input networks total number of actors");
			OrccLogger.traceln("*\tEnd MDC report");		
			
			
			/*OrccLogger.traceln("*\t\t- input networks actor instances: " + inputActorInsts);
			OrccLogger.traceln("*\t\t- output network actor instances: " + outputActorInsts);
			OrccLogger.traceln("*\t\t\t of which sbox: " + sboxActorInsts);*/
		}
		
	}
	
	
public void printLogicRegionsReport(String hdlDir, boolean genCopr, String coprType, Map<String,Set<String>> logicRegions, Map<String, Set<String>> netRegions, Map<String, Set<String>> logicRegionsNetsMap){
	
	Map<String, Integer> logicRegionsIndex = new HashMap<String, Integer>();
	int clkIndex = 0;
	logicRegionsIndex.put("CLK", clkIndex);
	clkIndex = clkIndex + 1;

	for (String lr : logicRegions.keySet()) {
		logicRegionsIndex.put(lr.toString(), clkIndex);
		clkIndex = clkIndex + 1;
	}
	
	
	if(hdlDir!=null){
	
		try{

			FileWriter writer;
			if(!genCopr) {
				writer = new FileWriter(new File ( hdlDir + 
						File.separator + "reportLogicRegions.txt"));
			} else if(coprType.equals("MEMORY-MAPPED")) {
				File path = new File( hdlDir + File.separator + "pcores");
				if(!path.exists()) {
					path.mkdir();
				}
				path = new File( hdlDir + File.separator + "pcores" + File.separator + "mm_accelerator_v1_00_a");
				if(!path.exists()) {
					path.mkdir();
				}
				writer = new FileWriter(new File ( hdlDir + File.separator + "pcores" + File.separator + "mm_accelerator_v1_00_a" + 
						File.separator + "reportLogicRegions.txt"));
			} else if(coprType.equals("STREAM-BASED (XILINX FSL)")) {
				File path = new File( hdlDir + File.separator + "pcores");
				if(!path.exists()) {
					path.mkdir();
				}
				path = new File( hdlDir + File.separator + "pcores" + File.separator + "s_accelerator_v1_00_a");
				if(!path.exists()) {
					path.mkdir();
				}
				writer = new FileWriter(new File ( hdlDir + File.separator + "pcores" + File.separator + "s_accelerator_v1_00_a" + 
						File.separator + "reportLogicRegions.txt"));
			} else {
				writer = new FileWriter(new File ( hdlDir + 
						File.separator + "reportLogicRegions.txt"));
			}
			
			writer.write("###########################################################################\n");
			writer.write("# 					Multi-Dataflow Composer 							#\n");
			writer.write("# 					 Logic Regions Report	 							#\n");
			writer.write("###########################################################################\n");
			
			writer.write("\n# Number of identified logic regions: " + logicRegions.size() + "\n");
			for (String lr : logicRegions.keySet()){
				writer.write("Logic region " + logicRegionsIndex.get(lr) + " includes instance(s): " + logicRegions.get(lr) + "\n");
			}
			
			writer.write("\n");
			for (String lr : logicRegionsNetsMap.keySet()){
				writer.write("Logic Region " + logicRegionsIndex.get(lr) + " is enabled by network(s): " + logicRegionsNetsMap.get(lr)+ "\n");
			}
			
			writer.write("\n");
			for (String net : netRegions.keySet()){
				writer.write("Network " + net + " enables logic region(s): [");
					for(String lr: netRegions.get(net))
						writer.write(logicRegionsIndex.get(lr) + " ");
					writer.write("]\n");
			}

			writer.write("\n\n###########################################################################");
			writer.close();	
			
			
		} catch (IOException e) {
			System.out.println("Exception catched on MDC report printing!\n\t" + e);
			for(StackTraceElement se : e.getStackTrace())
				System.out.println("" + se);
		}
	} else {
		
		OrccLogger.traceln("*\tNumber of identified logic regions: " + logicRegions.size());
	
		

	}
						
	}
	
	
	
	
	/**
	 * Print the given network on ORCC logger
	 *
	 * @param network
	 */
	public void printNetwork(Network network){
		
		OrccLogger.traceln("Network " + network + " composition:");
			
		
		// print inputs
		OrccLogger.traceln("Inputs: " );
		for(Port input : network.getInputs())
			OrccLogger.traceln("\t" + input.getName() + ", " + input.getType());
		
		// print outputs
		OrccLogger.traceln("Outputs: ");
		for(Port output : network.getOutputs())
			OrccLogger.traceln("\t" + output.getName() + ", " + output.getType());
				
		// print instances
		OrccLogger.traceln("Instances: ");
		for (Vertex child : network.getChildren()){
			OrccLogger.traceln("\t" + child);
		}
		
		// print actors
		OrccLogger.traceln("Actors: ");
		for (Actor actor : network.getAllActors()){
			OrccLogger.traceln("\t" + actor);
		}
		// print actors
		OrccLogger.traceln("Connections: ");
		for (Connection conn : network.getConnections()){
			OrccLogger.traceln("\t" + conn);
		}
	}
	
}
