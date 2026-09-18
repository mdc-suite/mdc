# Vivado batch exits nonzero on a caught failure, including nested sourced scripts.
set mdc_script_dir [file dirname [file normalize [info script]]]
if {[catch {
    source [file join $mdc_script_dir generate_ip.tcl]
    source [file join $mdc_script_dir generate_top.tcl]
} message options]} {
    puts stderr "MDC KV260 build failed: $message"
    puts stderr [dict get $options -errorinfo]
    exit 1
}
