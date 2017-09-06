package it.mdc.tool.core;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintStream;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import it.mdc.tool.core.sboxManagement.SboxLut;
import it.mdc.tool.core.ConfigPrinterCal;
import it.mdc.tool.core.SBoxPrinterCal;
import net.sf.orcc.df.Actor;
import net.sf.orcc.df.Argument;
import net.sf.orcc.df.Connection;
import net.sf.orcc.df.DfFactory;
import net.sf.orcc.df.Instance;
import net.sf.orcc.df.Network;
import net.sf.orcc.df.Port;
import net.sf.orcc.graph.Vertex;
import net.sf.orcc.ir.IrFactory;
import net.sf.orcc.ir.util.ExpressionEvaluator;
import net.sf.orcc.util.OrccLogger;

/**
 * Manage the configuration of the multi-dataflow
 * network.
 * 
 * @author Carlo Sau
 *
 */
public class ConfigManager {

	/**
	 * File writer
	 */
	protected FileWriter writer;
	
	/**
	 * Configuration map: associates to each network 
	 * a different ID
	 */
	private Map<Integer,String> configMap;
	
	/**
	 * The list of combined networks
	 */
	private List<Network> networks;
	
	/**
	 * The progressive count to define the networks
	 * IDs
	 */
	private int count;
	
	/**
	 * The backend output path
	 */
	private String outPath;
	

	/**
	 * The backend output path
	 */
	private String rvcCalOutputFolder;
	
	
	/**
	 * The constructor
	 * 
	 * @param outPath
	 * 			the backend output path
	 * @param rvcCalOutputFolder
	 */
	public ConfigManager(String outPath, String rvcCalOutputFolder) {
		this.outPath = outPath;
		this.rvcCalOutputFolder = rvcCalOutputFolder;
		configMap = new HashMap<Integer,String>();
		count=1;
	}
	
	/**
	 * Configure a DYNAMIC network
	 * 
	 * @param network
	 * 		The given network
	 * @param luts
	 * 		Sbox Look Up Table
	 * @throws IOException
	 */
	private void configDynamicNet(Network network, List<SboxLut> luts) throws IOException {
		
		// create SelGen actor
		Actor selGenActor = DfFactory.eINSTANCE.createActor();

		String split_by = null;
		if(OsUtils.isWindows())
			split_by = "\\\\";
		else
			split_by = File.separator;
		selGenActor.setFileName(rvcCalOutputFolder.split(split_by)[rvcCalOutputFolder.split(split_by).length-1] + ".cal.Configurator.cal");
		
		String name = rvcCalOutputFolder.split(split_by)[rvcCalOutputFolder.split(split_by).length-1] + ".cal.Configurator";//"mdc.cal.Configurator";
		//selGenActor.setAttribute("only_cal", (Object) null);
		selGenActor.setName(name);
				
		// add id port
		Port idPort = DfFactory.eINSTANCE.createPort(IrFactory.eINSTANCE.createTypeInt(8), "ID");
		network.addInput(idPort);
		
		// add SelGen instance
		Port networkID = DfFactory.eINSTANCE.createPort(IrFactory.eINSTANCE.createTypeInt(8), "ID");
		selGenActor.getInputs().add(networkID);
		Instance configInst = DfFactory.eINSTANCE.createInstance("configurator_0", selGenActor);
		network.add(configInst);
		
		// add connection between id port and SelGen instance
		Connection connection = DfFactory.eINSTANCE.createConnection(idPort, null, configInst, networkID);
		network.add(connection);
		
		// link SelGen instance to the sboxes
		for(SboxLut lut : luts) {
			
			String count = lut.getSboxInstance().getSimpleName().split("_")[1];
			Port sel = DfFactory.eINSTANCE.createPort(IrFactory.eINSTANCE.createTypeBool(), ("sel" + count));
			
			Port sboxSel = DfFactory.eINSTANCE.createPort(IrFactory.eINSTANCE.createTypeBool(), "sel");
			sboxSel.setAttribute("native", (Object) null);
			lut.getSboxInstance().getAdapter(Actor.class).getInputs().add(sboxSel);
			
			Connection selConnection = DfFactory.eINSTANCE.createConnection(configInst, sel, lut.getSboxInstance(), sboxSel);
			network.add(selConnection);
			
		}
			
		
	}

