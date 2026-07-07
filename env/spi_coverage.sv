//
// Description: This file contains the coverage class for the SPI Master project. It defines coverpoints and crosses to measure the coverage of the design under test (DUT).
// ****************************************************************************


class spi_coverage extends uvm_component;
`uvm_component_utils(spi_coverage)


    // Analysis infrastructure
    // (Export <-> FIFO) for transactions fed to the block as controllers transactions
    uvm_analysis_export #(apb_sequence_item)apb_cov_export; 
    uvm_tlm_analysis_fifo #(apb_sequence_item) fifo_apb;
    // (Export <-> FIFO) for transactions fed to the block as controllers transactions
    uvm_analysis_export #(spi_sequence_item) spi_cov_export;
    uvm_tlm_analysis_fifo #(spi_sequence_item) fifo_spi;
    
    apb_sequence_item apb_item;
    spi_sequence_item spi_item;


    covergroup g1 ;

    

        // =========================================================
        // SPI MODE / WIDTH / BIT ORDER COVERAGE
        // =========================================================
        cp_reg_address : coverpoint apb_item.PADDR  {
            bins CTRL       = {8'h00};
            bins STATUS     = {8'h04};
            bins TX_DATA    = {8'h08};
            bins RX_DATA    = {8'h0C};
            bins CLK_DIV    = {8'h10};
            bins SS_CTRL    = {8'h14};
            bins INT_EN     = {8'h18};
            bins INT_STAT   = {8'h1C};
            bins DELAY      = {8'h20};
        }

        cp_clk_div_value : coverpoint apb_item.PWDATA iff(apb_item.PADDR == 8'h10 && apb_item.PWRITE) {
            bins div_0      = {16'h0000};
            bins div_1      = {16'h0001};
            bins div_2      = {16'h0002};
            bins div_3      = {16'h0003};
            bins div_255    = {16'h00FF};
            bins div_1024   = {16'h0400};
            bins div_65535  = {16'hFFFF};
        }

        cp_lsb_first : coverpoint apb_item.PWDATA[4] iff(apb_item.PADDR == 8'h00 && apb_item.PWRITE) {
            bins lsb_first = {1};
            bins msb_first = {0};
        }

        cp_mode : coverpoint apb_item.PWDATA[3:2] iff(apb_item.PADDR == 8'h00 && apb_item.PWRITE) {
            bins mode0 = {2'b00};
            bins mode1 = {2'b01};
            bins mode2 = {2'b10};
            bins mode3 = {2'b11};
        }

        cp_width : coverpoint apb_item.PWDATA[7:6] iff(apb_item.PADDR == 8'h00 && apb_item.PWRITE) {
            bins w8  = {2'b00};
            bins w16 = {2'b01};
            bins w32 = {2'b10};
        }

        // =========================================================
        //DELAY bins: 0, 1, and one large value (>= 128).
        // =========================================================
        cp_delay_value : coverpoint apb_item.PWDATA iff(apb_item.PADDR == 8'h20 && apb_item.PWRITE) {
            bins delay_0     = { 32'h0 };
            bins delay_1     = { 32'h1 };
            bins delay_large = { [32'd128 : 32'hFFFF_FFFF] };
        }

        // =========================================================
        // All 4 SPI modes x all 3 widths = 12 combinations, each with MSB-first and LSB-first -> 24 bins.
        // =========================================================
        cp_spi_mode_x_all_widths : cross cp_reg_address, cp_mode, cp_width , cp_lsb_first {
            option.cross_auto_bin_max = 0; // Disable automatic binning to allow for manual bin definitions
            bins mode1_with_w8_msb  = binsof(cp_reg_address.CTRL) && binsof(cp_width.w8)   && binsof(cp_mode.mode0) && binsof(cp_lsb_first.msb_first) ;
            bins mode1_with_w16_msb = binsof(cp_reg_address.CTRL) && binsof(cp_width.w16)  && binsof(cp_mode.mode0) && binsof(cp_lsb_first.msb_first) ;
            bins mode1_with_w32_msb = binsof(cp_reg_address.CTRL) && binsof(cp_width.w32)  && binsof(cp_mode.mode0) && binsof(cp_lsb_first.msb_first) ;
            bins mode2_with_w8_msb  = binsof(cp_reg_address.CTRL) && binsof(cp_width.w8)   && binsof(cp_mode.mode1) && binsof(cp_lsb_first.msb_first) ;
            bins mode2_with_w16_msb = binsof(cp_reg_address.CTRL) && binsof(cp_width.w16)  && binsof(cp_mode.mode1) && binsof(cp_lsb_first.msb_first) ;
            bins mode2_with_w32_msb = binsof(cp_reg_address.CTRL) && binsof(cp_width.w32)  && binsof(cp_mode.mode1) && binsof(cp_lsb_first.msb_first) ;
            bins mode3_with_w8_msb  = binsof(cp_reg_address.CTRL) && binsof(cp_width.w8)   && binsof(cp_mode.mode2) && binsof(cp_lsb_first.msb_first) ;
            bins mode3_with_w16_msb = binsof(cp_reg_address.CTRL) && binsof(cp_width.w16)  && binsof(cp_mode.mode2) && binsof(cp_lsb_first.msb_first) ;
            bins mode3_with_w32_msb = binsof(cp_reg_address.CTRL) && binsof(cp_width.w32)  && binsof(cp_mode.mode2) && binsof(cp_lsb_first.msb_first) ;
            bins mode4_with_w8_msb  = binsof(cp_reg_address.CTRL) && binsof(cp_width.w8)   && binsof(cp_mode.mode3) && binsof(cp_lsb_first.msb_first) ;
            bins mode4_with_w16_msb = binsof(cp_reg_address.CTRL) && binsof(cp_width.w16)  && binsof(cp_mode.mode3) && binsof(cp_lsb_first.msb_first) ;
            bins mode4_with_w32_msb = binsof(cp_reg_address.CTRL) && binsof(cp_width.w32)  && binsof(cp_mode.mode3) && binsof(cp_lsb_first.msb_first) ;


            bins mode1_with_w8_lsb  = binsof(cp_reg_address.CTRL) && binsof(cp_width.w8)   && binsof(cp_mode.mode0) && binsof(cp_lsb_first.lsb_first) ;
            bins mode1_with_w16_lsb = binsof(cp_reg_address.CTRL) && binsof(cp_width.w16)  && binsof(cp_mode.mode0) && binsof(cp_lsb_first.lsb_first) ;
            bins mode1_with_w32_lsb = binsof(cp_reg_address.CTRL) && binsof(cp_width.w32)  && binsof(cp_mode.mode0) && binsof(cp_lsb_first.lsb_first) ;
            bins mode2_with_w8_lsb  = binsof(cp_reg_address.CTRL) && binsof(cp_width.w8)   && binsof(cp_mode.mode1) && binsof(cp_lsb_first.lsb_first) ;
            bins mode2_with_w16_lsb = binsof(cp_reg_address.CTRL) && binsof(cp_width.w16)  && binsof(cp_mode.mode1) && binsof(cp_lsb_first.lsb_first) ;
            bins mode2_with_w32_lsb = binsof(cp_reg_address.CTRL) && binsof(cp_width.w32)  && binsof(cp_mode.mode1) && binsof(cp_lsb_first.lsb_first) ;
            bins mode3_with_w8_lsb  = binsof(cp_reg_address.CTRL) && binsof(cp_width.w8)   && binsof(cp_mode.mode2) && binsof(cp_lsb_first.lsb_first) ;
            bins mode3_with_w16_lsb = binsof(cp_reg_address.CTRL) && binsof(cp_width.w16)  && binsof(cp_mode.mode2) && binsof(cp_lsb_first.lsb_first) ;
            bins mode3_with_w32_lsb = binsof(cp_reg_address.CTRL) && binsof(cp_width.w32)  && binsof(cp_mode.mode2) && binsof(cp_lsb_first.lsb_first) ;
            bins mode4_with_w8_lsb  = binsof(cp_reg_address.CTRL) && binsof(cp_width.w8)   && binsof(cp_mode.mode3) && binsof(cp_lsb_first.lsb_first) ;
            bins mode4_with_w16_lsb = binsof(cp_reg_address.CTRL) && binsof(cp_width.w16)  && binsof(cp_mode.mode3) && binsof(cp_lsb_first.lsb_first) ;
            bins mode4_with_w32_lsb = binsof(cp_reg_address.CTRL) && binsof(cp_width.w32)  && binsof(cp_mode.mode3) && binsof(cp_lsb_first.lsb_first) ;

        }

        // =========================================================
        // CLK_DIV corners: 0, 1, 2, 3, 255, 1024, 65535, plus a random covering bin over the full range
        // ========================================================
        cp_clock_div_corners : cross cp_reg_address, cp_clk_div_value {
            option.cross_auto_bin_max = 0;
            bins div_0      = binsof(cp_reg_address.CLK_DIV) && binsof(cp_clk_div_value.div_0);
            bins div_1      = binsof(cp_reg_address.CLK_DIV) && binsof(cp_clk_div_value.div_1);
            bins div_2      = binsof(cp_reg_address.CLK_DIV) && binsof(cp_clk_div_value.div_2);
            bins div_3      = binsof(cp_reg_address.CLK_DIV) && binsof(cp_clk_div_value.div_3);
            bins div_255    = binsof(cp_reg_address.CLK_DIV) && binsof(cp_clk_div_value.div_255);
            bins div_1024   = binsof(cp_reg_address.CLK_DIV) && binsof(cp_clk_div_value.div_1024);
            bins div_65535  = binsof(cp_reg_address.CLK_DIV) && binsof(cp_clk_div_value.div_65535);
            bins div_random = binsof(cp_reg_address.CLK_DIV) && binsof(cp_clk_div_value) intersect {[0:65535]}; // Any value not in the defined bins
        }    

        // =========================================================
        // Loopback enable/disable coverage (bit 5 of CTRL) - important to verify both states are tested
        // =========================================================
        cp_loop_back : coverpoint apb_item.PWDATA[5] iff(apb_item.PADDR == 8'h00 && apb_item.PWRITE) {
            bins loopback_enabled = {1};
            bins loopback_disabled = {0};
        }

        cp_pwrite : coverpoint apb_item.PWRITE  {
            bins write = {1};
            bins read  = {0};
        }

        //=========================================================
        //Each register: written, read back, reset-value observed.
        //=========================================================
        cp_each_reg_read_write : cross cp_reg_address, cp_pwrite {
            option.cross_auto_bin_max = 0;
            bins reg_read  = binsof(cp_pwrite.read)  && binsof(cp_reg_address);
            bins reg_write = binsof(cp_pwrite.write) && binsof(cp_reg_address);
        }

        // Coverpoint to capture read data values specifically
        cp_prdata : coverpoint apb_item.PRDATA iff(!apb_item.PWRITE) {
            bins zero_val   = { 32'h0000_0000 };
            bins status_val = { 32'h0000_0012 }; // Specific reset value for STATUS
        }

        // Cross-coverage to lock addresses to their exact spec-sheet reset value
        cp_reset_observed : cross cp_reg_address, cp_prdata {
            option.cross_auto_bin_max = 0;
            bins ctrl_reset     = binsof(cp_reg_address.CTRL)     && binsof(cp_prdata.zero_val);
            bins status_reset   = binsof(cp_reg_address.STATUS)   && binsof(cp_prdata.status_val);
            bins tx_data_reset  = binsof(cp_reg_address.TX_DATA)  && binsof(cp_prdata.zero_val);
            bins rx_data_reset  = binsof(cp_reg_address.RX_DATA)  && binsof(cp_prdata.zero_val);
            bins clk_div_reset  = binsof(cp_reg_address.CLK_DIV)  && binsof(cp_prdata.zero_val);
            bins ss_ctrl_reset  = binsof(cp_reg_address.SS_CTRL)  && binsof(cp_prdata.zero_val);
            bins int_en_reset   = binsof(cp_reg_address.INT_EN)   && binsof(cp_prdata.zero_val);
            bins int_stat_reset = binsof(cp_reg_address.INT_STAT) && binsof(cp_prdata.zero_val);
            bins delay_reset    = binsof(cp_reg_address.DELAY)    && binsof(cp_prdata.zero_val);
        }


    endgroup
    

   function new(string name = "spi_coverage" , uvm_component parent = null);
        super.new(name,parent);
        g1=new();
    endfunction
    
    function void build_phase (uvm_phase phase);
    super.build_phase(phase);
        apb_cov_export=new("apb_cov_export",this);
        fifo_apb=new("fifo_apb",this);
        spi_cov_export=new("spi_cov_export",this);
        fifo_spi=new("fifo_spi",this);
    endfunction 

    function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    `uvm_info("connect_phase", "Connecting coverage analysis ports to FIFOs", UVM_LOW)
        apb_cov_export.connect(fifo_apb.analysis_export);
        spi_cov_export.connect(fifo_spi.analysis_export);
    endfunction : connect_phase
     
    task run_phase(uvm_phase phase);
    super.run_phase(phase);
    
    fork
        // Process APB items independently
        forever begin
            fifo_apb.get(apb_item);
            g1.sample(); // Samples immediately when any APB transaction occurs
        end
        
        // Process SPI items independently (if needed later)
        forever begin
            fifo_spi.get(spi_item);
            // If you add SPI coverpoints to g1 later, you can sample here too, 
            // or put them in a separate covergroup.
        end
    join
    endtask

endclass 
    
