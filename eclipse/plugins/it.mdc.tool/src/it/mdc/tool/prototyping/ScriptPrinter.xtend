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
	protected boolean enDma = false;
	
	//TODO boardpart refine input (not always a board is selected)
	String boardpart
	String partname
	String coupling
	List<String> libraries
	String processor

	def initScriptPrinter(List<String> libraries, String coupling, String processor, Boolean enDma,
							String boardpart, String partname
	){
		this.boardpart = boardpart;
		this.partname = partname;
		this.coupling = coupling;
		this.libraries = libraries;
		this.processor = processor;
		this.enDma = enDma;
	}
	
	def isMemoryMapped(){
		if(coupling.equals("mm")) {
			return true
		} else {
			return false
		}
	}
	
	def isArm(){
		if(processor.equals("ARM")) {
			return true
		} else {
			return false
		}
	}

	def printTopScript(Network network) {
		mapInOut(network);
		'''
		# Script compliant with Vivado 2017.1
		
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
		
		«IF boardpart!="none"»
		# Board part
		set boardpart "«boardpart»"
		«ENDIF»
		
		# Design name
		set design system
		set bd_design "design_1"
		
		set ip_name "«coupling»_accelerator"
		set ip_version "1.0"
		set ip_v "v1_0"
		
		
		###########################
		# Create Project
		###########################
		create_project -force $design $projdir -part $partname 
		«IF boardpart!="none"»set_property board_part $boardpart [current_project]«ENDIF»
		set_property target_language Verilog [current_project]
		set_property  ip_repo_paths $ipdir [current_project]
		update_ip_catalog -rebuild -scan_changes
		###########################
		#create block design
		create_bd_design $bd_design
		
		«IF isArm»
			# Zynq PS
			create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0
			apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable" }  [get_bd_cells processing_system7_0]
			connect_bd_net [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK] [get_bd_pins processing_system7_0/FCLK_CLK0]
		«ELSE»
			# MicroBlaze
			create_bd_cell -type ip -vlnv xilinx.com:ip:microblaze:10.0 microblaze_0
			apply_bd_automation -rule xilinx.com:bd_rule:microblaze -config {preset "None" local_mem "8KB" ecc "None" cache "None" debug_module "Debug Only" axi_periph "Enabled" axi_intc "0" clk "New Clocking Wizard (100 MHz)" }  [get_bd_cells microblaze_0]
			set_property -dict [list CONFIG.PRIM_SOURCE {Single_ended_clock_capable_pin} CONFIG.USE_LOCKED {false} CONFIG.USE_RESET {false}] [get_bd_cells clk_wiz_1]
			delete_bd_objs [get_bd_nets clk_wiz_1_locked]
			apply_bd_automation -rule xilinx.com:bd_rule:board -config {Board_Interface "sys_clock ( System clock ) " }  [get_bd_pins clk_wiz_1/clk_in1]
			apply_bd_automation -rule xilinx.com:bd_rule:board -config {rst_polarity "ACTIVE_LOW" }  [get_bd_pins rst_clk_wiz_1_100M/ext_reset_in]
			set_property -dict [list CONFIG.C_FSL_LINKS {«IF inputMap.size>outputMap.size»«inputMap.size»«ELSE»«outputMap.size»«ENDIF»}] [get_bd_cells microblaze_0]
		«ENDIF»
		
		# accelerator IP
		create_bd_cell -type ip -vlnv user.org:user:$ip_name:$ip_version $ip_name\_0
		«IF isArm»
			apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/processing_system7_0/M_AXI_GP0" intc_ip "New AXI Interconnect" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins $ip_name\_0/s00_axi]
		«ELSE»
			apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/microblaze_0 (Periph)" intc_ip "New AXI Interconnect" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins $ip_name\_0/s00_axi]
		«ENDIF»				
		««« not parametric!!! mm_accelerator_reg
		«IF isMemoryMapped»		
			«IF isArm»
				«IF enDma»
					# CDMA
					create_bd_cell -type ip -vlnv xilinx.com:ip:axi_cdma:4.1 axi_cdma_0
					set_property -dict [list CONFIG.C_INCLUDE_SG {0}] [get_bd_cells axi_cdma_0]
					apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/processing_system7_0/M_AXI_GP0" intc_ip "/ps7_0_axi_periph" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins axi_cdma_0/S_AXI_LITE]
					set_property -dict [list CONFIG.PCW_USE_S_AXI_HP0 {1}] [get_bd_cells processing_system7_0]
					apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/axi_cdma_0/M_AXI" intc_ip "New AXI Interconnect" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins mm_accelerator_0/s01_axi]
					apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/axi_cdma_0/M_AXI" intc_ip "/axi_mem_intercon" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins processing_system7_0/S_AXI_HP0]
				«ELSE»
					apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/processing_system7_0/M_AXI_GP0" intc_ip "Auto" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins $ip_name\_0/s01_axi]
				«ENDIF»
			«ELSE»
				apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/microblaze_0 (Periph)" intc_ip "Auto" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins mm_accelerator_0/s01_axi]		
				«IF enDma»
					# AXI controlled BRAM
					create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.0 axi_bram_ctrl_0
					apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/microblaze_0 (Periph)" intc_ip "/microblaze_0_axi_periph" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]
					apply_bd_automation -rule xilinx.com:bd_rule:bram_cntlr -config {BRAM "Auto" }  [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA]
					apply_bd_automation -rule xilinx.com:bd_rule:bram_cntlr -config {BRAM "Auto" }  [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTB]
					# CDMA
					create_bd_cell -type ip -vlnv xilinx.com:ip:axi_cdma:4.1 axi_cdma_0
					set_property -dict [list CONFIG.C_INCLUDE_SG {0}] [get_bd_cells axi_cdma_0]
					apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Slave "/axi_bram_ctrl_0/S_AXI" intc_ip "/microblaze_0_axi_periph" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins axi_cdma_0/M_AXI]
					apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/microblaze_0 (Periph)" intc_ip "/microblaze_0_axi_periph" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins axi_cdma_0/S_AXI_LITE]
					include_bd_addr_seg [get_bd_addr_segs -excluded axi_cdma_0/Data/SEG_mm_accelerator_0_reg03]
				«ENDIF»
			«ENDIF»
		«ELSE»

			# fifos - accelerator side
			«FOR input : inputMap.keySet()»
				# fifo_in «inputMap.get(input)»
				«IF isArm»
					connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins s_accelerator_0/s«getLongId(inputMap.get(input))»_axis_aclk]
					connect_bd_net [get_bd_pins rst_ps7_0_100M/peripheral_aresetn] [get_bd_pins s_accelerator_0/s«getLongId(inputMap.get(input))»_axis_aresetn]
					«IF enDma»
						create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:1.1 axis_data_fifo_in_«inputMap.get(input)»
						connect_bd_intf_net [get_bd_intf_pins axis_data_fifo_in_«inputMap.get(input)»/M_AXIS] [get_bd_intf_pins s_accelerator_0/s«getLongId(inputMap.get(input))»_axis]
						connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins axis_data_fifo_in_«inputMap.get(input)»/s_axis_aclk]
						connect_bd_net [get_bd_pins rst_ps7_0_100M/peripheral_aresetn] [get_bd_pins axis_data_fifo_in_«inputMap.get(input)»/s_axis_aresetn]
					«ENDIF»
				«ELSE»
					connect_bd_net [get_bd_pins s_accelerator_0/s«getLongId(inputMap.get(input))»_axis_aclk] [get_bd_pins clk_wiz_1/clk_out1]
					connect_bd_net [get_bd_pins s_accelerator_0/s«getLongId(inputMap.get(input))»_axis_aresetn] [get_bd_pins rst_clk_wiz_1_100M/peripheral_aresetn]
					create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:1.1 axis_data_fifo_in_«inputMap.get(input)»
					connect_bd_intf_net [get_bd_intf_pins axis_data_fifo_in_«inputMap.get(input)»/M_AXIS] [get_bd_intf_pins s_accelerator_0/s«getLongId(inputMap.get(input))»_axis]
					connect_bd_net [get_bd_pins clk_wiz_1/clk_out1] [get_bd_pins axis_data_fifo_in_«inputMap.get(input)»/s_axis_aclk]
					connect_bd_net [get_bd_pins rst_clk_wiz_1_100M/peripheral_aresetn] [get_bd_pins axis_data_fifo_in_«inputMap.get(input)»/s_axis_aresetn]
				«ENDIF»
			«ENDFOR»
			
			«FOR output : outputMap.keySet()»
				# fifo_out «inputMap.get(output)»
				«IF isArm»
					connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins s_accelerator_0/m«getLongId(outputMap.get(output))»_axis_aclk]
					connect_bd_net [get_bd_pins rst_ps7_0_100M/peripheral_aresetn] [get_bd_pins s_accelerator_0/m«getLongId(outputMap.get(output))»_axis_aresetn]	
					«IF enDma»
						create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:1.1 axis_data_fifo_out_«outputMap.get(output)»
						connect_bd_intf_net [get_bd_intf_pins s_accelerator_0/m«getLongId(outputMap.get(output))»_axis] [get_bd_intf_pins axis_data_fifo_out_«outputMap.get(output)»/S_AXIS]
						connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins axis_data_fifo_out_«outputMap.get(output)»/s_axis_aclk]
						connect_bd_net [get_bd_pins rst_ps7_0_100M/peripheral_aresetn] [get_bd_pins axis_data_fifo_out_«outputMap.get(output)»/s_axis_aresetn]
					«ENDIF»
				«ELSE»
					connect_bd_net [get_bd_pins s_accelerator_0/m«getLongId(outputMap.get(output))»_axis_aclk] [get_bd_pins clk_wiz_1/clk_out1]
					connect_bd_net [get_bd_pins s_accelerator_0/m«getLongId(outputMap.get(output))»_axis_aresetn] [get_bd_pins rst_clk_wiz_1_100M/peripheral_aresetn]
					create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:1.1 axis_data_fifo_out_«outputMap.get(output)»
					connect_bd_intf_net [get_bd_intf_pins s_accelerator_0/m«getLongId(outputMap.get(output))»_axis] [get_bd_intf_pins axis_data_fifo_out_«outputMap.get(output)»/S_AXIS]
					connect_bd_net [get_bd_pins clk_wiz_1/clk_out1] [get_bd_pins axis_data_fifo_out_«outputMap.get(output)»/s_axis_aclk]
					connect_bd_net [get_bd_pins rst_clk_wiz_1_100M/peripheral_aresetn] [get_bd_pins axis_data_fifo_out_«outputMap.get(output)»/s_axis_aresetn]
				«ENDIF»
			«ENDFOR»
			
			# fifos - processor side
			«IF enDma»
				«IF isArm»
					«FOR i : 0..fifoNum-1»
						# DMA «i»
						create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 axi_dma_«i»
						apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/processing_system7_0/M_AXI_GP0" intc_ip "/ps7_0_axi_periph" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins axi_dma_«i»/S_AXI_LITE]
						set_property -dict [list CONFIG.c_include_sg {0} CONFIG.c_sg_include_stscntrl_strm {0}] [get_bd_cells axi_dma_«i»]
						set_property -dict [list CONFIG.PCW_USE_S_AXI_HP«i» {1}] [get_bd_cells processing_system7_0]			
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
					# AXI controlled BRAM
					create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.0 axi_bram_ctrl_0
					apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/microblaze_0 (Periph)" intc_ip "/microblaze_0_axi_periph" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]
					apply_bd_automation -rule xilinx.com:bd_rule:bram_cntlr -config {BRAM "Auto" }  [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA]
					apply_bd_automation -rule xilinx.com:bd_rule:bram_cntlr -config {BRAM "Auto" }  [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTB]
					«FOR i : 0..fifoNum-1»
						# DMA «i»
						create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 axi_dma_«i»
						set_property -dict [list CONFIG.c_include_sg {0} CONFIG.c_sg_include_stscntrl_strm {0}] [get_bd_cells axi_dma_«i»]
						apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/microblaze_0 (Periph)" intc_ip "/microblaze_0_axi_periph" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins axi_dma_«i»/S_AXI_LITE]
						«IF i < inputMap.size»
							apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Slave "/axi_bram_ctrl_0/S_AXI" intc_ip "/microblaze_0_axi_periph" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins axi_dma_«i»/M_AXI_MM2S]
							connect_bd_intf_net [get_bd_intf_pins axis_data_fifo_in_«i»/S_AXIS] [get_bd_intf_pins axi_dma_«i»/M_AXIS_MM2S]
						«ENDIF»
						«IF i < outputMap.size»
							apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Slave "/axi_bram_ctrl_0/S_AXI" intc_ip "/microblaze_0_axi_periph" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins axi_dma_«i»/M_AXI_S2MM]
							connect_bd_intf_net [get_bd_intf_pins axis_data_fifo_out_«i»/M_AXIS] [get_bd_intf_pins axi_dma_«i»/S_AXIS_S2MM]
						«ENDIF»
					«ENDFOR»
				«ENDIF»
			«ELSE»
				«IF isArm»
					«FOR i : 0..fifoNum-1»
						create_bd_cell -type ip -vlnv xilinx.com:ip:axi_fifo_mm_s:4.1 axi_fifo_mm_s_«i»
						set_property -dict [list CONFIG.C_USE_TX_CTRL {0}] [get_bd_cells axi_fifo_mm_s_«i»]
						set_property -dict [list CONFIG.C_DATA_INTERFACE_TYPE {1}] [get_bd_cells axi_fifo_mm_s_«i»]
						apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/processing_system7_0/M_AXI_GP0" intc_ip "/ps7_0_axi_periph" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins axi_fifo_mm_s_«i»/S_AXI]
						apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/processing_system7_0/M_AXI_GP0" intc_ip "/ps7_0_axi_periph" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins axi_fifo_mm_s_«i»/S_AXI_FULL]
						«IF i < inputMap.size»
							connect_bd_intf_net [get_bd_intf_pins axi_fifo_mm_s_«i»/AXI_STR_TXD] [get_bd_intf_pins s_accelerator_0/s«getLongId(i)»_axis]
						«ELSE»
							set_property -dict [list CONFIG.C_USE_TX_DATA {0}] [get_bd_cells axi_fifo_mm_s_«i»]
						«ENDIF»
						«IF i < outputMap.size»
							connect_bd_intf_net [get_bd_intf_pins s_accelerator_0/m«getLongId(i)»_axis] [get_bd_intf_pins axi_fifo_mm_s_«i»/AXI_STR_RXD]
						«ELSE»
							set_property -dict [list CONFIG.C_USE_RX_DATA {0}] [get_bd_cells axi_fifo_mm_s_«i»]
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
		
		generate_target all [get_files  $projdir/$design.srcs/sources_1/bd/design_1/design_1.bd]
		'''
	}
	
	
		
	def printIpScript() {
		'''
		# Script compliant with Vivado 2017.1
		
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
		
		
		«IF boardpart != "none"»
		# Board part
		set boardpart "«boardpart»"
		«ENDIF»
		
		# Design name
		set ip_name "«coupling»_accelerator"
		set design $ip_name
		
		###########################
		# Create IP
		###########################
		
		create_project -force $design $ipdir -part $partname 
		«IF boardpart != "none"»set_property board_part $boardpart [current_project]«ENDIF»
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
		
		if {[llength [glob -nocomplain -dir $hdl_files_path *.dat]] != 0} {
			foreach dat_file [glob -dir $hdl_files_path *.dat] {
				import_file $dat_file
			}
		}
		
		if {[llength [glob -nocomplain -dir $hdl_files_path *.mem]] != 0} {
			foreach mem_file [glob -dir $hdl_files_path *.mem] {
				import_file $mem_file
			}
		}
		
		if {[llength [glob -nocomplain -dir $hdl_files_path *.tcl]] != 0} {
			 foreach tcl_file [glob -dir $hdl_files_path *.tcl] {
			     source $tcl_file
			}
		}
		
		set_property top $ip_name [current_fileset]
		
		ipx::package_project -root_dir $ipdir -vendor user.org -library user -taxonomy AXI_Peripheral
		
		ipx::remove_address_block reg0 [ipx::get_memory_maps s00_axi -of_objects [ipx::current_core]]
		ipx::add_address_block s00_axi_reg [ipx::get_memory_maps s00_axi -of_objects [ipx::current_core]]
		set_property usage register [ipx::get_address_blocks s00_axi_reg -of_objects [ipx::get_memory_maps s00_axi -of_objects [ipx::current_core]]]
		ipx::add_address_block_parameter OFFSET_BASE_PARAM [ipx::get_address_blocks s00_axi_reg -of_objects [ipx::get_memory_maps s00_axi -of_objects [ipx::current_core]]]
		ipx::add_address_block_parameter OFFSET_HIGH_PARAM [ipx::get_address_blocks s00_axi_reg -of_objects [ipx::get_memory_maps s00_axi -of_objects [ipx::current_core]]]
		set_property value C_CFG_BASEADDR [ipx::get_address_block_parameters OFFSET_BASE_PARAM -of_objects [ipx::get_address_blocks s00_axi_reg -of_objects [ipx::get_memory_maps s00_axi -of_objects [ipx::current_core]]]]
		set_property value C_CFG_HIGHADDR [ipx::get_address_block_parameters OFFSET_HIGH_PARAM -of_objects [ipx::get_address_blocks s00_axi_reg -of_objects [ipx::get_memory_maps s00_axi -of_objects [ipx::current_core]]]]	
		«IF isMemoryMapped»
		ipx::remove_address_block reg0 [ipx::get_memory_maps s01_axi -of_objects [ipx::current_core]]
		ipx::add_address_block s01_axi_mem [ipx::get_memory_maps s01_axi -of_objects [ipx::current_core]]
		set_property usage memory [ipx::get_address_blocks s01_axi_mem -of_objects [ipx::get_memory_maps s01_axi -of_objects [ipx::current_core]]]
		ipx::add_address_block_parameter OFFSET_BASE_PARAM [ipx::get_address_blocks s01_axi_mem -of_objects [ipx::get_memory_maps s01_axi -of_objects [ipx::current_core]]]
		ipx::add_address_block_parameter OFFSET_HIGH_PARAM [ipx::get_address_blocks s01_axi_mem -of_objects [ipx::get_memory_maps s01_axi -of_objects [ipx::current_core]]]
		set_property value C_MEM_BASEADDR [ipx::get_address_block_parameters OFFSET_BASE_PARAM -of_objects [ipx::get_address_blocks s01_axi_mem -of_objects [ipx::get_memory_maps s01_axi -of_objects [ipx::current_core]]]]
		set_property value C_MEM_HIGHADDR [ipx::get_address_block_parameters OFFSET_HIGH_PARAM -of_objects [ipx::get_address_blocks s01_axi_mem -of_objects [ipx::get_memory_maps s01_axi -of_objects [ipx::current_core]]]]
			
		set_property enablement_dependency spirit:decode(id('MODELPARAM_VALUE.C_S01_AXI_ID_WIDTH'))>0 [ipx::get_ports s01_axi_awid -of_objects [ipx::current_core]]
		set_property enablement_dependency spirit:decode(id('MODELPARAM_VALUE.C_S01_AXI_AWUSER_WIDTH'))>0 [ipx::get_ports s01_axi_awuser -of_objects [ipx::current_core]]
		set_property enablement_dependency spirit:decode(id('MODELPARAM_VALUE.C_S01_AXI_WUSER_WIDTH'))>0 [ipx::get_ports s01_axi_wuser -of_objects [ipx::current_core]]
		set_property enablement_dependency spirit:decode(id('MODELPARAM_VALUE.C_S01_AXI_ID_WIDTH'))>0 [ipx::get_ports s01_axi_bid -of_objects [ipx::current_core]]
		set_property enablement_dependency spirit:decode(id('MODELPARAM_VALUE.C_S01_AXI_BUSER_WIDTH'))>0 [ipx::get_ports s01_axi_buser -of_objects [ipx::current_core]]
		set_property enablement_dependency {spirit:decode(id('MODELPARAM_VALUE.C_S01_AXI_ID_WIDTH')) >0} [ipx::get_ports s01_axi_arid -of_objects [ipx::current_core]]
		set_property enablement_dependency spirit:decode(id('MODELPARAM_VALUE.C_S01_AXI_ARUSER_WIDTH')) [ipx::get_ports s01_axi_aruser -of_objects [ipx::current_core]]
		set_property enablement_dependency spirit:decode(id('MODELPARAM_VALUE.C_S01_AXI_ARUSER_WIDTH'))>0 [ipx::get_ports s01_axi_aruser -of_objects [ipx::current_core]]
		set_property enablement_dependency spirit:decode(id('MODELPARAM_VALUE.C_S01_AXI_ID_WIDTH'))>0 [ipx::get_ports s01_axi_rid -of_objects [ipx::current_core]]
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