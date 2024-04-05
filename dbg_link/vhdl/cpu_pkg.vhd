-------------------------------------------------------------------------------
--             Copyright 2023  Ken Campbell
--               All rights reserved.
-------------------------------------------------------------------------------
-- $Author: sckoarn $
--
-- Description :  CPU Package
--
------------------------------------------------------------------------------
--  This file is part of The VHDL Test Bench Package examples.
--
--  Redistribution and use in source and binary forms, with or without
--  modification, are permitted provided that the following conditions are met:
--
--  1. Redistributions of source code must retain the above copyright notice,
--     this list of conditions and the following disclaimer.
--
--  2. Redistributions in binary form must reproduce the above copyright notice,
--     this list of conditions and the following disclaimer in the documentation
--     and/or other materials provided with the distribution.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
-- IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
-- ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
-------------------------------------------------------------------------------
library IEEE;

use IEEE.STD_LOGIC_1164.all;

package cpu_pkg is

  
  type dbg_i_type  is record
    hold   :  std_logic;
    step   :  std_logic;
  end record;

  type dbg_o_type  is record
    dbg_mode  :  std_logic;
  end record;



  subtype int_15    is integer range 0 to 15;


  function to_int15(v : std_logic_vector(3 downto 0)) return int_15;
  
component debug_sys is
  generic(
          sim_en  :  integer  := 1
        );
  port(
    rst   :   in  std_logic;
    clk   :   in  std_logic;
    rxs   :   in  std_logic;
    txs   :   out std_logic
    );
end component;

component dev_sys is
  generic(
          sim_en  :  integer  := 1
        );
  port(
    rst   :   in  std_logic;
    clk   :   in  std_logic;
    rxs   :   in  std_logic;
    txs   :   out std_logic
    );
end component;

component sram_4kx16 is
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
end component;

component regs_512x16 is
  port (
    -- port 1 (read only)
    clk1  : in  std_logic;
    en1   : in  std_logic;
    addr1 : in  std_logic_vector(8 downto 0);
    do1   : out std_logic_vector(15 downto 0);
    -- port b (read/write)
    clkb  : in  std_logic;
    enb   : in  std_logic;
    web   : in  std_logic;
    addrb : in  std_logic_vector(8 downto 0);
    dib   : in  std_logic_vector(15 downto 0);
    dob   : out std_logic_vector(15 downto 0)
  );
end component regs_512x16;

component sck_cpu_regs is
  port (
    rst_n   : in  std_logic;  --
    clk     : in  std_logic;  --  100 Hz
    reg_word_addr1     : in  std_logic_vector(3 downto 0);
    reg_word_addr2     : in  std_logic_vector(3 downto 0);
    reg_wr_addr        : in  std_logic_vector(3 downto 0);
    wr                 : in  std_logic;
    wr_word_in         : in  std_logic_vector(15 downto 0);
    word_out1          : out std_logic_vector(15 downto 0);
    word_out2          : out std_logic_vector(15 downto 0);
    reg_bit_addr       : in  std_logic_vector(7 downto 0);
    clr_bit            : in  std_logic;
    set_bit            : in  std_logic;
    bit_out            : out std_logic
  );
end component;

component clk_gen is
  generic(
    mult        : integer;
    div         : integer
  );
  port(
    rst_in      :  in  std_logic;
    clk_in      :  in  std_logic;
    clk_out     :  out std_logic;
    clkx_out    :  out std_logic;
    locked      :  out std_logic
    );
end component;


end cpu_pkg;


package body cpu_pkg is


  function to_int15(v : std_logic_vector(3 downto 0)) return int_15 is
    variable int : int_15;
  begin
    case v is
      when "0000" => int :=  0;
      when "0001" => int :=  1;
      when "0010" => int :=  2;
      when "0011" => int :=  3;
      when "0100" => int :=  4;
      when "0101" => int :=  5;
      when "0110" => int :=  6;
      when "0111" => int :=  7;
      when "1000" => int :=  8;
      when "1001" => int :=  9;
      when "1010" => int :=  10;
      when "1011" => int :=  11;
      when "1100" => int :=  12;
      when "1101" => int :=  13;
      when "1110" => int :=  14;
      when "1111" => int :=  15;
      when others  =>
        null;
    end case;
    
    return int;
  end to_int15;



end cpu_pkg;
