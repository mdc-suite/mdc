-- sbfifo_behavioral.vhd
--
-- Xilinx Confidential
-- Copyright (c) 2004,2005 Xilinx Inc.

--   2005-06-23 DBP   Corrected fanout implementation

-----------------------------------------------------------------------
--

architecture behavioral of ram_1p_int is
  constant abits : positive := SystemBuilder.fifo_utilities.address_bits( l );
  constant asize : positive := 2 ** abits;
  type mem_type is array ( asize-1 downto 0 ) of int(w-1 downto 0);
  signal mem: mem_type;
begin
  process( SB_clock )
  begin
    if rising_edge(SB_clock) then
      if we = '1' then
        mem(conv_integer (addr)) <= din;
      end if;
      if re = '1' then
        dout <= mem(conv_integer (addr));
      end if;
    end if;
  end process;
end architecture behavioral;

architecture behavioral of ram_1p_bool is
  constant abits : positive := SystemBuilder.fifo_utilities.address_bits( l );
  constant asize : positive := 2 ** abits;
  type mem_type is array ( asize-1 downto 0 ) of bool;
  signal mem: mem_type;
begin
  process( SB_clock )
  begin
    if rising_edge(SB_clock) then
      if we = '1' then
        mem(conv_integer (addr)) <= din;
      end if;
      if re = '1' then
        dout <= mem(conv_integer (addr));
      end if;
    end if;
  end process;
end architecture behavioral;

architecture behavioral of ram_2p_int is
  constant abits : positive := SystemBuilder.fifo_utilities.address_bits( l );
  constant asize : positive := 2 ** abits;
  type mem_type is array ( asize-1 downto 0 ) of int(w-1 downto 0);
  signal mem: mem_type;
begin
  process( SB_clock )
  begin
    if rising_edge(SB_clock) then
      if we_a = '1' then
        mem(conv_integer (addr_a)) <= din_a;
      end if;
    end if;
  end process;

  process( SB_clock )
  begin
    if rising_edge(SB_clock) then
      if re_b = '1' then
        dout_b <= mem( conv_integer(addr_b) );
      end if;	
    end if;
  end process;

end architecture behavioral;


architecture behavioral_distributed of ram_2p_int is
  constant abits : positive := SystemBuilder.fifo_utilities.address_bits( l );
  constant asize : positive := 2 ** abits;
  type mem_type is array ( asize-1 downto 0 ) of int(w-1 downto 0);
  signal mem: mem_type;
  attribute ram_style: string;
  attribute ram_style of mem : signal is "distributed";
begin
  process( SB_clock )
  begin
    if rising_edge(SB_clock) then
      if we_a = '1' then
        mem(conv_integer (addr_a)) <= din_a;
      end if;
    end if;
  end process;

  process( SB_clock )
  begin
    if rising_edge(SB_clock) then
      if re_b = '1' then
        dout_b <= mem( conv_integer(addr_b) );
      end if;	
    end if;
  end process;

end architecture behavioral_distributed;

architecture behavioral of ram_2p_bool is
  constant abits : positive := SystemBuilder.fifo_utilities.address_bits( l );
  constant asize : positive := 2 ** abits;
  type mem_type is array ( asize-1 downto 0 ) of bool;
  signal mem: mem_type;
begin
  process( SB_clock )
  begin
    if rising_edge(SB_clock) then
      if we_a = '1' then
        mem(conv_integer (addr_a)) <= din_a;
      end if;
    end if;
  end process;

  process( SB_clock )
  begin
    if rising_edge(SB_clock) then
      if re_b = '1' then	
        dout_b <= mem( conv_integer(addr_b) );
      end if;
    end if;
  end process;
  
end architecture behavioral;

-- DBP: Synplicity requires registered read address
architecture behavioral of ram_2p_dualclock_int is
  constant abits : positive := SystemBuilder.fifo_utilities.address_bits( l );
  constant asize : positive := 2 ** abits;
  type mem_type is array ( asize-1 downto 0 ) of int(w-1 downto 0);
  shared variable mem: mem_type;
  signal reg_addr_b : std_logic_vector(abits-1 downto 0); 
begin
  process( SB_clock_a )
  begin
    if rising_edge(SB_clock_a) then
      if en_a = '1' then
        -- if we_a = '1' then
          mem(conv_integer (addr_a)) := din_a;
        -- end if;
        -- dout_a <= mem(conv_integer (addr_a));
      end if;
    end if;
  end process;

  -- dout_a <= mem(conv_integer (reg_addr_a));

  process( SB_clock_b )
  begin
    if rising_edge(SB_clock_b) then	
      if en_b = '1' then
        -- if we_b = '1' then
        --    mem(conv_integer (addr_b)) := din_b;
        --  end if;
        -- dout_b <= mem(conv_integer (addr_b));
        reg_addr_b <= addr_b;
      end if;
    end if;
  end process;

  dout_b <= mem(conv_integer (reg_addr_b));

