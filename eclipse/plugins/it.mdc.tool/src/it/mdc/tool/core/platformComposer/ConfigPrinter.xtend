package it.mdc.tool.core.platformComposer

import java.text.SimpleDateFormat
import java.util.Date
import java.util.List
import net.sf.orcc.df.Network

import it.mdc.tool.core.sboxManagement.SboxLut
import it.mdc.tool.core.ConfigManager
import java.util.ArrayList
import net.sf.orcc.util.OrccLogger

/**
 * A Verilog Network Configurator printer
 * 
 * @author Carlo Sau
 */
class ConfigPrinter {
    
    var List<SboxLut> luts;
    
    var List<Network> networks;
    
    var ConfigManager configManager;
    
    def headerComments(){
                
        //OrccLogger.traceln("[DEBUG ConfigPrinter.headerComments] Entering method");
        var dateFormat = new SimpleDateFormat("yyyy/MM/dd HH:mm:ss");
        var date = new Date();
        //OrccLogger.traceln("[DEBUG ConfigPrinter.headerComments] Date formatted: " + dateFormat.format(date));
        
        '''
        // ----------------------------------------------------------------------------
        //
        // Multi-Dataflow Composer tool - Platform Composer
        // Configurator module 
        // Date: «dateFormat.format(date)»
        //
        // ----------------------------------------------------------------------------
        '''    
        
    }
    
    def computeNets() {
    //OrccLogger.traceln("[DEBUG ConfigPrinter.computeNets] Entering method");
    //OrccLogger.traceln("[DEBUG ConfigPrinter.computeNets] configManager is null? " + (configManager == null));
    //OrccLogger.traceln("[DEBUG ConfigPrinter.computeNets] luts is null? " + (luts == null));
    //OrccLogger.traceln("[DEBUG ConfigPrinter.computeNets] luts size: " + (if(luts != null) luts.size() else "null"));
    
    if(configManager == null) {
        OrccLogger.warnln("Warning: configManager is null!");
        return;
    }
    
    if(luts == null || luts.isEmpty()) {
        OrccLogger.warnln("Warning: luts is null or empty!");
        return;
    }
    
    val networkList = configManager.getNetworkList();
    /*OrccLogger.traceln("[DEBUG ConfigPrinter.computeNets] Network list size from configManager: " + 
        (if(networkList != null) networkList.size() else "null"));*/
    
    if(networkList != null) {
        for(net : networkList) {
           /*  OrccLogger.traceln("[DEBUG ConfigPrinter.computeNets] Processing network: " + 
                (if(net != null) net.simpleName else "null"));*/
            
            if(net != null) {
              //OrccLogger.traceln("[DEBUG ConfigPrinter.computeNets] Getting network by name: " + net.simpleName);
                
                // Debug the first lut before calling getNetworkByName
                val firstLut = luts.get(0);
               //OrccLogger.traceln("[DEBUG ConfigPrinter.computeNets] First LUT is null? " + (firstLut == null));
                if(firstLut != null) {
                   // OrccLogger.traceln("[DEBUG ConfigPrinter.computeNets] First LUT class: " + firstLut.getClass().getName());
                    
                    // Check if network exists in LUT before calling getNetworkByName
                    // We need to be more defensive since getNetworkByName throws an exception
                    try {
                        val foundNet = firstLut.getNetworkByName(net.simpleName);
                       /* OrccLogger.traceln("[DEBUG ConfigPrinter.computeNets] Found network: " + 
                            (if(foundNet != null) foundNet.simpleName else "null"));*/
                        
                        if(foundNet != null) {
                            networks.add(foundNet);
                           // OrccLogger.traceln("[DEBUG ConfigPrinter.computeNets] Added network to networks list. Current size: " + networks.size());
                        } else {
                            OrccLogger.warnln("[DEBUG ConfigPrinter.computeNets] Network " + net.simpleName + " not found in LUT (returned null)");
                            // Try to add the original network from configManager instead
                            networks.add(net);
                            //OrccLogger.traceln("[DEBUG ConfigPrinter.computeNets] Added original network instead. Current size: " + networks.size());
                        }
                    } catch(IndexOutOfBoundsException e) {
                        //OrccLogger.traceln("[DEBUG ConfigPrinter.computeNets] IndexOutOfBoundsException for network '" + net.simpleName + "': " + e.getMessage());
                       // OrccLogger.traceln("[DEBUG ConfigPrinter.computeNets] Network '" + net.simpleName + "' doesn't exist in LUTs. Adding original network.");
                        // Add the original network from configManager
                        networks.add(net);
                      //  OrccLogger.traceln("[DEBUG ConfigPrinter.computeNets] Added original network. Current size: " + networks.size());
                    } catch(Exception e) {
                      //  OrccLogger.traceln("[DEBUG ConfigPrinter.computeNets] General exception for network '" + net.simpleName + "': " + e.getMessage());
                       // OrccLogger.traceln("[DEBUG ConfigPrinter.computeNets] Adding original network as fallback.");
                        networks.add(net);
                        //OrccLogger.traceln("[DEBUG ConfigPrinter.computeNets] Added original network. Current size: " + networks.size());
                    }
                } else {
                   // OrccLogger.warnln("[DEBUG ConfigPrinter.computeNets] First LUT is null! Adding original network.");
                    networks.add(net);
                }
            }
        }
    }
    
    //OrccLogger.traceln("[DEBUG ConfigPrinter.computeNets] Final networks list size: " + networks.size());
}
    
