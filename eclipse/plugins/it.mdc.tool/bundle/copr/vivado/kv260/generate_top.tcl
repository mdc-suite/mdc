# Build the hardware described by the shared CoprocessorSpec.
source [file join [file dirname [info script]] mdc_common.tcl]
mdc::require_version
set pointer [file join $mdc::script_dir packaged_ip.path]
set package_dir [string trim [mdc::read_utf8 $pointer]]
if {[mdc::read_utf8 [file join $package_dir accelerator.json]] ne [mdc::read_utf8 [file join $mdc::root accelerator.json]]} {
    error "Packaged IP uses a different specification; run generate_ip.tcl again"
}
set plan [dict get $mdc_spec hardware_plan]
set dmas [dict get $plan dma_controllers]
set count [llength $dmas]
set board [dict get $mdc_spec target board_part]
mdc::one [get_board_parts -quiet $board] "installed board part $board"
set top_run [mdc::new_run_dir [file join $mdc::root build top]]
create_project mdc_kv260 [file join $top_run project] -part [dict get $mdc_spec target part]
set_property board_part $board [current_project]
set_property ip_repo_paths [list $package_dir] [current_project]
update_ip_catalog
foreach vlnv {xilinx.com:ip:zynq_ultra_ps_e:3.5 xilinx.com:ip:axi_dma:7.1 xilinx.com:ip:smartconnect:1.0 xilinx.com:ip:axi_interconnect:2.1 xilinx.com:ip:proc_sys_reset:5.0 xilinx.com:ip:xlconstant:1.1 user.org:user:s_accelerator:1.0} {
    mdc::require_ip $vlnv
}
create_bd_design design_1
create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e:3.5 ps
apply_bd_automation -rule xilinx.com:bd_rule:zynq_ultra_ps_e -config {apply_board_preset "1"} [get_bd_cells ps]
set_property -dict [list CONFIG.PSU__USE__M_AXI_GP0 {1} CONFIG.PSU__USE__M_AXI_GP1 {1} CONFIG.PSU__USE__M_AXI_GP2 {0} CONFIG.PSU__USE__S_AXI_GP0 {1} CONFIG.PSU__SAXIGP0__DATA_WIDTH {128} CONFIG.PSU__FPGA_PL0_ENABLE {1} CONFIG.PSU__CRL_APB__PL0_REF_CTRL__FREQMHZ [dict get $plan clock_mhz]] [get_bd_cells ps]
create_bd_cell -type ip -vlnv user.org:user:s_accelerator:1.0 accelerator
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 control
set_property -dict [list CONFIG.NUM_SI 2 CONFIG.NUM_MI [expr {$count+1}]] [get_bd_cells control]
create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 memory
set_property -dict [list CONFIG.NUM_SI $count CONFIG.NUM_MI 1] [get_bd_cells memory]
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 reset
# PS reset is active-low; auxiliary reset is tied to zero below and must be active-high.
set_property -dict [list CONFIG.C_EXT_RESET_HIGH 0 CONFIG.C_AUX_RESET_HIGH 1] [get_bd_cells reset]
foreach {name width value} {zero 1 0 one 1 1 zero32 32 0} {
    create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 $name
    set_property -dict [list CONFIG.CONST_WIDTH $width CONFIG.CONST_VAL $value] [get_bd_cells $name]
}
mdc::wire ps/pl_clk0 {ps/maxihpm0_fpd_aclk ps/maxihpm1_fpd_aclk ps/saxihpc0_fpd_aclk control/ACLK control/S00_ACLK control/S01_ACLK memory/aclk reset/slowest_sync_clk accelerator/s00_axi_aclk}
mdc::wire ps/pl_resetn0 {reset/ext_reset_in}
mdc::wire zero/dout {reset/aux_reset_in reset/mb_debug_sys_rst}
mdc::wire one/dout {reset/dcm_locked}
mdc::wire reset/interconnect_aresetn {control/ARESETN control/S00_ARESETN control/S01_ARESETN memory/aresetn}
mdc::wire reset/peripheral_aresetn {accelerator/s00_axi_aresetn}
mdc::link ps/M_AXI_HPM0_FPD control/S00_AXI
mdc::link ps/M_AXI_HPM1_FPD control/S01_AXI
mdc::link memory/M00_AXI ps/S_AXI_HPC0_FPD
set i 0
foreach d $dmas p [dict get $mdc_spec ports] {
    if {[dict get $d port_id] ne [dict get $p id]} {error "DMA/port identity mismatch"}
    set dma [dict get $d controller]
    set axis [dict get $p axis_interface]
    set tx [expr {[dict get $d direction] eq "MM2S"}]
    create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 $dma
    set_property -dict [list CONFIG.c_include_sg 0 CONFIG.c_sg_include_stscntrl_strm 0 CONFIG.c_addr_width [dict get $plan dma_address_bits] CONFIG.c_sg_length_width [dict get $plan dma_length_bits] CONFIG.c_include_mm2s $tx CONFIG.c_include_s2mm [expr {!$tx}]] [get_bd_cells $dma]
    set mi [format M%02d $i]
    set si [format S%02d $i]
    mdc::link control/${mi}_AXI $dma/S_AXI_LITE
    mdc::wire ps/pl_clk0 [list control/${mi}_ACLK $dma/s_axi_lite_aclk accelerator/${axis}_aclk]
    mdc::wire reset/interconnect_aresetn [list control/${mi}_ARESETN]
    mdc::wire reset/peripheral_aresetn [list $dma/axi_resetn accelerator/${axis}_aresetn]
    if {$tx} {
        set_property -dict [list CONFIG.c_m_axi_mm2s_data_width 32 CONFIG.c_m_axis_mm2s_tdata_width 32] [get_bd_cells $dma]
        mdc::link $dma/M_AXI_MM2S memory/${si}_AXI
        mdc::link $dma/M_AXIS_MM2S accelerator/$axis
        mdc::wire ps/pl_clk0 [list $dma/m_axi_mm2s_aclk]
        mdc::wire zero32/dout [list accelerator/${axis}_data_count]
        set data_space $dma/Data_MM2S
    } else {
        set_property -dict [list CONFIG.c_m_axi_s2mm_data_width 32 CONFIG.c_s_axis_s2mm_tdata_width 32] [get_bd_cells $dma]
        mdc::link $dma/M_AXI_S2MM memory/${si}_AXI
        mdc::link accelerator/$axis $dma/S_AXIS_S2MM
        mdc::wire ps/pl_clk0 [list $dma/m_axi_s2mm_aclk]
        set data_space $dma/Data_S2MM
    }
    assign_bd_address -offset [dict get $d base_address] -range [dict get $d range_bytes] -target_address_space [get_bd_addr_spaces ps/Data] [get_bd_addr_segs $dma/S_AXI_LITE/Reg] -force
    # Deliberately map only low DDR for the current 32-bit DMA allocation ABI.
    assign_bd_address -offset [dict get $plan ddr_low_base] -range [dict get $plan ddr_low_range] -target_address_space [get_bd_addr_spaces $data_space] [get_bd_addr_segs ps/SAXIGP0/HPC0_DDR_LOW] -force
    incr i
}
set mi [format M%02d $count]
mdc::link control/${mi}_AXI accelerator/s00_axi
mdc::wire ps/pl_clk0 [list control/${mi}_ACLK]
mdc::wire reset/interconnect_aresetn [list control/${mi}_ARESETN]
assign_bd_address -offset [dict get $plan control_base_address] -range [dict get $plan control_range_bytes] -target_address_space [get_bd_addr_spaces ps/Data] [get_bd_addr_segs accelerator/s00_axi/s00_axi_reg] -force
validate_bd_design
save_bd_design
set bd [mdc::one [get_files */design_1.bd] "design_1.bd"]
write_bd_tcl [file join $top_run design_1.tcl]
file copy [file join $mdc::root accelerator.json] [file join $top_run accelerator.json]
if {[info exists ::env(MDC_BD_ONLY)] && $::env(MDC_BD_ONLY) eq "1"} {
    puts "MDC block design validated (no bitstream): $top_run"
    close_project
} else {
    generate_target all $bd
    set wrapper [make_wrapper -files $bd -top]
    add_files -norecurse $wrapper
    set_property top design_1_wrapper [current_fileset]
    update_compile_order -fileset sources_1
    launch_runs synth_1 -jobs [mdc::jobs]
    wait_on_run synth_1
    mdc::require_completed synth_1
    launch_runs impl_1 -to_step write_bitstream -jobs [mdc::jobs]
    wait_on_run impl_1
    mdc::require_completed impl_1
    open_run impl_1
    report_timing_summary -file [file join $top_run timing_summary.rpt]
    report_drc -file [file join $top_run drc.rpt]
    foreach type {max min} {
        set paths [get_timing_paths -delay_type $type -max_paths 1]
        if {[llength $paths] == 0 || [get_property SLACK [lindex $paths 0]] < 0} {error "Missing or failing $type timing; inspect $top_run"}
    }
    set bit [file join [get_property DIRECTORY [get_runs impl_1]] design_1_wrapper.bit]
    if {![file isfile $bit]} {error "Implementation produced no bitstream"}
    file copy $bit [file join $top_run design_1_wrapper.bit]
    write_hw_platform -fixed -include_bit -force -file [file join $top_run design_1_wrapper.xsa]
    set f [open [file join $top_run HARDWARE_BUILD_COMPLETE] w]
    puts $f "Hardware build completed; Linux driver/application integration remains a separate step."
    close $f
    puts "MDC hardware build: $top_run"
    close_project
}