end architecture behavioral;

architecture behavioral of ram_2p_dualclock_bool is
  constant abits : positive := SystemBuilder.fifo_utilities.address_bits( l );
  constant asize : positive := 2 ** abits;
  type mem_type is array ( asize-1 downto 0 ) of bool;
  shared variable mem: mem_type;
  signal reg_addr_b : std_logic_vector(abits-1 downto 0);
begin
  process( SB_clock_a )
  begin
    if rising_edge(SB_clock_a) then
      if en_a = '1' then
        -- if we_a = '1' then
          mem(conv_integer (addr_a)) := din_a;
        -- end if;
        -- dout_a <= mem(conv_integer (addr_a));
      end if;
    end if;
  end process;

  process( SB_clock_b )
  begin
    if rising_edge(SB_clock_b) then	
      if en_b = '1' then
        -- if we_b = '1' then
        --   mem(conv_integer (addr_b)) := din_b;
        -- end if;
        -- dout_b <= mem(conv_integer (addr_b));
        reg_addr_b <= addr_b;
      end if;
    end if;
  end process;

  dout_b <= mem(conv_integer (reg_addr_b));

end architecture behavioral;

architecture behavioral of async_fifo_controller is
  constant abits : positive := SystemBuilder.fifo_utilities.address_bits( l );
  constant asize : positive := 2 ** abits;

  -- initializations for the address counters, registered gray versions
  -- Note: 'next gray' is computed by converting current binary address
  -- to gray, i.e. we are using an offset gray code where binary 0 is
  -- 10000000 gray.
  constant init_addr: std_logic_vector( abits-1 downto 0 ) := ( others => '0' );
  constant init_lastgray: std_logic_vector( abits-1 downto 0 )
     := SystemBuilder.fifo_utilities.bin2gray(conv_std_logic_vector(-3,abits));
  constant init_addrgray: std_logic_vector( abits-1 downto 0 )
     := SystemBuilder.fifo_utilities.bin2gray(conv_std_logic_vector(-2,abits));
  constant init_nextgray: std_logic_vector( abits-1 downto 0 )
     := SystemBuilder.fifo_utilities.bin2gray(conv_std_logic_vector(-1,abits));

  signal read_addr    : std_logic_vector( abits-1 downto 0 );
  signal read_lastgray: std_logic_vector( abits-1 downto 0 );
  signal read_addrgray: std_logic_vector( abits-1 downto 0 );
  signal read_nextgray: std_logic_vector( abits-1 downto 0 );
  signal read_allow: std_logic;
  signal o_send_flag: std_logic;

  signal write_addr    : std_logic_vector( abits-1 downto 0 );
  signal write_addrgray: std_logic_vector( abits-1 downto 0 );
  signal write_nextgray: std_logic_vector( abits-1 downto 0 );
  signal write_allow: std_logic;

  signal empty_asynch: std_logic;
  signal empty: std_logic;
  signal empty_allow: std_logic;

  signal full_asynch: std_logic;
  signal full: std_logic;
  signal full_allow: std_logic;
  
  constant delay: time := 1 ns;

begin

  i_mem_addr <= write_addr after delay;
  i_mem_enable <= write_allow after delay;
  i_full <= full after delay;
  
  o_mem_addr <= read_addr after delay;
  o_mem_enable <= read_allow after delay;

  -- input side addressing
  process( SB_clock_i, SB_reset_i ) is
  begin
    if( SB_reset_i = '1' ) then

      write_addr <= init_addr;
      write_nextgray <= init_nextgray;
      write_addrgray <= init_addrgray;

    elsif( rising_edge( SB_clock_i ) ) then
      if write_allow = '1' then

        -- run the write address counter
        write_addr <= write_addr + 1;

        -- advance to next gray addr
        write_addrgray <= write_nextgray;
        write_nextgray <= SystemBuilder.fifo_utilities.bin2gray( write_addr );

      end if; -- write_allow

    end if;
  end process;

  -- input side controls
  -- Note: added small delay to avoid convergence problem when simulating
  -- with same input and output clocks.
  full_asynch <= '1' after delay when ( (read_lastgray = write_addrgray) and (full = '1') ) else
                 '1' after delay when ( (read_lastgray = write_nextgray) and (full = '0') ) else
                 '0' after delay;
  write_allow <= (not full and i_send ) after delay;
  full_allow  <= (full or (i_send)) after delay;

  i_ack <= write_allow after delay;

  process( SB_clock_i, SB_reset_i )
  begin
    if( SB_reset_i = '1') then
      full <= '1';
    elsif rising_edge( SB_clock_i ) then
      if full_allow = '1' then
        full <= full_asynch;
      end if;
    end if;
  end process;
 
  -- output side controls
  empty_asynch <= '1' after delay when ( (write_addrgray = read_addrgray) and (empty = '1') ) else
                  '1' after delay when ( (write_addrgray = read_nextgray) and (empty = '0') ) else
                  '0' after delay;

  read_allow <= ( not empty ) and ( (not o_send_flag) or o_ack ) after delay;
  empty_allow <= (empty) or (not o_send_flag) or o_ack after delay;

  o_send <= o_send_flag after delay;

  process( SB_clock_o, SB_reset_o )
  begin
    if SB_reset_o = '1' then
      o_send_flag <= '0';
    elsif rising_edge( SB_clock_o ) then