	/**
	 * Configure a STATIC network
	 * 
	 * @param network
	 * 		The given network
	 */
	private void configStaticNet(Network network) {
	
		int sboxId;
				
		for(Vertex vertex : network.getChildren())
			if(vertex.getAdapter(Instance.class) != null)
				if(vertex.getAdapter(Actor.class).hasAttribute("sbox")) {
					sboxId = (Integer) vertex.getAttribute("count").getObjectValue();
					Argument arg = DfFactory.eINSTANCE.createArgument(
							IrFactory.eINSTANCE.createVar(IrFactory.eINSTANCE.createTypeInt(32), "ID", true, 0), 
							IrFactory.eINSTANCE.createExprInt(sboxId));
					vertex.getAdapter(Instance.class).getArguments().add(arg);		
				}	
		
	}
	
	/**
	 * Utilities necessary to manage different kind of Operating Systems
	 * 
	 * @author Carlo Sau
	 *
	 */
	public static final class OsUtils
	{
	   private static String OS = null;
	   public static String getOsName()
	   {
	      if(OS == null) { OS = System.getProperty("os.name"); }
	      return OS;
	   }
	   public static boolean isWindows()
	   {
	      return getOsName().startsWith("Windows");
	   }
	}

	
	/**
	 * Generate the configurator CAL file for SBoxes (it.unica.diee.mdc.ConfigPrinterCal.printConfig()
	 * 
	 * @param luts
	 * 		Sbox Look Up Table
	 * @param type
	 * @throws IOException
	 */
	private void generateConfig(List<SboxLut> luts, String type) throws IOException {
	
		File calGenDir = new File(rvcCalOutputFolder + File.separator + "cal");
		
		// If directory doesn't exist, create it
		if (!calGenDir.exists()) {
			calGenDir.mkdirs();
		}
		
		String split_by = null;
		if(OsUtils.isWindows())
			split_by = "\\\\";
		else
			split_by = File.separator;
		String packageName = rvcCalOutputFolder.split(split_by)[rvcCalOutputFolder.split(split_by).length-1] + ".cal";
		
		String file = calGenDir.getPath()  + File.separator + "Configurator.cal";
		
		for(Network network :networks)
			getNetworkId(network.getSimpleName());
				
		CharSequence sequence = new ConfigPrinterCal().printConfig(type,packageName,luts,configMap);
	
		try {
			PrintStream ps = new PrintStream(new FileOutputStream(file));
			ps.print(sequence.toString());
			ps.close();
		} catch (FileNotFoundException e) {
			OrccLogger.severeln("File Not Found Exception: " + e.getMessage());
		}
		
		
	}
	
