// =============================================================================
// r1_r2_reg_seq.sv
// Covers R1: APB R/W registers return last written value
//         R2: All registers return reset values after PRESETn
// =============================================================================
class r1_r2_reg_seq extends sequence_base;
    `uvm_object_utils(r1_r2_reg_seq)

    function new(string name = "r1_r2_reg_seq");
        super.new(name);
    endfunction

    task body();
        // -----------------------------------------------------------------
        // R2: Check reset values by reading every register right after reset
        // Reset is already applied by apb_reset_seq before this runs.
        // Expected reset values from spec:
        //   CTRL=0x00000000, STATUS=0x00000012 (TX_EMPTY=1,RX_EMPTY=1)
        //   CLK_DIV=0, SS_CTRL=0, INT_EN=0, INT_STAT=0, DELAY=0
        // -----------------------------------------------------------------
        `uvm_info("R1_R2_SEQ", "=== R2: Checking reset values ===", UVM_LOW)

        apb_read(8'h00); // CTRL     expect 0x00000000
        apb_read(8'h04); // STATUS   expect 0x00000012 (bits 4=RX_EMPTY,1=TX_EMPTY? spec says reset=0x12)
        apb_read(8'h10); // CLK_DIV  expect 0x00000000
        apb_read(8'h14); // SS_CTRL  expect 0x00000000
        apb_read(8'h18); // INT_EN   expect 0x00000000
        apb_read(8'h1C); // INT_STAT expect 0x00000000
        apb_read(8'h20); // DELAY    expect 0x00000000

        // -----------------------------------------------------------------
        // R1: Write then read back every R/W register
        // -----------------------------------------------------------------
        `uvm_info("R1_R2_SEQ", "=== R1: Write-then-readback all R/W registers ===", UVM_LOW)

        // CTRL (0x00): write EN=1,MSTR=1,MODE=2'b10,WIDTH=8b,LSB_FIRST=0,LOOPBACK=0
        apb_write(8'h00, 32'h00000007); // EN=1,MSTR=1,MODE=01
        apb_read (8'h00);

        // CTRL: different pattern - 16-bit, mode 3, MSB first
        apb_write(8'h00, 32'h0000004F); // WIDTH=01(16b),LOOPBACK=0,LSB=0,MODE=11,MSTR=1,EN=1
        apb_read (8'h00);

        // CTRL: 32-bit, mode 2, loopback on
        apb_write(8'h00, 32'h000000AB); // WIDTH=10,LOOPBACK=1,LSB=0,MODE=10,MSTR=1,EN=1
        apb_read (8'h00);

        // CLK_DIV (0x10)
        apb_write(8'h10, 32'h00000000); // DIV=0 -> SCLK=PCLK/2 (R24)
        apb_read (8'h10);

        apb_write(8'h10, 32'h00000001); // DIV=1
        apb_read (8'h10);

        apb_write(8'h10, 32'h00000003); // DIV=3
        apb_read (8'h10);

        apb_write(8'h10, 32'h000000FF); // DIV=255
        apb_read (8'h10);

        apb_write(8'h10, 32'h0000FFFF); // DIV=65535 (max)
        apb_read (8'h10);

        // SS_CTRL (0x14)
        apb_write(8'h14, 32'h00000001); // SS_EN[0]=1, SS_VAL[0]=0
        apb_read (8'h14);

        apb_write(8'h14, 32'h000000F0); // SS_VAL=4'hF, SS_EN=0
        apb_read (8'h14);

        apb_write(8'h14, 32'h000000FF); // SS_VAL=4'hF, SS_EN=4'hF
        apb_read (8'h14);

        // INT_EN (0x18) - all 5 interrupt bits
        apb_write(8'h18, 32'h0000001F); // enable all 5 interrupts
        apb_read (8'h18);

        apb_write(8'h18, 32'h00000000); // disable all
        apb_read (8'h18);

        // DELAY (0x20)
        apb_write(8'h20, 32'h00000001); // delay=1
        apb_read (8'h20);

        apb_write(8'h20, 32'h00000080); // delay=128
        apb_read (8'h20);

        apb_write(8'h20, 32'h000000FF); // delay=255 (max)
        apb_read (8'h20);

        // Restore clean state
        apb_write(8'h00, 32'h00000000);
        apb_write(8'h10, 32'h00000000);
        apb_write(8'h14, 32'h00000000);
        apb_write(8'h18, 32'h00000000);
        apb_write(8'h20, 32'h00000000);

        `uvm_info("R1_R2_SEQ", "=== R1/R2 sequence complete ===", UVM_LOW)
    endtask

endclass
