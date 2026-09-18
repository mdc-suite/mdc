# Run from any working directory: vivado -mode batch -source .../generate_ip.tcl
source [file join [file dirname [info script]] mdc_common.tcl]
mdc::require_version
set part [dict get $mdc_spec target part]
set board [dict get $mdc_spec target board_part]
mdc::one [get_board_parts -quiet $board] "installed board part $board"
set source_hdl [file join $mdc::root s_accelerator hdl]
mdc::verify_wrapper [file join $source_hdl s_accelerator.v]
set ip_run [mdc::new_run_dir [file join $mdc::root build ip]]
set package_dir [file join $ip_run acc_ip]
file mkdir $package_dir
file copy $source_hdl [file join $package_dir hdl]
create_project s_accelerator [file join $ip_run project] -part $part
set_property board_part $board [current_project]
set_property target_language Verilog [current_project]
set source_count 0
foreach f [mdc::files_below [file join $package_dir hdl]] {
    set ext [string tolower [file extension $f]]
    if {$ext in {.v .sv .vh .svh .vhd .vhdl .mem .dat .xci .xcix}} {
        add_files -norecurse $f
        incr source_count
        if {$ext in {.vhd .vhdl} && [regexp {/lib/([^/]+)/} [string map {\\ /} $f] -> lib]} {
            set_property library $lib [get_files $f]
        }
    } elseif {$ext eq ".tcl"} {
        # IP-generation Tcl may introduce files outside the package. Require
        # pre-generated XCI/XCIX instead of silently producing a nonportable IP.
        error "HDL library contains executable Tcl ($f). Generate its IP as XCI/XCIX before packaging this profile."
    }
}
if {$source_count == 0} {error "No HDL sources found"}
set_property top s_accelerator [current_fileset]
update_compile_order -fileset sources_1
# All sources are already inside package_dir; deliberately avoid import_files.
ipx::package_project -root_dir $package_dir -vendor user.org -library user -taxonomy /UserIP -set_current true
set core [ipx::current_core]
set_property name s_accelerator $core
set_property version 1.0 $core
set_property core_revision 4 $core
set mm [mdc::one [ipx::get_memory_maps s00_axi -of_objects $core] "s00_axi memory map"]
foreach b [ipx::get_address_blocks -of_objects $mm] {ipx::remove_address_block [get_property NAME $b] $mm}
set block [ipx::add_address_block s00_axi_reg $mm]
set_property usage register $block
set_property base_address 0 $block
set_property range [dict get $mdc_spec hardware_plan control_range_bytes] $block
set_property width 32 $block
set bus_names [list s00_axi]
foreach p [dict get $mdc_spec ports] {lappend bus_names [dict get $p axis_interface]}
foreach bus $bus_names {
    mdc::one [ipx::get_bus_interfaces $bus -of_objects $core] "$bus interface"
    ipx::associate_bus_interfaces -busif $bus -clock ${bus}_aclk $core
    set clock_if [mdc::one [ipx::get_bus_interfaces ${bus}_aclk -of_objects $core] "$bus clock interface"]
    set assoc [ipx::get_bus_parameters ASSOCIATED_RESET -of_objects $clock_if]
    if {[llength $assoc] == 0} {set assoc [ipx::add_bus_parameter ASSOCIATED_RESET $clock_if]}
    set_property value ${bus}_aresetn $assoc
}
ipx::create_xgui_files $core
# Resolve every IP-XACT file relative to the package, then enforce containment.
# This detects the previous ../project.srcs portability failure.
foreach group [ipx::get_file_groups -of_objects $core] {
    foreach f [ipx::get_files -of_objects $group] {
        set name [get_property NAME $f]
        set absolute [file normalize [file join $package_dir $name]]
        set prefix "[file normalize $package_dir]/"
        if {[string first $prefix $absolute] != 0 || ![file isfile $absolute]} {
            error "Nonportable or missing IP-XACT file: $name"
        }
        set_property name [string range $absolute [string length $prefix] end] $f
    }
}
ipx::check_integrity $core
ipx::update_checksums $core
ipx::save_core $core
file copy [file join $mdc::root accelerator.json] [file join $package_dir accelerator.json]
close_project
# Publish the pointer only after packaging succeeds; previous runs are retained.
set pointer [file join $mdc::root scripts packaged_ip.path]
set fp [open ${pointer}.tmp w]; puts $fp $package_dir; close $fp
file rename -force ${pointer}.tmp $pointer
puts "MDC packaged IP: $package_dir"
