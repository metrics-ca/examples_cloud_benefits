-------------------------------------------------------------------------------
--             Copyright 2023  Ken Campbell
--               All rights reserved.
-------------------------------------------------------------------------------
-- $Author: sckoarn $
--
-- Description :  Behave of debug link,  (non-functional code)
--                This file will be updated in future releases
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
use IEEE.std_logic_unsigned.all;
use work.debug_link_pkg.all;


entity dbg_link is
  generic (
           stimulus_file: string := "stm/stimulus_file.stm"
  );
  port (
    rst_n   :  in  std_logic;
    clk     :  in  std_logic;
    
    rxd     :  in  std_logic;
    txd     :  out std_logic;
    
    if_out  :  out  if_out_type;
    if_in   :  in   if_in_type
  );
end entity dbg_link;

