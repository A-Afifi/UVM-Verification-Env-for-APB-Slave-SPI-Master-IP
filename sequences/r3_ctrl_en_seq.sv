// =============================================================================
// r3_ctrl_en_seq.sv
// Covers R3: CTRL.EN=0 holds shifter+FIFOs in reset; SCLK stays at CPOL idle;
//            SS_n forced high regardless of SS_CTRL
// =============================================================================
class r3_ctrl_en_seq extends sequence_base;
    `uvm_object_utils(r3_ctrl_en_seq)

    function new(string name = "r3_ctrl_en_seq");
        super.new(name);
    endfunction

    task body();
        `uvm_info("R3_SEQ", "=== R3: CTRL.EN=0 behavior ===", UVM_LOW)

        // --- Part A: Try to push TX while EN=0 (write ignored per spec) ---
        apb_write(8'h00, 32'h00000000); // EN=0 (reset state)
        apb_write(8'h08, 32'h000000AA); // TX_DATA write while disabled - should be ignored
        apb_read (8'h04);               // STATUS: TX_EMPTY should still be 1

        // --- Part B: Set SS_CTRL with EN=0, SS_n must remain high ---
        apb_write(8'h14, 32'h00000001); // SS_EN[0]=1, SS_VAL=0 (wants SS_n[0] low)
        apb_read (8'h04);               // Read status - BUSY must be 0
        apb_read (8'h14);               // Read back SS_CTRL

        // --- Part C: Verify FIFO flush when EN goes 0->1->0 ---
        // First enable and push data
        apb_write(8'h00, 32'h00000003); // EN=1, MSTR=1
        apb_write(8'h14, 32'h00000001); // SS_EN[0]=1
        apb_write(8'h08, 32'h000000AA); // Push to TX FIFO
        apb_write(8'h08, 32'h000000BB); // Push to TX FIFO
        apb_read (8'h04);               // STATUS: TX_EMPTY should be 0

        // Now disable - FIFOs must be flushed
        apb_write(8'h00, 32'h00000000); // EN=0
        apb_read (8'h04);               // STATUS: TX_EMPTY=1, BUSY=0 expected

        // --- Part D: Different CPOL modes with EN=0, SCLK must stay at CPOL idle ---
        // Mode 0 (CPOL=0): SCLK must be 0
        apb_write(8'h00, 32'h00000000); // EN=0, CPOL=0
        apb_read (8'h04);

        // Mode 2 (CPOL=1): SCLK must be 1
        // Write CTRL with CPOL=1 but EN still 0
        apb_write(8'h00, 32'h00000004); // MODE=01 (CPOL=1,CPHA=0), EN=0
        apb_read (8'h04);

        // Restore SS_CTRL and disable
        apb_write(8'h14, 32'h00000000);
        apb_write(8'h00, 32'h00000000);

        `uvm_info("R3_SEQ", "=== R3 sequence complete ===", UVM_LOW)
    endtask

endclass
