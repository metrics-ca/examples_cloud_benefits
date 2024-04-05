-------------------------------------------------------------------------------
--  Copyright Ken Campbell
-------------------------------------------------------------------------------
-- $Author: User $
--
-- $Date: 2010/02/07 15:49:30 $
--
-- $Name:  $
--
-- $Id: sram_4kx16.vhd,v 1.1 2010/02/07 15:49:30 User Exp $
--
-- $Source: C:/cvsroot/source/dbg_link/vhdl/sram_4kx16.vhd,v $
--
-- Description :  my cpu
--                
--                
--
------------------------------------------------------------------------------

library IEEE;
use     IEEE.std_logic_1164.all;
use     IEEE.std_logic_arith.all;

entity sram_4kx16 is
  port (
    -- port 1 (read only)
    clk1  : in  std_logic;
    en1   : in  std_logic;
    addr1 : in  std_logic_vector(11 downto 0);
    do1   : out std_logic_vector(15 downto 0);
    -- port b (write only)
    clkb  : in  std_logic;
    enb   : in  std_logic;
    web   : in  std_logic;
    addrb : in  std_logic_vector(11 downto 0);
    dib   : in  std_logic_vector(15 downto 0)
  );
end entity sram_4kx16;

architecture rtl of sram_4kx16 is

  type MEM_TYPE is array(0 to 4095) of std_logic_vector(15 downto 0);
  signal memory : MEM_TYPE;
  
  signal sim_ce    : std_logic;
  --  simulation entry points to the RAM
-- pragma translate_off
  signal sim_addr  : integer;
  signal sim_dataw : std_logic_vector(15 downto 0);
  signal sim_datar : std_logic_vector(15 downto 0);
  signal sim_wr    : std_logic;
-- pragma translate_on

  attribute syn_ramstyle : string;
  attribute syn_hier     : string;
  attribute syn_ramstyle of memory : signal       is "block_ram";
  attribute syn_hier     of rtl    : architecture is "hard";

begin

  ------------------------------------------------------------------------------
  -- Port A (read only)
  ------------------------------------------------------------------------------
  process( clk1 )
  begin
    if ( rising_edge(clk1) ) then
      if ( en1='1' ) then
        do1 <= memory( conv_integer(unsigned(addr1)) );
      end if;
    end if;
  end process;

  ------------------------------------------------------------------------------
  -- Port B (write only)
  ------------------------------------------------------------------------------
  process( clkb, sim_ce )
  begin
    if ( rising_edge(clkb) ) then
      if ( enb='1' ) then
        if ( web='1' ) then
          memory( conv_integer(unsigned(addrb)) ) <= dib;
        end if;
      end if;
    end if;
-- pragma translate_off
      if(sim_ce'event and sim_ce = '1') then
        if(sim_wr = '1') then
          memory(sim_addr) <= sim_dataw;
        elsif(sim_wr = '0') then
          sim_datar  <=  memory(sim_addr);
        end if;
      end if;
-- pragma translate_on
  end process;

-- pragma translate_off
--  sim_access:
--    process(sim_ce)
--    begin
--      if(sim_ce'event and sim_ce = '1') then
--        if(sim_wr = '1') then
--          memory(sim_addr) <= sim_dataw;
--        elsif(sim_wr = '0') then
--          sim_datar  <=  memory(sim_addr);
--        end if;
--      end if;
--  end process sim_access;

-- pragma translate_on

  
  
end architecture rtl;
