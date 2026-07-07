// =============================================================================
// r19_r23_misc_seq.sv
// Covers:
//   R19: Loopback mode routes MOSI->RX internally; external MISO ignored
//   R20: SS_n[i] = !SS_EN[i] | SS_VAL[i] combinationally
//   R21: DELAY SCLK half-cycles inserted between consecutive transfers
//   R22: PSLVERR=0, PREADY=1 for every access (zero wait states)
//   R23: Reserved offsets (0x24+) read as 0, writes ignored
// =============================================================================
class r19_r23_misc_seq extends sequence_base;
    `uvm_object_utils(r19_r23_misc_seq)

    function new(string name = "r19_r23_misc_seq");
        super.new(name);
    endfunction

    task body();
        `uvm_info("R19_R23_SEQ", "=== R19-R23: Misc Tests ===", UVM_LOW)

        // -----------------------------------------------------------------
        // R19: Loopback mode - all 3 widths
        // In loopback: MOSI is fed back to RX. TX word should equal RX word.
        // -----------------------------------------------------------------
        `uvm_info("R19_R23_SEQ", "R19: Loopback 8-bit", UVM_LOW)
        apb_write(8'h00, 32'h00000000); // disable first
        apb_write(8'h10, 32'h00000001); // DIV=1
        apb_write(8'h00, 32'h00000023); // EN=1,MSTR=1,LOOPBACK=1,8-bit,Mode0
        apb_write(8'h14, 32'h00000001); // SS asserted
        apb_write(8'h08, 32'h000000A5); // TX=0xA5 -> RX must be 0xA5 in loopback
        repeat(100) apb_read(8'h04);    // wait
        apb_read (8'h0C);               // RX: expect 0xA5
        apb_write(8'h14, 32'h00000000);
        apb_write(8'h1C, 32'h0000001F);

        `uvm_info("R19_R23_SEQ", "R19: Loopback 16-bit", UVM_LOW)
        apb_write(8'h00, 32'h00000000);
        apb_write(8'h00, 32'h00000063); // EN=1,MSTR=1,LOOPBACK=1,16-bit,Mode0
        apb_write(8'h14, 32'h00000001);
        apb_write(8'h08, 32'h0000BEEF); // TX=0xBEEF
        repeat(150) apb_read(8'h04);
        apb_read (8'h0C);               // RX: expect 0xBEEF
        apb_write(8'h14, 32'h00000000);
        apb_write(8'h1C, 32'h0000001F);

        `uvm_info("R19_R23_SEQ", "R19: Loopback 32-bit", UVM_LOW)
        apb_write(8'h00, 32'h00000000);
        apb_write(8'h00, 32'h000000A3); // EN=1,MSTR=1,LOOPBACK=1,32-bit,Mode0
        apb_write(8'h14, 32'h00000001);
        apb_write(8'h08, 32'hDEADBEEF); // TX=0xDEADBEEF
        repeat(200) apb_read(8'h04);
        apb_read (8'h0C);               // RX: expect 0xDEADBEEF
        apb_write(8'h14, 32'h00000000);
        apb_write(8'h1C, 32'h0000001F);

        // -----------------------------------------------------------------
        // R20: SS_n[i] = !SS_EN[i] | SS_VAL[i] for all combinations
        // SS_n is combinational - no transfer needed
        // -----------------------------------------------------------------
        `uvm_info("R19_R23_SEQ", "R20: SS_n combinational control", UVM_LOW)

        // SS_EN=0 -> SS_n=1 (all deasserted) regardless of SS_VAL
        apb_write(8'h14, 32'h00000000); // SS_EN=0, SS_VAL=0 -> SS_n=4'hF
        apb_read (8'h14);

        // SS_EN[0]=1, SS_VAL[0]=0 -> SS_n[0]=0 (asserted)
        apb_write(8'h14, 32'h00000001); // SS_EN=0001, SS_VAL=0000
        apb_read (8'h14);

        // SS_EN[0]=1, SS_VAL[0]=1 -> SS_n[0]=1 (deasserted via val)
        apb_write(8'h14, 32'h00000011); // SS_EN=0001, SS_VAL=0001
        apb_read (8'h14);

        // All 4 lanes enabled, all asserted (VAL=0)
        apb_write(8'h14, 32'h0000000F); // SS_EN=4'hF, SS_VAL=0
        apb_read (8'h14);

        // All 4 lanes enabled, SS_VAL=4'hF -> all deasserted
        apb_write(8'h14, 32'h000000FF); // SS_EN=4'hF, SS_VAL=4'hF
        apb_read (8'h14);

        // Mix: SS_EN[1:0]=2'b11, SS_VAL[1:0]=2'b01 -> SS_n[1]=0,SS_n[0]=1
        apb_write(8'h14, 32'h00000013); // SS_EN=0011, SS_VAL=0001
        apb_read (8'h14);

        apb_write(8'h14, 32'h00000000); // clean up

        // -----------------------------------------------------------------
        // R21: Inter-transfer delay
        // Configure DELAY > 0, push 3 words, verify delay between transfers
        // -----------------------------------------------------------------
        `uvm_info("R19_R23_SEQ", "R21: Inter-transfer delay=0", UVM_LOW)
        apb_write(8'h00, 32'h00000000);
        apb_write(8'h20, 32'h00000000); // DELAY=0 (no delay)
        apb_write(8'h10, 32'h00000001); // DIV=1
        apb_write(8'h00, 32'h00000023); // EN=1,MSTR=1,loopback,8-bit
        apb_write(8'h14, 32'h00000001); // SS asserted
        apb_write(8'h08, 32'h000000AA);
        apb_write(8'h08, 32'h000000BB);
        apb_write(8'h08, 32'h000000CC);
        repeat(200) apb_read(8'h04);
        apb_read(8'h0C); apb_read(8'h0C); apb_read(8'h0C);
        apb_write(8'h14, 32'h00000000);
        apb_write(8'h1C, 32'h0000001F);

        `uvm_info("R19_R23_SEQ", "R21: Inter-transfer delay=1", UVM_LOW)
        apb_write(8'h00, 32'h00000000);
        apb_write(8'h20, 32'h00000001); // DELAY=1
        apb_write(8'h00, 32'h00000023);
        apb_write(8'h14, 32'h00000001);
        apb_write(8'h08, 32'h000000AA);
        apb_write(8'h08, 32'h000000BB);
        apb_write(8'h08, 32'h000000CC);
        repeat(300) apb_read(8'h04);
        apb_read(8'h0C); apb_read(8'h0C); apb_read(8'h0C);
        apb_write(8'h14, 32'h00000000);
        apb_write(8'h1C, 32'h0000001F);

        `uvm_info("R19_R23_SEQ", "R21: Inter-transfer delay=128 (large)", UVM_LOW)
        apb_write(8'h00, 32'h00000000);
        apb_write(8'h20, 32'h00000080); // DELAY=128
        apb_write(8'h00, 32'h00000023);
        apb_write(8'h14, 32'h00000001);
        apb_write(8'h08, 32'h00000011);
        apb_write(8'h08, 32'h00000022);
        repeat(600) apb_read(8'h04);
        apb_read(8'h0C); apb_read(8'h0C);
        apb_write(8'h14, 32'h00000000);
        apb_write(8'h20, 32'h00000000);
        apb_write(8'h1C, 32'h0000001F);

        // -----------------------------------------------------------------
        // R22: PSLVERR=0 and PREADY=1 for every access
        // The APB monitor captures PREADY and PSLVERR every transaction.
        // We just do reads/writes to all valid registers - scoreboard checks.
        // -----------------------------------------------------------------
        `uvm_info("R19_R23_SEQ", "R22: PREADY=1, PSLVERR=0 for all accesses", UVM_LOW)
        apb_write(8'h00, 32'h00000003);
        apb_read (8'h00);
        apb_read (8'h04);
        apb_write(8'h10, 32'h00000005);
        apb_read (8'h10);
        apb_write(8'h14, 32'h00000001);
        apb_read (8'h14);
        apb_write(8'h18, 32'h0000001F);
        apb_read (8'h18);
        apb_write(8'h20, 32'h00000010);
        apb_read (8'h20);

        // -----------------------------------------------------------------
        // R23: Reserved offsets read as 0, writes ignored
        // -----------------------------------------------------------------
        `uvm_info("R19_R23_SEQ", "R23: Reserved offsets", UVM_LOW)
        apb_read (8'h24); // reserved -> 0
        apb_read (8'h28); // reserved -> 0
        apb_read (8'h30); // reserved -> 0
        apb_read (8'hFF); // way out of range -> 0
        apb_write(8'h24, 32'hDEADBEEF); // write -> ignored
        apb_read (8'h24); // still 0

        // Clean up everything
        apb_write(8'h00, 32'h00000000);
        apb_write(8'h10, 32'h00000000);
        apb_write(8'h14, 32'h00000000);
        apb_write(8'h18, 32'h00000000);
        apb_write(8'h1C, 32'h0000001F);
        apb_write(8'h20, 32'h00000000);

        `uvm_info("R19_R23_SEQ", "=== R19-R23 sequence complete ===", UVM_LOW)
    endtask

endclass
