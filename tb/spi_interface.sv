`timescale 1ns/1ps

interface spi_if (PCLK);
    input logic PCLK;
    logic        SCLK;          
    logic        MOSI;          
    logic        MISO;          
    logic [3:0]  SS_n;          
    logic        IRQ;           

    initial begin
        MISO = 0;
    end

    // --------------- Slave driver-side clocking block ----------------------------
    clocking cb_slave @(posedge PCLK);
        default input #1step output #0;
        input SCLK, MOSI, SS_n, IRQ;
        output MISO;
    endclocking

    // --------------- Monitor-side clocking block ----------------------------
    clocking cb_mon @(posedge PCLK);
        default input #1step;
        input SCLK, MOSI, MISO, SS_n, IRQ;
    endclocking

    modport DUT  (input PCLK, MISO,
                     output SCLK, MOSI, SS_n, IRQ);

    modport monitor (input PCLK, SCLK, MOSI, MISO, SS_n, IRQ,
                     clocking cb_mon);

    modport driver (input PCLK, MISO,
                     output SCLK, MOSI, SS_n, IRQ,
                     clocking cb_slave);

endinterface : spi_if