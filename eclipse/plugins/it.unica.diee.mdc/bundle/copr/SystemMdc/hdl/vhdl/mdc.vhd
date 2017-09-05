-- ----------------------------------------------------------------------------
-- Multi-Dataflow Composer Library
-- 
--	File Name: mdc.vhd
--	Last Revision Date: 2014/03/19
--
-- ----------------------------------------------------------------------------
--
-- Library composition:
--		- Sbox1x2int	(switching actor 1 in 2 outs for integer type)
--		- Sbox1x2bool	(switching actor 1 in 2 outs for boolean type)
--		- Sbox1x2float	(switching actor 1 in 2 outs for float type)
--		- Sbox1x2		(switching actor 1 in 2 outs for generic type)
--		- Sbox2x1int	(switching actor 2 in 1 outs for integer type)
--		- Sbox2x1bool	(switching actor 2 in 1 outs for boolean type)
--		- Sbox2x1float	(switching actor 2 in 1 outs for float type)
--		- Sbox2x1		(switching actor 2 in 1 outs for generic type)
--		- clk_gates		(clock gates for the power saving features)
--
-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------


-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
-- Library Entities -----------------------------------------------------------
-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- Sbox1x2int entity ----------------------------------------------------------
-- ----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
-- ----------------------------------------------------------------------------
entity Sbox1x2int is
  generic (
    size: integer );
  port ( 
		-- Instance Sbox1x2int Input(s)
		in1_data 	: in std_logic_vector(size-1 downto 0);
		in1_send 	: in std_logic;
		in1_ack	 	: out std_logic;
		in1_rdy	 	: out std_logic;
		in1_count	: in std_logic_vector(15 downto 0);
		-- Instance Sbox1x2int Output(s)
		out1_data 	: out std_logic_vector(size-1 downto 0);
		out1_send 	: out std_logic;
		out1_ack 	: in std_logic; 
		out1_rdy		: in std_logic;
		out1_count	: out std_logic_vector(15 downto 0);
		
		out2_data 	: out std_logic_vector(size-1 downto 0);
		out2_send	: out std_logic;
		out2_ack		: in std_logic;
		out2_rdy		: in std_logic;
		out2_count	: out std_logic_vector(15 downto 0);
		-- Instance Sbox1x2int Selector
		sel			: in std_logic);
end entity Sbox1x2int;
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- Sbox1x2bool entity ---------------------------------------------------------
-- ----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
-- ----------------------------------------------------------------------------
entity Sbox1x2bool is
  generic (
    size: integer );
  port ( 
		-- Instance Sbox1x2bool Input(s)
		in1_data 	: in std_logic;
		in1_send 	: in std_logic;
		in1_ack	 	: out std_logic;
		in1_rdy	 	: out std_logic;
		in1_count	: in std_logic_vector(15 downto 0);
		-- Instance Sbox1x2bool Output(s)
		out1_data 	: out std_logic;
		out1_send 	: out std_logic;
		out1_ack 	: in std_logic; 
		out1_rdy		: in std_logic;
		out1_count	: out std_logic_vector(15 downto 0);
		
		out2_data 	: out std_logic;
		out2_send	: out std_logic;
		out2_ack		: in std_logic;
		out2_rdy		: in std_logic;
		out2_count	: out std_logic_vector(15 downto 0);
		-- Instance Sbox1x2bool Selector
		sel			: in std_logic);
end entity Sbox1x2bool;
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- Sbox1x2float entity --------------------------------------------------------
-- ----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
-- ----------------------------------------------------------------------------
entity Sbox1x2float is
  generic (
    size: integer );
  port ( 
		-- Instance Sbox1x2float Input(s)
		in1_data 	: in std_logic_vector(size-1 downto 0);
		in1_send 	: in std_logic;
		in1_ack	 	: out std_logic;
		in1_rdy	 	: out std_logic;
		in1_count	: in std_logic_vector(15 downto 0);
		-- Instance Sbox1x2float Output(s)
		out1_data 	: out std_logic_vector(size-1 downto 0);
		out1_send 	: out std_logic;
		out1_ack 	: in std_logic; 
		out1_rdy		: in std_logic;
		out1_count	: out std_logic_vector(15 downto 0);
		
		out2_data 	: out std_logic_vector(size-1 downto 0);
		out2_send	: out std_logic;
		out2_ack		: in std_logic;
		out2_rdy		: in std_logic;
		out2_count	: out std_logic_vector(15 downto 0);
		-- Instance Sbox1x2float Selector
		sel			: in std_logic);
