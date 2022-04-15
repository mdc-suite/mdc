/*
 * Copyright (c) 2012, IETR/INSA of Rennes
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 *   * Redistributions of source code must retain the above copyright notice,
 *     this list of conditions and the following disclaimer.
 *   * Redistributions in binary form must reproduce the above copyright notice,
 *     this list of conditions and the following disclaimer in the documentation
 *     and/or other materials provided with the distribution.
 *   * Neither the name of the IETR/INSA of Rennes nor the names of its
 *     contributors may be used to endorse or promote products derived from this
 *     software without specific prior written permission.
 * about
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 * WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */
package net.sf.orcc.backends.c.hls

import net.sf.orcc.df.Connection
import net.sf.orcc.df.Instance
import net.sf.orcc.df.Port

import static net.sf.orcc.OrccLaunchConstants.*

/**
 * Top network VHDL Code
 *  
 * @author Khaled Jerbi and Mariem Abid
 * 
 */
class TopVhdlPrinter extends net.sf.orcc.backends.c.NetworkPrinter {

	override getNetworkFileContent() '''
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity TopDesign is
port(
	ap_clk : IN STD_LOGIC;
	ap_rst : IN STD_LOGIC;
	ap_start : IN STD_LOGIC;
	ap_done : OUT STD_LOGIC;
	ap_idle : OUT STD_LOGIC;
	ap_ready : OUT STD_LOGIC;
	«FOR instance : network.children.filter(typeof(Instance)).filter[isActor]»
		«FOR port : instance.getActor.inputs»
			«val connection = instance.incomingPortMap.get(port)»
			«IF connection != null && connection.sourcePort == null»
				«connection.castfifoNameWrite»_V_dout   : IN STD_LOGIC_VECTOR («connection.fifoType.sizeInBits - 1» downto 0);
				«connection.castfifoNameWrite»_V_empty_n : IN STD_LOGIC;
				«connection.castfifoNameWrite»_V_read    : OUT STD_LOGIC;
			«ENDIF»
		«ENDFOR»
		«FOR portout : instance.getActor.outputs.filter[! native]»
			«FOR connection : instance.outgoingPortMap.get(portout)»
				«IF connection.targetPort == null»
					«connection.castfifoNameRead»_V_din    : OUT STD_LOGIC_VECTOR («connection.fifoType.sizeInBits - 1» downto 0);
					«connection.castfifoNameRead»_V_full_n : IN STD_LOGIC;
					«connection.castfifoNameRead»_V_write  : OUT STD_LOGIC;
				«ENDIF»				
			«ENDFOR»
		«ENDFOR»
	«ENDFOR»
	ap_return : OUT STD_LOGIC_VECTOR (31 downto 0));
end entity TopDesign;
	
	-- ----------------------------------------------------------------------------------
	-- Architecture Declaration
	-- ----------------------------------------------------------------------------------

architecture rtl of TopDesign is

	-- ----------------------------------------------------------------------------------
	-- Signal Instantiation
	-- ----------------------------------------------------------------------------------
	
	signal top_ap_clk :  STD_LOGIC;
	signal top_ap_rst :  STD_LOGIC;
	signal top_ap_start :  STD_LOGIC;
	signal top_ap_done :  STD_LOGIC;
	signal top_ap_idle :  STD_LOGIC;
	signal top_ap_ready :  STD_LOGIC;
	
	-- FIFO Instantiation
	
	«FOR instance : network.children.filter(typeof(Instance)).filter[isActor]»
		«instance.assignFifoSignal»
	«ENDFOR»
	
-- ----------------------------------------------------------------------------------
-- Components of the Network
-- ---------------------------------------------------------------------------------------
	
	«FOR instance : network.children.filter(typeof(Instance)).filter[isActor]»
		«instance.declareComponentSignal»
		«FOR port : instance.getActor.inputs»
			«val connection = instance.incomingPortMap.get(port)»
			«IF connection != null && connection.sourcePort == null»
				component cast_«instance.name»_«connection.targetPort.name»_write_scheduler IS
					port (
						«connection.ramName»_address0    : OUT  STD_LOGIC_VECTOR («closestLog_2(connection.safeSize)»-1 downto 0);
						«connection.ramName»_ce0 : OUT STD_LOGIC;
						«connection.ramName»_we0  : OUT STD_LOGIC;
						«connection.ramName»_d0  : OUT STD_LOGIC_VECTOR («connection.fifoType.sizeInBits - 1»  downto 0);
						
						«connection.wName»_address0    :  OUT STD_LOGIC_VECTOR (0 downto 0);
						«connection.wName»_ce0 :  OUT STD_LOGIC;
						«connection.wName»_we0  : OUT STD_LOGIC;
						«connection.wName»_d0  :  OUT STD_LOGIC_VECTOR (31  downto 0);
						
						«connection.rName»_address0    : OUT STD_LOGIC_VECTOR (0 downto 0);
						«connection.rName»_ce0 : OUT STD_LOGIC;
						«connection.rName»_q0  : IN  STD_LOGIC_VECTOR (31  downto 0);
								
						«connection.castfifoNameWrite»_V_dout   : IN STD_LOGIC_VECTOR («connection.fifoType.sizeInBits - 1» downto 0);
						«connection.castfifoNameWrite»_V_empty_n : IN STD_LOGIC;
						«connection.castfifoNameWrite»_V_read    : OUT STD_LOGIC;
						
						ap_clk : IN STD_LOGIC;
						ap_rst : IN STD_LOGIC;
						ap_start : IN STD_LOGIC;
						ap_done : OUT STD_LOGIC;
						ap_idle : OUT STD_LOGIC;
						ap_ready : OUT STD_LOGIC);
					end component;
			«ENDIF»
		«ENDFOR»
		
			«FOR port : instance.getActor.outputs.filter[! native]»
				«FOR connection : instance.outgoingPortMap.get(port)»
					«IF connection.targetPort == null»
						component cast_«instance.name»_«instance.outgoingPortMap.get(port).head.sourcePort.name»_read_scheduler IS
						port (
						«connection.ramName»_address0    : OUT STD_LOGIC_VECTOR («closestLog_2(connection.safeSize)»-1 downto 0);
						«connection.ramName»_ce0 : OUT STD_LOGIC;
						«connection.ramName»_q0  :  IN STD_LOGIC_VECTOR («connection.fifoType.sizeInBits - 1»  downto 0);
						
						«connection.wName»_address0    : OUT STD_LOGIC_VECTOR (0 downto 0);
						«connection.wName»_ce0 : OUT STD_LOGIC;
						«connection.wName»_q0  : IN  STD_LOGIC_VECTOR (31  downto 0);
						
						«connection.rName»_address0    :OUT  STD_LOGIC_VECTOR (0 downto 0);
						«connection.rName»_ce0 : OUT STD_LOGIC;
						«connection.rName»_we0  : OUT STD_LOGIC;
						«connection.rName»_d0  : OUT  STD_LOGIC_VECTOR (31  downto 0);
						
						«connection.castfifoNameRead»_V_din    : OUT STD_LOGIC_VECTOR («connection.fifoType.sizeInBits - 1» downto 0);
						«connection.castfifoNameRead»_V_full_n : IN STD_LOGIC;
						«connection.castfifoNameRead»_V_write  : OUT STD_LOGIC;
						
						
						ap_clk : IN STD_LOGIC;
						ap_rst : IN STD_LOGIC;
						ap_start : IN STD_LOGIC;
						ap_done : OUT STD_LOGIC;
						ap_idle : OUT STD_LOGIC;
						ap_ready : OUT STD_LOGIC);
						end component;
					«ENDIF»
				«ENDFOR»
			«ENDFOR»
	«ENDFOR»

	component ram_tab is 
	 generic(
	         dwidth     : INTEGER; 
	         awidth     : INTEGER;  
	         mem_size    : INTEGER 
	 ); 
	 port (
	       addr0     : in std_logic_vector(awidth-1 downto 0); 
	       ce0       : in std_logic; 
	       q0        : out std_logic_vector(dwidth-1 downto 0);
	       addr1     : in std_logic_vector(awidth-1 downto 0); 
	       ce1       : in std_logic; 
	       d1        : in std_logic_vector(dwidth-1 downto 0); 
	       we1       : in std_logic; 
	       clk        : in std_logic 
	 ); 
	end component; 
begin

	«FOR instance : network.children.filter(typeof(Instance)).filter[isActor]»
		«instance.mappingComponentFifoSignal»
	«ENDFOR»
	
	«FOR instance : network.children.filter(typeof(Instance)).filter[isActor]»
		«instance.mappingComponentSignal»
	«ENDFOR»
	
---------------------------------------------------------------------------
-- Network Ports Instantiation 
---------------------------------------------------------------------------
	
	«FOR instance : network.children.filter(typeof(Instance)).filter[isActor]»
		«instance.assignNetworkPorts»
	«ENDFOR»
		top_ap_start <= ap_start;
		top_ap_clk <= ap_clk;
		top_ap_rst <= ap_rst;
		
	end architecture rtl;
'''

