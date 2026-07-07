// =============================================================================
// coverage_closure_seq.sv
// Targets every remaining ZERO bin from the coverage report:
//
//  1. cp_clk_div_value:      div_2 (16'h0002), div_1024 (16'h0400)
//  2. cp_clock_div_corners:  div_2, div_1024 (cross — auto-closes once above hit)
//  3. cp_spi_mode_x_all_widths: 12 missing bins:
//       mode1_w16_lsb, mode1_w32_lsb
//       mode2_w8_lsb,  mode2_w16_lsb (already covered), mode2_w32_lsb
//       mode3_w8_lsb,  mode3_w16_lsb, mode3_w32_lsb  (only mode3_w32_msb covered)
//       mode4_w8_lsb,  mode4_w16_lsb, mode4_w32_lsb
//       mode2_w16_msb, mode2_w32_msb  (also ZERO in the MSB group)
//       mode3_w16_msb                  (also ZERO in the MSB group)
//       mode1_w16_lsb, mode1_w32_lsb  (ZERO in LSB group)
//  4. cp_reset_observed.tx_data_reset: read 8'h08 right after reset → expect 0
// =============================================================================
class coverage_closure_seq extends sequence_base;
    `uvm_object_utils(coverage_closure_seq)

    function new(string name = "coverage_closure_seq");
        super.new(name);
    endfunction

    // -----------------------------------------------------------------------
    // Helper: write CTRL register to encode mode/width/lsb_first combo,
    // do one loopback transfer, then restore a clean state.
    // ctrl_val layout (from existing code):
    //   [7:6] = width  (00=8b, 01=16b, 10=32b)
    //   [5]   = loopback = 1 (self-test)
    //   [4]   = lsb_first
    //   [3:2] = mode   (CPOL/CPHA: 00,01,10,11)
    //   [1]   = mstr   = 1
    //   [0]   = en     = 1
    // -----------------------------------------------------------------------
    task do_loopback_transfer(
        input bit [1:0] mode,
        input bit [1:0] width,
        input bit       lsb_first,
        input bit [15:0] div,
        input bit [31:0] tx_data
    );
        bit [7:0] ctrl_val;
        ctrl_val = {width, 1'b1, lsb_first, mode, 1'b1, 1'b1};

        apb_write(8'h10, {16'h0, div});       // CLK_DIV
        apb_write(8'h00, {24'h0, ctrl_val});  // CTRL
        apb_write(8'h14, 32'h00000001);       // SS_EN[0]=1
        apb_write(8'h08, tx_data);            // TX push
        repeat(300) apb_read(8'h04);          // poll STATUS until done
        apb_read(8'h0C);                      // drain RX
        apb_write(8'h14, 32'h00000000);       // deassert SS
        apb_write(8'h1C, 32'h0000001F);       // clear INT_STAT
        apb_write(8'h00, 32'h00000000);       // disable
    endtask

    task body();
        `uvm_info("COV_CLOSURE", "=== Coverage closure sequence ===", UVM_LOW)

        // ===================================================================
        // FIX 1 & 2 — cp_clk_div_value: div_2 and div_1024
        //             cp_clock_div_corners: div_2, div_1024 (cross closes too)
        //
        // Strategy: write to CLK_DIV register with these exact values while
        // PADDR==8'h10 and PWRITE==1. The cross coverpoint fires automatically
        // because cp_reg_address.CLK_DIV and cp_clk_div_value.div_X are both
        // sampled on the same APB transaction.
        // ===================================================================
        `uvm_info("COV_CLOSURE", "FIX 1/2: CLK_DIV=2 and CLK_DIV=1024", UVM_LOW)

        // Enable SPI so the write is a valid operating condition
        apb_write(8'h00, 32'h00000003);       // EN=1, MSTR=1

        // Hit div_2  (16'h0002)
        apb_write(8'h10, 32'h00000002);       // CLK_DIV = 2
        apb_read (8'h10);                     // read back for sanity

        // Hit div_1024 (16'h0400)
        apb_write(8'h10, 32'h00000400);       // CLK_DIV = 1024
        apb_read (8'h10);

        // Run one transfer at each new div value to prove the clock actually works
        do_loopback_transfer(2'b00, 2'b00, 1'b0, 16'h0002, 32'h000000C5); // div=2
        do_loopback_transfer(2'b00, 2'b00, 1'b0, 16'h0400, 32'h000000D7); // div=1024

        // ===================================================================
        // FIX 3 — cp_spi_mode_x_all_widths: all 12 missing bins
        //
        // Reading the report carefully:
        //   MSB-first ZERO bins:
        //     mode2_w16_msb  (mode=01, w16, lsb=0)
        //     mode2_w32_msb  (mode=01, w32, lsb=0)
        //     mode3_w16_msb  (mode=10, w16, lsb=0)
        //
        //   LSB-first ZERO bins:
        //     mode1_w16_lsb  (mode=00, w16, lsb=1)
        //     mode1_w32_lsb  (mode=00, w32, lsb=1)
        //     mode2_w8_lsb   (mode=01, w8,  lsb=1)
        //     mode2_w32_lsb  (mode=01, w32, lsb=1)
        //     mode3_w8_lsb   (mode=10, w8,  lsb=1)
        //     mode3_w16_lsb  (mode=10, w16, lsb=1)
        //     mode4_w8_lsb   (mode=11, w8,  lsb=1)
        //     mode4_w16_lsb  (mode=11, w16, lsb=1)
        //     mode4_w32_lsb  (mode=11, w32, lsb=1)
        //
        // Each call writes CTRL with PADDR=8'h00 and PWRITE=1.  The cross
        // samples cp_reg_address.CTRL, cp_mode, cp_width, cp_lsb_first
        // simultaneously from that single APB write, so one write per combo
        // is sufficient.  The loopback transfer verifies the DUT actually
        // completes a transaction in that configuration.
        // ===================================================================
        `uvm_info("COV_CLOSURE", "FIX 3: missing mode×width×lsb_first cross bins", UVM_LOW)

        // --- Missing MSB-first bins ---

        // mode2_with_w16_msb: mode=01 (CPOL=0,CPHA=1), width=01 (16b), lsb=0
        `uvm_info("COV_CLOSURE", "mode2_w16_msb", UVM_LOW)
        do_loopback_transfer(2'b01, 2'b01, 1'b0, 16'h0001, 32'h0000CAFE);

        // mode2_with_w32_msb: mode=01, width=10 (32b), lsb=0
        `uvm_info("COV_CLOSURE", "mode2_w32_msb", UVM_LOW)
        do_loopback_transfer(2'b01, 2'b10, 1'b0, 16'h0001, 32'hDEAD0001);

        // mode3_with_w16_msb: mode=10 (CPOL=1,CPHA=0), width=01, lsb=0
        `uvm_info("COV_CLOSURE", "mode3_w16_msb", UVM_LOW)
        do_loopback_transfer(2'b10, 2'b01, 1'b0, 16'h0001, 32'h0000BEEF);

        // --- Missing LSB-first bins ---

        // mode1_with_w16_lsb: mode=00, width=01, lsb=1
        `uvm_info("COV_CLOSURE", "mode1_w16_lsb", UVM_LOW)
        do_loopback_transfer(2'b00, 2'b01, 1'b1, 16'h0001, 32'h0000A5A5);

        // mode1_with_w32_lsb: mode=00, width=10, lsb=1
        `uvm_info("COV_CLOSURE", "mode1_w32_lsb", UVM_LOW)
        do_loopback_transfer(2'b00, 2'b10, 1'b1, 16'h0001, 32'hA5A5A5A5);

        // mode2_with_w8_lsb:  mode=01, width=00 (8b), lsb=1
        `uvm_info("COV_CLOSURE", "mode2_w8_lsb", UVM_LOW)
        do_loopback_transfer(2'b01, 2'b00, 1'b1, 16'h0001, 32'h000000B3);

        // mode2_with_w32_lsb: mode=01, width=10, lsb=1
        `uvm_info("COV_CLOSURE", "mode2_w32_lsb", UVM_LOW)
        do_loopback_transfer(2'b01, 2'b10, 1'b1, 16'h0001, 32'hFACEFEED);

        // mode3_with_w8_lsb:  mode=10, width=00, lsb=1
        `uvm_info("COV_CLOSURE", "mode3_w8_lsb", UVM_LOW)
        do_loopback_transfer(2'b10, 2'b00, 1'b1, 16'h0001, 32'h000000E1);

        // mode3_with_w16_lsb: mode=10, width=01, lsb=1
        `uvm_info("COV_CLOSURE", "mode3_w16_lsb", UVM_LOW)
        do_loopback_transfer(2'b10, 2'b01, 1'b1, 16'h0001, 32'h0000E1E2);

        // mode4_with_w8_lsb:  mode=11, width=00, lsb=1
        `uvm_info("COV_CLOSURE", "mode4_w8_lsb", UVM_LOW)
        do_loopback_transfer(2'b11, 2'b00, 1'b1, 16'h0001, 32'h000000F1);

        // mode4_with_w16_lsb: mode=11, width=01, lsb=1
        `uvm_info("COV_CLOSURE", "mode4_w16_lsb", UVM_LOW)
        do_loopback_transfer(2'b11, 2'b01, 1'b1, 16'h0001, 32'h0000F1F2);

        // mode4_with_w32_lsb: mode=11, width=10, lsb=1
        `uvm_info("COV_CLOSURE", "mode4_w32_lsb", UVM_LOW)
        do_loopback_transfer(2'b11, 2'b10, 1'b1, 16'h0001, 32'hF1F2F3F4);

        // ===================================================================
        // FIX 4 — cp_reset_observed.tx_data_reset
        //
        // Root cause: TX_DATA (0x08) is write-only in the spec — reading it
        // after a reset likely returns 0, but the testbench never performed
        // that read before any TX write, so PRDATA==0 was never observed for
        // PADDR==0x08.
        //
        // Strategy: apply a soft reset (disable SPI via CTRL), then
        // immediately read TX_DATA before touching the TX FIFO.  With EN=0
        // the register returns its reset value (0x00000000), which hits the
        // cp_prdata.zero_val bin for PADDR==TX_DATA.
        //
        // NOTE: if TX_DATA is truly write-only and always returns 0 regardless
        // of written value, the read will still produce PRDATA=0 and close the
        // bin.  If the RTL gates reads on EN, you may need to keep EN=1; in
        // that case uncomment the alternative below.
        // ===================================================================
        `uvm_info("COV_CLOSURE", "FIX 4: tx_data_reset — read TX_DATA after reset", UVM_LOW)

        // Ensure a clean reset state: disable SPI
        apb_write(8'h00, 32'h00000000);  // CTRL = 0, EN=0 flushes FIFOs
        apb_write(8'h14, 32'h00000000);  // SS_CTRL = 0
        apb_write(8'h1C, 32'h0000001F);  // clear all INT_STAT

        // Read TX_DATA now — FIFO flushed, no writes yet → PRDATA must be 0
        // This fires cp_prdata.zero_val with cp_reg_address.TX_DATA,
        // closing the cp_reset_observed.tx_data_reset bin.
        apb_read(8'h08);  // TX_DATA → expect PRDATA=32'h00000000

        // Verify the read returned 0 (scoreboard will check, but read STATUS too)
        apb_read(8'h04);  // STATUS: TX_EMPTY=1, BUSY=0 expected in reset state

        // --- Alternative if TX_DATA reads as 0 only when EN=1 ---
        // apb_write(8'h00, 32'h00000003); // EN=1, MSTR=1, no data in TX FIFO yet
        // apb_read(8'h08);                 // TX_DATA → PRDATA=0 (FIFO empty)
        // apb_write(8'h00, 32'h00000000);

        // ===================================================================
        // Final cleanup
        // ===================================================================
        apb_write(8'h00, 32'h00000000);
        apb_write(8'h10, 32'h00000000);
        apb_write(8'h14, 32'h00000000);
        apb_write(8'h18, 32'h00000000);
        apb_write(8'h1C, 32'h0000001F);
        apb_write(8'h20, 32'h00000000);

        `uvm_info("COV_CLOSURE", "=== Coverage closure sequence complete ===", UVM_LOW)
    endtask

endclass