end entity Sbox1x2float;
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- Sbox1x2 entity -------------------------------------------------------------
-- ----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
-- ----------------------------------------------------------------------------
entity Sbox1x2 is
  generic (
    size: integer );
  port ( 
		-- Instance Sbox1x2 Input(s)
		in1_data 	: in std_logic_vector(size-1 downto 0);
		in1_send 	: in std_logic;
		in1_ack	 	: out std_logic;
		in1_rdy	 	: out std_logic;
		in1_count	: in std_logic_vector(15 downto 0);
		-- Instance Sbox1x2 Output(s)
		out1_data 	: out std_logic_vector(size-1 downto 0);
		out1_send 	: out std_logic;
		out1_ack 	: in std_logic; 
		out1_rdy		: in std_logic;
		out1_count	: out std_logic_vector(15 downto 0);
		
		out2_data 	: out std_logic_vector(size-1 downto 0);
		out2_send	: out std_logic;
		out2_ack		: in std_logic;
		out2_rdy		: in std_logic;
		out2_count	: out std_logic_vector(15 downto 0);
		-- Instance Sbox1x2 Selector
		sel			: in std_logic);
end entity Sbox1x2;
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- Sbox2x1int entity ----------------------------------------------------------
-- ----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
-- ----------------------------------------------------------------------------
entity Sbox2x1int is
  generic (
		size			: integer );
  port (
		-- Entity Sbox2x1int Input(s)
		in1_data 	: in std_logic_vector(size-1 downto 0);
		in1_send 	: in std_logic;
		in1_ack	 	: out std_logic;
		in1_rdy	 	: out std_logic;
		in1_count	: in std_logic_vector(15 downto 0);
		
		in2_data 	: in std_logic_vector(size-1 downto 0);
		in2_send 	: in std_logic;
		in2_ack	 	: out std_logic;
		in2_rdy	 	: out std_logic;
		in2_count	: in std_logic_vector(15 downto 0);
		-- Entity Sbox2x1int Output(s)
		out1_data 	: out std_logic_vector(size-1 downto 0);
		out1_send 	: out std_logic;
		out1_ack 	: in std_logic; 
		out1_rdy		: in std_logic;
		out1_count	: out std_logic_vector(15 downto 0);
		-- Entity Sbox2x1int Selector
		sel			: in std_logic);
end entity Sbox2x1int;
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- Sbox2x1bool entity ---------------------------------------------------------
-- ----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
-- ----------------------------------------------------------------------------
entity Sbox2x1bool is
  generic (
		size			: integer );
  port (
		-- Entity Sbox2x1bool Input(s)
		in1_data 	: in std_logic;
		in1_send 	: in std_logic;
		in1_ack	 	: out std_logic;
		in1_rdy	 	: out std_logic;
		in1_count	: in std_logic_vector(15 downto 0);
		
		in2_data 	: in std_logic;
		in2_send 	: in std_logic;
		in2_ack	 	: out std_logic;
		in2_rdy	 	: out std_logic;
		in2_count	: in std_logic_vector(15 downto 0);
		-- Entity Sbox2x1bool Output(s)
		out1_data 	: out std_logic;
		out1_send 	: out std_logic;
		out1_ack 	: in std_logic; 
		out1_rdy		: in std_logic;
		out1_count	: out std_logic_vector(15 downto 0);
		-- Entity Sbox2x1bool Selector
		sel			: in std_logic);