--      assert o_ack = '0' or o_send_flag = '1' report "Send/ack protocol failure" severity failure;
      o_send_flag <= (not empty) or not ( o_ack or (not o_send_flag ) ); --read_allow;
    end if;
  end process;

  process( SB_clock_o, SB_reset_o )
  begin
    if( SB_reset_o = '1') then
      empty <= '1';
    elsif( rising_edge( SB_clock_o ) ) then
      if( empty_allow = '1' ) then
        empty <= empty_asynch;
      end if;
    end if;
  end process;

  -- output side addressing
  process( SB_clock_o, SB_reset_o ) is
  begin
    if( SB_reset_o = '1' ) then

      read_addr <= init_addr;
      read_nextgray <= init_nextgray;
      read_addrgray <= init_addrgray;
      read_lastgray <= init_lastgray;
 
    elsif( rising_edge( SB_clock_o ) ) then
      if( read_allow = '1' ) then

        -- run the read address counter
        read_addr <= read_addr + 1;

        -- advance to next gray addr
        read_lastgray <= read_addrgray;
        read_addrgray <= read_nextgray;
        read_nextgray <= SystemBuilder.fifo_utilities.bin2gray( read_addr );

      end if; -- read_allow
    end if;

  end process;
  
end architecture behavioral;

architecture behavioral of async_fifo_int is
  constant abits : positive := SystemBuilder.fifo_utilities.address_bits( l );
  constant asize : positive := 2 ** abits;
  constant all_zeros : int( w-1 downto 0) := (others => '0');
  
  signal read_addr    : std_logic_vector( abits - 1 downto 0 );
  signal read_enable  : std_logic;
  signal write_addr   : std_logic_vector( abits - 1 downto 0 );
  signal write_enable : std_logic;
  signal is_full : std_logic;
  signal o_sending : std_logic;

begin

  i_rdy <= not(is_full);
  o_count <= (15 downto 1=>'0', 0=>o_sending);
  o_send <= o_sending;

  ctl: entity SystemBuilder.async_fifo_controller( behavioral )
    generic map ( l => l )
    port map (
      SB_reset_i => SB_reset_i,
      SB_clock_i => SB_clock_i,
      i_send => i_send,
      i_ack => i_ack,
      i_mem_addr => write_addr,
      i_mem_enable => write_enable,
      i_full => is_full,
      SB_reset_o => SB_reset_o,
      SB_clock_o => SB_clock_o,
      o_send => o_sending,
      o_ack => o_ack,
      o_mem_addr => read_addr,
      o_mem_enable => read_enable );

  ram: entity SystemBuilder.ram_2p_dualclock_int( behavioral )
    generic map ( w => w, l => l )
    port map (
      din_a => i_data,
      addr_a => write_addr,
      en_a => write_enable,
      -- we_a => write_enable,
      -- dout_a => open,
      -- din_b => all_zeros,
      addr_b => read_addr,
      en_b => read_enable,
      -- we_b => '0',
      dout_b => o_data,
      SB_clock_a => SB_clock_i,
      SB_clock_b => SB_clock_o );

end architecture behavioral;

architecture behavioral of async_fifo_bool is
  constant abits : positive := SystemBuilder.fifo_utilities.address_bits( l );
  constant asize : positive := 2 ** abits;

  signal read_addr    : std_logic_vector( abits - 1 downto 0 );
  signal read_enable  : std_logic;
  signal write_addr   : std_logic_vector( abits - 1 downto 0 );
  signal write_enable : std_logic;
  signal is_full : std_logic;
  signal o_sending : std_logic;
  
