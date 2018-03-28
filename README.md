# MDC
Welcome to the main reposirory of the **Multi-Dataflow Composer (MDC)** design suite.

The _doc_ folder contains some useful documentation about **MDC**. In particular, the different features of the suite will be introduced separately below.

## Baseline
The baseline feature of MDC is...

## Profiler
The _profiler_ is..

## Power Manager
The _power manager_ is... 

## Prototyper
The _prototyper_ is in charge of generating a ready-to-use IP accelerator on the top of the CGR datapath provided by the _baseline_ feature.
Here below its main characteristics.

|    **status** |   OK          |   OK   |   no          |   no   |
|--------------:|:-------------:|:------:|:-------------:|:------:|
| **processor** | uBlaze        | uBlaze | uBlaze        | uBlaze |
|       **DMA** |   no          |   no   |   yes         |   yes  |
|  **coupling** | memory-mapped | stream | memory-mapped | stream |

|    **status** | no            | no     | no            | no     |
|--------------:|:-------------:|:------:|:-------------:|:------:|
| **processor** | ARM           | ARM    | ARM           | ARM    |
|       **DMA** |  no           |  no    | yes           | yes    |
|  **coupling** | memory-mapped | stream | memory-mapped | stream |
