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
  
architecture rtl of dbg_link is

  constant c_rx_sample_point : integer :=  4;
  type astate_t is (rst, idle, start, align, aligned);
  type ubit_t   is (init, idle, start, db, reg_d, stop1, stop2);
  type cmd_state_t is (init, idle, reg_rd, reg_wr, io_rd, io_wr);
  type io_state_t is (addr_rx, ack_wait, tx_start, tx_wait);

  
  signal astate    : astate_t;
  signal rxstate   : ubit_t;
  signal txstate   : ubit_t;
  signal cmdstate  : cmd_state_t;
  signal iostate   : io_state_t;
  
  signal rx_init_cnt      :  integer range 3 downto 0;
  signal sample_rx        :  std_logic;
  
  signal ioaddr           :  std_logic_vector(31 downto 0);
  signal iodatao           :  std_logic_vector(31 downto 0);
  signal iodatai           :  std_logic_vector(31 downto 0);
  signal iorwn            :  std_logic;
  signal iosel            :  std_logic;
  

  signal bit_cnt1         :  std_logic_vector(16 downto 0);
  signal bit_cnt2         :  std_logic_vector(12 downto 0);
  signal scaler           :  std_logic_vector(12 downto 0);
  signal scalerdiv8       :  std_logic_vector(9 downto 0);
  signal scalerdiv        :  std_logic_vector(9 downto 0);
  signal scale_cnt        :  std_logic_vector(12 downto 0);
  signal rx_cnt_en        :  std_logic;
  signal detect_cnt       :  std_logic_vector(1 downto 0);
  signal b_aligned        :  std_logic;
  signal realign          :  std_logic;
  
--  signal bit_pulse        :  std_logic;
  signal one_eight_cnt    :  integer range 7 downto 0;
  signal bit_pos          :  integer range 15 downto 0;
  
  signal rxd_met   :  std_logic;
  signal rxd_meti  :  std_logic;
  signal pos_edge  :  std_logic;
  signal neg_edge  :  std_logic;
  signal frame_err :  std_logic;
  
  signal rx_dbits    :  std_logic_vector(7 downto 0);
  signal rx_bidx     :  integer range 7 downto 0;
  signal rx_ddata    :  std_logic_vector(7 downto 0);
  signal rx_wdata    :  std_logic_vector(7 downto 0);
  signal new_rx      :  std_logic;
  
  signal tx_scale    :  std_logic_vector(12 downto 0);
  signal tx_sc_cnt   :  integer range 7 downto 0;
  signal txdata      :  std_logic_vector(7 downto 0);
  signal tx_done     :  std_logic;
  signal tx_en       :  std_logic;
  signal tx_cnt_en   :  std_logic;
  signal tx_bit_en   :  std_logic;
  signal tx_bit_idx  :  integer range 7 downto 0;
  
  signal byte_cnt  :  integer range 15 downto 0;
  signal frame_cnt :  std_logic_vector(5 downto 0);
  
  signal ctl_reg   :  std_logic_vector(7 downto 0);
  signal user_reg  :  std_logic_vector(7 downto 0);
  signal stat_reg  :  std_logic_vector(7 downto 0);

begin

---------------------------------------------------------------------
--  register and IO access state machine
command_state:
  process(rst_n, clk)
  begin
    if(rst_n   =  '0') then
      user_reg  <=  (others => '0');
      cmdstate  <=  init;
      iostate   <=  addr_rx;
      byte_cnt  <=  0;
      frame_cnt <=  "000000";
      
      ioaddr  <=  (others => '0');
      iodatao  <=  (others => '0');
      iodatai  <=  (others => '0');
      iorwn   <=  '1';
      iosel   <=  '0';
      txdata    <=  (others => '0');
      tx_en        <=  '0';
      realign      <=  '0';
      
      ctl_reg  <=  (others => '0');
