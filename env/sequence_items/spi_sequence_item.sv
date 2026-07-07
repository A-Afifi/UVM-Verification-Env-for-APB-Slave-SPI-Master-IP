import spi_master_pkg::*;

class spi_sequence_item extends uvm_sequence_item;
    `uvm_object_utils(spi_sequence_item)
        
    function new(string name = "spi_sequence_item");
            super.new(name);
    endfunction //new()

    logic        SCLK;          
    logic        MOSI;          
    logic        MISO;          
    logic [3:0]  SS_n;          
    logic        IRQ;  


endclass
