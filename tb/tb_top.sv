// ****************************************************************************
// *                                                                          *
// * Copyright (c) 2014-2015 Synopsys Inc. All rights reserved.               *
// *                                                                          *
// * Synopsys Proprietary and Confidential. This file contains confidential   *
// * information and the trade secrets of Synopsys Inc. Use, disclosure, or   *
// * reproduction is prohibited without the prior express written permission  *
// * of Synopsys, Inc.                                                        *
// *                                                                          *
// * Synopsys, Inc.                                                           *
// * 700 East Middlefield Road                                                *
// * Mountain View, California 94043                                          *
// * (800) 541-7737                                                           *
// *                                                                          *
// ****************************************************************************


module spi_master_top;
    import uvm_pkg::*;
    import spi_master_pkg::*;
    `include "uvm_macros.svh"
    `timescale 1ns/1ps
    // Clock Generation
    bit clk ;
    initial begin
        forever begin
            #1;
            clk=!clk;
        end
    end
   // instantite dut & interfaces
    spi_if spi_if(clk);
    apb_if apb_if(clk);

    spi_master u_dut(.PRESETn(apb_if.PRESETn),
               .PCLK(spi_if.PCLK),
               .SCLK(spi_if.SCLK),
               .MOSI(spi_if.MOSI),
               .MISO(spi_if.MISO),
               .SS_n(spi_if.SS_n),
               .IRQ(spi_if.IRQ),
               .PSEL(apb_if.PSEL),
               .PENABLE(apb_if.PENABLE),
               .PWRITE(apb_if.PWRITE),
               .PADDR(apb_if.PADDR),
               .PWDATA(apb_if.PWDATA),
               .PRDATA(apb_if.PRDATA),
               .PREADY(apb_if.PREADY),
               .PSLVERR(apb_if.PSLVERR)
    );

    
// =============================================================================
// BIND DECLARATIONS
// =============================================================================
bind apb_regfile apb_regfile_sva u_apb_sva (
    .PCLK             (PCLK),
    .PRESETn          (PRESETn),
    .PSEL             (PSEL),
    .PENABLE          (PENABLE),
    .PWRITE           (PWRITE),
    .PADDR            (PADDR),
    .PWDATA           (PWDATA),
    .PRDATA           (PRDATA),
    .PREADY           (PREADY),
    .PSLVERR          (PSLVERR),
    .ctrl_en          (ctrl_en),
    .int_stat         (int_stat),
    .int_en           (int_en),
    .IRQ              (IRQ),
    .rx_full_w        (rx_full_w),
    .rx_push_valid    (rx_push_valid),
    .tx_push_dropped  (tx_push_dropped),
    .tx_push_accepted (tx_push_accepted),
    .tx_full_w        (tx_full_w),
    .busy_in          (busy_in)
);

bind spi_core spi_core_sva u_core_sva (
    .PCLK                 (PCLK),
    .PRESETn              (PRESETn),
    .cfg_en               (cfg_en),
    .cfg_mstr             (cfg_mstr),
    .cfg_mode             (cfg_mode),
    .cfg_lsb_first        (cfg_lsb_first),
    .cfg_loopback         (cfg_loopback),
    .cfg_width            (cfg_width),
    .cfg_clk_div          (cfg_clk_div),
    .cfg_delay            (cfg_delay),
    .SCLK                 (SCLK),
    .MOSI                 (MOSI),
    .MISO                 (MISO),
    .ss_n_drive           (ss_n_drive),
    .tx_word              (tx_word),
    .tx_empty             (tx_empty),
    .tx_pop               (tx_pop),
    .rx_push_valid        (rx_push_valid),
    .rx_push_data         (rx_push_data),
    .busy                 (busy),
    .transfer_done_pulse  (transfer_done_pulse),
    .state                (state),
    .bit_cnt              (bit_cnt),
    .sclk_cnt             (sclk_cnt),
    .gap_cnt              (gap_cnt),
    .sclk_phase           (sclk_phase),
    .sh_tx                (sh_tx),
    .sh_rx                (sh_rx),
    .xfer_mode            (xfer_mode),
    .xfer_lsb_first       (xfer_lsb_first),
    .xfer_width           (xfer_width),
    .xfer_div             (xfer_div)
);

    initial begin

        uvm_config_db#(virtual spi_if)::set(null,"uvm_test_top", "SPI_IF",   spi_if  );
        uvm_config_db#(virtual apb_if)::set(null,"uvm_test_top", "APB_IF",   apb_if  );

        run_test("full_req_test");
    end
endmodule : spi_master_top
