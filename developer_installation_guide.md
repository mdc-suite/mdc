# Multi-Dataflow Composer suite 
## Developer Installation Guide

### Install Eclipse IDE
   * Install Eclipse IDE for Java and DSL Developers 2022-03 R
       * Available at http://www.eclipse.org/downloads/packages/release/2022-03/r
   * Requires new software installation
      * Help > Install New Software … >
      * search Graphiti on all available sites (Work with tab menu: -- All available sites)
      * Select all available options (Modeling and Testing)
         <img src="https://github.com/mdc-suite/mdc/blob/cps24/blob/screenshoot-eclipse.jpeg" alt="" width="500"/>


### Clone the MDC repository
* git clone --recurse-submodules --branch cps24 https://github.com/mdc-suite/mdc.git 

### Import and Setup plugins
* Launch Eclipse
* Import ORCC plugins:
   * File -> Import ... -> General -> Existing project into workspace
   * Select ORCC directory (mdc/orcc)
   * Click "Finish" (Ignore the warnings)
* Setup ORCC plugins:
   * Right-click on net.sf.orcc.core -> Run as -> Run Configurations...
   * Double click on Eclipse Application (it will create a new configuration)
   * Select the Plug-ins tab and tick "Validate Plug-ins automatically prior to launching"
       <img src="https://github.com/mdc-suite/mdc/blob/cps24/blob/screenshoot-eclipse2.jpeg" alt="" width="500">
   * Click Apply and close the tab
* Import MDC plugins:
   * File -> Import ... -> General -> Existing project into workspace
   * Select MDC plugins (mdc/eclipse/plugins)
   * Click "Finish"
* Setup MDC plugins:
   * Right-click on it.mdc.tool -> properties
   * Click on Resource -> Text file encoding -> Other: UTF-8
   * Click "Apply and close"

    