  def printBody() {
    //OrccLogger.traceln("[DEBUG ConfigPrinter.printBody] Entering method");
    //OrccLogger.traceln("[DEBUG ConfigPrinter.printBody] networks is null? " + (networks == null));
    //OrccLogger.traceln("[DEBUG ConfigPrinter.printBody] networks size: " + (if(networks != null) networks.size() else "null"));
   // OrccLogger.traceln("[DEBUG ConfigPrinter.printBody] luts is null? " + (luts == null));
   // OrccLogger.traceln("[DEBUG ConfigPrinter.printBody] luts size: " + (if(luts != null) luts.size() else "null"));
   // OrccLogger.traceln("[DEBUG ConfigPrinter.printBody] configManager is null? " + (configManager == null));
    
    if(luts == null || luts.isEmpty()) {
        OrccLogger.traceln("Warning: luts is null or empty!");
        return "";
    }
    
    if(networks == null || networks.isEmpty()) {
        OrccLogger.traceln("Warning: networks is null or empty!");
        return "";
    }
    
   // OrccLogger.traceln("[DEBUG ConfigPrinter.printBody] Generating Verilog with luts.size=" + luts.size());
    
    try {
        // Build the result step by step
        val result = new StringBuilder();
        
        result.append('''
        
        reg [«luts.size - 1»:0] sel;
        
        // case ID
        always@(ID)
        case(ID)
        ''');
        
        // Process each network
        for(network : networks) {
            if(network != null) {
                //OrccLogger.traceln("[DEBUG ConfigPrinter.printBody] Processing network: " + network.simpleName);
                
                try {
                    val networkId = configManager.getNetworkId(network.getSimpleName());
                 //   OrccLogger.traceln("[DEBUG ConfigPrinter.printBody] Network ID for " + network.simpleName + ": " + networkId);
                    
                    result.append("8'd" + networkId + ":    begin    // " + network.getSimpleName() + "\n");
                    
                    // Process each LUT
                    for(lut : luts) {
                        if(lut != null) {
                           // OrccLogger.traceln("[DEBUG ConfigPrinter.printBody] Processing lut count: " + lut.getCount());
                            try {
                                val lutValue = lut.getLutValue(network,0);
                              //  OrccLogger.traceln("[DEBUG ConfigPrinter.printBody] Processing lut value: " + lutValue);
                                
                                result.append("sel[" + lut.getCount() + "]=" + (if(lutValue) "1'b1" else "1'b0") + ";\n");
                            } catch(Exception e) {
                              //  OrccLogger.traceln("[DEBUG ConfigPrinter.printBody] Error getting LUT value for lut " + lut.getCount() + ": " + e.getMessage());
                                result.append("// ERROR: sel[" + lut.getCount() + "]=?;\n");
                            }
                        }
                    }
                    
                    result.append("end\n");
                } catch(Exception e) {
                  //  OrccLogger.traceln("[DEBUG ConfigPrinter.printBody] Error getting network ID for " + network.simpleName + ": " + e.getMessage());
                    result.append("// ERROR: Network " + network.simpleName + " not found in configManager\n");
                }
            } else {
                OrccLogger.warnln("Warning: Found null network in networks list!");
            }
        }
        
        result.append("default:    sel=" + luts.size + "'bx;\n");
        result.append("endcase\n");
        
        return result.toString();
    } catch(Exception e) {
       //OrccLogger.traceln("[DEBUG ConfigPrinter.printBody] General exception in printBody: " + e.getMessage());
        e.printStackTrace();
        return "// ERROR: Failed to generate configuration body";
    }
}
    
    def printSignals() {
        //OrccLogger.traceln("[DEBUG ConfigPrinter.printSignals] Entering method");
        //OrccLogger.traceln("[DEBUG ConfigPrinter.printSignals] luts is null? " + (luts == null));
        //OrccLogger.traceln("[DEBUG ConfigPrinter.printSignals] luts size: " + (if(luts != null) luts.size() else "null"));
        
        if(luts == null) {
            OrccLogger.warnln("Warning: luts is null, using default size 0");
            return '''
            
            // Input
            input [7:0] ID;
            
            // Ouptut(s)
            output [0:0] sel;
            
            '''
        }
        
        '''
        
        // Input
        input [7:0] ID;
        
        // Ouptut(s)
        output [«luts.size - 1»:0] sel;
        
        '''
    }
    
