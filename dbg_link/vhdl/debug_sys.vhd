-------------------------------------------------------------------------------
--  Copyright Ken Campbell
-------------------------------------------------------------------------------
-- $Author: User $
--
-- $Date: 2010/02/07 15:49:30 $
--
-- $Name:  $
--
-- $Id: debug_sys.vhd,v 1.1 2010/02/07 15:49:30 User Exp $
--
-- $Source: C:/cvsroot/source/dbg_link/vhdl/debug_sys.vhd,v $
--
-- Description :  Dev board
--                
--                
--
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
-- pragma translate_on
use work.cpu_pkg.all;
use work.debug_link_pkg.all;



entity debug_sys is
  generic(
          sim_en  :  integer  := 1
        );
  port(
    rst   :   in  std_logic;
    clk   :   in  std_logic;
    rxs   :   in  std_logic;
    txs   :   out std_logic
    );
end entity debug_sys;




architecture rtl of debug_sys is

  constant hi      :  std_logic  := '1';
  constant lo      :  std_logic  := '0';

  signal if_out      :  if_out_type;
  signal if_in       :  if_in_type;  
  signal ram_addr    :  std_logic_vector(11 downto 0);
  signal ramr_word1  :  std_logic_vector(15 downto 0);
  signal ramw_word   :  std_logic_vector(15 downto 0);
  signal ramw_en     :  std_logic;
  signal ram_en      :  std_logic;
  signal regw_en     :  std_logic;
  signal reg_en      :  std_logic;
  
  signal out_of_range  :  std_logic;
  
  signal  rst_n    :  std_logic;
  signal  rx_sin   :  std_logic;
  
  signal  waddr    :  std_logic_vector(31 downto 0);
  signal  wo_data    :  std_logic_vector(31 downto 0);
  signal  wuser_o  :  std_logic_vector(7 downto 0);
  signal  wsel     :  std_logic;
  signal  wrwn     :  std_logic;
  signal  wi_data   :  std_logic_vector(31 downto 0);
  signal  wack    :  std_logic;
  signal  wuser_i :  std_logic_vector(7 downto 0);
--  signal  rst_sim  : std_logic;


component dbg_link is
--  generic (
--  );
  port (
    rst_n   :  in  std_logic;
    clk     :  in  std_logic;
    rxd     :  in  std_logic;
    txd     :  out std_logic;
    if_out  :  out  if_out_type;
    if_in   :  in   if_in_type
  );
end component;



begin

    rst_n   <=  not rst;
    db_linc: dbg_link
    --  generic (
    --  );
      port map(
        rst_n   =>  rst_n,
        clk     =>  clk,
        rxd     =>  rx_sin,
        txd     =>  txs,
        if_out  =>  if_out,
        if_in   =>  if_in
      );
    rx_sin  <=  rxs;


-- break out record type for waving.
  waddr   <= if_out.addr;
  wo_data <= if_out.data;
  wuser_o <= if_out.user_o;
  wsel    <= if_out.sel;
  wrwn    <= if_out.rwn;
  wi_data <= if_in.data;
  wack    <= if_in.ack;
  wuser_i <= if_in.user_i;

ifack_gen:
  process(rst_n, clk)
  begin
    if(rst_n  = '0') then
      if_in.ack  <=  '0';
    elsif(clk'event and clk = '1') then
      if(if_out.sel = '1') then
        if_in.ack  <=  '1';
      else
        if_in.ack  <=  '0';
      end if;
    end if;
end process ifack_gen;
  
  
  
sram1: sram_4kx16
  port map(
    clk1  =>  clk,
    en1   =>  ram_en,
    addr1 =>  ram_addr,
    do1   =>  ramr_word1,
    clkb  =>  clk,
    enb   =>  ram_en,
    web   =>  ramw_en,
    addrb =>  ram_addr,
    dib   =>  ramw_word
  );

  ram_addr    <=  if_out.addr(11 downto 0);
  ramw_word   <=  if_out.data(15 downto 0);
  ramw_en     <=  not if_out.rwn;
  ram_en      <=  if_out.sel;
  --ramr_word1  <=  
io_mux:
  process(ramr_word1, out_of_range)
  begin
    if(out_of_range  = '0') then
      if_in.data(15 downto 0)  <=  ramr_word1;
      if_in.data(31 downto 16)  <=  (others => '0');
    else
      if_in.data(15 downto 0)  <=  x"BEEF";
      if_in.data(31 downto 16)  <= x"DEAD";
    end if;
end process;

addr_decode:
  process(if_out.addr)
    variable v_bit  : std_logic;
  begin
    v_bit :=  '0';
    for i in 15 downto 12 loop
      v_bit  :=  v_bit or if_out.addr(i);
    end loop;
    out_of_range  <=  v_bit;
end process addr_decode;

end rtl;