begin

  i_rdy <= not(is_full);
  o_count <= (15 downto 1=>'0', 0=>o_sending);
  o_send <= o_sending;

  ctl: entity SystemBuilder.async_fifo_controller( behavioral )
    generic map ( l => l )
    port map (
      SB_reset_i => SB_reset_i,
      SB_clock_i => SB_clock_i,
      i_send => i_send,
      i_ack => i_ack,
      i_mem_addr => write_addr,
      i_mem_enable => write_enable,
      i_full => is_full,
      SB_reset_o => SB_reset_o,
      SB_clock_o => SB_clock_o,
      o_send => o_send,
      o_ack => o_ack,
      o_mem_addr => read_addr,
      o_mem_enable => read_enable );

  ram: entity SystemBuilder.ram_2p_dualclock_bool( behavioral )
    generic map ( l => l )
    port map (
      din_a => i_data,
      addr_a => write_addr,
      en_a => write_enable,
      -- we_a => write_enable,
      -- dout_a => open,
      -- din_b => SystemBuilder.sb_types.false,
      addr_b => read_addr,
      en_b => read_enable,
      -- we_b => '0',
      dout_b => o_data,
      SB_clock_a => SB_clock_i,
      SB_clock_b => SB_clock_o );

end architecture behavioral;

architecture behavioral of sync_fifo_controller is
  constant abits : positive := SystemBuilder.fifo_utilities.address_bits( l );
  constant asize : positive := 2 ** abits;

  signal read_addr: std_logic_vector( abits-1 downto 0);
  signal write_addr: std_logic_vector( abits-1 downto 0);
  signal going_empty, going_full, match_means_empty, is_full, is_empty, match: std_logic;
  signal msread, mswrite: std_logic_vector(1 downto 0);
  signal write, read, sending : std_logic;
  constant start_addr : std_logic_vector( abits-1 downto 0 ) := (others => '0' );
begin

  msread <= read_addr( abits-1 downto abits-2 );
  mswrite <= write_addr( abits-1 downto abits-2 );
  
  -- Detect the read address just behind the write address
  going_empty  <= '1' when
      ( msread = 0 and mswrite = 1 ) or
      ( msread = 1 and mswrite = 2 ) or
      ( msread = 2 and mswrite = 3 ) or
      ( msread = 3 and mswrite = 0 )
    else '0';

  -- Detect the write address just behind the read address
  going_full  <= '1' when
      ( mswrite = 0 and msread = 1 ) or
      ( mswrite = 1 and msread = 2 ) or
      ( mswrite = 2 and msread = 3 ) or
      ( mswrite = 3 and msread = 0 )
    else '0';

  -- Predict the meaning of a read/write address match
  -- If there is no going_empty or going_full indication, keep the same prediction
  process( SB_clock, SB_reset )
  begin
    if SB_reset = '1' then
      match_means_empty <= '1';
    elsif rising_edge( SB_clock ) then
      if going_empty = '1' then
        match_means_empty <= '1';
      elsif going_full = '1' then
        match_means_empty <= '0';
      end if;
    end if;
  end process; 

  match <= '1' when (read_addr = write_addr) else '0';
  is_full  <= match and not match_means_empty;
  is_empty <= match and match_means_empty;

  -- Input side address and controls
  write <= i_send and not is_full;
  process( input_clock, SB_reset )
  begin
    if SB_reset = '1' then
      write_addr <= start_addr;
    elsif rising_edge( input_clock ) then
      if write = '1' then
        write_addr <= write_addr + 1;
      end if;
    end if;
  end process;
  i_ack <= write;
  i_mem_addr <= write_addr;
  i_mem_enable <= write;
  
  -- Output side address and controls.  NOTE: This 'not sending' clause
  -- converts this queue fifo into a first-word-fall-through (FWFT).
  read <= ( (not sending) or o_ack ) and (not is_empty);
  process( output_clock, SB_reset )
  begin
    if SB_reset = '1' then
      read_addr <= start_addr;
    elsif rising_edge( output_clock ) then
      if read = '1' then
        read_addr <= read_addr + '1';
      end if;
    end if;
  end process;
  process( output_clock, SB_reset )
  begin
    if SB_reset = '1' then
      sending <= '0';
    elsif rising_edge( output_clock ) then
      if read = '1' then
        sending <= '1';
      elsif o_ack = '1' then
        sending <= '0';
      end if;
    end if;
  end process; 
   
  o_mem_addr <= read_addr;
  o_mem_enable <= read;
  o_send <= sending;

  full <= is_full;
  empty <= is_empty;        
end architecture behavioral;


architecture behavioral of msync_fifo_int is

