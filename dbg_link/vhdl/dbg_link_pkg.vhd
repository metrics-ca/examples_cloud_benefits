-------------------------------------------------------------------------------
--             Copyright 2023  Ken Campbell
--               All rights reserved.
-------------------------------------------------------------------------------
-- $Author: sckoarn $
--
-- Description :  debug link package
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

package debug_link_pkg is

type if_out_type is record
  addr    :  std_logic_vector(31 downto 0);
  data    :  std_logic_vector(31 downto 0);
  user_o  :  std_logic_vector(7 downto 0);
  sel     :  std_logic;
  rwn     :  std_logic;
end record;
type if_in_type is record
  data   :  std_logic_vector(31 downto 0);
  ack    :  std_logic;
  user_i :  std_logic_vector(7 downto 0);
end record;

  subtype int_15    is integer range 0 to 15;

end debug_link_pkg;
