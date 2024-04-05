///////////////////////////////////////////////////////////////////////////////
//             Copyright ///////////////////////////////////
//                        All Rights Reserved
///////////////////////////////////////////////////////////////////////////////
// $Author:  $
//
//
// Description :
//          This file was generated by SV TB Gen Version 1.2
//            on 18 Dec 2023 13:08:26
//////////////////////////////////////////////////////////////////////////////
// This software contains concepts confidential to ////////////////
// /////////. and is only made available within the terms of a written
// agreement.
///////////////////////////////////////////////////////////////////////////////

module tb_top ();

  string STM_FILE = "./dbg_link/sv_sim/stm/stimulus_file.stm";
  string tmp_fn;
  int    tc = 0;

  //  Handle plus args
  initial begin : file_select
    tc = $get_initial_random_seed();
    case (tc & 'b111)
      0: STM_FILE  = "./dbg_link/sv_sim/stm/stimulus_file.stm";
      1: STM_FILE  = "./dbg_link/sv_sim/stm/controls.stm";
      2: STM_FILE  = "./dbg_link/sv_sim/stm/iowrite00.stm";
      3: STM_FILE  = "./dbg_link/sv_sim/stm/iowrite40.stm";
      4: STM_FILE  = "./dbg_link/sv_sim/stm/iowrite100_140.stm";
      5: STM_FILE  = "./dbg_link/sv_sim/stm/iowrite00.stm";
      6: STM_FILE  = "./dbg_link/sv_sim/stm/iowrite40.stm";
      7: STM_FILE  = "./dbg_link/sv_sim/stm/iowrite100_140.stm";
      default: STM_FILE  = "./dbg_link/sv_sim/stm/stimulus_file.stm";
    endcase
    $display("Running test case:  %s",STM_FILE);
    if($value$plusargs("STM_FILE=%s", tmp_fn)) begin
      STM_FILE = tmp_fn;
    end
  end

  dut_if theif();

  debug_sys u1 (
    .rst(!theif.rst),
    .clk(theif.clk),
    .rxs(theif.rxs),
    .txs(theif.txs)
  );

  tb_mod tb_inst(theif);

endmodule
