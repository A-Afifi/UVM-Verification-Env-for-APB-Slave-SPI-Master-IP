`timescale 1ns/1ps

interface apb_if (PCLK);
    input logic PCLK;
    logic       PRESETn;
    logic        PSEL;
    logic        PENABLE;
    logic        PWRITE;
    logic [7:0]  PADDR;
    logic [31:0] PWDATA;
    logic [31:0] PRDATA;
    logic        PREADY;
    logic        PSLVERR;

    initial begin
        PRESETn = 0;
        PSEL = 0;
        PENABLE = 0;
        PWRITE = 0;
        PADDR = 8'h00;
        PWDATA = 32'h00000000;
    end


    // --------------- Driver-side clocking block ----------------------------
    clocking cb_master @(posedge PCLK);
        default input #1step output #1;
        output PSEL, PENABLE, PWRITE, PADDR, PWDATA, PRESETn;
        input PRDATA, PREADY, PSLVERR;
    endclocking

    // --------------- Monitor-side clocking block ----------------------------
    clocking cb_monitor @(posedge PCLK);
        default input #1step;
        input PSEL, PENABLE, PWRITE, PADDR, PWDATA, PRESETn;
        input PRDATA, PREADY, PSLVERR;
    endclocking
                     
    modport DUT (input PCLK, PRESETn, PSEL, PENABLE, PWRITE, PADDR, PWDATA, 
                     output PRDATA, PREADY, PSLVERR);

    modport monitor (input PCLK, PRESETn, PSEL, PENABLE, PWRITE, PADDR, PWDATA, PRDATA, PREADY, PSLVERR,
                     clocking cb_monitor);

    modport driver (input PCLK, PRESETn,
                     output PSEL, PENABLE, PWRITE, PADDR, PWDATA,
                     clocking cb_master);
                     
endinterface : apb_if