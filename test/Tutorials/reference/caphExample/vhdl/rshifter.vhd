-- -------------------------------------------------------------------------------
-- This file has been automatically generated by the Caph compiler (version 2.8.4d)
-- from file main.cph, on 2018-03-14 at 11:22:16, by <unknown>
-- For more information, see : http://caph.univ-bpclermont.fr
-- -------------------------------------------------------------------------------

library ieee,caph;
use ieee.std_logic_1164.all;
use caph.core.all;
use caph.data_types.all;
use ieee.numeric_std.all;

entity rshifter is
   port (
    in0_empty: in std_logic;
    in0: in std_logic_vector(15 downto 0);
    in0_rd: out std_logic;
    out0_full: in std_logic;
    out0: out std_logic_vector(15 downto 0);
    out0_wr: out std_logic;
    clock: in std_logic;
    reset: in std_logic
    );
end rshifter;

architecture FSM of rshifter is
begin
  comb: process(in0, in0_empty, out0_full)
    variable p_data : signed(15 downto 0);
  begin
    -- in0.rdy, out0.rdy / p_data=in0, wr(out0,(p_data)>>1)
    if in0_empty='0' and out0_full='0' then
      p_data := from_std_logic_vector(in0,16);
      in0_rd <= '1';
      out0 <= std_logic_vector(SHIFT_RIGHT(p_data, 1));
      out0_wr <= '1';
    else
      in0_rd <= '0';
      out0_wr <= '0';
      out0 <= (others => 'X');
    end if;
  end process;
  seq: process(clock, reset)
  begin
    if (reset='0') then
    elsif rising_edge(clock) then
    end if;
  end process;
end FSM;