	//ok
	def assignNetworkPorts(Instance instance) '''
«FOR port : instance.getActor.inputs»
	«val connection = instance.incomingPortMap.get(port)»
	«IF connection != null && connection.sourcePort == null»
		top_«connection.castfifoNameWrite»_V_dout <= «connection.castfifoNameWrite»_V_dout;
		top_«connection.castfifoNameWrite»_V_empty_n <= «connection.castfifoNameWrite»_V_empty_n;
		«connection.castfifoNameWrite»_V_read <= top_«connection.castfifoNameWrite»_V_read;	
	«ENDIF»
«ENDFOR»	

«FOR portout : instance.getActor.outputs.filter[! native]»
	«FOR connection : instance.outgoingPortMap.get(portout)»
		«IF connection.targetPort == null»
			«connection.castfifoNameRead»_V_din    <= top_«connection.castfifoNameRead»_V_din;
			top_«connection.castfifoNameRead»_V_full_n <= «connection.castfifoNameRead»_V_full_n;
			«connection.castfifoNameRead»_V_write <= top_«connection.castfifoNameRead»_V_write;
		«ENDIF»
	«ENDFOR»
«ENDFOR»
'''

	def mappingComponentSignal(Instance instance) '''
call_«instance.name»_scheduler : component «instance.name»_scheduler
port map(
	«FOR connList : instance.outgoingPortMap.values»		
		«connList.head.ramName»_address0 => top_«connList.head.ramName»_address1,
		«connList.head.ramName»_ce0 => top_«connList.head.ramName»_ce1,
		«connList.head.ramName»_we0 => top_«connList.head.ramName»_we1,
		«connList.head.ramName»_d0 => top_«connList.head.ramName»_d1,
		
		«connList.head.wName»_address0 => top_«connList.head.wName»_address1,
		«connList.head.wName»_ce0 => top_«connList.head.wName»_ce1,
		«connList.head.wName»_we0 => top_«connList.head.wName»_we1,
		«connList.head.wName»_d0 => top_«connList.head.wName»_d1,
		
		«connList.head.rName»_address0 => top_«connList.head.rName»_address1,
		«connList.head.rName»_ce0 => top_«connList.head.rName»_ce1,
		«connList.head.rName»_q0 => top_«connList.head.rName»_q1,						
	«ENDFOR»
	«FOR connList : instance.incomingPortMap.values»				
		«connList.ramName»_address0 => top_«connList.ramName»_address0,
		«connList.ramName»_ce0 => top_«connList.ramName»_ce0,
		«connList.ramName»_q0 => top_«connList.ramName»_q0,
		
		«connList.wName»_address0 => top_«connList.wName»_address0,
		«connList.wName»_ce0 => top_«connList.wName»_ce0,
		«connList.wName»_q0 => top_«connList.wName»_q0,
		
		«connList.rName»_address0 => top_«connList.rName»_address0,
		«connList.rName»_ce0 => top_«connList.rName»_ce0,
		«connList.rName»_we0 => top_«connList.rName»_we0,
		«connList.rName»_d0 => top_«connList.rName»_d0,				
	«ENDFOR»
	
	ap_start => top_ap_start,
	ap_clk => top_ap_clk,
	ap_rst => top_ap_rst,
	ap_done => top_ap_done,
	ap_idle => top_ap_idle,
	ap_ready => top_ap_ready
	);
	
«FOR port : instance.getActor.outputs.filter[! native]»
	«FOR connection : instance.outgoingPortMap.get(port)»
		«IF connection.targetPort == null»
			call_cast_«instance.name»_«connection.sourcePort.name»_read_scheduler : component cast_«instance.name»_«connection.
		sourcePort.name»_read_scheduler
			port map(
			«connection.ramName»_address0 => top_«connection.ramName»_address0, 
			«connection.ramName»_ce0 => top_«connection.ramName»_ce0,
			«connection.ramName»_q0  => top_«connection.ramName»_q0,
			
			«connection.wName»_address0 => top_«connection.wName»_address0,
			«connection.wName»_ce0 => top_«connection.wName»_ce0,
			«connection.wName»_q0  => top_«connection.wName»_q0,
			
			«connection.rName»_address0 => top_«connection.rName»_address0,
			«connection.rName»_ce0 => top_«connection.rName»_ce0,
			«connection.rName»_we0  => top_«connection.rName»_we0,
			«connection.rName»_d0  => top_«connection.rName»_d0,
			
			«connection.castfifoNameRead»_V_din    => top_«connection.castfifoNameRead»_V_din,
			«connection.castfifoNameRead»_V_full_n => top_«connection.castfifoNameRead»_V_full_n,
			«connection.castfifoNameRead»_V_write  => top_«connection.castfifoNameRead»_V_write,
				
				ap_start => top_ap_start,
				ap_clk => top_ap_clk,
				ap_rst => top_ap_rst,
				ap_done => top_ap_done,
				ap_idle => top_ap_idle,
				ap_ready => top_ap_ready);
			
		«ENDIF»
	«ENDFOR»
«ENDFOR»

«FOR port : instance.getActor.inputs»		
	«val connection = instance.incomingPortMap.get(port)»
	«IF connection != null && connection.sourcePort == null»
		call_cast_«instance.name»_«connection.targetPort.name»_write_scheduler :component cast_«instance.name»_«connection.
		targetPort.name»_write_scheduler
				port map(
				«connection.ramName»_address0   => top_«connection.ramName»_address1,
				«connection.ramName»_ce0 => top_«connection.ramName»_ce1,
				«connection.ramName»_we0 => top_«connection.ramName»_we1,
				«connection.ramName»_d0  => top_«connection.ramName»_d1,
				
				«connection.wName»_address0  => top_«connection.wName»_address1,
				«connection.wName»_ce0 => top_«connection.wName»_ce1,
				«connection.wName»_we0  => top_«connection.wName»_we1,
				«connection.wName»_d0  => top_«connection.wName»_d1,
				
				«connection.rName»_address0   => top_«connection.rName»_address1,
				«connection.rName»_ce0 => top_«connection.rName»_ce1,
				«connection.rName»_q0  => top_«connection.rName»_q1,
						
				«connection.castfifoNameWrite»_V_dout   => top_«connection.castfifoNameWrite»_V_dout,
				«connection.castfifoNameWrite»_V_empty_n => top_«connection.castfifoNameWrite»_V_empty_n,
				«connection.castfifoNameWrite»_V_read    => top_«connection.castfifoNameWrite»_V_read,
					ap_start => top_ap_start,
						ap_clk => top_ap_clk,
						ap_rst => top_ap_rst,
						ap_done => top_ap_done,
						ap_idle => top_ap_idle,
						ap_ready => top_ap_ready);
					
	«ENDIF»
«ENDFOR»
'''

