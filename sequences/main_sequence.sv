class main_seq extends sequence_base ;
    `uvm_object_utils(main_seq)

    apb_sequence_item apb_item;

    function new(string name = "main_seq");
        super.new(name);
    endfunction

    task body();
        // Initialize SPI Master via APB writes
        // 1. Enable SPI Master, set to master mode, 8-bit width, CPOL=0, CPHA=0
        apb_write(8'h00, 32'h00000003); // CTRL: en=1, mstr=1, from RTL: ctrl_mstr is bit 1, so 32'h00000011 for en=1, mstr=1

        // Actually, CTRL: bit0=en, bit1=mstr, so 32'h00000011 for en=1, mstr=1

       // apb_read(8'h00); // Read back CTRL to verify

        // Set clock divider to 16
        apb_write(8'h10, 32'h00000001);

        // Set SS control: enable SS0, value=0 (active low)
        apb_write(8'h14, 32'h00000001); // ss_en=1, ss_val=0

        //inter transfer delay: 16 cycles
        apb_write(8'h20, 32'h00000002); 

        // // Enable interrupts: TX_EMPTY, RX_FULL, TRANSFER_DONE
        // apb_write(8'h18, 32'h00000017); // bits 0,1,4

        // Write data to TX FIFO
        apb_write(8'h08, 32'h000000AA); // TX_DATA: 8'hAA
        apb_write(8'h08, 32'h000000BB); // TX_DATA: 8'hBB
        apb_write(8'h08, 32'h000000AA); // TX_DATA: 8'hAA
        apb_write(8'h08, 32'h000000BB); // TX_DATA: 8'hBB
        apb_write(8'h08, 32'h000000AA); // TX_DATA: 8'hAA
        apb_write(8'h08, 32'h000000BB); // TX_DATA: 8'hBB
        apb_write(8'h08, 32'h000000AA); // TX_DATA: 8'hAA
        apb_write(8'h08, 32'h000000BB); // TX_DATA: 8'hBB

        // Set SS control: enable SS0, value=0 (active low)
        //apb_write(8'h14, 32'h00000001); // ss_en=1, ss_val=1

        // // Read STATUS to check TX_EMPTY (should be 0 now)
        // apb_read(8'h04);

        // // Read INT_STAT to check flags
        // apb_read(8'h1C);

        // // Simulate transfer done (in real test, this would be from SPI core)
        // // For now, just read RX_DATA
        // apb_read(8'h0C); // RX_DATA

        // // Read STATUS again
        // apb_read(8'h04);

        // // Clear interrupts by writing to INT_STAT
        // apb_write(8'h1C, 32'h00000017); // clear bits 0,1,4

        // // Read INT_STAT to verify cleared
        // apb_read(8'h1C);

        // // Disable SPI
        // apb_write(8'h00, 32'h00000000);

    endtask



endclass
