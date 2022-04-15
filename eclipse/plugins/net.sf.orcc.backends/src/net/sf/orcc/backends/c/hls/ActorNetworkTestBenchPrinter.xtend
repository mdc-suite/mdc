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

import static net.sf.orcc.util.OrccAttributes.*

/**
 * Top VHDL testbench for actor debug 
 *  
 * @author Khaled Jerbi and Mariem Abid
 * 
 */
class ActorNetworkTestBenchPrinter extends net.sf.orcc.backends.c.InstancePrinter {

	def actorNetworkFileContent() '''
			LIBRARY ieee;
			USE ieee.std_logic_1164.ALL;
			USE ieee.std_logic_unsigned.all;
			USE ieee.numeric_std.ALL;
			USE std.textio.all;
			
			LIBRARY work;
			USE work.sim_package.all;
			
			ENTITY testbench IS
			END testbench;
			
			ARCHITECTURE behavior OF testbench IS
			
			-- Component Declaration
			COMPONENT TopDesign
			PORT(
			ap_clk : IN STD_LOGIC;
			ap_rst : IN STD_LOGIC;
			ap_start : IN STD_LOGIC;
			ap_done : OUT STD_LOGIC;
			ap_idle : OUT STD_LOGIC;
			ap_ready : OUT STD_LOGIC;
			
			«FOR port : actor.inputs»
				«val connection = incomingPortMap.get(port)»
				«IF connection != null»
					«connection.castfifoNameWrite»_V_dout   : IN STD_LOGIC_VECTOR («connection.fifoTypeIn.sizeInBits - 1» downto 0);
					«connection.castfifoNameWrite»_V_empty_n : IN STD_LOGIC;
					«connection.castfifoNameWrite»_V_read    : OUT STD_LOGIC;
				«ENDIF»
			«ENDFOR»
			
			«FOR portout : actor.outputs.filter[! native]»
				«FOR connection : outgoingPortMap.get(portout)»
					«connection.castfifoNameRead»_V_din    : OUT STD_LOGIC_VECTOR («connection.fifoTypeOut.sizeInBits - 1» downto 0);
					«connection.castfifoNameRead»_V_full_n : IN STD_LOGIC;
					«connection.castfifoNameRead»_V_write  : OUT STD_LOGIC;
				«ENDFOR»
			«ENDFOR»
			
			«IF actor.hasAttribute(DIRECTIVE_DEBUG)»
				«FOR action : actor.actions»	
				myStream_cast_tab_«action.name»_read_V_din    : OUT STD_LOGIC_VECTOR (7 downto 0);
				myStream_cast_tab_«action.name»_read_V_full_n : IN STD_LOGIC;
				myStream_cast_tab_«action.name»_read_V_write  : OUT STD_LOGIC;
				«ENDFOR»
			«ENDIF»
			
			ap_return : OUT STD_LOGIC_VECTOR (31 downto 0)
			);
			END COMPONENT;	
			
			signal ap_clk :  STD_LOGIC:= '0';
			signal ap_rst : STD_LOGIC:= '0';
			signal ap_start : STD_LOGIC:= '0';
			signal ap_done :  STD_LOGIC;
			signal ap_idle :  STD_LOGIC;
			signal ap_ready :  STD_LOGIC;
			
			«FOR port : actor.inputs»
			«val connection = incomingPortMap.get(port)»
			«IF connection != null»
				Signal «connection.castfifoNameWrite»_V_dout   :  STD_LOGIC_VECTOR («connection.fifoTypeIn.sizeInBits - 1» downto 0);
				Signal «connection.castfifoNameWrite»_V_empty_n :  STD_LOGIC;
				Signal «connection.castfifoNameWrite»_V_read    :  STD_LOGIC;				
			«ENDIF»
			«ENDFOR»
			«FOR portout : actor.outputs.filter[! native]»
			«FOR connection : outgoingPortMap.get(portout)»				
				Signal «connection.castfifoNameRead»_V_din    :  STD_LOGIC_VECTOR («connection.fifoTypeOut.sizeInBits - 1» downto 0);
				Signal «connection.castfifoNameRead»_V_full_n :  STD_LOGIC;
				Signal «connection.castfifoNameRead»_V_write  :  STD_LOGIC;				
			«ENDFOR»
			«ENDFOR»
			«IF actor.hasAttribute(DIRECTIVE_DEBUG)»
				«FOR action : actor.actions»	
				Signal myStream_cast_tab_«action.name»_read_V_din    :  STD_LOGIC_VECTOR (7 downto 0);
				Signal myStream_cast_tab_«action.name»_read_V_full_n : STD_LOGIC;
				Signal myStream_cast_tab_«action.name»_read_V_write  :  STD_LOGIC;
				«ENDFOR»
			«ENDIF»
		
			signal ap_return :  STD_LOGIC_VECTOR (31 downto 0):= (others => '0');
			
			-- Configuration
			signal count       : integer range 255 downto 0 := 0;
			
			constant PERIOD : time := 20 ns;
			constant DUTY_CYCLE : real := 0.5;
			constant OFFSET : time := 100 ns;
			
			type severity_level is (note, warning, error, failure);
			type tb_type is (after_reset, read_file, CheckRead);
			
			-- Input and Output files
			signal tb_FSM_bits  : tb_type;
			
			«FOR connection : outgoingPortMap.values»
			file sim_file_«entityName»_«connection.head.sourcePort.name»  : text is "«entityName»_«connection.head.sourcePort.
			name».txt";
			«ENDFOR»
			«FOR connection : incomingPortMap.values»
			file sim_file_«entityName»_«connection.targetPort.name»  : text is "«entityName»_«connection.targetPort.name».txt";
			«ENDFOR»
			
			begin
			
			uut : TopDesign port map (
				ap_clk => ap_clk,
				ap_rst => ap_rst,
				ap_start => ap_start,
				ap_done => ap_done,
				ap_idle => ap_idle,
				ap_ready =>ap_ready,
				«FOR port : actor.inputs»
					«val connection = incomingPortMap.get(port)»
					«IF connection != null»
						«connection.castfifoNameWrite»_V_dout   => «connection.castfifoNameWrite»_V_dout,
						«connection.castfifoNameWrite»_V_empty_n => «connection.castfifoNameWrite»_V_empty_n,
						«connection.castfifoNameWrite»_V_read    => «connection.castfifoNameWrite»_V_read,
					«ENDIF»
				«ENDFOR»
				«FOR portout : actor.outputs.filter[! native]»
					«FOR connection : outgoingPortMap.get(portout)»
						«connection.castfifoNameRead»_V_din    => «connection.castfifoNameRead»_V_din,
						«connection.castfifoNameRead»_V_full_n => «connection.castfifoNameRead»_V_full_n,
						«connection.castfifoNameRead»_V_write  => «connection.castfifoNameRead»_V_write,
					«ENDFOR»
				«ENDFOR»
				«IF actor.hasAttribute(DIRECTIVE_DEBUG)»
				«FOR action : actor.actions»	
					myStream_cast_tab_«action.name»_read_V_din    => myStream_cast_tab_«action.name»_read_V_din,
					myStream_cast_tab_«action.name»_read_V_full_n => myStream_cast_tab_«action.name»_read_V_full_n,
					myStream_cast_tab_«action.name»_read_V_write  => myStream_cast_tab_«action.name»_read_V_write,
				«ENDFOR»
			«ENDIF»
				ap_return => ap_return
			);
		
				clockProcess : process
				begin
					wait for OFFSET;
					clock_LOOP : loop
						ap_clk <= '0';
						      wait for (PERIOD - (PERIOD * DUTY_CYCLE));
						      ap_clk <= '1';
						      wait for (PERIOD * DUTY_CYCLE);
						end loop clock_LOOP;
				end process;
				
				resetProcess : process
				begin                
					wait for OFFSET;
					-- reset state for 100 ns.
					ap_rst <= '1';
					wait for 100 ns;
					ap_rst <= '0';
					wait;
				end process;
		
				WaveGen_Proc_In : process (ap_clk)
					variable Input_bit   : integer range 2147483647 downto - 2147483648;
					variable line_number : line;
					«FOR port : actor.inputs»
						«val connection = incomingPortMap.get(port)»
						«IF connection != null»
							variable count«connection.castfifoNameWrite»: integer:= 0;
						«ENDIF»
					«ENDFOR»
		
				begin
					if rising_edge(ap_clk) then
					«FOR port : actor.inputs»
						«val connection = incomingPortMap.get(port)»
						«IF connection != null»
							«printInputWaveGen(connection, connection.castfifoNameWrite)»
						«ENDIF»
					«ENDFOR»
					end if;
				end process WaveGen_Proc_In;
		
				WaveGen_Proc_Out : process (ap_clk)
					variable Input_bit   : integer range 2147483647 downto - 2147483648;
					variable line_number : line;
					«FOR port : actor.outputs.filter[! native]»
						«FOR connection : outgoingPortMap.get(port)»
							variable count«connection.castfifoNameRead»: integer:= 0;
						«ENDFOR»
					«ENDFOR»
					«IF actor.hasAttribute(DIRECTIVE_DEBUG)»
						«FOR action : actor.actions»	
							variable count_myStream_cast_tab_«action.name»_read: integer:= 0;
						«ENDFOR»
					«ENDIF»
		
				begin
					if (rising_edge(ap_clk)) then
				
						«FOR port : actor.outputs.filter[! native]»
							«FOR connection : outgoingPortMap.get(port)»								
								«printOutputWaveGen(connection, connection.castfifoNameRead)»								
							«ENDFOR»
						«ENDFOR»
						«IF actor.hasAttribute(DIRECTIVE_DEBUG)»
							«FOR action : actor.actions»						
							if ( myStream_cast_tab_«action.name»_read_V_write = '1') then
							count_myStream_cast_tab_«action.name»_read := count_myStream_cast_tab_«action.name»_read + 1;
							report "Number of myStream_cast_tab_«action.name»_read = " & integer'image(count_myStream_cast_tab_«action.name»_read);
							end if;
							«ENDFOR»
						«ENDIF»
				
				end if;
				end process WaveGen_Proc_Out;
				
		
				«FOR portout : actor.outputs.filter[! native]»
					«FOR connection : outgoingPortMap.get(portout)»						
						«connection.castfifoNameRead»_V_full_n <= '1';						
					«ENDFOR»
				«ENDFOR»
				«IF actor.hasAttribute(DIRECTIVE_DEBUG)»
					«FOR action : actor.actions»	
						myStream_cast_tab_«action.name»_read_V_full_n <= '1';
					«ENDFOR»
				«ENDIF»
		
			END;
	'''