	def mappingComponentFifoSignal(Instance instance) '''		

«FOR connection : instance.incomingPortMap.values»			
	«printFifoMapping(connection)»
«ENDFOR»

«FOR port : instance.getActor.outputs.filter[! native]»
	«FOR connection : instance.outgoingPortMap.get(port)»
		«IF connection.targetPort == null»
			«printFifoMapping(connection)»
		«ENDIF»	
	«ENDFOR»
«ENDFOR»
'''

	def printFifoMapping(Connection connection) '''
		
		«connection.ramName» : ram_tab
				generic map (dwidth     => «connection.fifoType.sizeInBits»,
				       awidth     => «closestLog_2(connection.safeSize)»,
				       mem_size   => «connection.safeSize»)
		port map (
			clk => top_ap_clk,
			addr0 => top_«connection.ramName»_address0,
			ce0 => top_«connection.ramName»_ce0,
			q0 => top_«connection.ramName»_q0,
			addr1 => top_«connection.ramName»_address1,
			ce1 => top_«connection.ramName»_ce1,
			we1 => top_«connection.ramName»_we1,
			d1 => top_«connection.ramName»_d1
		);
		«connection.rName» : ram_tab
				generic map (dwidth     => 32,
				       awidth     => 1,
				       mem_size   => 1)
		port map (
			clk => top_ap_clk,
			addr0 => top_«connection.rName»_address1,
			ce0 => top_«connection.rName»_ce1,
			q0 => top_«connection.rName»_q1,
			addr1 => top_«connection.rName»_address0,
			ce1 => top_«connection.rName»_ce0,
			we1 => top_«connection.rName»_we0,
			d1 => top_«connection.rName»_d0
		);
		«connection.wName» : ram_tab
				generic map (dwidth     => 32,
				       awidth     => 1,
				       mem_size   => 1)
		port map (
			clk => top_ap_clk,
			addr0 => top_«connection.wName»_address0,
			ce0 => top_«connection.wName»_ce0,
			q0 => top_«connection.wName»_q0,
			addr1 => top_«connection.wName»_address1,
			ce1 => top_«connection.wName»_ce1,
			we1 => top_«connection.wName»_we1,
			d1 => top_«connection.wName»_d1
			);
	'''

