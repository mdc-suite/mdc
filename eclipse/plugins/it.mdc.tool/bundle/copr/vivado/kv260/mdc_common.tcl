# MDC KV260 helpers. No board programming or driver installation is performed.
namespace eval mdc {
    variable script_dir [file dirname [file normalize [info script]]]
    variable root [file dirname $script_dir]
}
source [file join $mdc::script_dir accelerator_config.tcl]
set fh [open [file join $mdc::root accelerator.json] r]
fconfigure $fh -encoding utf-8 -translation lf
set actual_json [read $fh]
close $fh
if {$actual_json ne $mdc_manifest_json} {
    error "accelerator.json and accelerator_config.tcl differ; regenerate with MDC rather than editing either file"
}
unset actual_json mdc_manifest_json
if {[dict get $mdc_spec schema_version] != 2} {error "Unsupported MDC schema"}
if {[dict get $mdc_spec hardware_plan status] ne "scripts_emitted_not_built"} {error "Not a Step-3 hardware plan"}
if {[llength [dict get $mdc_spec ports]] > 15} {error "At most 15 DMA ports supported by this control fabric"}
proc mdc::require_version {} {
    if {![string match "2024.2*" [version -short]]} {
        error "These scripts target Vivado 2024.2; validate another version explicitly before changing the profile"
    }
}
proc mdc::require_ip {vlnv} {
    if {[llength [get_ipdefs -all -quiet $vlnv]] != 1} {error "Required IP unavailable or ambiguous: $vlnv"}
}
proc mdc::one {objects description} {
    if {[llength $objects] != 1} {error "Expected one $description, found [llength $objects]"}
    return [lindex $objects 0]
}
proc mdc::ipin {name} {return [mdc::one [get_bd_intf_pins -quiet $name] $name]}
proc mdc::pin {name} {return [mdc::one [get_bd_pins -quiet $name] $name]}
proc mdc::wire {driver sinks} {
    foreach sink $sinks {connect_bd_net [mdc::pin $driver] [mdc::pin $sink]}
}
proc mdc::link {a b} {connect_bd_intf_net [mdc::ipin $a] [mdc::ipin $b]}
proc mdc::files_below {dir} {
    set result [list]
    foreach f [lsort [glob -nocomplain -directory $dir *]] {
        if {[file isdirectory $f]} {set result [concat $result [mdc::files_below $f]]} else {lappend result $f}
    }
    return $result
}
proc mdc::read_utf8 {path} {
    set f [open $path r]; fconfigure $f -encoding utf-8 -translation lf
    set s [read $f]; close $f; return $s
}
proc mdc::verify_wrapper {path} {
    global mdc_spec
    set text [mdc::read_utf8 $path]
    set count 0
    foreach p [dict get $mdc_spec ports] {
        set axis [dict get $p axis_interface]
        if {![regexp "${axis}_tdata" $text]} {error "Wrapper is missing $axis"}
        if {[dict get $p direction] eq "output"} {incr count}
    }
    set params [regexp -all -inline {parameter\s+SIZE_COUNT_[0-9]+\s*=\s*([0-9]+)\s*;} $text]
    if {[llength $params] != 2*$count} {error "Wrapper output-counter parameters differ from manifest"}
    foreach {whole width} $params {if {$width != 32} {error "Stale wrapper: regenerate the 32-bit KV260 packet counter"}}
    if {![regexp {C_S00_AXI_ADDR_WIDTH\s*=\s*16} $text]} {error "Stale wrapper: KV260 AXI-Lite address width must be 16"}
}
proc mdc::jobs {} {
    if {[info exists ::env(MDC_JOBS)]} {set n $::env(MDC_JOBS)} else {set n 2}
    if {![string is integer -strict $n] || $n < 1} {error "MDC_JOBS must be a positive integer"}
    return $n
}
proc mdc::require_completed {run} {
    set status [get_property STATUS [get_runs $run]]
    if {![string match "*Complete*" $status] || [string match -nocase "*error*" $status]} {
        error "$run did not complete: $status"
    }
}
# Use a fresh output directory. Existing releases are retained for inspection.
proc mdc::new_run_dir {parent} {
    file mkdir $parent
    set dir [file join $parent "run-[clock seconds]-[pid]-[clock clicks]"]
    file mkdir $dir; return $dir
}