	def printInputWaveGen(Connection connection, CharSequence Fname) '''
		case tb_FSM_bits is
			when after_reset =>
			count <= count + 1;
			
			if (count = 15) then
				tb_FSM_bits <= read_file;
				count           <= 0;
			end if;
		
			when read_file =>
			if (not endfile (sim_file_«entityName»_«connection.targetPort.name»)) then
				readline(sim_file_«entityName»_«connection.targetPort.name», line_number);
				if (line_number'length > 0 and line_number(1) /= '/') then
					read(line_number, input_bit);
					«IF connection.fifoTypeIn.int»
						«Fname»_V_dout  <= std_logic_vector(to_signed(input_bit, «connection.fifoTypeIn.sizeInBits»));
					«ENDIF»
					«IF connection.fifoTypeIn.uint»
						«Fname»_V_dout  <= std_logic_vector(to_unsigned(input_bit, «connection.fifoTypeIn.sizeInBits»));
					«ENDIF»
					«IF connection.fifoTypeIn.bool»
						if (input_bit = 1) then 
						«Fname»_V_dout  <= "1";
						else
						«Fname»_V_dout  <= "0";
						end if;
					«ENDIF»
					«Fname»_V_empty_n <= '1';
					ap_start <= '1';    
					tb_FSM_bits <= CheckRead;
				end if;
			end if;
		
			when CheckRead =>
			if (not endfile (sim_file_«entityName»_«connection.targetPort.name»)) and «Fname»_V_read = '1' then
			count«Fname» := count«Fname» + 1;
			report "Number of inputs«Fname» = " & integer'image(count«Fname»);
			«Fname»_V_empty_n <= '0';
			readline(sim_file_«entityName»_«connection.targetPort.name», line_number);
				if (line_number'length > 0 and line_number(1) /= '/') then
					read(line_number, input_bit);
						«IF connection.fifoTypeIn.int»
							«Fname»_V_dout  <= std_logic_vector(to_signed(input_bit, «connection.fifoTypeIn.sizeInBits»));
						«ENDIF»
						«IF connection.fifoTypeIn.uint»
							«Fname»_V_dout  <= std_logic_vector(to_unsigned(input_bit, «connection.fifoTypeIn.sizeInBits»));
						«ENDIF»
						«Fname»_V_empty_n <= '1';
						«IF connection.fifoTypeIn.bool»
							if (input_bit = 1) then 
							«Fname»_V_dout  <= "1";
							else
							«Fname»_V_dout  <= "0";
							end if;
						«ENDIF»
						ap_start <= '1';      
				end if;
			elsif (endfile (sim_file_«entityName»_«connection.targetPort.name»)) then
				ap_start <= '1';
				«Fname»_V_empty_n <= '0';
			end if;
		
			when others => null;
		end case;
	'''

