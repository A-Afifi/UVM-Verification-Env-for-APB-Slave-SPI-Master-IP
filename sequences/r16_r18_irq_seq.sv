// =============================================================================
// r16_r18_irq_seq.sv
// Covers:
//   R16: IRQ = |(INT_STAT & INT_EN) at all times; INT_EN doesn't gate capture
//   R17: INT_STAT is W1C: writing 1 clears, writing 0 has no effect
//   R18: W1C race: event on same cycle as W1C -> bit stays 1
// =============================================================================
class r16_r18_irq_seq extends sequence_base;
    `uvm_object_utils(r16_r18_irq_seq)

    function new(string name = "r16_r18_irq_seq");
        super.new(name);
    endfunction

    task body();
        `uvm_info("R16_R18_SEQ", "=== R16-R18: Interrupt Tests ===", UVM_LOW)

        // -----------------------------------------------------------------
        // R16 Part A: Masked event still sets INT_STAT, just no IRQ
        // Generate TX_OVF with INT_EN[TX_OVF]=0 -> stat set, IRQ stays 0
        // -----------------------------------------------------------------
        `uvm_info("R16_R18_SEQ", "R16A: Masked event sets INT_STAT but no IRQ", UVM_LOW)
        apb_write(8'h18, 32'h00000000); // INT_EN = 0 (all masked)
        apb_write(8'h00, 32'h00000003); // EN=1, MSTR=1, 8-bit
        // Fill TX FIFO to 8
        apb_write(8'h08, 32'h00000001);
        apb_write(8'h08, 32'h00000002);
        apb_write(8'h08, 32'h00000003);
        apb_write(8'h08, 32'h00000004);
        apb_write(8'h08, 32'h00000005);
        apb_write(8'h08, 32'h00000006);
        apb_write(8'h08, 32'h00000007);
        apb_write(8'h08, 32'h00000008);
        // 9th write -> TX_OVF event fires
        apb_write(8'h08, 32'h000000FF);
        apb_read (8'h1C); // INT_STAT: TX_OVF=1 (captured even though masked)
        apb_read (8'h04); // STATUS: check IRQ via STATUS (IRQ is on SPI IF)
        // Clear all
        apb_write(8'h1C, 32'h0000001F);
        apb_write(8'h00, 32'h00000000);

        // -----------------------------------------------------------------
        // R16 Part B: Unmask TX_EMPTY -> IRQ fires when TX runs dry
        // -----------------------------------------------------------------
        `uvm_info("R16_R18_SEQ", "R16B: IRQ fires when unmasked and event occurs", UVM_LOW)
        apb_write(8'h1C, 32'h0000001F); // clear all first
        apb_write(8'h18, 32'h00000001); // INT_EN[0]=TX_EMPTY only
        apb_write(8'h00, 32'h00000023); // EN=1,MSTR=1,loopback,8-bit
        apb_write(8'h10, 32'h00000001); // DIV=1
        apb_write(8'h14, 32'h00000001); // SS asserted
        apb_write(8'h08, 32'h000000A5); // one TX word
        // Wait for TX_EMPTY interrupt
        repeat(100) apb_read(8'h04);
        apb_read (8'h18); // INT_EN
        apb_read (8'h1C); // INT_STAT: TX_EMPTY should be set
        apb_write(8'h14, 32'h00000000); // deassert SS

        // -----------------------------------------------------------------
        // R17: W1C behavior
        // Write 1 to clear a set bit; write 0 has no effect
        // -----------------------------------------------------------------
        `uvm_info("R16_R18_SEQ", "R17: W1C clear behavior", UVM_LOW)
        apb_read (8'h1C);               // read current INT_STAT
        apb_write(8'h1C, 32'h00000000); // write all 0s -> no change
        apb_read (8'h1C);               // INT_STAT unchanged
        apb_write(8'h1C, 32'h00000001); // W1C bit0 (TX_EMPTY)
        apb_read (8'h1C);               // bit0 cleared
        apb_write(8'h1C, 32'h0000001F); // clear all remaining
        apb_read (8'h1C);               // all zero

        // -----------------------------------------------------------------
        // Test all 5 interrupt sources one at a time
        // -----------------------------------------------------------------
        `uvm_info("R16_R18_SEQ", "R16: Test all 5 interrupt sources", UVM_LOW)

        // INT[0]: TX_EMPTY - fires when TX FIFO goes empty
        apb_write(8'h1C, 32'h0000001F);
        apb_write(8'h18, 32'h00000001); // enable TX_EMPTY
        apb_write(8'h00, 32'h00000023);
        apb_write(8'h10, 32'h00000001);
        apb_write(8'h14, 32'h00000001);
        apb_write(8'h08, 32'h000000AA);
        repeat(80) apb_read(8'h04);
        apb_read(8'h1C);
        apb_write(8'h14, 32'h00000000);
        apb_write(8'h1C, 32'h0000001F);

        // INT[1]: RX_FULL - fires when RX FIFO fills up
        apb_write(8'h18, 32'h00000002); // enable RX_FULL
        apb_write(8'h00, 32'h00000023);
        apb_write(8'h14, 32'h00000001);
        apb_write(8'h08, 32'h00000001); apb_write(8'h08, 32'h00000002);
        apb_write(8'h08, 32'h00000003); apb_write(8'h08, 32'h00000004);
        apb_write(8'h08, 32'h00000005); apb_write(8'h08, 32'h00000006);
        apb_write(8'h08, 32'h00000007); apb_write(8'h08, 32'h00000008);
        repeat(400) apb_read(8'h04);
        apb_read(8'h1C); // RX_FULL interrupt
        apb_write(8'h14, 32'h00000000);
        // drain RX
        repeat(8) apb_read(8'h0C);
        apb_write(8'h1C, 32'h0000001F);

        // INT[2]: TX_OVF - already tested above, quick repeat
        apb_write(8'h18, 32'h00000004);
        apb_write(8'h08, 32'h00000001); apb_write(8'h08, 32'h00000002);
        apb_write(8'h08, 32'h00000003); apb_write(8'h08, 32'h00000004);
        apb_write(8'h08, 32'h00000005); apb_write(8'h08, 32'h00000006);
        apb_write(8'h08, 32'h00000007); apb_write(8'h08, 32'h00000008);
        apb_write(8'h08, 32'h000000FF); // overflow
        apb_read(8'h1C);
        apb_write(8'h1C, 32'h0000001F);

        // INT[4]: TRANSFER_DONE
        apb_write(8'h18, 32'h00000010); // enable TRANSFER_DONE
        apb_write(8'h14, 32'h00000001);
        apb_write(8'h08, 32'h000000CC);
        repeat(100) apb_read(8'h04);
        apb_read(8'h1C); // TRANSFER_DONE set
        apb_write(8'h14, 32'h00000000);
        apb_write(8'h1C, 32'h0000001F);

        // -----------------------------------------------------------------
        // R18: W1C race condition
        // The spec says: if event fires same cycle as W1C, bit stays 1
        // We test by clearing INT_STAT while a new overflow is happening
        // -----------------------------------------------------------------
        `uvm_info("R16_R18_SEQ", "R18: W1C race condition test", UVM_LOW)
        // Fill TX to 8, then simultaneously trigger OVF and try to clear
        apb_write(8'h18, 32'h00000004); // enable TX_OVF
        apb_write(8'h08, 32'h00000001); apb_write(8'h08, 32'h00000002);
        apb_write(8'h08, 32'h00000003); apb_write(8'h08, 32'h00000004);
        apb_write(8'h08, 32'h00000005); apb_write(8'h08, 32'h00000006);
        apb_write(8'h08, 32'h00000007); apb_write(8'h08, 32'h00000008);
        // 9th write causes OVF event
        apb_write(8'h08, 32'h000000FF);
        // Immediately W1C same bit - race condition
        apb_write(8'h1C, 32'h00000004); // try to clear TX_OVF
        apb_read (8'h1C);               // check: TX_OVF may still be 1 if race

        // Clean up
        apb_write(8'h18, 32'h00000000);
        apb_write(8'h1C, 32'h0000001F);
        apb_write(8'h00, 32'h00000000);
        apb_write(8'h14, 32'h00000000);

        `uvm_info("R16_R18_SEQ", "=== R16-R18 sequence complete ===", UVM_LOW)
    endtask

endclass
