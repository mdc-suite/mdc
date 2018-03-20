/*
 *
 */
 
package it.mdc.tool.prototyping
import net.sf.orcc.df.Network
import java.util.Map
import java.util.HashMap
import net.sf.orcc.df.Port

/**
 * Vivado Script Printer
 * 
 * @author Tiziana Fanni
 * @author Carlo Sau
 * 
 */
class ScriptPrinter {
	
	protected Map <Port,Integer> inputMap;
	protected Map <Port,Integer> outputMap;
	protected Map <Port,Integer> portMap;
	protected int fifoNum;
	
	String partname = "xc7z020clg400-1"
	String boardpart = "digilentinc.com:arty-z7-20:part0:1.0"
	String coupling = "mm"
	String lib_name = "caph"

	def initScriptPrinter(String partname, String boardpart, String coupling, String lib_name){
		this.partname = partname;
		this.boardpart = boardpart;
		this.coupling = coupling;
		this.lib_name = lib_name;
	}

	def printTopScript(Network network) {
		mapInOut(network);
		'''
		###########################
		# IP Settings
		###########################
		
		# paths
		
		# user should properly set root path
		set root "."
		set projdir $root/project
		
		set constraints_files []
		
		set lib_name «lib_name»
		
		# FPGA device
		set partname "«partname»"
		
		# Board part
		set boardpart "«boardpart»"
		
		# Design name
		set design project_1
		set bd_design "design_1"
		
		set ip_name "«coupling»_accelerator"
		set ip_version "1.0"
		set ip_v "v1_0"
		
		
		###########################
		# Create Project
		###########################
		create_project -force $design $projdir -part $partname 
		set_property board_part $boardpart [current_project]
		set_property target_language Verilog [current_project]
		set_property  ip_repo_paths $root [current_project]
		update_ip_catalog -rebuild -scan_changes
		###########################
		#create block design
		create_bd_design $bd_design
		startgroup
		create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0
		endgroup
		apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable" }  [get_bd_cells processing_system7_0]
		connect_bd_net [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK] [get_bd_pins processing_system7_0/FCLK_CLK0]
		
		#import IP
		
		startgroup
		create_bd_cell -type ip -vlnv user.org:user:$ip_name:$ip_version $ip_name\_0
		endgroup
		
		«IF coupling.equals("mm")»		
		startgroup
		apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/processing_system7_0/M_AXI_GP0" intc_ip "New AXI Interconnect" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins $ip_name\_0/s00_axi]
		«IF coupling == "mm"»
		apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/processing_system7_0/M_AXI_GP0" intc_ip "Auto" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins $ip_name\_0/s01_axi]
		«ENDIF»
		endgroup
		«ELSE»
		startgroup
		apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/processing_system7_0/M_AXI_GP0" intc_ip "New AXI Interconnect" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins $ip_name\_0/s00_axi]
		endgroup
		
		
		# AManage connection for each accelerator port
		
		«FOR input : inputMap.keySet()»
		connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins s_accelerator_0/s«getLongId(inputMap.get(input))»_axis_aclk]
		connect_bd_net [get_bd_pins rst_ps7_0_100M/peripheral_aresetn] [get_bd_pins s_accelerator_0/s«getLongId(inputMap.get(input))»_axis_aresetn]
		startgroup
		create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:1.1 axis_data_fifo_in_«inputMap.get(input)»
		endgroup
		connect_bd_intf_net [get_bd_intf_pins axis_data_fifo_in_«inputMap.get(input)»/M_AXIS] [get_bd_intf_pins s_accelerator_0/s«getLongId(inputMap.get(input))»_axis]
		connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins axis_data_fifo_in_«inputMap.get(input)»/s_axis_aclk]
		connect_bd_net [get_bd_pins rst_ps7_0_100M/peripheral_aresetn] [get_bd_pins axis_data_fifo_in_«inputMap.get(input)»/s_axis_aresetn]
		«ENDFOR»
		
		«FOR output : outputMap.keySet()»
		connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins s_accelerator_0/m«getLongId(outputMap.get(output))»_axis_aclk]
		connect_bd_net [get_bd_pins rst_ps7_0_100M/peripheral_aresetn] [get_bd_pins s_accelerator_0/m«getLongId(outputMap.get(output))»_axis_aresetn]
		startgroup
		create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:1.1 axis_data_fifo_out_«outputMap.get(output)»
		endgroup
		connect_bd_intf_net [get_bd_intf_pins s_accelerator_0/m«getLongId(outputMap.get(output))»_axis] [get_bd_intf_pins axis_data_fifo_out_«outputMap.get(output)»/S_AXIS]
		connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins axis_data_fifo_out_«outputMap.get(output)»/s_axis_aclk]
		connect_bd_net [get_bd_pins rst_ps7_0_100M/peripheral_aresetn] [get_bd_pins axis_data_fifo_out_«outputMap.get(output)»/s_axis_aresetn]
		«ENDFOR»
		

			
		«FOR i : 0..fifoNum-1»
		startgroup
		create_bd_cell -type ip -vlnv xilinx.com:ip:axi_mm2s_mapper:1.1 axi_mm2s_mapper_«i»
		endgroup
		set_property -dict [list CONFIG.INTERFACES {S_AXI}] [get_bd_cells axi_mm2s_mapper_«i»]
		apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/processing_system7_0/M_AXI_GP0" intc_ip "/ps7_0_axi_periph" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins axi_mm2s_mapper_«i»/S_AXI]
		
		«IF i < inputMap.size»
		connect_bd_intf_net [get_bd_intf_pins axi_mm2s_mapper_«i»/M_AXIS] [get_bd_intf_pins axis_data_fifo_in_«i»/S_AXIS]
		«ENDIF»
		
		«IF i < inputMap.size»
		connect_bd_intf_net [get_bd_intf_pins axi_mm2s_mapper_«i»/S_AXIS] [get_bd_intf_pins axis_data_fifo_out_«i»/M_AXIS]
		«ENDIF»
		
		«ENDFOR»
		
		
		

		
		«ENDIF»
		
		make_wrapper -files [get_files $projdir/$design.srcs/sources_1/bd/design_1/design_1.bd] -top
		add_files -norecurse $projdir/$design.srcs/sources_1/bd/design_1/hdl/design_1_wrapper.v
		'''
	}
	
		
	def printIpScript() {
		'''
		###########################
		# IP Settings
		###########################
		
		# paths
		
		# user should properly set root path
		set root "."
		
		set hdl_files_path $root/hdl
		set lib_path $root/hdl/lib
		
		set lib_name «lib_name»
		set constraints_files []
		
		# FPGA device
		set partname "«partname»"
		
		# Board part
		set boardpart "«boardpart»"
		
		# Design name
		set ip_name "«coupling»_accelerator"
		set design $ip_name
		
		###########################
		# Create IP
		###########################
		
		create_project -force $design $root/$ip_name -part $partname 
		set_property board_part $boardpart [current_project]
		set_property target_language Verilog [current_project]
		
		add_files $hdl_files_path
		#import «lib_name» lib
		add_files $lib_path/$lib_name
		import_files -force
		
		set files [glob -tails -directory $root/$ip_name/$ip_name.srcs/sources_1/imports/hdl/lib/$lib_name/ *]
		foreach f $files {
			set name $f
			set_property library $lib_name [get_files  $root/$ip_name/$ip_name.srcs/sources_1/imports/hdl/lib/$lib_name/$f]
		        }
		
		set_property top $ip_name [current_fileset]
		
		ipx::package_project -root_dir $root -vendor user.org -library user -taxonomy /UserIP
		
		«IF coupling == "mm"»
		set_property enablement_dependency spirit:decode(id('MODELPARAM_VALUE.C_S01_AXI_ID_WIDTH'))>0 [ipx::get_ports s01_axi_awid -of_objects [ipx::current_core]]
		set_property enablement_dependency spirit:decode(id('MODELPARAM_VALUE.C_S01_AXI_AWUSER_WIDTH'))>0 [ipx::get_ports s01_axi_awuser -of_objects [ipx::current_core]]
		set_property enablement_dependency spirit:decode(id('MODELPARAM_VALUE.C_S01_AXI_WUSER_WIDTH'))>0 [ipx::get_ports s01_axi_wuser -of_objects [ipx::current_core]]
		set_property enablement_dependency spirit:decode(id('MODELPARAM_VALUE.C_S01_AXI_BUSER_WIDTH'))>0 [ipx::get_ports s01_axi_buser -of_objects [ipx::current_core]]
		set_property enablement_dependency {spirit:decode(id('MODELPARAM_VALUE.C_S01_AXI_ID_WIDTH')) >0} [ipx::get_ports s01_axi_arid -of_objects [ipx::current_core]]
		set_property enablement_dependency spirit:decode(id('MODELPARAM_VALUE.C_S01_AXI_ARUSER_WIDTH')) [ipx::get_ports s01_axi_aruser -of_objects [ipx::current_core]]
		set_property enablement_dependency spirit:decode(id('MODELPARAM_VALUE.C_S01_AXI_ARUSER_WIDTH'))>0 [ipx::get_ports s01_axi_aruser -of_objects [ipx::current_core]]
		set_property enablement_dependency spirit:decode(id('MODELPARAM_VALUE.C_S01_AXI_RUSER_WIDTH'))>0 [ipx::get_ports s01_axi_ruser -of_objects [ipx::current_core]]
		
		set bd_pkg_dir $root/bd
		file mkdir $bd_pkg_dir
		set bd_group [ipx::add_file_group -type xilinx_blockdiagram {} [ipx::current_core]]
		file copy -force bd.tcl $bd_pkg_dir
		ipx::add_file $bd_pkg_dir/bd.tcl $bd_group
		
		«ENDIF»
		set_property core_revision 3 [ipx::current_core]
		ipx::create_xgui_files [ipx::current_core]
		ipx::update_checksums [ipx::current_core]
		ipx::save_core [ipx::current_core]
		set_property  ip_repo_paths $root [current_project]
		update_ip_catalog
		close_project
		'''		
	}
	
		protected def getLongId(int id) {
			if(id<10) {
				return "0"+id.toString();
			} else {
				return id.toString();	
			}
		}
	
		protected def mapInOut(Network network) {
		
		var index=0;
		
		inputMap = new HashMap<Port,Integer>();
		outputMap = new HashMap<Port,Integer>();
		fifoNum = 0;
		
		for(Port input : network.getInputs()) {
			inputMap.put(input,index);
			index=index+1;
		}
		
		index=0;
		for(Port output : network.getOutputs()) {
			outputMap.put(output,index);
			index=index+1;
		}
		
		if (inputMap.size >= outputMap.size)
			{fifoNum = 	inputMap.size;}
		else 
			{fifoNum = 	outputMap.size;	}
	}
	
	
	
}