	def assignFifoSignal(Instance instance) '''
«FOR connList : instance.outgoingPortMap.values»
	«IF connList.head.target instanceof Port»
		«printOutputFifoSignalAssignHLS(connList.head)»
		«printInputRAMSignalAssignHLS(connList.head)»
	«ENDIF»
	«printOutputRamSignalAssignHLS(connList.head)»
		
	
«ENDFOR»
«FOR connection : instance.incomingPortMap.values»
	«IF connection.source instanceof Port»
		«printInputFifoSignalAssignHLS(connection)»
		«printOutputRamSignalAssignHLS(connection)»
	«ENDIF»
	«printInputRAMSignalAssignHLS(connection)»
	
«ENDFOR»
'''

	def printOutputRamSignalAssignHLS(Connection connection) '''
signal top_«connection.ramName»_address1    :  STD_LOGIC_VECTOR («closestLog_2(connection.safeSize)»-1 downto 0);
signal top_«connection.ramName»_ce1 :  STD_LOGIC;
signal top_«connection.ramName»_we1  :  STD_LOGIC;
signal top_«connection.ramName»_d1  :   STD_LOGIC_VECTOR («connection.fifoType.sizeInBits - 1»  downto 0);

signal top_«connection.wName»_address1    :  STD_LOGIC_VECTOR (0 downto 0);
signal top_«connection.wName»_ce1 :  STD_LOGIC;
signal top_«connection.wName»_we1  :  STD_LOGIC;
signal top_«connection.wName»_d1  :   STD_LOGIC_VECTOR (31  downto 0);

signal top_«connection.rName»_address1    :  STD_LOGIC_VECTOR (0 downto 0);
signal top_«connection.rName»_ce1 :  STD_LOGIC;
signal top_«connection.rName»_q1  :   STD_LOGIC_VECTOR (31  downto 0);
	
'''