begin
  -- Length 0, 1 are supported as special cases
  -- See not for why length 1 is no longer a special case
  fifo_zero: if l <= 1 generate
    signal reg_dat: int(w-1 downto 0);
    signal reg_valid: std_logic;
    signal write, read: std_logic;
    
  begin
    -- Pass through
    -- o <= i;
    -- o_send <= i_send;
    -- i_ack <= o_ack;
    -- full <= i_send and not o_ack;
    -- empty <= not (i_send and not o_ack);
    -- size <= b"000";
    
    -- Zero length is register with ability to read and write simultaneously
    read <= o_ack;
    write <= (not(reg_valid) or read) and i_send;
    i_ack <= write;
    o <= reg_dat;
    o_send <= reg_valid;
    full <= reg_valid and not(read);
    empty <= not(reg_valid) or read;

    process (SB_clock, SB_reset) is begin
      if SB_reset = '1' then
        reg_dat <= (others => '0');
        reg_valid <= '0';
      elsif rising_edge( SB_clock ) then
        reg_valid <= (reg_valid and not(read)) or write;
        if write = '1' then
          reg_dat <= i;
        end if;
      end if;
    end process;
    
  end generate fifo_zero;

  -- length 1 breaks the combinatorial path
  -- IDM 06.2007.  Breaking the combinatorial path with a register effectively
  -- halves the throughput.  No longer supported as an option.
