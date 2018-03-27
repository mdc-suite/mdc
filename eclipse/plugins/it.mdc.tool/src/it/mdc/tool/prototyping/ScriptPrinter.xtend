/*
 *
 */
 
package it.mdc.tool.prototyping

import net.sf.orcc.df.Network
import java.util.Map
import java.util.HashMap
import net.sf.orcc.df.Port
import java.util.ArrayList
import java.util.List

/**
 * Vivado AXI IP Script Printer 
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
	protected boolean enDMA = false;
	
	String partname = "xc7z020clg400-1"
	String boardpart = "digilentinc.com:arty-z7-20:part0:1.0"
	String coupling = "mm"
	List<String> libraries = new ArrayList<String>()
	String proc = ""

	def initScriptPrinter(String partname, String boardpart, String coupling, List<String> libraries){
		this.partname = partname;
		this.boardpart = boardpart;
		this.coupling = coupling;
		this.libraries = libraries;
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
		set projdir $root/project_top
		set ipdir $root/«coupling»_accelerator/project_ip
		
		set constraints_files []
		
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
		set_property  ip_repo_paths $ipdir [current_project]
		update_ip_catalog -rebuild -scan_changes
		###########################
		#create block design
		create_bd_design $bd_design
		
		«IF proc.equals("arm")»
		create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0
		apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable" }  [get_bd_cells processing_system7_0]
		connect_bd_net [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK] [get_bd_pins processing_system7_0/FCLK_CLK0]
		«ELSE»
		create_bd_cell -type ip -vlnv xilinx.com:ip:microblaze:10.0 microblaze_0
		apply_bd_automation -rule xilinx.com:bd_rule:microblaze -config {preset "None" local_mem "8KB" ecc "None" cache "None" debug_module "Debug Only" axi_periph "Enabled" axi_intc "0" clk "New Clocking Wizard (100 MHz)" }  [get_bd_cells microblaze_0]
		set_property -dict [list CONFIG.PRIM_SOURCE {Single_ended_clock_capable_pin} CONFIG.USE_LOCKED {false} CONFIG.USE_RESET {false}] [get_bd_cells clk_wiz_1]
		delete_bd_objs [get_bd_nets clk_wiz_1_locked]
		apply_bd_automation -rule xilinx.com:bd_rule:board -config {Board_Interface "sys_clock ( System clock ) " }  [get_bd_pins clk_wiz_1/clk_in1]
		apply_bd_automation -rule xilinx.com:bd_rule:board -config {rst_polarity "ACTIVE_LOW" }  [get_bd_pins rst_clk_wiz_1_100M/ext_reset_in]
		set_property -dict [list CONFIG.C_FSL_LINKS {1}] [get_bd_cells microblaze_0]
		«ENDIF»
		
		#import IP
		
		startgroup
		create_bd_cell -type ip -vlnv user.org:user:$ip_name:$ip_version $ip_name\_0
		endgroup
		
		startgroup
		«IF coupling.equals("mm")»		
			«IF proc.equals("arm")»
				«IF enDMA»
				apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/processing_system7_0/M_AXI_GP0" intc_ip "New AXI Interconnect" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins $ip_name\_0/s00_axi]
				create_bd_cell -type ip -vlnv xilinx.com:ip:axi_cdma:4.1 axi_cdma_0
				set_property -dict [list CONFIG.C_INCLUDE_SG {0}] [get_bd_cells axi_cdma_0]
				connect_bd_intf_net [get_bd_intf_pins mm_accelerator_0/s01_axi] [get_bd_intf_pins axi_cdma_0/M_AXI]
				apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {Clk "/processing_system7_0/FCLK_CLK0 (100 MHz)" }  [get_bd_pins mm_accelerator_0/s01_axi_aclk]
				apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/processing_system7_0/M_AXI_GP0" intc_ip "/ps7_0_axi_periph" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins axi_cdma_0/S_AXI_LITE]
				assign_bd_address
				include_bd_addr_seg [get_bd_addr_segs -excluded axi_cdma_0/Data/SEG_mm_accelerator_0_reg0]
				endgroup
				«ELSE»
				apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/processing_system7_0/M_AXI_GP0" intc_ip "New AXI Interconnect" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins $ip_name\_0/s00_axi]
				apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/processing_system7_0/M_AXI_GP0" intc_ip "Auto" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins $ip_name\_0/s01_axi]
				«ENDIF»
			«ELSE»
			apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/microblaze_0 (Periph)" intc_ip "New AXI Interconnect" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins mm_accelerator_0/s00_axi]
			apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/microblaze_0 (Periph)" intc_ip "Auto" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins mm_accelerator_0/s01_axi]
			«ENDIF»
			endgroup
		«ELSE»	
			«IF proc.equals("arm")»
			apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/processing_system7_0/M_AXI_GP0" intc_ip "New AXI Interconnect" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins $ip_name\_0/s00_axi]
			«ELSE»
			apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/microblaze_0 (Periph)" intc_ip "New AXI Interconnect" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins s_accelerator_0/s00_axi]
			apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/microblaze_0 (Periph)" intc_ip "Auto" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins s_accelerator_0/s00_axi]
			«ENDIF»
			endgroup
		
		# Manage connection for each accelerator port
		«FOR input : inputMap.keySet()»
		«IF coupling.equals("mm")»
		connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins s_accelerator_0/s«getLongId(inputMap.get(input))»_axis_aclk]
		connect_bd_net [get_bd_pins rst_ps7_0_100M/peripheral_aresetn] [get_bd_pins s_accelerator_0/s«getLongId(inputMap.get(input))»_axis_aresetn]
		startgroup
		create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:1.1 axis_data_fifo_in_«inputMap.get(input)»
		endgroup
		connect_bd_intf_net [get_bd_intf_pins axis_data_fifo_in_«inputMap.get(input)»/M_AXIS] [get_bd_intf_pins s_accelerator_0/s«getLongId(inputMap.get(input))»_axis]
		connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins axis_data_fifo_in_«inputMap.get(input)»/s_axis_aclk]
		connect_bd_net [get_bd_pins rst_clk_wiz_1_100M/peripheral_aresetn] [get_bd_pins axis_data_fifo_in_«inputMap.get(input)»/s_axis_aresetn]		
		«ELSE»
		connect_bd_net [get_bd_pins s_accelerator_0/s«getLongId(inputMap.get(input))»_axis_aclk] [get_bd_pins clk_wiz_1/clk_out1]
		connect_bd_net [get_bd_pins s_accelerator_0/s«getLongId(inputMap.get(input))»_axis_aresetn] [get_bd_pins rst_clk_wiz_1_100M/peripheral_aresetn]
		startgroup
		create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:1.1 axis_data_fifo_in_«inputMap.get(input)»
		endgroup
		connect_bd_intf_net [get_bd_intf_pins axis_data_fifo_in_«inputMap.get(input)»/M_AXIS] [get_bd_intf_pins s_accelerator_0/s«getLongId(inputMap.get(input))»_axis]
		connect_bd_net [get_bd_pins clk_wiz_1/clk_out1] [get_bd_pins axis_data_fifo_in_«inputMap.get(input)»/s_axis_aclk]
		connect_bd_net [get_bd_pins rst_clk_wiz_1_100M/peripheral_aresetn] [get_bd_pins axis_data_fifo_in_«inputMap.get(input)»/s_axis_aresetn]
		«ENDIF»
		«ENDFOR»
		
				
		«FOR output : outputMap.keySet()»
		«IF coupling.equals("mm")»
		connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins s_accelerator_0/m«getLongId(outputMap.get(output))»_axis_aclk]
		connect_bd_net [get_bd_pins rst_ps7_0_100M/peripheral_aresetn] [get_bd_pins s_accelerator_0/m«getLongId(outputMap.get(output))»_axis_aresetn]
		startgroup
		create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:1.1 axis_data_fifo_out_«outputMap.get(output)»
		endgroup
		connect_bd_intf_net [get_bd_intf_pins s_accelerator_0/m«getLongId(outputMap.get(output))»_axis] [get_bd_intf_pins axis_data_fifo_out_«outputMap.get(output)»/S_AXIS]
		connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins axis_data_fifo_out_«outputMap.get(output)»/s_axis_aclk]
		connect_bd_net [get_bd_pins rst_ps7_0_100M/peripheral_aresetn] [get_bd_pins axis_data_fifo_out_«outputMap.get(output)»/s_axis_aresetn]
		«ELSE»
		connect_bd_net [get_bd_pins s_accelerator_0/m«getLongId(outputMap.get(output))»_axis_aclk] [get_bd_pins clk_wiz_1/clk_out1]
		connect_bd_net [get_bd_pins s_accelerator_0/m«getLongId(outputMap.get(output))»_axis_aresetn] [get_bd_pins rst_clk_wiz_1_100M/peripheral_aresetn]
		startgroup
		create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:1.1 axis_data_fifo_out_«outputMap.get(output)»
		endgroup
		connect_bd_intf_net [get_bd_intf_pins s_accelerator_0/m«getLongId(outputMap.get(output))»_axis] [get_bd_intf_pins axis_data_fifo_out_«outputMap.get(output)»/S_AXIS]
		connect_bd_net [get_bd_pins clk_wiz_1/clk_out1] [get_bd_pins axis_data_fifo_out_«outputMap.get(output)»/s_axis_aclk]
		connect_bd_net [get_bd_pins rst_clk_wiz_1_100M/peripheral_aresetn] [get_bd_pins axis_data_fifo_out_«outputMap.get(output)»/s_axis_aresetn]
		«ENDIF»
		«ENDFOR»
		
		«IF enDMA»
		«FOR i : 0..fifoNum-1»
		startgroup
		create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 axi_dma_«i»
		endgroup
		apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/processing_system7_0/M_AXI_GP0" intc_ip "/ps7_0_axi_periph" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins axi_dma_«i»/S_AXI_LITE]
		startgroup
		set_property -dict [list CONFIG.c_include_sg {0} CONFIG.c_sg_include_stscntrl_strm {0}] [get_bd_cells axi_dma_«i»]
		endgroup
		
		startgroup
		set_property -dict [list CONFIG.PCW_USE_S_AXI_HP«i» {1}] [get_bd_cells processing_system7_0]
		endgroup
		
		«IF i < inputMap.size»
		connect_bd_intf_net [get_bd_intf_pins axis_data_fifo_in_«i»/S_AXIS] [get_bd_intf_pins axi_dma_«i»/M_AXIS_MM2S]
		apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/axi_dma_«i»/M_AXI_MM2S" intc_ip "Auto" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins processing_system7_0/S_AXI_HP«i»]
		«ELSE»
		set_property -dict [list CONFIG.c_include_mm2s {0} CONFIG.c_include_s2mm {1}] [get_bd_cells axi_dma_1]
		connect_bd_intf_net [get_bd_intf_pins axis_data_fifo_out_«i»/M_AXIS] [get_bd_intf_pins axi_dma_«i»/S_AXIS_S2MM]
		apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Slave "/processing_system7_0/S_AXI_HP«i»" intc_ip "/axi_smc" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins axi_dma_«i»/M_AXI_S2MM]
		«ENDIF»
		«IF i < outputMap.size»
		connect_bd_intf_net [get_bd_intf_pins axis_data_fifo_out_«i»/M_AXIS] [get_bd_intf_pins axi_dma_«i»/S_AXIS_S2MM]
		apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Slave "/processing_system7_0/S_AXI_HP«i»" intc_ip "/axi_smc" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins axi_dma_«i»/M_AXI_S2MM]
		«ELSE»
		set_property -dict [list CONFIG.c_include_mm2s {1} CONFIG.c_include_s2mm {0}] [get_bd_cells axi_dma_«i»]
		connect_bd_intf_net [get_bd_intf_pins axis_data_fifo_in_«i»/S_AXIS] [get_bd_intf_pins axi_dma_«i»/M_AXIS_MM2S]
		apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/axi_dma_«i»/M_AXI_MM2S" intc_ip "Auto" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins processing_system7_0/S_AXI_HP«i»]
		«ENDIF»
		
		«ENDFOR»
		
		«ELSE»
		«IF coupling.equals("mm")»
			«FOR i : 0..fifoNum-1»
			startgroup
			create_bd_cell -type ip -vlnv xilinx.com:ip:axi_mm2s_mapper:1.1 axi_mm2s_mapper_«i»
			endgroup
			set_property -dict [list CONFIG.INTERFACES {S_AXI}] [get_bd_cells axi_mm2s_mapper_«i»]
			apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/processing_system7_0/M_AXI_GP0" intc_ip "/ps7_0_axi_periph" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins axi_mm2s_mapper_«i»/S_AXI]
			set_property -dict [list CONFIG.TDATA_NUM_BYTES {4}] [get_bd_cells axi_mm2s_mapper_«i»]
			set_property -dict [list CONFIG.ID_WIDTH {12}] [get_bd_cells axi_mm2s_mapper_«i»]
			«IF i < inputMap.size»
			connect_bd_intf_net [get_bd_intf_pins axi_mm2s_mapper_«i»/M_AXIS] [get_bd_intf_pins axis_data_fifo_in_«i»/S_AXIS]
			«ENDIF»
			«IF i < outputMap.size»
			connect_bd_intf_net [get_bd_intf_pins axi_mm2s_mapper_«i»/S_AXIS] [get_bd_intf_pins axis_data_fifo_out_«i»/M_AXIS]
			«ENDIF»
			«ENDFOR»
		«ELSE»
		«FOR i : 0..fifoNum-1»
			«IF i < inputMap.size»
			connect_bd_intf_net [get_bd_intf_pins microblaze_0/S«i»_AXIS] [get_bd_intf_pins axis_data_fifo_out_«i»/M_AXIS]
			«ENDIF»
			«IF i < outputMap.size»
			connect_bd_intf_net [get_bd_intf_pins microblaze_0/M«i»_AXIS] [get_bd_intf_pins axis_data_fifo_in_«i»/S_AXIS]
			«ENDIF»
		«ENDFOR»
		«ENDIF»
		«ENDIF»
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
		set iproot $root/«coupling»_accelerator
		set ipdir $iproot/project_ip
		
		set hdl_files_path $root/«coupling»_accelerator/hdl
		
		set bd_pkg_dir «coupling»_accelerator/bd
		set drivers_dir «coupling»_accelerator/drivers
		
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
		
		create_project -force $design $ipdir -part $partname 
		set_property board_part $boardpart [current_project]
		set_property target_language Verilog [current_project]
		
		add_files $hdl_files_path
		import_files -force
		
		«FOR lib : libraries»
		set files [glob -tails -directory $ipdir/$ip_name.srcs/sources_1/imports/hdl/lib/«lib»/ *]
		foreach f $files {
			set name $f
			set_property library «lib» [get_files  $ipdir/$ip_name.srcs/sources_1/imports/hdl/lib/«lib»/$f]
		        }
		 «ENDFOR»
		
		set_property top $ip_name [current_fileset]
		
		ipx::package_project -root_dir $ipdir -vendor user.org -library user -taxonomy /UserIP
		
		ipx::add_address_block_parameter OFFSET_BASE_PARAM [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps s00_axi -of_objects [ipx::current_core]]]
		ipx::add_address_block_parameter OFFSET_HIGH_PARAM [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps s00_axi -of_objects [ipx::current_core]]]
		set_property value C_CFG_BASEADDR [ipx::get_address_block_parameters OFFSET_BASE_PARAM -of_objects [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps s00_axi -of_objects [ipx::current_core]]]]
		set_property value C_CFG_HIGHADDR [ipx::get_address_block_parameters OFFSET_HIGH_PARAM -of_objects [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps s00_axi -of_objects [ipx::current_core]]]]	
		«IF coupling == "mm"»
		ipx::add_address_block_parameter OFFSET_BASE_PARAM [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps s01_axi -of_objects [ipx::current_core]]]
		ipx::add_address_block_parameter OFFSET_HIGH_PARAM [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps s01_axi -of_objects [ipx::current_core]]]
		set_property value C_MEM_BASEADDR [ipx::get_address_block_parameters OFFSET_BASE_PARAM -of_objects [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps s01_axi -of_objects [ipx::current_core]]]]
		set_property value C_MEM_HIGHADDR [ipx::get_address_block_parameters OFFSET_HIGH_PARAM -of_objects [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps s01_axi -of_objects [ipx::current_core]]]]
			
		set_property enablement_dependency spirit:decode(id('MODELPARAM_VALUE.C_S01_AXI_ID_WIDTH'))>0 [ipx::get_ports s01_axi_awid -of_objects [ipx::current_core]]
		set_property enablement_dependency spirit:decode(id('MODELPARAM_VALUE.C_S01_AXI_AWUSER_WIDTH'))>0 [ipx::get_ports s01_axi_awuser -of_objects [ipx::current_core]]
		set_property enablement_dependency spirit:decode(id('MODELPARAM_VALUE.C_S01_AXI_WUSER_WIDTH'))>0 [ipx::get_ports s01_axi_wuser -of_objects [ipx::current_core]]
		set_property enablement_dependency spirit:decode(id('MODELPARAM_VALUE.C_S01_AXI_BUSER_WIDTH'))>0 [ipx::get_ports s01_axi_buser -of_objects [ipx::current_core]]
		set_property enablement_dependency {spirit:decode(id('MODELPARAM_VALUE.C_S01_AXI_ID_WIDTH')) >0} [ipx::get_ports s01_axi_arid -of_objects [ipx::current_core]]
		set_property enablement_dependency spirit:decode(id('MODELPARAM_VALUE.C_S01_AXI_ARUSER_WIDTH')) [ipx::get_ports s01_axi_aruser -of_objects [ipx::current_core]]
		set_property enablement_dependency spirit:decode(id('MODELPARAM_VALUE.C_S01_AXI_ARUSER_WIDTH'))>0 [ipx::get_ports s01_axi_aruser -of_objects [ipx::current_core]]
		set_property enablement_dependency spirit:decode(id('MODELPARAM_VALUE.C_S01_AXI_RUSER_WIDTH'))>0 [ipx::get_ports s01_axi_ruser -of_objects [ipx::current_core]]
		
		
		
		file copy -force $iproot/bd $ipdir
		set bd_pkg_dir bd
		set bd_group [ipx::add_file_group -type xilinx_blockdiagram {} [ipx::current_core]]
		ipx::add_file $bd_pkg_dir/bd.tcl $bd_group		
		«ENDIF»
		
		file copy -force $iproot/drivers $ipdir
		set drivers_dir drivers
		ipx::add_file_group -type software_driver {} [ipx::current_core]
		ipx::add_file $drivers_dir/src/«coupling»_accelerator.c [ipx::get_file_groups xilinx_softwaredriver -of_objects [ipx::current_core]]
		set_property type cSource [ipx::get_files $drivers_dir/src/«coupling»_accelerator.c -of_objects [ipx::get_file_groups xilinx_softwaredriver -of_objects [ipx::current_core]]]
		ipx::add_file $drivers_dir/src/«coupling»_accelerator.h [ipx::get_file_groups xilinx_softwaredriver -of_objects [ipx::current_core]]
		set_property type cSource [ipx::get_files $drivers_dir/src/«coupling»_accelerator.h -of_objects [ipx::get_file_groups xilinx_softwaredriver -of_objects [ipx::current_core]]]
		ipx::add_file $drivers_dir/src/Makefile [ipx::get_file_groups xilinx_softwaredriver -of_objects [ipx::current_core]]
		set_property type unknown [ipx::get_files $drivers_dir/src/Makefile -of_objects [ipx::get_file_groups xilinx_softwaredriver -of_objects [ipx::current_core]]]
		ipx::add_file $drivers_dir/data/«coupling»_accelerator.tcl [ipx::get_file_groups xilinx_softwaredriver -of_objects [ipx::current_core]]
		set_property type tclSource [ipx::get_files $drivers_dir/data/«coupling»_accelerator.tcl -of_objects [ipx::get_file_groups xilinx_softwaredriver -of_objects [ipx::current_core]]]
		ipx::add_file $drivers_dir/data/«coupling»_accelerator.mdd [ipx::get_file_groups xilinx_softwaredriver -of_objects [ipx::current_core]]
		set_property type mdd [ipx::get_files $drivers_dir/data/«coupling»_accelerator.mdd -of_objects [ipx::get_file_groups xilinx_softwaredriver -of_objects [ipx::current_core]]]
				
		set_property core_revision 3 [ipx::current_core]
		ipx::create_xgui_files [ipx::current_core]
		ipx::update_checksums [ipx::current_core]
		ipx::save_core [ipx::current_core]
		set_property  ip_repo_paths $ipdir [current_project]
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