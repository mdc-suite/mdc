package it.mdc.tool.core.platformComposer;


import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import net.sf.orcc.df.Network;
import net.sf.orcc.util.OrccLogger;
import it.mdc.tool.core.sboxManagement.*;
import it.mdc.tool.core.ConfigManager;
import it.mdc.tool.core.platformComposer.NetworkPrinterCustom;
import it.mdc.tool.core.platformComposer.SBoxPrinter;
import it.mdc.tool.core.sboxManagement.SboxLut;
import it.mdc.tool.powerSaving.CpfPrinter;
import it.mdc.tool.powerSaving.PowerController;
import net.sf.orcc.df.transform.Instantiator;
import net.sf.orcc.df.transform.NetworkFlattener;

import java.io.BufferedReader;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.IOException;
import java.io.File;
import java.io.PrintStream;

/**
 * 
 * This class write HDL top modules of the network merged by MDC backend.
 * 
 * @author Carlo Sau
 * @see it.mdc.tool.utility package
 */
public class CustomPrinter extends PlatformComposer {
	
	/**
	 * Protocol signals
	 */
	private List<String[]> signals;
	private List<String[]> extSignals;
	private String clockSignal;
	
	private BufferedReader reader;
	
	
	public CustomPrinter(String outPath, ConfigManager configManager, Network network, String protPath) throws IOException{
		super(outPath,configManager,network);
		signals = new ArrayList<String[]>();
		extSignals = new ArrayList<String[]>();
		clockSignal = null;
		if(!protPath.equals("")){
			reader = new BufferedReader(new FileReader(new File(protPath)));
			acquireProtocol();
		}
	}
	
	/**
	 * Acquire communication protocol
	 * 
	 * @throws IOException
	 */
	private void acquireProtocol() throws IOException {
		String nextLine = null;
		
		while((nextLine = reader.readLine()) != null)
			acquireProtocolLine(nextLine);
		
		if(clockSignal == null)
			System.out.println("Warning! There is not clock signal in the system!");
		
		}
	
	/**
	 * Acquire a single line (a signal) of communication protocol
	 * 
	 * @param line
	 */
	private void acquireProtocolLine(String line) {
	
		String[] signal = new String[5];
		String[] extSignal = new String[3];
				
		if(line.contains(">")) {			// right direction signal
			if(line.split(">").length > 2) {
				signal[DIRECTION] = "dx";
				signal[OUT_PORT] = line.split(">")[0];
				signal[SIZE] = line.split(">")[1];
				signal[IN_PORT] = line.split(">")[2].split(",")[0];
				signal[IS_NATIVE] = line.split(">")[2].split(",")[1];
			} else {
					extSignal[DIRECTION] = "dx";
					extSignal[PORT] = line.split(">")[0];
					extSignal[SIZE] = line.split(">")[1];				
			}
		} else if (line.contains("<")) {	// left direction signal
			if(line.split("<").length > 2) {
				signal[DIRECTION] = "sx";
				signal[OUT_PORT] = line.split("<")[0];
				signal[SIZE] = line.split("<")[1];
				signal[IN_PORT] = line.split("<")[2].split(",")[0];
				signal[IS_NATIVE] = line.split("<")[2].split(",")[1];
			} else {
				extSignal[DIRECTION] = "sx";
				extSignal[PORT] = line.split("<")[0];
				extSignal[SIZE] = line.split("<")[1];
			}
		} else if(line.contains(",clock")) {
			clockSignal = line.split(",")[0];
		}
		
		if(signal[0]!=null) {
			signals.add(signal);
		} else if(extSignal[0]!=null){
			extSignals.add(extSignal);
		}

	}

