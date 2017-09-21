# Multi-Dataflow Composer suite installation guide

1. Install Orcc and Eclipse IDE (http://orcc.sourceforge.net/get-involved/contribution/)
    1. Download Eclipse Neon (requires Java 8) - option b is recommended
        1. Eclipse for RCP and RAP Developers, recommended by Orcc (http://www.eclipse.org/downloads/packages/eclipse-rcp-and-rap-developers/neon2) (1) Requires new software installation (Help > Install New Software … > search Xtext, EMF, Graphiti on all available sites)
        2. Eclipse IDE for Java and DSL Developers (http://www.eclipse.org/downloads/packages/eclipse-ide-java-and-dsl-developers/neon2) (1) Requires new software installation (Help > Install New Software … > search Graphiti on all available sites)
    2. Clone the Orcc Git repository 
        1. git clone git@github.com:orcc/orcc.git
    3. Build Orcc with maven
        1. cd orcc/eclipse/plugins
        2. mvn install (if you need to install maven: sudo apt install maven)
2. Setup the Orcc framework
    1. Open Eclipse (a “design time” workspace has to be selected)
    2. Change text file encoding (Window > Preferences > General > Workspace : Text file encoding (select "Other : UTF-8", then click on Apply))
    3. Import Orcc plugins (File > Import > General > Existing Projects into Workspace > root directory orcc/eclipse/plugins (check “Search for nested projects” and uncheck “net.sf.orcc”))
    4. Launch Orcc Workspace (right click on “net.sf.orcc.core” > Run As… > Eclipse Application).
        1. To change “run time” workspace, in the “design time” workspace menu go on Run > Run Configurations… > create or identify an Eclipse Application instance and under select a new location for the field “Workspace Data”
    5. Make visible "Run Configurations..." into the "run time" workspace (Window > Perspective > Customize Perspective > Action Set Availability (check Launch))
    6. Details about the workspaces
        1. The “design time” workspace is the one containing the framework (Orcc and MDC) and it is the place where the framework itself could be modified
        2. The “run time” workspace is a running instance of the framework where it can be tested and debugged
3. Clone the MDC Git repository
    1. git clone https://github.com/mdc-suite/mdc.git
4. Import MDC plugins into Eclipse (in the same “design time” workspace where Orcc has been previously imported)
    1. Import MDC plugins (File > Import > General > Existing Projects into Workspace > root directory mdcproject/trunk/ (check “Search for nested projects”)
    2. Import HLS (Xronos) plugins (File > Import > General > Existing Projects into Workspace > root directory mdcproject/hls/ (check “Search for nested projects”))