	/**
	 * Generate the CAL files for SBoxes
	 * 
	 * @param network
	 * 		the given network
	 * @param luts
	 * 			Sbox Look Up Table
	 * @param calType
	 * 			CAL type (static or dynamic)
	 * @throws IOException
	 */
	public void generateSboxes(Network network, List<SboxLut> luts, String calType) throws IOException {	
			
		File calFolder = new File(rvcCalOutputFolder + File.separator + "cal");
		
		// If directory doesn't exist, create it
		if (!calFolder.exists()) {
			calFolder.mkdirs();
		}
		
		String split_by = null;
		if(OsUtils.isWindows())
			split_by = "\\\\";
		else
			split_by = File.separator;
		String packageName = rvcCalOutputFolder.split(split_by)[rvcCalOutputFolder.split(split_by).length-1] + ".cal";
			
		Set<String> genSBoxes = new HashSet<String>();
		String typeData = "";
		String sizeData = "";
		
		/// <ul> <li> Print SBoxes: it.unica.diee.mdc.SBoxPrinterCal.printSboxes() 
		String file = null;
		for (SboxLut lut : luts) {
						
			String actorName = lut.getSboxInstance().getActor().getSimpleName();
			
			lut.getSboxInstance().getActor().setFileName(packageName + "." + actorName);			
			
			if(actorName.contains("1x2") && actorName.contains("bool")
					&& !genSBoxes.contains(actorName)) {

				genSBoxes.add(actorName);
			
				typeData = "bool";
				file = calFolder.getPath()  + File.separator + "Sbox1x2" + typeData + ".cal";
		
				CharSequence sequence1x2bool = new SBoxPrinterCal().printSboxes(calType,typeData,sizeData,"1x2",packageName);
	
				try {
					PrintStream ps = new PrintStream(new FileOutputStream(file));
					ps.print(sequence1x2bool.toString());
					ps.close();
				} catch (FileNotFoundException e) {
					OrccLogger.severeln("File Not Found Exception: " + e.getMessage());
				}
			
			} else if(actorName.contains("2x1") && actorName.contains("bool")
					&& !genSBoxes.contains(actorName)) {

				genSBoxes.add(actorName);
				
				typeData = "bool";
				file = calFolder.getPath()  + File.separator + "Sbox2x1" + typeData + ".cal";
		
				CharSequence sequence2x1bool = new SBoxPrinterCal().printSboxes(calType,typeData,sizeData,"2x1",packageName);
	
				try {
					PrintStream ps = new PrintStream(new FileOutputStream(file));
					ps.print(sequence2x1bool.toString());
					ps.close();
				} catch (FileNotFoundException e) {
					OrccLogger.severeln("File Not Found Exception: " + e.getMessage());
				}
			} else if(actorName.contains("1x2") && actorName.contains("float")
					&& !genSBoxes.contains(actorName)) {

				genSBoxes.add(actorName);
			
				typeData = "float";
				file = calFolder.getPath()  + File.separator + "Sbox1x2" + typeData + ".cal";
		
				CharSequence sequence1x2float = new SBoxPrinterCal().printSboxes(calType,typeData,sizeData,"1x2",packageName);
		
				try {
					PrintStream ps = new PrintStream(new FileOutputStream(file));
					ps.print(sequence1x2float.toString());
					ps.close();
				} catch (FileNotFoundException e) {
					OrccLogger.severeln("File Not Found Exception: " + e.getMessage());
				}
			} else if(actorName.contains("2x1") && actorName.contains("float")
					&& !genSBoxes.contains(actorName)) {

				genSBoxes.add(actorName);
				
				typeData = "float";
				file = calFolder.getPath()  + File.separator + "Sbox2x1" + typeData + ".cal";
			
				CharSequence sequence2x1float = new SBoxPrinterCal().printSboxes(calType,typeData,sizeData,"2x1",packageName);
		
				try {
					PrintStream ps = new PrintStream(new FileOutputStream(file));
					ps.print(sequence2x1float.toString());
					ps.close();
				} catch (FileNotFoundException e) {
					OrccLogger.severeln("File Not Found Exception: " + e.getMessage());
				}
			} else if(actorName.contains("1x2") && actorName.contains("int")
					&& !genSBoxes.contains(actorName)) {

				genSBoxes.add(actorName);
				
				typeData = "int";
				sizeData = String.valueOf(new ExpressionEvaluator().evaluateAsInteger(lut.getSboxInstance().getArgument("SIZE").getValue()));

				file = calFolder.getPath()  + File.separator + "Sbox1x2" + typeData + "" + sizeData + ".cal";
					
				CharSequence sequence1x2int = new SBoxPrinterCal().printSboxes(calType,typeData,sizeData,"1x2",packageName);
		
				try {
					PrintStream ps = new PrintStream(new FileOutputStream(file));
					ps.print(sequence1x2int.toString());
					ps.close();
				} catch (FileNotFoundException e) {
					OrccLogger.severeln("File Not Found Exception: " + e.getMessage());
				}
				
			} else if(actorName.contains("2x1") && actorName.contains("int")
					&& !genSBoxes.contains(actorName)) {
				
				genSBoxes.add(actorName);

				typeData = "int";
				sizeData = String.valueOf(new ExpressionEvaluator().evaluateAsInteger(lut.getSboxInstance().getArgument("SIZE").getValue()));

				file = calFolder.getPath()  + File.separator + "Sbox2x1" + typeData + "" + sizeData + ".cal";
				
				CharSequence sequence2x1int = new SBoxPrinterCal().printSboxes(calType,typeData,sizeData,"2x1",packageName);
		
				try {
					PrintStream ps = new PrintStream(new FileOutputStream(file));
					ps.print(sequence2x1int.toString());
					ps.close();
				} catch (FileNotFoundException e) {
					OrccLogger.severeln("File Not Found Exception: " + e.getMessage());
				}
				
			}

			lut.getSboxInstance().getActor().setName(packageName + "." + actorName);
		}
		/// <li> generate configurator: generateConfig() <ol>
		if(calType.equals("STATIC")) {
			generateConfig(luts,"STATIC");
			/// <li> if calType is static:  configStaticNet()
			configStaticNet(network);
		} else if(calType.equals("DYNAMIC")) {
			generateConfig(luts,"DYNAMIC");
			/// <li> if calType is dynamic: configDynamicNet()
			configDynamicNet(network, luts);
		}
		/// </ol> </ul>
	}

