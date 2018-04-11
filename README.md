# MDC
Welcome to the main reposirory of the **Multi-Dataflow Composer (MDC)** design suite.

The _doc_ folder contains some useful documentation about **MDC**. In particular, the different features of the suite will be introduced separately below.

## Baseline
The _baseline_ feature of MDC is the composition of a coarse-grained reconfigurable (CGR) hardware datapath starting from a set of dataflow applications.
The _baseline_ feature involves two main components:
- Multi-Dataflow Generator (MDG): it merges together different dataflows into one unique reconfigurable multi-dataflow by the insertion of switching modules named _SBoxes_. Two different merging algorithms are supported: empiric and Moreano. The former is more suitable for non-recursive dataflows but less optimized than the latter.
- Platform composer (PC): it derives the RTL description of the CGR datapath from the multi-dataflow. It requires the user to define the communication protocol between actors in hardware (XML) and the RTL description of the actors involved in the dataflows (HDL Components Library, HCL).

## Profiler
The _profiler_ is in charge of topologically optimizing the multi-dataflow generate by the MDG according to a characterization (post-synthesis) of the input dataflows implementation. It takes as input the characterization of the dataflows in terms of area occupancy, static power consumption and maximum operating frequency. It can optimize the system considering two different design goals: area occupancy/static power or maximum operating frequency.

| **status** |   OK |  no  |
|-----------:|:----:|:----:|
| **target** | ASIC | FPGA |

## Power Manager
The _power manager_ is in charge of identifying on the multi-dataflow different logic regions, that are regions composed by actors always active/inactive together in the computation. On the top of this system-level partitioning, different power saving techniques can be applied: both clock-gating (CG) and power-gating (PG) are supported at the moment.

|  **status**  |  OK  |  OK  |  OK  |
|-------------:|:----:|:----:|:----:|
|  **target**  | ASIC | ASIC | FPGA |
| **technique**|  CG  |  PG  |  CG  |

## Prototyper
The _prototyper_ is in charge of generating a ready-to-use IP accelerator on the top of the CGR datapath provided by the _baseline_ feature. Wrapper logic, tcl scripts and software drivers are all provided.
Here below its main characteristics.

|    **status** |   OK   |   OK   |   OK   |   OK   | OK  | no  | no  | no  |
|--------------:|:------:|:------:|:------:|:------:|:---:|:---:|:---:|:---:|
| **processor** | uBlaze | uBlaze | uBlaze | uBlaze | ARM | ARM | ARM | ARM |
|       **DMA** |   no   |   no   |   yes  |   yes  |  no |  no | yes | yes |
|  **coupling** |   mm   |    s   |   mm   |    s   |  mm |  s  |  mm |  s  |