	def printInputRAMSignalAssignHLS(Connection connection) '''
signal top_«connection.ramName»_address0    :  STD_LOGIC_VECTOR («closestLog_2(connection.safeSize)»-1 downto 0);
signal top_«connection.ramName»_ce0 :  STD_LOGIC;
signal top_«connection.ramName»_q0  :   STD_LOGIC_VECTOR («connection.fifoType.sizeInBits - 1»  downto 0);

signal top_«connection.wName»_address0    :  STD_LOGIC_VECTOR (0 downto 0);
signal top_«connection.wName»_ce0 :  STD_LOGIC;
signal top_«connection.wName»_q0  :   STD_LOGIC_VECTOR (31  downto 0);

signal top_«connection.rName»_address0    :  STD_LOGIC_VECTOR (0 downto 0);
signal top_«connection.rName»_ce0 :  STD_LOGIC;
signal top_«connection.rName»_we0  :  STD_LOGIC;
signal top_«connection.rName»_d0  :   STD_LOGIC_VECTOR (31  downto 0);
	
'''

	def printOutputRamAssignHLS(Connection connection) '''
«connection.ramName»_address0    : OUT  STD_LOGIC_VECTOR («closestLog_2(connection.safeSize)»-1 downto 0);
«connection.ramName»_ce0 : OUT STD_LOGIC;
«connection.ramName»_we0  : OUT STD_LOGIC;
«connection.ramName»_d0  : OUT STD_LOGIC_VECTOR («connection.fifoType.sizeInBits - 1»  downto 0);

«connection.wName»_address0    :  OUT STD_LOGIC_VECTOR (0 downto 0);
«connection.wName»_ce0 :  OUT STD_LOGIC;
«connection.wName»_we0  : OUT STD_LOGIC;
«connection.wName»_d0  :  OUT STD_LOGIC_VECTOR (31  downto 0);

«connection.rName»_address0    : OUT STD_LOGIC_VECTOR (0 downto 0);
«connection.rName»_ce0 : OUT STD_LOGIC;
«connection.rName»_q0  : IN  STD_LOGIC_VECTOR (31  downto 0);
	
'''

