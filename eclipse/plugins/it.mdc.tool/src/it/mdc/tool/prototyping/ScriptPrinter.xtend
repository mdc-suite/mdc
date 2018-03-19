/*
 *
 */
 
package it.mdc.tool.prototyping

/**
 * Vivado Script Printer
 * 
 * @author Tiziana Fanni
 * @author Carlo Sau
 * 
 */
class ScriptPrinter {
	
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

	def printTopScript() {
		'''
		###########################
		# IP Settings
		###########################
		
		# paths
		
		# user should properly set root path
		set root "project_root"
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
		
		
		startgroup
		create_bd_cell -type ip -vlnv user.org:user:$ip_name:$ip_version $ip_name\_0
		endgroup
		
		
		startgroup
		apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/processing_system7_0/M_AXI_GP0" intc_ip "New AXI Interconnect" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins $ip_name\_0/s00_axi]
		apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/processing_system7_0/M_AXI_GP0" intc_ip "Auto" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins $ip_name\_0/s01_axi]
		endgroup
		
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
		set root "project_root"
		
		set ip_files_path $root//hdl/ip
		set hdl_files_path $root/hdl/rtl
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
		
		add_files $ip_files_path
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
		
		ipx::package_project -root_dir $ipdir -vendor user.org -library user -taxonomy /UserIP
		set_property core_revision 3 [ipx::current_core]
		ipx::create_xgui_files [ipx::current_core]
		ipx::update_checksums [ipx::current_core]
		ipx::save_core [ipx::current_core]
		set_property  ip_repo_paths $ipdir [current_project]
		update_ip_catalog
		close_project
		'''		
	}
	
}