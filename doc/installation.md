Multi-Dataflow Composer suite installation guide

1) Install Orcc and Eclipse IDE (http://orcc.sourceforge.net/get-involved/contribution/)
a) Download Eclipse Neon (requires Java 8) - option ii is recommended
i) Eclipse for RCP and RAP Developers, recommended by Orcc (http://www.eclipse.org/downloads/packages/eclipse-rcp-and-rap-developers/neon2) 
(1) Requires new software installation (Help > Install New Software … > search Xtext, EMF, Graphiti on all available sites)
ii) Eclipse IDE for Java and DSL Developers (http://www.eclipse.org/downloads/packages/eclipse-ide-java-and-dsl-developers/neon2)
(1) Requires new software installation (Help > Install New Software … > search Graphiti on all available sites)
b) Clone the Orcc Git repository 
i) git clone git@github.com:orcc/orcc.git)
c) Build Orcc with maven
i) cd orcc/eclipse/plugins
ii) mvn install
2) Setup the Orcc framework
a) Open Eclipse (a “design time” workspace has to be selected)
b) Import Orcc plugins (File > Import > General > Existing Projects into Workspace > root directory orcc/eclipse/plugins (check “Search for nested projects” and uncheck “net.sf.orcc”))
c) Launch Orcc Workspace (right click on “net.sf.orcc.core” > Run As… > Eclipse Application).
i) To change “run time” workspace, in the “design time” workspace menu go on Run > Run Configurations… > create or identify an Eclipse Application instance and under select a new location for the field “Workspace Data”
d) Details about the workspaces
i) The “design time” workspace is the one containing the framework (Orcc and MDC) and it is the place where the framework itself could be modified
ii) The “run time” workspace is a running instance of the framework where it can be tested and debugged
3) Checkout (it will be cloned after porting MDC from svn to git) mdcproject repository
a) svn checkout eolab.diee.unica.it/mdcproject
4) Import MDC plugins into Eclipse (in the same “design time” workspace where Orcc has been previously imported)
a) Import MDC plugins (File > Import > General > Existing Projects into Workspace > root directory mdcproject/trunk/ (check “Search for nested projects”)
b) Import HLS (Xronos) plugins (File > Import > General > Existing Projects into Workspace > root directory mdcproject/hls/ (check “Search for nested projects”)
