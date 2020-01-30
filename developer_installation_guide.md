# Multi-Dataflow Composer suite 
## Developer Installation Guide

#### Install Eclipse IDE 
* Download Eclipse Neon (requires Java 8) - **Option II** is recommended
    * **Option I** - Eclipse for RCP and RAP Developers, recommended by Orcc (http://www.eclipse.org/downloads/packages/) **not tested recently**
        * Requires new software installation (Help > Install New Software … > search Xtext, EMF, Graphiti on all available sites)
    * **Option II** - Eclipse IDE for Java and DSL Developers (http://www.eclipse.org/downloads/packages/)
        * Requires new software installation (Help > Install New Software … > search Graphiti on all available sites)
        
 **Recently tested with Eclipse 2019-12!**


### Linux OS:
#### Install Orcc
* Clone the Orcc Git repository 
    * git clone git@github.com:orcc/orcc.git)
* Build Orcc with maven
    * cd orcc/eclipse/plugins
    * mvn install

#### Setup the Orcc framework
* Open Eclipse (a “design time” workspace, that is the workspace fot the source code of the tool, has to be selected)
* Import Orcc plugins (File > Import > General > Existing Projects into Workspace > root directory orcc/eclipse/plugins (check “Search for nested projects” and uncheck “net.sf.orcc”))
    * **If there are Maven errors**, such as: “maven project build maven lifecycle mapping problem”, right click on the project folders and select “Disable Maven Nature”
    * If there is an error as “Unsatisfied version constraint: 'org.eclipse.xtext: 2.12.0'    MANIFEST.MF    /net.sf.orcc.cal/META-INF” → replace 2.12.0 with 2.9.0
* Launch Orcc Workspace (right click on “net.sf.orcc.core” > Run As… > Eclipse Application).
    * To change “run time” workspace, in the “design time” workspace menu go on Run > Run Configurations… > create or identify an Eclipse Application instance and under select a new location for the field “Workspace Data”
* Details about the workspaces
    * The “design time” workspace is the one containing the framework (Orcc and MDC) and it is the place where the framework itself could be modified
    * The “run time” workspace is a running instance of the framework where it can be tested and debugged
    * 
#### Clone the MDC Git repository
* git clone https://github.com/mdc-suite/mdc.git 

#### Import MDC plugins
* Import MDC in the same “design time” workspace where Orcc has been previously imported
* Import MDC plugins (File > Import > General > Existing Projects into Workspace > root directory mdcproject/trunk/ (check “Search for nested projects”)
    * Right click on it.mdc.tool → properties → Text file encoding → Other: UTF-8


### Windows OS:

#### Install Orcc 
* Clone the Orcc Git repository
    * Install a git bash, such as: https://git-scm.com/downloads 
    * go to the directory that you want to place the repository
    * Right click → Git Bash Here
    * git clone https://github.com/orcc/orcc.git
    * for more details about Git see guide Introduction to git
* Build Orcc with maven 
    * Download maven: https://maven.apache.org/download.cgi
    * Set environment variables: PATH\apache-maven-3.5.0\bin
    * Open windows cmd
    * cd orcc/eclipse/plugins
    * mvn install

#### Setup the Orcc framework

* Open Eclipse (a “design time” workspace has to be selected)
* Import Orcc plugins (File > Import > General > Existing Projects into Workspace > root directory orcc/eclipse/plugins (check “Search for nested projects” and uncheck “net.sf.orcc”))
   * **If there are Maven errors**, such as: “maven project build maven lifecycle mapping problem”, right click on the project folders and select “Disable Maven Nature”
   * If there is an error as “**Unsatisfied version constraint**: 'org.eclipse.xtext: 2.12.0'    MANIFEST.MF    /net.sf.orcc.cal/META-INF” → replace 2.12.0 with 2.9.0
   * If there are **xtent encoding errors**: Right click on the projects with errors → properties → Text file encoding → Other: UTF-8
   * If you have an error such as: **Description    Resource Path Location Type: The feature 'editDirectory' of 'org.eclipse.emf.codegen.ecore.genmodel.impl.GenModelImpl@b235e66{platform:/resource/net.sf.orcc.cal/model/generated/Cal.genmodel#/}' contains a bad value    Cal.genmodel    /net.sf.orcc.cal/model/generated    line: 1 /net.sf.orcc.cal/model/generated/Cal.genmodel    Xtext Check (fast)** --> Open on /net.sf.orcc.cal/model/generated/Cal.genmodel, and in properties tab replace src with /net.sf.orcc.cal/scr
 
        
* Launch Orcc Workspace (right click on “net.sf.orcc.core” > Run As… > Eclipse Application).
    * To change “run time” workspace, in the “design time” workspace menu go on Run > Run Configurations… > create or identify an Eclipse Application instance and under select a new location for the field “Workspace Data”
* Details about the workspaces
    * The “design time” workspace is the one containing the framework (Orcc and MDC) and it is the place where the framework itself could be modified
    * The “run time” workspace is a running instance of the framework where it can be tested and debugged


#### Clone the MDC Git repository 
* git clone https://github.com/mdc-suite/mdc.git


#### Import MDC plugins into Eclipse 
* Import MDC in the same “design time” workspace where Orcc has been previously imported
* Import MDC plugins (File > Import > General > Existing Projects into Workspace > root directory mdcproject/trunk/ (check “Search for nested projects”)
    * Right click on it.mdc.tool → properties → Text file encoding → Other: UTF-8