end entity Sbox2x1bool;
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- Sbox2x1float entity --------------------------------------------------------
-- ----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
-- ----------------------------------------------------------------------------
entity Sbox2x1float is
  generic (
		size			: integer );
  port (
		-- Entity Sbox2x1float Input(s)
		in1_data 	: in std_logic_vector(size-1 downto 0);
		in1_send 	: in std_logic;
		in1_ack	 	: out std_logic;
		in1_rdy	 	: out std_logic;
		in1_count	: in std_logic_vector(15 downto 0);
		
		in2_data 	: in std_logic_vector(size-1 downto 0);
		in2_send 	: in std_logic;
		in2_ack	 	: out std_logic;
		in2_rdy	 	: out std_logic;
		in2_count	: in std_logic_vector(15 downto 0);
		-- Entity Sbox2x1float Output(s)
		out1_data 	: out std_logic_vector(size-1 downto 0);
		out1_send 	: out std_logic;
		out1_ack 	: in std_logic; 
		out1_rdy		: in std_logic;
		out1_count	: out std_logic_vector(15 downto 0);
		-- Entity Sbox2x1float Selector
		sel			: in std_logic);
end entity Sbox2x1float;
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- Sbox2x1 entity -------------------------------------------------------------
-- ----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
-- ----------------------------------------------------------------------------
entity Sbox2x1 is
  generic (
		size			: integer );
  port (
		-- Entity Sbox2x1 Input(s)
		in1_data 	: in std_logic_vector(size-1 downto 0);
		in1_send 	: in std_logic;
		in1_ack	 	: out std_logic;
		in1_rdy	 	: out std_logic;
		in1_count	: in std_logic_vector(15 downto 0);
		
		in2_data 	: in std_logic_vector(size-1 downto 0);
		in2_send 	: in std_logic;
		in2_ack	 	: out std_logic;
		in2_rdy	 	: out std_logic;
		in2_count	: in std_logic_vector(15 downto 0);
		-- Entity Sbox2x1 Output(s)
		out1_data 	: out std_logic_vector(size-1 downto 0);
		out1_send 	: out std_logic;
		out1_ack 	: in std_logic; 
		out1_rdy		: in std_logic;
		out1_count	: out std_logic_vector(15 downto 0);
		-- Entity Sbox2x1 Selector
		sel			: in std_logic);
end entity Sbox2x1;
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- clk_gates entity -----------------------------------------------------------
-- ----------------------------------------------------------------------------

library ieee,unisim;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use unisim.vcomponents.all;
-- ----------------------------------------------------------------------------
entity clk_gates is
	generic (
		count			: integer );
	port(
		-- Entity clk_gates Inputs
		clock_in		: in std_logic;
		clocks_en	: in std_logic_vector(count-1 downto 0);
		-- Entity clk_gates Inputs
		clocks		: out std_logic_vector(count-1 downto 0));
end entity clk_gates;
-- ----------------------------------------------------------------------------



-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
-- Library Architectures ------------------------------------------------------
-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- Sbox1x2int architecture ----------------------------------------------------
-- ----------------------------------------------------------------------------
architecture behavioral of Sbox1x2int is
begin
	out1_data <= in1_data when sel='0' else (size-1 downto 0 => '0');
	out2_data <= in1_data when sel='1' else (size-1 downto 0 => '0');
	out1_send <= in1_send when sel='0' else '0';
	out2_send <= in1_send when sel='1' else '0';
	in1_ack <= out1_ack when sel='0' else out2_ack;
	in1_rdy <= out1_rdy when sel='0' else out2_rdy; 
	out1_count <= in1_count when sel='0' else (15 downto 0 => '0');
	out2_count <= in1_count when sel='1' else (15 downto 0 => '0');
end architecture behavioral;
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- Sbox1x2bool architecture ----------------------------------------------------
-- ----------------------------------------------------------------------------
architecture behavioral of Sbox1x2bool is
begin
	out1_data <= in1_data when sel='0' else '0';
	out2_data <= in1_data when sel='1' else '0';
	out1_send <= in1_send when sel='0' else '0';
	out2_send <= in1_send when sel='1' else '0';
	in1_ack <= out1_ack when sel='0' else out2_ack;
	in1_rdy <= out1_rdy when sel='0' else out2_rdy; 
	out1_count <= in1_count when sel='0' else (15 downto 0 => '0');
	out2_count <= in1_count when sel='1' else (15 downto 0 => '0');