	/**
	 * This method generates the multi-dataflow network 
	 * configuration file
	 * 
	 * @param genCopr
	 * 			coprocessor generation enable
	 * @param coprEnv
	 * 			coprocessor environment (ISE or VIVADO)
	 * @param coprType
	 * 			coprocessor type (Stram or Memory-Mapped)
	 * @throws IOException
	 */
	public void generateConfigFile (boolean genCopr, String coprEnv, String coprType) throws IOException {
				
		if(configMap.size() != networks.size()) {
			for(Network network : networks) {
				getNetworkId(network.getSimpleName());
			}
		}
		
		// instantiate writer
		if(!genCopr) {
			writer = new FileWriter(new File ( outPath + 
					File.separator + "configNetID.txt"));
		} else if(coprEnv.equals("ISE")) {
			if (coprType.equals("MEMORY-MAPPED")) {
			writer = new FileWriter(new File ( outPath + File.separator + "pcores" + File.separator + "mm_accelerator_v1_00_a" + 
					File.separator + "configNetID.txt"));
			} else if(coprType.equals("STREAM")) {
				writer = new FileWriter(new File ( outPath + File.separator + "pcores" + File.separator + "s_accelerator_v1_00_a" + 
					File.separator + "configNetID.txt"));
			} else {
				writer = new FileWriter(new File ( outPath + 
						File.separator + "configNetID.txt"));
			}
		} else if(coprEnv.equals("VIVADO")) {
			if (coprType.equals("MEMORY-MAPPED")) {
				writer = new FileWriter(new File ( outPath + File.separator + "mm_accelerator" + 
					File.separator + "hdl" + File.separator + "configNetID.txt"));
			} else if(coprType.equals("STREAM")) {
			writer = new FileWriter(new File ( outPath + File.separator + "s_accelerator" + 
				File.separator + "hdl" + File.separator + "configNetID.txt"));
			} else {
				writer = new FileWriter(new File ( outPath + 
						File.separator + "configNetID.txt"));
			}
		} else {
			writer = new FileWriter(new File ( outPath + 
					File.separator + "configNetID.txt"));
		}
		for(int i : configMap.keySet())
			writer.write(configMap.get(i) + 
					" --> config id:" + i + "\n");
		
		// close writer
		writer.close();

	}
	
	/**
	 * Set and return a configuration ID for the given network
	 * 
	 * @param network
	 * 		the given network
	 * @return
	 * 		the assigned network ID
	 */
	public int getNetworkId(String network) {
		
		Integer id = null;

		// an id is already associated to the net
		for(Integer netId : configMap.keySet()){
			if(configMap.get(netId).equals(network)) {
				return netId;
			}
		}
		
		// fixed values for testing
		if(network.equals("sorter")) {
			id = 1;
		} else if (network.equals("max_min")) {
			id = 2;
		} else if (network.equals("rgb2ycc")
				||network.equals("rgb2ycc_2")) {
			id = 3;
		} else if (network.equals("ycc2rgb")
				||network.equals("ycc2rgb_2")) {
			id = 4;
		} else if (network.equals("k_abs")) {
			id = 5;
		} else if (network.equals("corr")) {
			id = 6;
		} else if (network.equals("sbwlabel")) {
			id = 7;
		} else if (network.equals("chgb")) {
			id = 8;
		} else if (network.equals("cubic_conv")) {
			id = 9;
		} else if (network.equals("median")) {
			id = 10;
		} else if (network.equals("cubic")) {
			id = 11;
		} else if (network.equals("filter")) {
			id = 12;
		} else if (network.equals("clip")) {
			id = 13;
		} else if (network.equals("inner_kernel")) {
			id = 14;
		} else if (network.equals("mdiv_kernel")) {
			id = 15;
		} else if (network.equals("k_nbit")) {
			id = 16;
		} else if (network.equals("k_sign")) {
			id = 17;
		} else if (network.equals("smear_kernel")) {
			id = 18;
		} else if (network.equals("rgb2yuv")
				||network.equals("rgb2yuv_2")) {
			id = 19;
		} else if (network.equals("yuv2rgb")
				||network.equals("yuv2rgb_2")) {
			id = 20;
		} else if (network.equals("filter_dec")) {
			id = 1;
		} else if (network.equals("filter_rec")) {
			id = 2;
		} else if (network.equals("thresholding")) {
			id = 3;
		} else if (network.equals("neo")) {
			id = 4;
		} else if (network.equals("w_vecmul")) {
			id = 5;
		} else if (network.equals("synchronizedAVG")) {
			id = 6;
		} else if (network.equals("vecsum_sq")) {
			id = 7;
		} else if (network.equals("synchronizedWAVG")) {
			id = 8;
		} else  if (network.equals("arithmetic_mean")) {
			id = 9;
		} else  if (network.equals("dot_prod")) {
			id = 10;
		} else  if (network.equals("maxabs_id")) {
			id = 11;
		} else if (network.equals("max_id")) {
			id = 12;
		} else {
			id = count;
			count++;
		}
		
		configMap.put(id,network);
		
		if(id>=count)
			count = id+1;
		return id;
		
	}
	
	/**
	 * Initialize the list of combined networks with the input networks.
	 * 
	 * @param inputNetworks
	 * 			List of input networks
	 */
	public void setNetworkList(List<Network> inputNetworks) {
		this.networks = inputNetworks;
	}
		
}