	def printOutputWaveGen(Connection connection, CharSequence Fname) '''
			if (not endfile (sim_file_«entityName»_«connection.sourcePort.name») and «Fname»_V_write = '1') then
			count«Fname» := count«Fname» + 1;
			report "Number of outputs«Fname» = " & integer'image(count«Fname»);
			readline(sim_file_«entityName»_«connection.sourcePort.name», line_number);
			if (line_number'length > 0 and line_number(1) /= '/') then
				read(line_number, input_bit);
				«IF connection.fifoTypeOut.int»
					assert («Fname»_V_din  = std_logic_vector(to_signed(input_bit, «connection.fifoTypeOut.sizeInBits»)))
					-- report "on «Fname» incorrectly value computed : " & to_string(to_integer(to_signed(«Fname»_V_din))) & " instead of :" & to_string(input_bit)
					report "on port «Fname» incorrectly value computed : " & str(to_integer(signed(«Fname»_V_din))) & " instead of :" & str(input_bit)
					severity error;
				«ENDIF»
				«IF connection.fifoTypeOut.uint»
					assert («Fname»_V_din  = std_logic_vector(to_unsigned(input_bit, «connection.fifoTypeOut.sizeInBits»)))
					-- report "on «Fname» incorrectly value computed : " & to_string(to_integer(to_unsigned(«Fname»_V_din))) & " instead of :" & to_string(input_bit)
					report "on port «Fname» incorrectly value computed : " & str(to_integer(unsigned(«Fname»_V_din))) & " instead of :" & str(input_bit)
					severity error;
				«ENDIF»
				«IF connection.fifoTypeOut.bool»
					if (input_bit = 1) then
						assert («Fname»_V_din  = "1")
						report "on port «Fname» 0 instead of 1"
						severity error;
					else
						assert («Fname»_V_din  = "0")
						report "on port «Fname» 1 instead of 0"
						severity error;
					end if;
				«ENDIF»
		
				 	--assert («Fname»_V_din /= std_logic_vector(to_signed(input_bit, «connection.fifoTypeOut.sizeInBits»)))
				 	--report "on port «Fname» correct value computed : " & str(to_integer(signed(«Fname»_V_din))) & " equals :" & str(input_bit)
				 	--severity note;
			
			end if;
			end if;
	'''

	def castfifoNameWrite(Connection connection) '''«IF connection != null»myStream_cast_«connection.getAttribute("id").
		objectValue»_write«ENDIF»'''

	def castfifoNameRead(Connection connection) '''«IF connection != null»myStream_cast_«connection.getAttribute("id").
		objectValue»_read«ENDIF»'''

	def fifoTypeOut(Connection connection) {
		if (connection.sourcePort == null) {
			connection.targetPort.type
		} else {
			connection.sourcePort.type
		}
	}

	def fifoTypeIn(Connection connection) {
		if (connection.targetPort == null) {
			connection.sourcePort.type
		} else {
			connection.targetPort.type
		}
	}
}
