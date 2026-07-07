// =============================================================================
// r4_r8_spi_protocol_seq.sv
// Covers:
//   R4:  SCLK idle polarity matches CPOL for all 4 modes
//   R5:  MOSI stable at sample edge, changes at launch edge
//   R6:  MSB-first vs LSB-first bit ordering
//   R7:  Transfer lasts exactly WIDTH SCLK cycles; BUSY timing
//   R8:  SCLK = PCLK/(2*(DIV+1)) for various DIV values
//   R24: CLK_DIV=0 yields SCLK=PCLK/2
//   R25: DIV/MODE/WIDTH/LSB_FIRST sampled at transfer start
// =============================================================================
class r4_r8_spi_protocol_seq extends sequence_base;
    `uvm_object_utils(r4_r8_spi_protocol_seq)

    function new(string name = "r4_r8_spi_protocol_seq");
        super.new(name);
    endfunction

    // Helper: do one complete SPI transfer and read back result
    // mode[1:0]={CPOL,CPHA}, width=00/01/10, lsb=0/1, div=clock divider
    task do_transfer(
        input bit [1:0] mode,
        input bit [1:0] width,
        input bit       lsb_first,
        input bit [15:0] div,
        input bit [31:0] tx_data
    );
        bit [7:0] ctrl_val;
        // Build CTRL: bits[7:6]=width, [5]=loopback=1(self-test), [4]=lsb_first,
        //             [3:2]=mode, [1]=mstr=1, [0]=en=1
        ctrl_val = {width, 1'b1, lsb_first, mode, 1'b1, 1'b1};

        // Setup
        apb_write(8'h10, {16'h0, div});      // CLK_DIV
        apb_write(8'h00, {24'h0, ctrl_val}); // CTRL with loopback=1
        apb_write(8'h14, 32'h00000001);      // SS_EN[0]=1, SS_VAL=0
        apb_write(8'h08, tx_data);           // Push TX word

        // Poll STATUS until BUSY=0 and TX_EMPTY=1
        repeat(200) apb_read(8'h04);

        // Read RX result
        apb_read(8'h0C);

        // Read STATUS and INT_STAT
        apb_read(8'h04);
        apb_read(8'h1C);

        // Deassert SS and clean up
        apb_write(8'h14, 32'h00000000);
        apb_write(8'h1C, 32'h0000001F); // W1C clear all interrupts
        apb_write(8'h00, 32'h00000000); // Disable
    endtask

    task body();
        `uvm_info("R4_R8_SEQ", "=== R4-R8: SPI Protocol Tests ===", UVM_LOW)

        // -----------------------------------------------------------------
        // R4 + R8 + R24: SCLK idle polarity and frequency tests
        // Test all 4 modes with DIV corners
        // -----------------------------------------------------------------

        // R24: DIV=0 -> SCLK=PCLK/2 (fastest), Mode 0, 8-bit, MSB-first
        `uvm_info("R4_R8_SEQ", "R24: DIV=0 SCLK=PCLK/2", UVM_LOW)
        do_transfer(2'b00, 2'b00, 1'b0, 16'h0000, 32'h000000A5);

        // R8: DIV=1 -> SCLK=PCLK/4
        `uvm_info("R4_R8_SEQ", "R8: DIV=1 SCLK=PCLK/4", UVM_LOW)
        do_transfer(2'b00, 2'b00, 1'b0, 16'h0001, 32'h000000C3);

        // R8: DIV=3 -> SCLK=PCLK/8
        `uvm_info("R4_R8_SEQ", "R8: DIV=3 SCLK=PCLK/8", UVM_LOW)
        do_transfer(2'b00, 2'b00, 1'b0, 16'h0003, 32'h000000F0);

        // R8: DIV=255 corner
        `uvm_info("R4_R8_SEQ", "R8: DIV=255 corner", UVM_LOW)
        do_transfer(2'b00, 2'b00, 1'b0, 16'h00FF, 32'h000000AA);

        // -----------------------------------------------------------------
        // R4: SCLK idle = CPOL for all 4 SPI modes, 8-bit MSB-first DIV=1
        // -----------------------------------------------------------------

        // Mode 0: CPOL=0,CPHA=0 - idle low, sample rising, launch falling
        `uvm_info("R4_R8_SEQ", "R4: Mode 0 (CPOL=0,CPHA=0)", UVM_LOW)
        do_transfer(2'b00, 2'b00, 1'b0, 16'h0001, 32'h000000A5);

        // Mode 1: CPOL=0,CPHA=1 - idle low, sample falling, launch rising
        `uvm_info("R4_R8_SEQ", "R4: Mode 1 (CPOL=0,CPHA=1)", UVM_LOW)
        do_transfer(2'b01, 2'b00, 1'b0, 16'h0001, 32'h000000B7);

        // Mode 2: CPOL=1,CPHA=0 - idle high, sample falling, launch rising
        `uvm_info("R4_R8_SEQ", "R4: Mode 2 (CPOL=1,CPHA=0)", UVM_LOW)
        do_transfer(2'b10, 2'b00, 1'b0, 16'h0001, 32'h000000C9);

        // Mode 3: CPOL=1,CPHA=1 - idle high, sample rising, launch falling
        `uvm_info("R4_R8_SEQ", "R4: Mode 3 (CPOL=1,CPHA=1)", UVM_LOW)
        do_transfer(2'b11, 2'b00, 1'b0, 16'h0001, 32'h000000DE);

        // -----------------------------------------------------------------
        // R5+R7: MOSI/BUSY timing - 8-bit, 16-bit, 32-bit transfers
        // Using loopback so we can verify received == transmitted
        // -----------------------------------------------------------------

        // 8-bit transfer Mode 0 MSB-first
        `uvm_info("R4_R8_SEQ", "R5/R7: 8-bit Mode0 MSB-first", UVM_LOW)
        do_transfer(2'b00, 2'b00, 1'b0, 16'h0001, 32'h000000A5);

        // 16-bit transfer Mode 0 MSB-first
        `uvm_info("R4_R8_SEQ", "R5/R7: 16-bit Mode0 MSB-first", UVM_LOW)
        do_transfer(2'b00, 2'b01, 1'b0, 16'h0001, 32'h0000BEEF);

        // 32-bit transfer Mode 0 MSB-first
        `uvm_info("R4_R8_SEQ", "R5/R7: 32-bit Mode0 MSB-first", UVM_LOW)
        do_transfer(2'b00, 2'b10, 1'b0, 16'h0001, 32'hDEADBEEF);

        // -----------------------------------------------------------------
        // R6: LSB-first vs MSB-first for all widths and modes
        // -----------------------------------------------------------------

        // 8-bit LSB-first Mode 0
        `uvm_info("R4_R8_SEQ", "R6: 8-bit LSB-first Mode0", UVM_LOW)
        do_transfer(2'b00, 2'b00, 1'b1, 16'h0001, 32'h000000A5);

        // 16-bit LSB-first Mode 1
        `uvm_info("R4_R8_SEQ", "R6: 16-bit LSB-first Mode1", UVM_LOW)
        do_transfer(2'b01, 2'b01, 1'b1, 16'h0001, 32'h0000CAFE);

        // 32-bit LSB-first Mode 2
        `uvm_info("R4_R8_SEQ", "R6: 32-bit LSB-first Mode2", UVM_LOW)
        do_transfer(2'b10, 2'b10, 1'b1, 16'h0001, 32'hFEEDFACE);

        // 32-bit MSB-first Mode 3
        `uvm_info("R4_R8_SEQ", "R6: 32-bit MSB-first Mode3", UVM_LOW)
        do_transfer(2'b11, 2'b10, 1'b0, 16'h0001, 32'h12345678);

        // -----------------------------------------------------------------
        // R25: Mid-transfer write to CLK_DIV must NOT affect current transfer
        // Start a slow transfer then write new CLK_DIV mid-flight
        // -----------------------------------------------------------------
        `uvm_info("R4_R8_SEQ", "R25: Mid-transfer CLK_DIV stability", UVM_LOW)
        apb_write(8'h10, 32'h00000003);      // DIV=3
        apb_write(8'h00, 32'h00000023);      // EN=1,MSTR=1,8-bit,loopback
        apb_write(8'h14, 32'h00000001);      // SS asserted
        apb_write(8'h08, 32'h000000AA);      // Push TX
        // Immediately try to change DIV mid-transfer
        apb_write(8'h10, 32'h000000FF);      // New DIV - must not affect this xfer
        repeat(100) apb_read(8'h04);         // Poll
        apb_read(8'h0C);
        apb_write(8'h14, 32'h00000000);
        apb_write(8'h00, 32'h00000000);

        `uvm_info("R4_R8_SEQ", "=== R4-R8 sequence complete ===", UVM_LOW)
    endtask

endclass
