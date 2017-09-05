package it.mdc.tool.core.platformComposer;


import java.util.List;
import java.util.Map;

import net.sf.orcc.df.Network;
import net.sf.orcc.util.OrccLogger;
import it.mdc.tool.core.ConfigManager;
import it.mdc.tool.core.sboxManagement.SboxLut;
import it.mdc.tool.core.platformComposer.NetworkPrinterRVC;
import it.mdc.tool.core.sboxManagement.*;
import net.sf.orcc.df.transform.Instantiator;
import net.sf.orcc.df.transform.NetworkFlattener;
import net.sf.orcc.df.transform.TypeResizer;

import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.File;
import java.io.PrintStream;

//import org.xronos.orcc.backend.NetworkPrinter;

/**
 * 
 * This class write HDL top modules of the multi-dataflow network
 * using the RVC-CAL based communication protocol.
 * 
 * @author Carlo Sau
 * @see it.unica.diee.mdc.utility package
 */
public class RvcPrinter extends PlatformComposer {
	
	/**
	 * The constructor
	 * 
	 * @param outPath
	 * 			the output folder path
	 * @param configManager
	 * 			the manager of the network configuration
	 * @param network
	 * 			the multi-dataflow network
	 * @throws IOException
	 */
	public RvcPrinter(String outPath, ConfigManager configManager, Network network) throws IOException
	{
		super(outPath,configManager,network);
	}
	
	
	@Override
	protected boolean printNetwork (List<SboxLut> luts, Map<String,Object> options)
	{	
		/////////////////////////////////////////////////////////////
		new Instantiator(true).doSwitch(network);
		new NetworkFlattener().doSwitch(network);

		new TypeResizer(false, true, false, false).doSwitch(network);
		// Compute the Network Template
		network.computeTemplateMaps();
		/////////////////////////////////////////////////////////////
		
		File dir; 
		if((Boolean) options.get("it.unica.diee.mdc.genCopr")) {
			dir = new File(hdlPath);
		} else {
			dir = new File(hdlPath + File.separator + "vhdl");
		}
		// If directory doesn't exist, create it
		if (!dir.exists()) {
			dir.mkdirs();
		}
		
		String file = dir.getPath() + File.separator + network.getSimpleName()
		+ ".vhd";
		
		NetworkPrinterRVC printer  = new NetworkPrinterRVC();
		CharSequence sequence = printer.printNetwork(network,luts,options,logicRegions,clockDomains);
		logicRegionID = printer.getLogicRegionID();
		
		try {
			PrintStream ps = new PrintStream(new FileOutputStream(file));
			ps.print(sequence.toString());
			ps.close();
		} catch (FileNotFoundException e) {
			OrccLogger.severeln("File Not Found Exception: " + e.getMessage());
		}
		
		return false;
		
	}	
	
}