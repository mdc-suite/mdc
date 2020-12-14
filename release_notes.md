# MDC Release notes

## Release version 0.0.1
2020.12.14

### New features
- Added support for dynamic parameters, which are inputs to the multi-dataflow datapath not corresponding to dataflow connections neither compliant with dataflow communication protocol. They are, typically, parameters which may change during execution. They have to be specified both as parameters of the XDF network and as parameters of the actors receiving them (matching names decides their connection). At the moment only multi-dataflow datapath and test bench are aligned with the dynamic parameters.

### Changes
- Static parameters, which were already supported and which are parameters assigned at design time (reflecting Verilog parameters), can still be specified as parameters of the actors: if there are matching name variables of the XDF network they are hierarchically assigned from the top multi-dataflow datapath, if not they are assigned according to the actor instance default value specified in the XDF network or inside the actor CAL description.

### Bugs fixed
- Uniform printing has been introduced, to process the list of XDF network to be merged always in the same order, thus avoiding differences in the resulting multi-dataflow network and datapath
 