    def printInterface(Network network) {
       // OrccLogger.traceln("[DEBUG ConfigPrinter.printInterface] Entering method");
      //  OrccLogger.traceln("[DEBUG ConfigPrinter.printInterface] Network is null? " + (network == null));
        
        '''
        
        module configurator(
            ID,
            sel
        );
        
        '''
    }
 def printConfig(Network network, List<SboxLut> luts, ConfigManager configManager){
   // OrccLogger.traceln("[DEBUG ConfigPrinter.printConfig] ===== STARTING PRINT CONFIG =====");
    //OrccLogger.traceln("[DEBUG ConfigPrinter.printConfig] Input network is null? " + (network == null));
   // OrccLogger.traceln("[DEBUG ConfigPrinter.printConfig] Input luts is null? " + (luts == null));
  //  OrccLogger.traceln("[DEBUG ConfigPrinter.printConfig] Input luts size: " + (if(luts != null) luts.size() else "null"));
  //  OrccLogger.traceln("[DEBUG ConfigPrinter.printConfig] Input configManager is null? " + (configManager == null));
    
    // Initialize members
    this.luts = luts; 
    this.configManager = configManager;
    networks = new ArrayList<Network>();
    
   // OrccLogger.traceln("[DEBUG ConfigPrinter.printConfig] After initialization:");
   // OrccLogger.traceln("[DEBUG ConfigPrinter.printConfig] - this.luts is null? " + (this.luts == null));
  //  OrccLogger.traceln("[DEBUG ConfigPrinter.printConfig] - this.configManager is null? " + (this.configManager == null));
   // OrccLogger.traceln("[DEBUG ConfigPrinter.printConfig] - networks is null? " + (networks == null));
    
    //OrccLogger.traceln("[DEBUG ConfigPrinter.printConfig] Calling computeNets()");
    computeNets();
    
   // OrccLogger.traceln("[DEBUG ConfigPrinter.printConfig] After computeNets:");
  //  OrccLogger.traceln("[DEBUG ConfigPrinter.printConfig] - networks size: " + networks.size());
    if(networks != null && !networks.isEmpty()) {
        for(i : 0 ..< networks.size) {
            val net = networks.get(i);
           /* OrccLogger.traceln("[DEBUG ConfigPrinter.printConfig] - networks[" + i + "]: " + 
                (if(net != null) net.simpleName else "null"));*/
        }
    }
    
    // Debug each lut
    if(this.luts != null) {
        //OrccLogger.traceln("[DEBUG ConfigPrinter.printConfig] Dumping luts details:");
        for(i : 0 ..< this.luts.size) {
            val lut = this.luts.get(i);
           // OrccLogger.traceln("[DEBUG ConfigPrinter.printConfig] - lut[" + i + "] is null? " + (lut == null));
            if(lut != null) {
                //OrccLogger.traceln("[DEBUG ConfigPrinter.printConfig] - lut[" + i + "].getCount(): " + lut.getCount());
                // Try to call getLutValue to see if it works
                try {
                    if(!networks.isEmpty() && networks.get(0) != null) {
                        val testValue = lut.getLutValue(networks.get(0), 0);
                        //OrccLogger.traceln("[DEBUG ConfigPrinter.printConfig] - lut[" + i + "].getLutValue(test): " + testValue);
                    }
                } catch(Exception e) {
                    //OrccLogger.traceln("[DEBUG ConfigPrinter.printConfig] - Error calling getLutValue: " + e.getMessage());
                }
            }
        }
    }
    
   // OrccLogger.traceln("[DEBUG ConfigPrinter.printConfig] Generating final Verilog output");
    
    // Try to generate each part separately to see which part fails
   // OrccLogger.traceln("[DEBUG ConfigPrinter.printConfig] Generating headerComments...");
    val header = headerComments();
   // OrccLogger.traceln("[DEBUG ConfigPrinter.printConfig] Generated headerComments");
    
   // OrccLogger.traceln("[DEBUG ConfigPrinter.printConfig] Generating printInterface...");
    val interfacePart = printInterface(network);
  //  OrccLogger.traceln("[DEBUG ConfigPrinter.printConfig] Generated printInterface");
    
   // OrccLogger.traceln("[DEBUG ConfigPrinter.printConfig] Generating printSignals...");
    val signalsPart = printSignals();
   // OrccLogger.traceln("[DEBUG ConfigPrinter.printConfig] Generated printSignals");
    
   // OrccLogger.traceln("[DEBUG ConfigPrinter.printConfig] Generating printBody...");
    val bodyPart = printBody();
   // OrccLogger.traceln("[DEBUG ConfigPrinter.printConfig] Generated printBody");
    
    val result = '''
    «header»
    
    // ----------------------------------------------------------------------------
    // Module Interface
    // ----------------------------------------------------------------------------
    «interfacePart»
    
    // ----------------------------------------------------------------------------
    // Module Signals
    // ----------------------------------------------------------------------------
    «signalsPart»
    
    // ----------------------------------------------------------------------------
    // Body
    // ----------------------------------------------------------------------------
    «bodyPart»
    
    endmodule
    // ----------------------------------------------------------------------------
    // ----------------------------------------------------------------------------
    // ----------------------------------------------------------------------------
    '''
    
    //OrccLogger.traceln("[DEBUG ConfigPrinter.printConfig] ===== FINISHED PRINT CONFIG =====");
    return result;
}   
}