end architecture behavioral;
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- Sbox1x2float architecture ---------------------------------------------------
-- ----------------------------------------------------------------------------
architecture behavioral of Sbox1x2float is
begin
	out1_data <= in1_data when sel='0' else (size-1 downto 0 => '0');
	out2_data <= in1_data when sel='1' else (size-1 downto 0 => '0');
	out1_send <= in1_send when sel='0' else '0';
	out2_send <= in1_send when sel='1' else '0';
	in1_ack <= out1_ack when sel='0' else out2_ack;
	in1_rdy <= out1_rdy when sel='0' else out2_rdy; 
	out1_count <= in1_count when sel='0' else (15 downto 0 => '0');
	out2_count <= in1_count when sel='1' else (15 downto 0 => '0');
end architecture behavioral;
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- Sbox1x2 architecture -------------------------------------------------------
-- ----------------------------------------------------------------------------
architecture behavioral of Sbox1x2 is
begin
	out1_data <= in1_data when sel='0' else (size-1 downto 0 => '0');
	out2_data <= in1_data when sel='1' else (size-1 downto 0 => '0');
	out1_send <= in1_send when sel='0' else '0';
	out2_send <= in1_send when sel='1' else '0';
	in1_ack <= out1_ack when sel='0' else out2_ack;
	in1_rdy <= out1_rdy when sel='0' else out2_rdy; 
	out1_count <= in1_count when sel='0' else (15 downto 0 => '0');
	out2_count <= in1_count when sel='1' else (15 downto 0 => '0');
end architecture behavioral;
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- Sbox2x1int architecture ----------------------------------------------------
-- ----------------------------------------------------------------------------
architecture behavioral of Sbox2x1int is
begin
	out1_data <= in1_data when sel='0' else in2_data;
	out1_send <= in1_send when sel='0' else in2_send;
	in1_ack <= out1_ack when sel='0' else '0';
	in2_ack <= out1_ack when sel='1' else '0';
	in1_rdy <= out1_rdy when sel='0' else '0';
	in2_rdy <= out1_rdy when sel='1' else '0'; 
	out1_count <= in1_count when sel='0' else in2_count;
end architecture behavioral;
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- Sbox2x1bool architecture ---------------------------------------------------
-- ----------------------------------------------------------------------------
architecture behavioral of Sbox2x1bool is
begin
	out1_data <= in1_data when sel='0' else in2_data;
	out1_send <= in1_send when sel='0' else in2_send;
	in1_ack <= out1_ack when sel='0' else '0';
	in2_ack <= out1_ack when sel='1' else '0';
	in1_rdy <= out1_rdy when sel='0' else '0';
	in2_rdy <= out1_rdy when sel='1' else '0'; 
	out1_count <= in1_count when sel='0' else in2_count;
end architecture behavioral;
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- Sbox2x1float architecture --------------------------------------------------
-- ----------------------------------------------------------------------------
architecture behavioral of Sbox2x1float is
begin
	out1_data <= in1_data when sel='0' else in2_data;
	out1_send <= in1_send when sel='0' else in2_send;
	in1_ack <= out1_ack when sel='0' else '0';
	in2_ack <= out1_ack when sel='1' else '0';
	in1_rdy <= out1_rdy when sel='0' else '0';
	in2_rdy <= out1_rdy when sel='1' else '0'; 
	out1_count <= in1_count when sel='0' else in2_count;
end architecture behavioral;
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- Sbox2x1 architecture -------------------------------------------------------
-- ----------------------------------------------------------------------------
architecture behavioral of Sbox2x1 is
begin
	out1_data <= in1_data when sel='0' else in2_data;
	out1_send <= in1_send when sel='0' else in2_send;
	in1_ack <= out1_ack when sel='0' else '0';
	in2_ack <= out1_ack when sel='1' else '0';
	in1_rdy <= out1_rdy when sel='0' else '0';
	in2_rdy <= out1_rdy when sel='1' else '0'; 
	out1_count <= in1_count when sel='0' else in2_count;
end architecture behavioral;
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- clk_gates architecture ----------------------------------------------------
-- ----------------------------------------------------------------------------
architecture behavioral of clk_gates is
begin
	gen_gated_clock: 
   for i in 0 to count-1 generate
      GATEX : BUFGCE
			port map (
				I => clock_in,
				CE => clocks_en(i),
				O => clocks(i));
   end generate gen_gated_clock;
end architecture behavioral;
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------