--   fifo_one: if l = 1 generate
--     signal is_full, write : std_logic;
--     signal reg_dat: int(w-1 downto 0);
--   begin
--     write <= i_send and (not is_full);
--     process( SB_clock, SB_reset ) is
--     begin
--       if SB_reset = '1' then
--         is_full <= '0';
--       elsif rising_edge( SB_clock ) then
--         if write = '1' then
--           is_full <= '1';
--         elsif is_full = '1' and o_ack = '1' then
--           is_full <= '0';
--         end if;
--       end if;
--     end process;
--     process( SB_clock ) is
--     begin
--       if rising_edge( SB_clock ) then
--         if write = '1' then
--           reg_dat <= i;
--         end if;
--       end if;
--     end process;
--     i_ack <= write;
--     o <= reg_dat;
--     o_send <= is_full;
--     full <= is_full;
--     empty <= not is_full;
--     size <= b"001" when is_full = '1' else b"000";
--    end generate fifo_one;
   
  -- For requested FIFO length greater than 1, implement length at least 4 (needed for FIFO
  -- controller code to work, and round the length up to a power of 2.
  fifo_many: if l > 1 generate
    constant abits : positive := SystemBuilder.fifo_utilities.address_bits( l );
    constant asize : positive := 2 ** abits;
    signal read_addr    : std_logic_vector( SystemBuilder.fifo_utilities.address_bits( l ) - 1 downto 0 );
    signal read_enable  : std_logic;
    signal write_addr   : std_logic_vector( SystemBuilder.fifo_utilities.address_bits( l ) - 1 downto 0 );
    signal write_enable : std_logic;
  begin
--     size <= std_logic_vector(resize(unsigned(write_addr) - unsigned(read_addr),
--                    abits + 1))
--           when write_addr >= read_addr else
--             std_logic_vector(to_unsigned(asize, abits + 1) - resize(unsigned(read_addr) - unsigned(write_addr), abits + 1));
    
    ctl: entity SystemBuilder.sync_fifo_controller( behavioral )
      generic map ( l => l )
      port map (
        SB_reset => SB_reset,
        SB_clock => SB_clock,
        input_clock => input_clock,
        output_clock => output_clock,
        i_send => i_send,
        i_ack => i_ack,
        i_mem_addr => write_addr,
        i_mem_enable => write_enable,
        o_send => o_send,
        o_ack => o_ack,
        o_mem_addr => read_addr,
        o_mem_enable => read_enable,
        full => full,
        empty => empty);
    ram: entity SystemBuilder.ram_2p_int( behavioral )
      generic map ( w => w, l => l )
      port map (
        din_a => i,
        addr_a => write_addr,
        we_a => write_enable,
        addr_b => read_addr,
        re_b => read_enable,
        dout_b => o,
        SB_clock => SB_clock );
  end generate fifo_many;

end architecture behavioral;

architecture behavioral of sync_fifo_int is
  signal msync_full : std_logic;
  signal msync_o_send : std_logic;
  
begin
  i_rdy <= not (msync_full);
  o_count <= (15 downto 1=>'0', 0=>msync_o_send);
  o_send <= msync_o_send;
  
  fifo: entity SystemBuilder.msync_fifo_int(behavioral) generic map(
    l => l, w => w)
  port map(
      SB_clock => SB_clock,
      input_clock => SB_clock,
      output_clock => SB_clock,
      SB_reset => SB_reset,
      full => msync_full,

      i => i_data,
      i_send => i_send,
      i_ack => i_ack,

      o => o_data,
      o_send => msync_o_send,
      o_ack => o_ack
);
end architecture behavioral;


architecture behavioral of msync_fifo_bool is
begin
  -- Length 0, 1 are supported as special cases
  fifo_zero: if l <= 1 generate
    signal reg_dat: bool;
    signal reg_valid: std_logic;
    signal write, read: std_logic;
  begin
    -- Zero length is a pass-through
--     o <= i;
--     o_send <= i_send;
--     i_ack <= o_ack;
--     full <= i_send and not o_ack;
--     empty <= not (i_send and not o_ack);
--     size <= b"000";

    -- Zero length is register with ability to read and write simultaneously
    read <= o_ack;
    write <= (not(reg_valid) or read) and i_send;
    i_ack <= write;
    o <= reg_dat;
    o_send <= reg_valid;
    full <= reg_valid and not(read);
    empty <= not(reg_valid) or read;

    process (SB_clock, SB_reset) is begin
      if SB_reset = '1' then
        reg_dat <= '0';
        reg_valid <= '0';
      elsif rising_edge( SB_clock ) then
        reg_valid <= (reg_valid and not(read)) or write;
        if write = '1' then
          reg_dat <= i;
        end if;
      end if;
    end process;
    
  end generate fifo_zero;

--   -- length 1 breaks the combinatorial path
--   fifo_one: if l = 1 generate
--     signal is_full, write : std_logic;
--     signal reg_dat: bool;
--   begin
--     write <= i_send and (not is_full);
--     process( SB_clock, SB_reset ) is
--     begin
--       if SB_reset = '1' then
--         is_full <= '0';
--       elsif rising_edge( SB_clock ) then
--         if write = '1' then
--           is_full <= '1';
--         elsif is_full = '1' and o_ack = '1' then
--           is_full <= '0';
--         end if;
--       end if;
--     end process;
--     process( SB_clock ) is
--     begin
--       if rising_edge( SB_clock ) then
--         if write = '1' then
--           reg_dat <= i;
--         end if;
--       end if;
--     end process;
--     i_ack <= write;
--     o <= reg_dat;
--     o_send <= is_full;
--     full <= is_full;
--     empty <= not is_full;
--     size <= b"001" when is_full = '1' else b"000";
--   end generate fifo_one;

  -- For requested FIFO length greater than 1, implement length at least 4 (needed for FIFO
  -- controller code to work, and round the length up to a power of 2.
  fifo_many: if l > 1 generate 
    constant abits : positive := SystemBuilder.fifo_utilities.address_bits( l );
    constant asize : positive := 2 ** abits;

    signal read_addr    : std_logic_vector( SystemBuilder.fifo_utilities.address_bits( l ) - 1 downto 0 );
    signal read_enable  : std_logic;
    signal write_addr   : std_logic_vector( (abits - 1) downto 0 );
    signal write_enable : std_logic;
  begin
--     size <= std_logic_vector(resize(unsigned(write_addr) - unsigned(read_addr),
--                    abits + 1))
--           when write_addr >= read_addr else
--             std_logic_vector(to_unsigned(asize, abits + 1) - resize(unsigned(read_addr) - unsigned(write_addr), abits + 1));

    ctl: entity SystemBuilder.sync_fifo_controller( behavioral )
      generic map ( l => l )
      port map (
        SB_reset => SB_reset,
        SB_clock => SB_clock,
        input_clock => input_clock,
        output_clock => output_clock,
        i_send => i_send,
        i_ack => i_ack,
        i_mem_addr => write_addr,
        i_mem_enable => write_enable,
        o_send => o_send,
        o_ack => o_ack,
        o_mem_addr => read_addr,
        o_mem_enable => read_enable,
        full => full,
        empty => empty);

    ram: entity SystemBuilder.ram_2p_bool( behavioral )
      generic map (l => l )
      port map (
        din_a => i,
        addr_a => write_addr,
        we_a => write_enable,
        addr_b => read_addr,
        re_b => read_enable,
        dout_b => o,
        SB_clock => SB_clock );
  end generate fifo_many;
  
end architecture behavioral;

architecture behavioral of sync_fifo_bool is
  signal msync_full : std_logic;
  signal msync_o_send : std_logic;
  
begin
  i_rdy <= not(msync_full);
  o_count <= (15 downto 1=>'0', 0=>msync_o_send);
  o_send <= msync_o_send;
  
  fifo: entity SystemBuilder.msync_fifo_bool(behavioral) generic map(
    l => l)
  port map(
      SB_clock => SB_clock,
      input_clock => SB_clock,
      output_clock => SB_clock,
      SB_reset => SB_reset,

      i => i_data,
      i_send => i_send,
      i_ack => i_ack,
      full => msync_full,
      
      o => o_data,
      o_send => msync_o_send,
      o_ack => o_ack
);
end architecture behavioral;

-----------------------------------------------------------------------
-- Queues (just a port rename from the fifos)
architecture behavioral of Queue is
    
begin  -- behavioral

    fifo: entity SystemBuilder.sync_fifo_int( behavioral )
      generic map ( w => width, l => length )
      port map (
        SB_reset => reset,
        SB_clock => clk,
        i_data   => In_DATA,
        i_send   => In_SEND,
        i_ack    => In_ACK,
        i_rdy    => In_RDY,
        i_count  => In_COUNT,
        o_data   => Out_DATA,
        o_send   => Out_SEND,
        o_ack    => Out_ACK,
        o_count  => Out_COUNT);
    
end behavioral;


architecture behavioral of Queue_bool is

begin  -- behavioral

  fifo: entity SystemBuilder.sync_fifo_bool( behavioral )
    generic map ( l => length )
    port map (
      SB_reset => reset,
      SB_clock => clk,
      i_data   => In_DATA,
      i_send   => In_SEND,
      i_ack    => In_ACK,
      i_rdy    => In_RDY,
      i_count  => In_COUNT,
      o_data   => Out_DATA,
      o_send   => Out_SEND,
      o_ack    => Out_ACK,
      o_count  => Out_COUNT);

end behavioral;

architecture behavioral of Queue_Async is
    
begin  -- behavioral

    fifo: entity SystemBuilder.async_fifo_int( behavioral )
      generic map ( w => width, l => length )
      port map (
        SB_reset_i => reset_i,
        SB_clock_i => clk_i,
        i_data   => In_DATA,
        i_send   => In_SEND,
        i_ack    => In_ACK,
        i_rdy    => In_RDY,
        i_count  => In_COUNT,
        SB_reset_o => reset_o,
        SB_clock_o => clk_o,
        o_data   => Out_DATA,
        o_send   => Out_SEND,
        o_ack    => Out_ACK,
        o_count  => Out_COUNT);
    
end behavioral;


architecture behavioral of Queue_bool_Async is

begin  -- behavioral

  fifo: entity SystemBuilder.async_fifo_bool( behavioral )
    generic map ( l => length )
    port map (
      SB_reset_i => reset_i,
      SB_clock_i => clk_i,
      i_data   => In_DATA,
      i_send   => In_SEND,
      i_ack    => In_ACK,
      i_rdy    => In_RDY,
      i_count  => In_COUNT,
      SB_reset_o => reset_o,
      SB_clock_o => clk_o,
      o_data   => Out_DATA,
      o_send   => Out_SEND,
      o_ack    => Out_ACK,
      o_count  => Out_COUNT);

end behavioral;

-----------------------------------------------------------------------
-- Fanouts

-- Manage the individual output-side send/ack signals
architecture behavioral of fanout_protocol is
  signal o_ack_captured : std_logic_vector(fanout-1 downto 0);
  signal o_send_local : std_logic_vector(fanout-1 downto 0);
  signal i_ack_local : std_logic;
begin

  In_ACK <= i_ack_local;
  Out_SEND <= o_send_local;
  -- Leave all buffering/registering in the queue.
  -- Generate the send to each consumer 
  -- generate the ack back to the producer when all consumers have acked
  process(In_SEND, o_ack_captured, Out_ACK, i_ack_local) is
  begin
    i_ack_local <= '1';
    for i in 0 to fanout-1 loop
      o_send_local(i) <= In_SEND and not(o_ack_captured(i));
      if Out_ACK(i) = '0' and o_ack_captured(i) = '0' then
        i_ack_local <= '0';
      end if;
    end loop;
  end process;

  -- In_RDY is the logical AND of all Out_RDY bits
  process(Out_RDY) is
  begin
    In_RDY <= '1';
    for i in 0 to fanout-1 loop
      if Out_RDY(i) = '0' then
        In_RDY <= '0';
      end if;
    end loop;  -- i
  end process;
  
  -- Capture any o_ack that we see
  process( SB_clock, SB_reset ) is
  begin
    if SB_reset = '1' then
      o_ack_captured <= (others => '0');
    elsif rising_edge( SB_clock ) then
      if i_ack_local = '1' then o_ack_captured <= (others => '0');
      else
        for i in 0 to fanout-1 loop
          if o_send_local(i) = '1' and Out_ACK(i) = '1' then o_ack_captured(i) <= '1'; end if;
        end loop;
      end if;
    end if;
  end process;

end architecture behavioral;

architecture behavioral of fanout is
begin

  fanout_one: if fanout = 1 generate
  begin
    -- simple pass through
    Out_SEND(0) <= In_SEND;
    In_ACK <= Out_ACK(0);
    Out_DATA <= In_DATA;
    Out_COUNT <= In_COUNT;
    In_RDY <= Out_RDY(0);
  end generate fanout_one;
    
  fanout_many: if fanout > 1 generate
  begin
    -- data is a pass through.  Manage the sends and acks.
    protocol: entity SystemBuilder.fanout_protocol( behavioral ) 
      generic map( fanout => fanout )
      port map (
        SB_reset => reset,
        SB_clock => clk,
        In_SEND => In_SEND,
        In_ACK => In_ACK,
        In_RDY => In_RDY,
        Out_SEND => Out_SEND,
        Out_ACK => Out_ACK,
        Out_RDY => Out_RDY
        );
    
    Out_DATA <= In_DATA;
    Out_COUNT <= In_COUNT;
  end generate fanout_many;

end architecture behavioral;

architecture behavioral of fanout_bool is
begin
  fanout_one: if fanout = 1 generate
  begin
    -- simple pass through
    Out_SEND(0) <= In_SEND;
    In_ACK <= Out_ACK(0);
    Out_DATA <= In_DATA;
    Out_COUNT <= In_COUNT;
    In_RDY <= Out_RDY(0);
  end generate fanout_one;
  
  fanout_many: if fanout > 1 generate
  begin
    protocol: entity SystemBuilder.fanout_protocol( behavioral ) 
      generic map( fanout => fanout )
      port map (
        SB_reset => reset,
        SB_clock => clk,
        In_SEND => In_SEND,
        In_ACK => In_ACK,
        In_RDY => In_RDY,
        Out_SEND => Out_SEND,
        Out_ACK => Out_ACK,
        Out_RDY => Out_RDY
        );

    Out_DATA <= In_DATA;
    Out_COUNT <= In_COUNT;
  end generate fanout_many;

end architecture behavioral;

architecture behavioral of sequencer is
  signal data : std_logic_vector(limit downto 0);
  signal temp : std_logic_vector(limit downto 0);
begin
  sequence <= data;
  output <= data(limit);

  process( SB_clock ) is
  begin
    if SB_clock'event and SB_clock = '0' then
      if SB_reset = '1' then
        temp(init'length - 1 downto 0) <= init;
        temp(limit downto init'length) <= (others => '0');
      else 
        temp <= data;
      end if;
    end if;
  end process;

  process( SB_clock ) is
  begin
    if (SB_clock'event and SB_clock = '1') then
      data(limit downto 1) <= temp(limit-1 downto 0);
    end if;
  end process;
  
  data(0) <= input;

end architecture behavioral;

architecture behavioral of phaseSequencer is
  signal data : std_logic_vector(limit downto 0);
  signal temp : std_logic_vector(limit downto 0);
begin
  sequence <= data;
  process( SB_clock ) is
  begin
    if SB_clock'event and SB_clock = '0' then
      if SB_reset = '1' then
        temp(init'length - 1 downto 0) <= init;
        temp(limit downto init'length) <= (others => '0');
      else 
        temp <= data;
      end if;
    end if;
  end process;
  process( SB_clock ) is
  begin
    if (SB_clock'event and SB_clock = '1') then
      data <= temp(limit-1 downto 0) & temp(limit);
    end if;
  end process;

end architecture behavioral;

-- Create a domain-specific reset for each input clock. This will have an
-- asynchronous rising edge and a synchronous falling edge

architecture behavioral of resetController is
  -- Get the synchronous falling edge by clocking the incoming reset through
  -- a delay line with this number of D flip-flops with reset.
  constant stages: positive := 3;
begin

  -- loop over all the clock domains  
  c: for n in 0 to count-1 generate
  
    -- delay line stages
    signal q : std_logic_vector( stages downto 0 );
    
  begin
  
    q(0) <= reset_in;
    
    -- create the delay line of DFFs with reset
    s: for i in 1 to stages generate
    begin
    
      process( clocks(n), reset_in ) is
      begin
        if reset_in = '1' then
          q(i) <= '1';
        elsif rising_edge( clocks(n) ) then
          q(i) <= q(i-1);
        end if;
      end process;
    
    end generate;
    
    -- create the domain reset with synchronous falling edge
    resets(n) <= q(stages) or reset_in;
    
  end generate;
  
end architecture behavioral;