--      stat_reg <=  (others => '0');
      
    elsif(clk'event and clk = '1') then
      tx_en        <=  '0';
      realign      <=  '0';
      -- on startup wait for rx to be idle
      case cmdstate is
        when init  =>
          if(rxstate  =  idle) then
            cmdstate  <=  idle;
          end if;
        -- once in idle state decode the first incoming byte
        when idle  =>
          iosel   <=  '0';
          iorwn   <=  '1';
          byte_cnt     <=  0;
          if(new_rx =  '1') then
            if(rx_ddata(7 downto 6) = "10") then
              cmdstate  <=  io_rd;
              frame_cnt <=  rx_ddata(5 downto 0);
            elsif(rx_ddata(7 downto 6) =  "11") then
              cmdstate  <=  io_wr;
              frame_cnt <=  rx_ddata(5 downto 0);
            else
              case rx_ddata(5 downto 0) is
                when "010000" =>
                  cmdstate  <=  reg_wr;
                when "010001" =>
                  txdata    <=  ctl_reg;
                  tx_en     <=  '1';
                  cmdstate  <=  reg_rd;
                when "010100" =>
                  txdata    <=  stat_reg;
                  tx_en     <=  '1';
                  cmdstate  <=  reg_rd;
                when "011000" =>
                  cmdstate  <=  reg_wr;
                when "011001" =>
                  txdata    <=  user_reg;
                  tx_en     <=  '1';
                  cmdstate  <=  reg_rd;
                when others =>
                  null;
              end case;
            end if;
          end if;
        -- wait here till tx is done writing out register
        when reg_rd  =>
          if(tx_done = '1') then
            cmdstate  <=  idle;
          end if;
          
        -- write next data into the addressed writeable register
        when reg_wr  =>
          if(new_rx =  '1') then
            case rx_ddata(5 downto 0) is
              when "010000" =>
                ctl_reg  <=  rx_wdata;
                ctl_reg(0)  <=  '0';
                realign  <=  rx_wdata(0);
              when "011000" =>
                user_reg  <=  rx_wdata;
              when others =>
                null;
            end case;
            cmdstate  <=  idle;
          end if;
          
        -- IO read cycle
        when io_rd  =>
          case iostate is
            when addr_rx =>
              if(new_rx =  '1') then
                case byte_cnt is
                  when 0 =>
                    ioaddr(15 downto 8)    <=  rx_wdata;
                    byte_cnt  <=  byte_cnt + 1;
                  when 1 =>
                    ioaddr(7 downto 0)    <=  rx_wdata;
                    byte_cnt  <=  byte_cnt + 1;
                    iosel   <=  '1';
                    iorwn   <=  '1';
                    iostate   <=  ack_wait;
                  when others =>
                    null;
                end case;
              end if;
              
            when ack_wait  =>
              if(if_in.ack = '1') then
                iodatai     <=  if_in.data;
                iostate   <=  tx_start;
                byte_cnt  <=  0;
              end if;
              
            when tx_start  =>
              iosel   <=  '0';
              if(byte_cnt  = 0) then
                txdata    <=  iodatai(15 downto 8);
                tx_en     <=  '1';
                iostate   <=  tx_wait;
              else
                txdata    <=  iodatai(7 downto 0);
                tx_en     <=  '1';
                iostate   <=  tx_wait;
              end if;
              
            when tx_wait   =>
              if(tx_done = '1') then
                if(byte_cnt  = 0) then
                  iostate   <=  tx_start;
                  byte_cnt  <=  byte_cnt + 1;
                elsif(frame_cnt = "000000") then
                  iostate   <=  addr_rx;
                  cmdstate  <=  idle;
                else
                  byte_cnt  <=  0;
                  ioaddr(15 downto 0)    <=  ioaddr(15 downto 0) + 1;
                  frame_cnt <= frame_cnt - "000001";
                  iostate   <=  ack_wait;
                  iosel   <=  '1';
                end if;
              end if;
            
          end case;
          
        -- and IO write cycle, no wait for ack
        when io_wr  =>
          iosel   <=  '0';
          if(new_rx =  '1') then
            case byte_cnt is
              when 0 =>
                ioaddr(15 downto 8)  <=  rx_wdata;
                byte_cnt  <=  byte_cnt + 1;
              when 1 =>
                ioaddr(7 downto 0)  <=  rx_wdata;
                byte_cnt  <=  byte_cnt + 1;
              when 2 =>
                iodatao(15 downto 8)  <=  rx_wdata;
                byte_cnt  <=  byte_cnt + 1;
              when 3 =>
                iodatao(7 downto 0)  <=  rx_wdata;
                iosel   <=  '1';
                iorwn   <=  '0';
                if(frame_cnt = "000000") then
                  cmdstate  <=  idle;
                else
                  byte_cnt  <=  byte_cnt + 1;
                  frame_cnt <= frame_cnt - "000001";
                end if;
              when 4 =>
                iodatao(15 downto 8)  <=  rx_wdata;
                byte_cnt  <=  byte_cnt + 1;
                ioaddr(15 downto 0)    <=  ioaddr(15 downto 0) + 1;
                
              when 5 =>
                iodatao(7 downto 0)  <=  rx_wdata;
                iosel   <=  '1';
                iorwn   <=  '0';
--                byte_cnt  <=  4;
                if(frame_cnt = "000000") then
                  cmdstate  <=  idle;
                else
                  frame_cnt <= frame_cnt - "000001";
                  byte_cnt  <=  4;
                end if;
              when 6 =>
              when 7 =>
              when others =>
            end case;
          end if;
          
      end case;
    end if;
end process command_state;

if_out.addr  <=  ioaddr;
if_out.data  <=  iodatao;
if_out.rwn   <=  iorwn;
if_out.sel   <=  iosel;
if_out.user_o  <=  user_reg;
stat_reg     <=  if_in.user_i;
-------------------------------------------------------------------
alignment:
  process(rst_n, clk)
  begin
    if(rst_n  = '0') then
      astate     <=   rst;
      bit_cnt1   <=  (others => '0');
      bit_cnt2   <=  (others => '0');
      detect_cnt <=  (others => '0');
      scaler     <=  (others => '1');  -- load max
      b_aligned  <=   '0';
      
    elsif(clk'event and clk = '1') then
      case astate is
        when rst  =>
          astate  <=  idle;
        when idle  =>
          b_aligned  <=   '0';
          if(neg_edge = '1') then
            astate  <=  start;
          end if;
        when start =>
          bit_cnt1  <=  (others => '0');
          bit_cnt2  <=  (others => '0');
          detect_cnt <=  (others => '0');
          scaler     <=  (others => '1');  -- load max
          b_aligned  <=   '0';
          astate    <=  align;
          
        when align =>
        
          if(bit_cnt1 = X"1FFFF") then
            astate    <=  idle;
          end if;
        
          bit_cnt1  <=  bit_cnt1 + 1;
          if(pos_edge = '1') then
            case detect_cnt is
              when "00" =>
                bit_cnt1  <=  (others => '0');
                detect_cnt  <=  detect_cnt + 1;
              when "01" =>
                bit_cnt2  <=  bit_cnt1(16 downto 4);
                detect_cnt  <=  detect_cnt + 1;
                bit_cnt1  <=  (others => '0');
              when "10" =>
                bit_cnt1  <=  (others => '0');
                if(bit_cnt1(16 downto 4) < bit_cnt2) then
                  bit_cnt2  <=  bit_cnt1(16 downto 4);
                  detect_cnt  <=  detect_cnt - 1;
                elsif(bit_cnt1(16 downto 4) = bit_cnt2) then
                  detect_cnt  <=  detect_cnt + 1;
                end if;
              when "11" =>
                bit_cnt1  <=  (others => '0');
                if(bit_cnt1(16 downto 4) < bit_cnt2) then
                  bit_cnt2  <=  bit_cnt1(16 downto 4);
                  detect_cnt  <=  detect_cnt - 1;
                elsif(bit_cnt1(16 downto 4) = bit_cnt2) then
                  detect_cnt  <=  detect_cnt + 1;
                  astate    <=  aligned;
                end if;
              when others =>
                null;
            end case;
          end if;
        
        when aligned  =>
          if(realign = '1') then
            astate    <=  idle;
            b_aligned  <=   '0';
          else
            b_aligned  <=   '1';
            scaler     <=   bit_cnt2;
            scalerdiv8 <=   bit_cnt2(12 downto 3) - 1;
          end if;
      end case;
    end if;
end process alignment;
---------------------------------------------------------------------
--  uart tx
uart_tx_sm:
  process(rst_n, clk)
  begin
    if(rst_n  = '0') then
      txstate   <=  init;
      tx_done   <=  '0';
      txd       <=  '1';
      tx_cnt_en <=  '0';
      tx_bit_idx  <=  0;
      
    elsif(clk'event and clk = '1') then
      case txstate is
        -- waiting here for alignment and two stop bits found
        when init  =>
          if(b_aligned = '1') then
            txstate  <=  idle;
          end if;
          
        -- if idle, wait for neg edge detect
        when idle  =>
          tx_bit_idx  <=  0;
          tx_done     <=  '0';
          if(tx_en = '1') then
            txstate  <=  start;
            tx_cnt_en <=  '1';
          end if;
        --  have a start edge wait see if is a start bit
        when start  =>
          txd       <=  '0';
          if(tx_bit_en = '1') then
            txstate  <=  db;
          end if;
        -- store data in rx_bits
        when db  =>
          txd       <=  txdata(tx_bit_idx);
          if(tx_bit_en = '1') then
            if(tx_bit_idx = 7) then
              txstate  <=  stop1;
            else
              tx_bit_idx  <=  tx_bit_idx  + 1;
            end if;
          end if;
        
        -- register data and signal new data arrived
        when reg_d =>
          null;
          
        -- wait for stop bit and indicate frame error if not present
        when stop1  =>
          txd       <=  '1';
          if(tx_bit_en = '1') then
            txstate  <=  stop2;
          end if;
          
        when stop2  =>
          txd       <=  '1';
          if(tx_bit_en = '1') then
            txstate  <=  idle;
            tx_cnt_en <=  '0';
            tx_done  <=  '1';
          end if;
      end case;      
    end if;
end process uart_tx_sm;

---------------------------------------------------------------------
--  tx counter
tx_bit_gen:
  process(rst_n, clk)
  begin
    if(rst_n = '0') then
      tx_sc_cnt <=   0;
      tx_scale  <=  (others  => '0');
      tx_bit_en  <=  '0';
      
    elsif(clk'event and clk = '1') then
      tx_bit_en  <=  '0';
      
      if(tx_cnt_en = '1') then
        if(tx_sc_cnt = 7) then
          tx_sc_cnt <=   0;
          if(tx_scale = "0000000000000") then
            tx_bit_en  <=  '1';
            tx_scale <= scaler;
            tx_sc_cnt <=   0;
          else
            tx_scale <= tx_scale - 1;
          end if;
        else
          tx_sc_cnt <= tx_sc_cnt + 1;
        end if;
      else
        tx_scale <= scaler;
        tx_sc_cnt <=   0;
      end if;
    end if;
end process tx_bit_gen;


---------------------------------------------------------------------
--  uart Rx
uart_rx_sm:
  process(rst_n, clk)
  begin
    if(rst_n  = '0') then
      rxstate      <=  init;
      rx_init_cnt  <=  0;
      rx_cnt_en    <=  '1';
      new_rx    <=  '0';
      frame_err <=  '0';
      rx_bidx  <=  0;
      rx_ddata   <=  (others => '0');
      rx_dbits   <=  (others => '0');
      
    elsif(clk'event and clk = '1') then
      new_rx    <=  '0';
      case rxstate is
        -- waiting here for alignment and two stop bits found
        when init  =>
          if(rx_init_cnt  =  2) then
            rxstate  <=  idle;
            rx_init_cnt  <=  0;
            rx_cnt_en    <=  '0';
          elsif(sample_rx = '1' and b_aligned = '1') then
            if(rxd_met = '1') then
              rx_init_cnt  <=  rx_init_cnt + 1;
            else
              rx_init_cnt  <=  0;
            end if;
          end if;
          
        -- if idle, wait for neg edge detect
        when idle  =>
          if(neg_edge  = '1') then
            rxstate  <=  start;
            rx_cnt_en  <=  '1';
          end if;
          
        --  have a start edge wait see if is a start bit
        when start  =>
          frame_err <=  '0';
          if(sample_rx = '1' and rxd_met = '1') then
            rxstate  <=  idle;
          elsif(sample_rx = '1' and rxd_met = '0') then
            rxstate  <=  db;
          end if;
          
        -- store data in rx_bits
        when db  =>
          if(sample_rx = '1') then
            if(rx_bidx = 7) then
              rxstate      <=  reg_d;
              rx_dbits(rx_bidx)  <=  rxd_met;
              rx_bidx  <=  0;
            else
              rx_dbits(rx_bidx)  <=  rxd_met;
              rx_bidx  <=  rx_bidx + 1;
            end if;
          end if;
        -- register data and signal new data arrived
        when reg_d =>
          if(cmdstate = idle) then
            rx_ddata   <=  rx_dbits;
          else
            rx_wdata   <=  rx_dbits;
          end if;
          
          new_rx     <=  '1';
          rxstate    <=  stop1;

        -- wait for stop bit and indicate frame error if not present
        when stop1  =>
          if( b_aligned = '0') then
            rxstate   <=  init;
          elsif(sample_rx = '1') then
            if(rxd_met  = '0') then
              frame_err   <=  '1';
            end if;
            rxstate      <=  idle;
            rx_cnt_en  <=  '0';
          end if;
        when stop2  =>
          null;
      end case;
    end if;
end process uart_rx_sm;

-------------------------------------------------------------------
-- bit counter generator
rxbit_cnt_gen:
  process(rst_n, clk)
  begin
    if(rst_n = '0') then
--      bit_pulse     <= '0';
      one_eight_cnt <=  7;
      scale_cnt     <=  (others  => '0');
      scalerdiv     <=  (others  => '0');
      bit_pos       <=  0;
      sample_rx     <=  '0';
    elsif(clk'event and clk = '1') then
--      bit_pulse     <= '0';
      sample_rx     <=  '0';
      if(b_aligned = '1' and rx_cnt_en = '1') then
        if(scale_cnt  = "000000000000" and one_eight_cnt = 7) then
          scale_cnt     <=  scaler;
          scalerdiv  <=  (others  => '0');
          one_eight_cnt <=  0;
--          bit_pulse     <= '1';
          bit_pos       <=  0;
        else
          if(one_eight_cnt = 7) then
            scale_cnt     <=  scale_cnt - 1;
            one_eight_cnt <=  0;
            
            if(bit_pos = c_rx_sample_point and scalerdiv = scalerdiv8) then
              sample_rx     <=  '1';
              bit_pos       <=  bit_pos + 1;
              scalerdiv  <=  (others  => '0');
            elsif(scalerdiv  = scalerdiv8) then
              bit_pos   <=  bit_pos + 1;
              scalerdiv  <=  (others  => '0');
            else
              scalerdiv  <=  scalerdiv + 1;
            end if;
          else
            one_eight_cnt <=  one_eight_cnt + 1;
          end if;
        end if;
      else
        one_eight_cnt <=  7;
        scale_cnt     <=  (others  => '0');
      end if;
    end if;
end process rxbit_cnt_gen;



-------------------------------------------------------------------


--- metastable FF for incoming data
met_ff:
  process(clk)
  begin
    if(clk'event and clk = '1') then
      rxd_meti   <=  rxd;
      rxd_met    <=  rxd_meti;
    end if;
end process met_ff;

-- edge detect the rx data
edge_detector:
  process(rst_n, clk)
    variable v_rxd  :  std_logic;
  begin
    if(rst_n  = '0') then
      pos_edge  <= '0';
      neg_edge  <= '0';
      v_rxd     :=  '1';
    elsif(clk'event and clk = '1') then
      pos_edge  <=  (v_rxd xor rxd_met) and rxd_met;
      neg_edge  <=  (v_rxd xor rxd_met) and not rxd_met;
      v_rxd  :=  rxd_met;
    end if;
end process edge_detector;

--  edge_dete <= pos_edge or neg_edge;


  
  
  
  
  
  
  
end rtl;