	def printInputRAMAssignHLS(Connection connection) '''
«connection.ramName»_address0    : OUT STD_LOGIC_VECTOR («closestLog_2(connection.safeSize)»-1 downto 0);
«connection.ramName»_ce0 : OUT STD_LOGIC;
«connection.ramName»_q0  :  IN STD_LOGIC_VECTOR («connection.fifoType.sizeInBits - 1»  downto 0);

«connection.wName»_address0    : OUT STD_LOGIC_VECTOR (0 downto 0);
«connection.wName»_ce0 : OUT STD_LOGIC;
«connection.wName»_q0  : IN  STD_LOGIC_VECTOR (31  downto 0);

«connection.rName»_address0    :OUT  STD_LOGIC_VECTOR (0 downto 0);
«connection.rName»_ce0 : OUT STD_LOGIC;
«connection.rName»_we0  : OUT STD_LOGIC;
«connection.rName»_d0  : OUT  STD_LOGIC_VECTOR (31  downto 0);
	
'''

	def printOutputFifoSignalAssignHLS(Connection connection) '''
signal top_«connection.castfifoNameRead»_V_din    :  STD_LOGIC_VECTOR («connection.fifoType.sizeInBits - 1»  downto 0);
signal top_«connection.castfifoNameRead»_V_full_n :  STD_LOGIC;
signal top_«connection.castfifoNameRead»_V_write  :  STD_LOGIC;
'''

	def printInputFifoSignalAssignHLS(Connection connection) '''
		
		signal top_«connection.castfifoNameWrite»_V_dout   :  STD_LOGIC_VECTOR («connection.fifoType.sizeInBits - 1» downto 0);
		signal top_«connection.castfifoNameWrite»_V_empty_n :  STD_LOGIC;
		signal top_«connection.castfifoNameWrite»_V_read    :  STD_LOGIC;
	'''

	def declareComponentSignal(Instance instance) '''
component «instance.name»_scheduler IS
port (
	«FOR connList : instance.outgoingPortMap.values»
		
			«printOutputRamAssignHLS(connList.head)»
	«ENDFOR»
	«FOR connList : instance.incomingPortMap.values»
		
				«printInputRAMAssignHLS(connList)»
		
	«ENDFOR»
		
		ap_clk : IN STD_LOGIC;
		ap_rst : IN STD_LOGIC;
		ap_start : IN STD_LOGIC;
		ap_done : OUT STD_LOGIC;
		ap_idle : OUT STD_LOGIC;
		ap_ready : OUT STD_LOGIC);
	end component;
	
'''

	def castfifoNameWrite(Connection connection) '''«IF connection != null»myStream_cast_«connection.getAttribute("id").
		objectValue»_write«ENDIF»'''

	def castfifoNameRead(Connection connection) '''«IF connection != null»myStream_cast_«connection.getAttribute("id").
		objectValue»_read«ENDIF»'''

	def ramName(Connection connection) '''«IF connection != null»tab_«connection.getAttribute("id").objectValue»«ENDIF»'''

	def wName(Connection connection) '''«IF connection != null»writeIdx_«connection.getAttribute("id").objectValue»«ENDIF»'''

	def localwName(Connection connection) '''«IF connection != null»wIdx_«connection.getAttribute("id").objectValue»«ENDIF»'''

	def localrName(Connection connection) '''«IF connection != null»rIdx_«connection.getAttribute("id").objectValue»«ENDIF»'''

	def rName(Connection connection) '''«IF connection != null»readIdx_«connection.getAttribute("id").objectValue»«ENDIF»'''

	def fifoType(Connection connection) {
		if (connection.sourcePort != null) {
			connection.sourcePort.type
		} else {
			connection.targetPort.type
		}
	}

	def closestLog_2(Integer x) {
		if(x == null) closestLog_2(DEFAULT_FIFO_SIZE) else closestLog_2(x.intValue)
	}

	def closestLog_2(int x) {
		var p = 1;
		var r = 0;
		while (p < x) {
			p = p * 2
			r = r + 1
		}
		return r;
	}
}