	@Override
	protected boolean printNetwork(List<SboxLut> luts, Map<String,Object> options) 
	{
			
		/////////////////////////////////////////////////////////////
		new Instantiator(true).doSwitch(network);
		new NetworkFlattener().doSwitch(network);
		//new TypeResizer(false, true, false, false).doSwitch(network);
		// Compute the Network Template
		network.computeTemplateMaps();
		/////////////////////////////////////////////////////////////
		
		//if enableClockGating is high, Clock Gating methodology is enabled
		boolean enableClockGating = ((Boolean) options.get("it.unica.diee.mdc.computeLogicRegions"))
				&& (options.get("it.unica.diee.mdc.lrPowerSaving").equals("CLOCK_GATING")
					|| (options.get("it.unica.diee.mdc.lrPowerSaving").equals("HYBRID")) );
		
		//if enablePSO is high, Power Shut Off methodology is enabled
		boolean enablePowerGating = ((Boolean) options.get("it.unica.diee.mdc.computeLogicRegions"))
				&& (options.get("it.unica.diee.mdc.lrPowerSaving").equals("POWER_GATING")
					|| (options.get("it.unica.diee.mdc.lrPowerSaving").equals("HYBRID")) );

		File dir; 
		if((Boolean) options.get("it.unica.diee.mdc.genCopr")) {
			dir = new File(hdlPath);
		} else {
			dir = new File(hdlPath + File.separator + "verilog");
		}
		// If directory doesn't exist, create it
		if (!dir.exists()) {
			dir.mkdirs();
		}
		
		String file = dir.getPath() + File.separator + network.getSimpleName()
		+ ".v";	
		
		NetworkPrinterCustom printer  = new NetworkPrinterCustom();
		CharSequence sequence = printer.printNetwork(network,luts,logicRegions,
				enableClockGating,enablePowerGating, extSignals,signals,clockSignal, logicRegions, 
				netRegions, powerSets, powerSetsIndex, logicRegionsSeqMap);
		logicRegionID = printer.getClockDomainIndex();
		
		try {
			PrintStream ps = new PrintStream(new FileOutputStream(file));
			ps.print(sequence.toString());
			ps.close();
		} catch (FileNotFoundException e) {
			OrccLogger.severeln("File Not Found Exception: " + e.getMessage());
		}
		
		
		if(enablePowerGating){			
			File cpfDir = new File(hdlPath.replace("hdl", "cpf"));
			// If directory doesn't exist, create it
			if (!cpfDir.exists()) {
				cpfDir.mkdirs();
			}
			
			//Generate CPF file
			String CPFfile = cpfDir.getPath() + File.separator + network.getSimpleName() + ".cpf";
			CpfPrinter printCPF = new CpfPrinter();
			CharSequence sequenceCPF = printCPF.printCPF(network, luts, logicRegions, 
					netRegions, logicRegionID, configManager, powerSets, logicRegionsSeqMap);
			//System.out.println("sequenceCPF  " + sequenceCPF);
			
			try {
				PrintStream psCPF = new PrintStream(new FileOutputStream(CPFfile));
				psCPF.print(sequenceCPF.toString());
				psCPF.close();
			} catch (FileNotFoundException e) {
				OrccLogger.severeln("File Not Found Exception: " + e.getMessage());
			  }
			
			
			//Generate Verilog Power Controller which generates all the power logic enables.			
			String PowerControllerFile = dir.getPath() + File.separator + "PowerController" + ".v";
			PowerController printPowerController = new PowerController();
			CharSequence sequencePowerController = printPowerController.printPowerController(network, luts, 
					logicRegions, netRegions, logicRegionID, configManager, powerSets, logicRegionsSeqMap);
			//System.out.println("sequencePowerController  " + sequencePowerController);
			
			try {
				PrintStream psPowerController = new PrintStream(new FileOutputStream(PowerControllerFile));
				psPowerController.print(sequencePowerController.toString());
				psPowerController.close();
			} catch (FileNotFoundException e) {
				OrccLogger.severeln("File Not Found Exception: " + e.getMessage());
			  }	
		}
		
		// Print sbox modules
		if(!luts.isEmpty())
		{
			String sbox1x2File = dir.getPath() + File.separator + "sbox1x2.v";
			String sbox2x1File = dir.getPath() + File.separator + "sbox2x1.v";
			
			SBoxPrinter sboxPrinter  = new SBoxPrinter();
			CharSequence sequence1x2 = sboxPrinter.printSbox("1x2",signals);
			CharSequence sequence2x1 = sboxPrinter.printSbox("2x1",signals);
			
			try {
				PrintStream ps1x2 = new PrintStream(new FileOutputStream(sbox1x2File));
				ps1x2.print(sequence1x2.toString());
				ps1x2.close();
				PrintStream ps2x1 = new PrintStream(new FileOutputStream(sbox2x1File));
				ps2x1.print(sequence2x1.toString());
				ps2x1.close();
			} catch (FileNotFoundException e) {
				OrccLogger.severeln("File Not Found Exception: " + e.getMessage());
			}
		}
			
		return false;
	
	}


	

	
	
}