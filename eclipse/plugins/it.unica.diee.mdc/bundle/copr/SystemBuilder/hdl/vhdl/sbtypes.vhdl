-- SystemBuilder types package
--
--  2005-06-23 DBP Add a bool_vector type
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
package sb_types is
    
  -- SystemBuilder intrinsic types
  subtype int  is std_logic_vector;
  subtype bool is std_logic;
  type bool_vector is array ( natural range <> ) of bool;

  -- Convert literal arguments to the appropriate type
  function sb_literal_int( v: integer; sz: natural ) return signed;
  function sb_literal_bool( v: integer ) return bool;
  function sb_to_bool( v: boolean ) return bool;
  function sb_to_bool( v: bool ) return bool;
  function sb_to_bool( v: int ) return bool;
  function sb_to_int( v: int; s: natural ) return int;
      
  -- Functions used in setting operator generics
  function sb_min( a: natural; b: natural ) return natural;
  function sb_max( a: natural; b: natural ) return natural;
  function sb_log2_bound( x: integer ) return natural;

  constant logic0: bool := '0';
  constant false : bool := '0'; 
  constant logic1: bool := '1';
  constant true  : bool := '1';
      
  constant sb_default_width: natural := 32;
            
end package sb_types;
    
package body sb_types is

  function sb_literal_int( v: integer; sz:natural ) return signed is begin
    return to_signed( v, sz );
  end function sb_literal_int;

  function sb_literal_bool( v: integer ) return bool is begin
    if v = 0 then return '0'; else return '1'; end if;
  end function sb_literal_bool;

  function sb_to_int( v: int; s: natural ) return int is
    variable r: int( s-1 downto 0 );
  begin
    if s > v'length then
      r( s-1 downto v'length ) := ( others => v(v'length-1) );
      r( v'length-1 downto 0 ) := v;
    else
      r := v( s-1 downto 0 );
    end if;
    return r;
  end function sb_to_int;

  function sb_min( a: natural; b: natural ) return natural is begin
    if a < b then return a; else return b; end if;
  end function sb_min;

  function sb_max( a: natural; b: natural ) return natural is begin
    if a > b then return a; else return b; end if;
  end function sb_max;

  function sb_log2_bound( x: integer ) return natural is
    variable n: natural := 1;
    variable absx: integer := x;
  begin
    if x < 0 then
      absx := - x;
    end if;
    while (2 ** n) < absx loop
      n := n + 1;
    end loop;
    return n + 1;
  end function sb_log2_bound;

  function sb_to_bool( v: boolean ) return bool is
  begin
    if v then
      return logic1;
    else
      return logic0;
    end if;
  end function sb_to_bool;

  function sb_to_bool( v: bool ) return bool is
  begin
    return v;
  end function sb_to_bool;

  function sb_to_bool( v: int ) return bool is
  begin
    return v(0);
  end function sb_to_bool;
  
end package body sb_types;
