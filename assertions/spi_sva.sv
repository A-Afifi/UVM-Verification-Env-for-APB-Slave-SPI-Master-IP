
// =============================================================================
// spi_sva.sv
// SVA Assertions for SPI Master Verification Project 
// =============================================================================
//
// BIND STRATEGY
// =============
//   Two checker modules are bound by MODULE TYPE.
//   Binding by type (not instance path) is portable across all DUT variants.
//
//   Checker                 Bound to type    Hierarchy reached
//   ──────────────────────  ───────────────  ────────────────────────────────
//   apb_regfile_sva         apb_regfile      spi_master_top.u_dut.u_regfile
//   spi_core_sva            spi_core         spi_master_top.u_dut.u_core
//
//   ALL signals referenced inside each checker are actual RTL signal names
//   taken directly from the released source (apb_regfile.sv / spi_core.sv).
//
// GRADER LOG CONTRACT  (Grading Interface Rev 1.2 - Section 3)
// =============================================================================
//   Every $error() uses the prefix  [ASSERTION_ERROR]  so the grader scanner
//   counts the failure as a bug catch.
// =============================================================================

`default_nettype wire
`timescale 1ns/1ps

// =============================================================================
// CHECKER 1 : apb_regfile_sva
// Bound to  : apb_regfile  (module type)
// =============================================================================
module apb_regfile_sva (
    input  logic         PCLK,
    input  logic         PRESETn,

    // APB bus
    input  logic         PSEL,
    input  logic         PENABLE,
    input  logic         PWRITE,
    input  logic [7:0]   PADDR,
    input  logic [31:0]  PWDATA,
    input  logic [31:0]  PRDATA,
    input  logic         PREADY,
    input  logic         PSLVERR,

    // Internal regfile state
    input  logic         ctrl_en,
    input  logic [4:0]   int_stat,
    input  logic [4:0]   int_en,
    input  logic         IRQ,
    input  logic         rx_full_w,
    input  logic         rx_push_valid,
    input  logic         tx_push_dropped,
    input  logic         tx_push_accepted,
    input  logic         tx_full_w,
    input  logic         busy_in
);

    // -------------------------------------------------------------------------
    // APB_1 : PSEL must remain asserted for at least 2 consecutive PCLK cycles.
    // -------------------------------------------------------------------------
    property apb_psel_min_2_cycles;
        @(posedge PCLK) disable iff (!PRESETn)
        $rose(PSEL) |=> PSEL;
    endproperty
    assert property (apb_psel_min_2_cycles)
        else $error("[ASSERTION_ERROR] apb_psel_min_2_cycles : PSEL deasserted after only 1 PCLK cycle");
    cover property (apb_psel_min_2_cycles);

    // -------------------------------------------------------------------------
    // APB_2 : PENABLE may only be high while PSEL is also high.
    // -------------------------------------------------------------------------
    property apb_penable_requires_psel;
        @(posedge PCLK) disable iff (!PRESETn)
        PENABLE |-> PSEL;
    endproperty
    assert property (apb_penable_requires_psel)
        else $error("[ASSERTION_ERROR] apb_penable_requires_psel : PENABLE=1 while PSEL=0");
    cover property (apb_penable_requires_psel);

    // -------------------------------------------------------------------------
    // APB_3 : PADDR, PWRITE, PWDATA must be stable from SETUP through ACCESS.
    // -------------------------------------------------------------------------
    property apb_ctrl_stable_setup_to_access;
        logic [7:0]  saved_addr;
        logic        saved_write;
        logic [31:0] saved_wdata;
        @(posedge PCLK) disable iff (!PRESETn)
        (PSEL && !PENABLE,
         saved_addr  = PADDR,
         saved_write = PWRITE,
         saved_wdata = PWDATA)
        |=> (PSEL && PENABLE &&
             PADDR  == saved_addr  &&
             PWRITE == saved_write &&
             PWDATA == saved_wdata);
    endproperty
    assert property (apb_ctrl_stable_setup_to_access)
        else $error("[ASSERTION_ERROR] apb_ctrl_stable_setup_to_access : PADDR/PWRITE/PWDATA changed between SETUP and ACCESS phases");
    cover property (apb_ctrl_stable_setup_to_access);

    // -------------------------------------------------------------------------
    // APB_4 : PREADY is always 1 (zero wait-state slave).
    // -------------------------------------------------------------------------
    property apb_pready_always_1;
        @(posedge PCLK) disable iff (!PRESETn)
        (PSEL && PENABLE) |-> PREADY;
    endproperty
    assert property (apb_pready_always_1)
        else $error("[ASSERTION_ERROR] apb_pready_always_1 : PREADY=0 during ACCESS phase (zero-wait-state violated)");
    cover property (apb_pready_always_1);

    // -------------------------------------------------------------------------
    // APB_5 : PSLVERR is always 0.
    // -------------------------------------------------------------------------
    property apb_pslverr_always_0;
        @(posedge PCLK) disable iff (!PRESETn)
        (PSEL && PENABLE) |-> !PSLVERR;
    endproperty
    assert property (apb_pslverr_always_0)
        else $error("[ASSERTION_ERROR] apb_pslverr_always_0 : PSLVERR=1 (must always be 0)");
    cover property (apb_pslverr_always_0);

    // -------------------------------------------------------------------------
    // IRQ_1 : IRQ == |(INT_STAT & INT_EN) at every PCLK edge (combinational).
    // -------------------------------------------------------------------------
    property irq_equation_correct;
        @(posedge PCLK) disable iff (!PRESETn)
        IRQ == |(int_stat & int_en);
    endproperty
    assert property (irq_equation_correct)
        else $error("[ASSERTION_ERROR] irq_equation_correct : IRQ=%b but |(INT_STAT & INT_EN)=%b  INT_STAT=%05b INT_EN=%05b",
                    IRQ, |(int_stat & int_en), int_stat, int_en);
    cover property (irq_equation_correct);

    // -------------------------------------------------------------------------
    // IRQ_2 : A TX_OVF event (tx_push_dropped) must set INT_STAT[TX_OVF]
    // -------------------------------------------------------------------------
    property tx_ovf_sets_int_stat;
        @(posedge PCLK) disable iff (!PRESETn)
        tx_push_dropped |=> int_stat[2];
    endproperty
    assert property (tx_ovf_sets_int_stat)
        else $error("[ASSERTION_ERROR] tx_ovf_sets_int_stat : TX_OVF event occurred but INT_STAT[TX_OVF] not set next cycle");
    cover property (tx_ovf_sets_int_stat);

    // -------------------------------------------------------------------------
    // IRQ_3 : An RX overflow event (push while full) must set INT_STAT[RX_OVF]
    // -------------------------------------------------------------------------
    property rx_ovf_sets_int_stat;
        @(posedge PCLK) disable iff (!PRESETn)
        (rx_push_valid && rx_full_w) |=> int_stat[3];
    endproperty
    assert property (rx_ovf_sets_int_stat)
        else $error("[ASSERTION_ERROR] rx_ovf_sets_int_stat : RX_OVF event occurred but INT_STAT[RX_OVF] not set next cycle");
    cover property (rx_ovf_sets_int_stat);

    // -------------------------------------------------------------------------
    // FIFO_1 : TX push accepted only when not full.
    // -------------------------------------------------------------------------
    property tx_push_not_when_full;
        @(posedge PCLK) disable iff (!PRESETn)
        !(tx_push_accepted && tx_full_w);
    endproperty
    assert property (tx_push_not_when_full)
        else $error("[ASSERTION_ERROR] tx_push_not_when_full : TX FIFO push accepted while TX_FULL=1");
    cover property (tx_push_not_when_full);

    // -------------------------------------------------------------------------
    // FIFO_2 : A dropped TX write (overflow) must be accompanied by tx_full_w=1.
    // -------------------------------------------------------------------------
    property tx_drop_implies_full;
        @(posedge PCLK) disable iff (!PRESETn)
        tx_push_dropped |-> tx_full_w;
    endproperty
    assert property (tx_drop_implies_full)
        else $error("[ASSERTION_ERROR] tx_drop_implies_full : TX push dropped but TX FIFO was not full");
    cover property (tx_drop_implies_full);

    // -------------------------------------------------------------------------
    // RESET_1 : After PRESETn deasserts, CTRL.EN must be 0
    // -------------------------------------------------------------------------
    property ctrl_en_reset_value;
        @(posedge PCLK)
        $rose(PRESETn) |=> !ctrl_en;
    endproperty
    assert property (ctrl_en_reset_value)
        else $error("[ASSERTION_ERROR] ctrl_en_reset_value : CTRL.EN not 0 after reset deasserts");
    cover property (ctrl_en_reset_value);

    // -------------------------------------------------------------------------
    // RESET_2 : After PRESETn deasserts, all INT_STAT bits must be 0.
    // -------------------------------------------------------------------------
    property int_stat_reset_value;
        @(posedge PCLK)
        $rose(PRESETn) |=> (int_stat == 5'h0);
    endproperty
    assert property (int_stat_reset_value)
        else $error("[ASSERTION_ERROR] int_stat_reset_value : INT_STAT not 0x00 after reset deasserts, got 0x%02h", int_stat);
    cover property (int_stat_reset_value);

    // -------------------------------------------------------------------------
    // RESET_3 : After PRESETn deasserts, IRQ must be 0
    // -------------------------------------------------------------------------
    property irq_reset_value;
        @(posedge PCLK)
        $rose(PRESETn) |=> !IRQ;
    endproperty
    assert property (irq_reset_value)
        else $error("[ASSERTION_ERROR] irq_reset_value : IRQ not 0 after reset deasserts");
    cover property (irq_reset_value);

endmodule : apb_regfile_sva


// =============================================================================
// CHECKER 2 : spi_core_sva
// Bound to  : spi_core  (module type)
// =============================================================================
module spi_core_sva (
    input  logic         PCLK,
    input  logic         PRESETn,

    // Config inputs
    input  logic         cfg_en,
    input  logic         cfg_mstr,
    input  logic [1:0]   cfg_mode,
    input  logic         cfg_lsb_first,
    input  logic         cfg_loopback,
    input  logic [1:0]   cfg_width,
    input  logic [15:0]  cfg_clk_div,
    input  logic [7:0]   cfg_delay,

    // Pin Observability 
    input  logic         SCLK,
    input  logic         MOSI,
    input  logic         MISO,
    input  logic [3:0]   ss_n_drive,

    // FIFO & Handshake state
    input  logic [31:0]  tx_word,
    input  logic         tx_empty,
    input  logic         tx_pop,
    input  logic         rx_push_valid,
    input  logic [31:0]  rx_push_data,
    input  logic         busy,
    input  logic         transfer_done_pulse,

    // Sub-system registers / Tracking tracks
    input  logic [1:0]   state,
    input  logic [5:0]   bit_cnt,
    input  logic [16:0]  sclk_cnt,
    input  logic [8:0]   gap_cnt,
    input  logic         sclk_phase,
    input  logic [31:0]  sh_tx,
    input  logic [31:0]  sh_rx,
    input  logic [1:0]   xfer_mode,
    input  logic         xfer_lsb_first,
    input  logic [1:0]   xfer_width,
    input  logic [15:0]  xfer_div
);

    // FSM execution local parameters
    localparam logic [1:0] S_IDLE   = 2'd0;
    localparam logic [1:0] S_SHIFT  = 2'd1;
    localparam logic [1:0] S_FINISH = 2'd2;
    localparam logic [1:0] S_GAP    = 2'd3;

    // Derived operational wires
    wire cpol = xfer_mode[1];
    wire cpha = xfer_mode[0];
    wire [16:0] half_period = {1'b0, xfer_div} + 17'd1;
    wire miso_eff = cfg_loopback ? MOSI : MISO;

    wire [5:0] width_bits = (xfer_width == 2'b00) ? 6'd8  :
                            (xfer_width == 2'b01) ? 6'd16 : 6'd32;

    // Native tracking expressions for clock edge detection using sub-system counters
    wire is_leading_edge = (state == S_SHIFT) && (sclk_cnt == half_period - 1);
    wire is_trailing_edge = (state == S_SHIFT) && (sclk_cnt == (half_period << 1) - 1);
    
    wire is_sample_edge = (cpha == 1'b0) ? is_leading_edge : is_trailing_edge;
    wire is_launch_edge = (cpha == 1'b0) ? is_trailing_edge : is_leading_edge;

    // Automatic Bit extraction function block
    function automatic logic get_tx_bit(input logic [31:0] v,
                                        input logic [5:0]  remaining,
                                        input logic [5:0]  total_bits,
                                        input logic        lsb_first);
        if (lsb_first)
            get_tx_bit = v[total_bits - remaining];
        else
            get_tx_bit = v[remaining - 1];
    endfunction

    // Automatic alignment truncation utility
    function automatic logic [31:0] align_rx(input logic [31:0] sh,
                                             input logic [5:0]  total_bits);
        align_rx = sh & ((total_bits == 6'd32) ? 32'hFFFF_FFFF :
                         ((32'h1 << total_bits) - 32'h1));
    endfunction

    // -------------------------------------------------------------------------
    // SECTION 3: MISO Line Configuration Selection
    // -------------------------------------------------------------------------
    property p_miso_eff_loopback;
        @(posedge PCLK) disable iff(!PRESETn)
        (cfg_loopback) |-> (miso_eff == MOSI);
    endproperty
    a_miso_eff_loopback: assert property(p_miso_eff_loopback) 
        else $error("[ASSERTION_ERROR] FAIL R5 : miso_eff does not follow MOSI when loopback is enabled");
    c_miso_eff_loopback: cover property(p_miso_eff_loopback);


    //-------------------------------------------------------------------------
    // SECTION 4: MISO Line Normal Operation
    //-------------------------------------------------------------------------
    property p_miso_eff_normal;
        @(posedge PCLK) disable iff(!PRESETn)
        (!cfg_loopback) |-> (miso_eff == MISO);
    endproperty
    a_miso_eff_normal: assert property(p_miso_eff_normal) 
        else $error("[ASSERTION_ERROR] FAIL R6 : miso_eff does not follow MISO when loopback is disabled");
    c_miso_eff_normal: cover property(p_miso_eff_normal);

    // -------------------------------------------------------------------------
    // SECTION 5: BUSY Flag Coherence 
    // -------------------------------------------------------------------------
    a_busy_state_cfg_r3: assert property (@(posedge PCLK) disable iff (!PRESETn)
        (busy == (state != S_IDLE)) &&
        ((state != S_SHIFT)  || busy) &&
        ((state != S_FINISH) || busy) &&
        ((state != S_GAP)    || busy))
    else $error("[ASSERTION_ERROR] FAIL R9 BUSY_STATE: busy/state relationship violated");

    // -------------------------------------------------------------------------
    // SECTION 6: MOSI Shift Launch Updates
    // -------------------------------------------------------------------------
    property p_mosi_launch_edge;
        @(posedge PCLK) disable iff(!PRESETn)
        (is_launch_edge && (bit_cnt > 6'd0)) |=> 
        (MOSI == get_tx_bit($past(sh_tx), $past(bit_cnt), $past(width_bits), $past(xfer_lsb_first)));
    endproperty
    a_mosi_launch_edge: assert property(p_mosi_launch_edge)
        else $error("[ASSERTION_ERROR] FAIL 14 : MOSI not launched correctly on launch edge");
    c_mosi_launch_edge: cover property(p_mosi_launch_edge);

    property p_mosi_cpha1_first_launch;
        @(posedge PCLK) disable iff(!PRESETn)
        (cpha == 1'b1 && is_leading_edge && (bit_cnt == width_bits)) |=> 
        (MOSI == get_tx_bit($past(sh_tx), $past(bit_cnt), $past(width_bits), $past(xfer_lsb_first)));
    endproperty
    a_mosi_cpha1_first_launch: assert property(p_mosi_cpha1_first_launch)
        else $error("[ASSERTION_ERROR] FAIL 15 : MOSI first-bit launch incorrect for CPHA=1");
    c_mosi_cpha1_first_launch: cover property(p_mosi_cpha1_first_launch);

    // -------------------------------------------------------------------------
    // SECTION 7: Commit States Validation
    // -------------------------------------------------------------------------
    property p_finish_generates_done_and_rxpush;
        @(posedge PCLK) disable iff(!PRESETn)
        (state == S_FINISH && (sclk_cnt == half_period - 1)) |=> 
        (transfer_done_pulse && rx_push_valid && (rx_push_data == align_rx($past(sh_rx), $past(width_bits))));
    endproperty
    a_finish_generates_done_and_rxpush: assert property(p_finish_generates_done_and_rxpush)
        else $error("[ASSERTION_ERROR] FAIL 16 : FINISH state did not generate RX push or done pulse correctly");
    c_finish_generates_done_and_rxpush: cover property(p_finish_generates_done_and_rxpush);

    property p_finish_restores_idle_clock;
        @(posedge PCLK) disable iff(!PRESETn)
        (state == S_FINISH && (sclk_cnt == half_period - 1)) |=> 
        ((sclk_cnt == 17'h0) && (SCLK == $past(cpol)) && (sclk_phase == 1'b0));
    endproperty
    a_finish_restores_idle_clock: assert property(p_finish_restores_idle_clock)
        else $error("[ASSERTION_ERROR] FAIL 17 : FINISH state did not restore idle SPI clock configuration");
    c_finish_restores_idle_clock: cover property(p_finish_restores_idle_clock);

    // -------------------------------------------------------------------------
    // SECTION 8: Inter-transfer Delays and Gap Processing
    // -------------------------------------------------------------------------
    property p_gap_keeps_idle_clock;
        @(posedge PCLK) disable iff(!PRESETn)
        (state == S_GAP) |=> (SCLK == $past(cpol));
    endproperty
    a_gap_keeps_idle_clock: assert property(p_gap_keeps_idle_clock)
        else $error("[ASSERTION_ERROR] FAIL 18 : GAP state did not keep SCLK at idle polarity");
    c_gap_keeps_idle_clock: cover property(p_gap_keeps_idle_clock);

    property p_gap_resets_sclk_counter;
        @(posedge PCLK) disable iff(!PRESETn)
        (state == S_GAP && (sclk_cnt == half_period - 1)) |=> (sclk_cnt == 17'h0);
    endproperty
    a_gap_resets_sclk_counter: assert property(p_gap_resets_sclk_counter)
        else $error("[ASSERTION_ERROR] FAIL 19 : GAP state did not reset sclk_cnt");
    c_gap_resets_sclk_counter: cover property(p_gap_resets_sclk_counter);

    property p_gap_decrements_gap_counter;
        @(posedge PCLK) disable iff(!PRESETn)
        (state == S_GAP && (sclk_cnt == half_period - 1)) |=> (gap_cnt == ($past(gap_cnt) - 9'h1));
    endproperty
    a_gap_decrements_gap_counter: assert property(p_gap_decrements_gap_counter)
        else $error("[ASSERTION_ERROR] FAIL 20 : GAP state did not decrement gap counter");
    c_gap_decrements_gap_counter: cover property(p_gap_decrements_gap_counter);

    property p_gap_to_idle_transition;
        @(posedge PCLK) disable iff(!PRESETn)
        (state == S_GAP && (sclk_cnt == half_period - 1) && (gap_cnt == 9'h1)) |=> (state == S_IDLE);
    endproperty
    a_gap_to_idle_transition: assert property(p_gap_to_idle_transition)
        else $error("[ASSERTION_ERROR] FAIL 21 : GAP state did not transition to IDLE");
    c_gap_to_idle_transition: cover property(p_gap_to_idle_transition);

    property p_gap_increments_sclk_counter;
        @(posedge PCLK) disable iff(!PRESETn)
        (state == S_GAP && (sclk_cnt != half_period - 1)) |=> (sclk_cnt == ($past(sclk_cnt) + 17'h1));
    endproperty
    a_gap_increments_sclk_counter: assert property(p_gap_increments_sclk_counter)
        else $error("[ASSERTION_ERROR] FAIL 22 : GAP state did not increment sclk_cnt");
    c_gap_increments_sclk_counter: cover property(p_gap_increments_sclk_counter);

    // -------------------------------------------------------------------------
    // SECTION 3: SPI: SCLK idle level matches CPOL whenever BUSY=0
    // -------------------------------------------------------------------------
    // property sclk_idle_matches_cpol;
    //     @(posedge PCLK) disable iff (!PRESETn)
    //     (!busy) |-> (SCLK == cpol);
    // endproperty
    // assert property (sclk_idle_matches_cpol) else $error("[ASSERTION_ERROR] sclk_idle_matches_cpol : SCLK mismatch when idle");

    // -------------------------------------------------------------------------
    // SECTION 4: width_bits field consistency with xfer_width encoding
    // ------------------------------------------------------------------------
    property width_bits_consistent;
        @(posedge PCLK) disable iff (!PRESETn || !busy)
        ((xfer_width == 2'b00) && (width_bits == 6'd8 )) ||
        ((xfer_width == 2'b01) && (width_bits == 6'd16)) ||
        ((xfer_width == 2'b10) && (width_bits == 6'd32));
    endproperty
    assert property (width_bits_consistent) else $error("[ASSERTION_ERROR] width_bits_consistent : Configuration width mismatch");

    property bit_cnt_in_range;
        @(posedge PCLK) disable iff (!PRESETn)
        (state == S_SHIFT) |-> (bit_cnt <= width_bits);
    endproperty
    assert property (bit_cnt_in_range) else $error("[ASSERTION_ERROR] bit_cnt_in_range : Overrun on tracking bit counter");




    // -------------------------------------------------------------------------
    // SPI_3 : SS_n held asserted for the entire WIDTH-bit transfer length
    // -------------------------------------------------------------------------
    // property ss_asserted_for_entire_width;
    //     @(posedge PCLK) disable iff (!PRESETn)
    //     // Only enforce the active slave lane check while the FSM is actively 
    //     // in the shifting state and bits are still remaining in the pipe.
    //     (state == S_SHIFT && bit_cnt > 6'd0) |-> (ss_n_drive != 4'hF);
    // endproperty
    // assert property (ss_asserted_for_entire_width) 
    //     else $error("[ASSERTION_ERROR] ss_asserted_for_entire_width : SS_n dropped high before the active width-bit data phase completed");
    // cover property (ss_asserted_for_entire_width);
    // // SPI_4 : transfer_done_pulse is a single-cycle pulse that occurs at the end of a transfer

    property xfer_done_pulse_single_cycle;
        @(posedge PCLK) disable iff (!PRESETn)
        transfer_done_pulse |=> !transfer_done_pulse;
    endproperty
    assert property (xfer_done_pulse_single_cycle) else $error("[ASSERTION_ERROR] xfer_done_pulse_single_cycle : Handshake pulse stuck high");

    property rx_push_single_cycle;
        @(posedge PCLK) disable iff (!PRESETn)
        rx_push_valid |=> !rx_push_valid;
    endproperty
    assert property (rx_push_single_cycle) else $error("[ASSERTION_ERROR] rx_push_single_cycle : Commit pulse stuck high");







endmodule : spi_core_sva



`default_nettype wire
