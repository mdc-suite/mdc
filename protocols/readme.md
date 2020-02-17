# Protocols for HLS engines
In order to use one of the supported HLS engines it is necessary to put the .xml file as protocol file and the HCL folder as hardware components library in the MDC GUI.
## Supported HLS engines
- Vivado HLS
-- functions corresponding to actors must have a ap_ctrl HLS INTERFACE associated to port return
-- functions corresponding to actors must have all the data ports with ap_fifo HLS INTERFACE
- CAPH
