// =============================================================================
// r9_r15_fifo_seq.sv
// Covers:
//   R9:  TX_DATA writes accepted while !TX_FULL, pushed in FIFO order
//   R10: RX_DATA reads pop RX FIFO in FIFO order when !RX_EMPTY
//   R11: TX FIFO depth exactly 8; TX_FULL on 8th entry
//   R12: RX FIFO depth exactly 8; RX_FULL on 8th received entry
//   R13: TX write while TX_FULL discards + sets TX_OVF
//   R14: Transfer completing while RX_FULL discards + sets RX_OVF
//   R15: RX_DATA read while RX_EMPTY returns 0, does NOT set RX_OVF
// =============================================================================
class r9_r15_fifo_seq extends sequence_base;
    `uvm_object_utils(r9_r15_fifo_seq)

    function new(string name = "r9_r15_fifo_seq");
        super.new(name);
    endfunction

    task body();
        `uvm_info("R9_R15_SEQ", "=== R9-R15: FIFO Tests ===", UVM_LOW)

        // -----------------------------------------------------------------
        // R15: Read RX_DATA when empty -> returns 0, no RX_OVF
        // Do this first before any transfers
        // -----------------------------------------------------------------
        `uvm_info("R9_R15_SEQ", "R15: RX read while empty", UVM_LOW)
        apb_write(8'h00, 32'h00000000); // make sure disabled/reset
        apb_read (8'h04);               // STATUS: RX_EMPTY=1 expected
        apb_read (8'h0C);               // RX_DATA read while empty -> 0
        apb_read (8'h04);               // STATUS: RX_OVF must still be 0
        apb_read (8'h1C);               // INT_STAT: RX_OVF bit must be 0

        // -----------------------------------------------------------------
        // R9 + R11: Fill TX FIFO to exactly 8, verify TX_FULL
        // -----------------------------------------------------------------
        `uvm_info("R9_R15_SEQ", "R9/R11: Fill TX FIFO to 8 entries", UVM_LOW)
        apb_write(8'h00, 32'h00000003); // EN=1, MSTR=1, 8-bit, no loopback
        apb_write(8'h10, 32'h00000063); // DIV=99 (slow clock so FIFO stays full)

        // Push 8 words - each with recognizable pattern for FIFO order check
        apb_write(8'h08, 32'h00000001); // entry 1
        apb_read (8'h04);               // check status after each push
        apb_write(8'h08, 32'h00000002); // entry 2
        apb_read (8'h04);
        apb_write(8'h08, 32'h00000003); // entry 3
        apb_read (8'h04);
        apb_write(8'h08, 32'h00000004); // entry 4
        apb_read (8'h04);
        apb_write(8'h08, 32'h00000005); // entry 5
        apb_read (8'h04);
        apb_write(8'h08, 32'h00000006); // entry 6
        apb_read (8'h04);
        apb_write(8'h08, 32'h00000007); // entry 7
        apb_read (8'h04);
        apb_write(8'h08, 32'h00000008); // entry 8 -> TX_FULL must assert now
        apb_read (8'h04);               // STATUS: TX_FULL=1 expected

        // -----------------------------------------------------------------
        // R13: One more write while TX_FULL -> discarded, TX_OVF set
        // -----------------------------------------------------------------
        `uvm_info("R9_R15_SEQ", "R13: TX overflow write", UVM_LOW)
        apb_write(8'h08, 32'h000000FF); // 9th write - must be dropped
        apb_read (8'h04);               // STATUS: TX_OVF=1 expected
        apb_read (8'h1C);               // INT_STAT: TX_OVF bit set

        // Clear TX_OVF via W1C
        apb_write(8'h1C, 32'h00000004); // W1C bit2=TX_OVF
        apb_read (8'h1C);               // INT_STAT: TX_OVF cleared

        // -----------------------------------------------------------------
        // Now enable SS and let transfers run with loopback to fill RX FIFO
        // R12: RX FIFO depth = 8; R10: RX pops in order
        // -----------------------------------------------------------------
        `uvm_info("R9_R15_SEQ", "R12/R10: Fill RX FIFO via loopback", UVM_LOW)

        // Disable, reconfigure with loopback to fill RX FIFO
        apb_write(8'h00, 32'h00000000); // disable (flushes FIFOs)
        apb_write(8'h00, 32'h00000023); // EN=1,MSTR=1,loopback=1,8-bit
        apb_write(8'h10, 32'h00000001); // DIV=1
        apb_write(8'h14, 32'h00000001); // SS asserted

        // Push 8 words to generate 8 RX entries via loopback
        apb_write(8'h08, 32'h000000A1);
        apb_write(8'h08, 32'h000000A2);
        apb_write(8'h08, 32'h000000A3);
        apb_write(8'h08, 32'h000000A4);
        apb_write(8'h08, 32'h000000A5);
        apb_write(8'h08, 32'h000000A6);
        apb_write(8'h08, 32'h000000A7);
        apb_write(8'h08, 32'h000000A8);

        // Wait for all transfers to complete
        repeat(400) apb_read(8'h04);

        // Deassert SS after transfers done
        apb_write(8'h14, 32'h00000000);

        // Check RX_FULL=1
        apb_read(8'h04); // STATUS: RX_FULL=1 expected

        // -----------------------------------------------------------------
        // R14: One more transfer while RX_FULL -> incoming word discarded, RX_OVF set
        // Push one more TX word and trigger another transfer
        // -----------------------------------------------------------------
        `uvm_info("R9_R15_SEQ", "R14: RX overflow", UVM_LOW)
        apb_write(8'h14, 32'h00000001); // SS asserted again
        apb_write(8'h08, 32'h000000FF); // One more TX - RX already full
        repeat(100) apb_read(8'h04);    // Wait for transfer
        apb_read (8'h04);               // STATUS: RX_OVF=1 expected
        apb_read (8'h1C);               // INT_STAT: RX_OVF bit set
        apb_write(8'h14, 32'h00000000); // Deassert SS

        // Clear RX_OVF via W1C
        apb_write(8'h1C, 32'h00000008); // W1C bit3=RX_OVF
        apb_read (8'h1C);               // verify cleared

        // -----------------------------------------------------------------
        // R10: Pop RX FIFO in order (should come out A1..A8)
        // -----------------------------------------------------------------
        `uvm_info("R9_R15_SEQ", "R10: Pop RX FIFO in order", UVM_LOW)
        apb_read(8'h0C); // should be 0xA1
        apb_read(8'h0C); // 0xA2
        apb_read(8'h0C); // 0xA3
        apb_read(8'h0C); // 0xA4
        apb_read(8'h0C); // 0xA5
        apb_read(8'h0C); // 0xA6
        apb_read(8'h0C); // 0xA7
        apb_read(8'h0C); // 0xA8
        apb_read(8'h04); // STATUS: RX_EMPTY=1 now

        // One more read on empty - R15 again (belt+suspenders)
        apb_read(8'h0C); // should return 0
        apb_read(8'h04); // RX_OVF must NOT be set

        // Clean up
        apb_write(8'h00, 32'h00000000);
        apb_write(8'h1C, 32'h0000001F); // clear all interrupt flags

        `uvm_info("R9_R15_SEQ", "=== R9-R15 sequence complete ===", UVM_LOW)
    endtask

endclass
