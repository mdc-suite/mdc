# MDC Release notes

## Release version 0.0.4
<<<<<<< HEAD
xxxx.xx.xx

### New features
- Added support for *.mem files in system generation
- Added support for monitoring of FIFO signals (through "monitor_in" attribute on dataflow connections)
- Added support for US+ in prototyping (tested for ARM, DMA, mm and stream)

### Changes
- Fixed bug on report printer while selecting system generation 
- Fixed bug on system generation scripts (when no *.dat and no *.tcl files are in the hardware components library)
- Fixed bug on library extraction for system generation
- Clean version of network printer generic (protocol management methods moved to ProtocolManager)
=======
XXXX.XX.XX

### New features
- 

### Changes
- protocols and test folders moved to another repo (mdc-apps)
>>>>>>> refs/remotes/origin/develop

## Release version 0.0.3
2021.01.19

### New features
- Added new CNN project to the available applications under test folder.

### Changes
- Vivado HLS protocol has been updated according to the latest modification on the corresponding HCL.

## Release version 0.0.2
2021.01.14

### New features
- Added support for dynamic parameters, which are inputs to the multi-dataflow datapath not corresponding to dataflow connections neither compliant with dataflow communication protocol. They are, typically, parameters which may change during execution. They have to be specified both as parameters of the XDF network and as parameters of the actors receiving them (matching names decides their connection). At the moment only multi-dataflow datapath and test bench are aligned with the dynamic parameters.

### Changes
- Static parameters, which were already supported and which are parameters assigned at design time (reflecting Verilog parameters), can still be specified as parameters of the actors: if there are matching name variables of the XDF network they are hierarchically assigned from the top multi-dataflow datapath, if not they are assigned according to the actor instance default value specified in the XDF network or inside the actor CAL description.
- Uniform printing has been introduced, to process the list of XDF networks to be merged always in the same order, thus avoiding differences in the resulting multi-dataflow network and datapath.

### Bugs fixed
 

## Release version 0.0.1
2020.12.14

### New features
- Merging algorithms supported: Empiric and Moreano Heruistic (according to [1]).
- Code generation of multi-dataflow networks (already merged).
- Code generation of standalone accelerators (HDL).
- Power optimization through clock- and power-gating (only for standalone accelerators)
- System generation: including co-processor in the system (only for Xilinx Vivado environment and FPGA devices).
- Supported memory-mapped and stream-based processor-coprocessor communication.
- Communication: DMA support for system generation.
- System generation: MicroBlaze and ARM supported.
- Code generation compatible with ARTICo³ framework.
- System monitoring with PAPI supported. Automatic generation of a configurable XML file.
- Monitors supported: input FIFOs, Clock cycles, Input tokens and Output tokens.
- System generation: preliminary version of PULP compatible accelerators.
- Profiling supported focused on frequency or area/power.

[1] N. Moreano et al., "Datapath merging and interconnection sharing for reconfigurable architectures", 15th International Symposium on System Synthesis, 2002.
