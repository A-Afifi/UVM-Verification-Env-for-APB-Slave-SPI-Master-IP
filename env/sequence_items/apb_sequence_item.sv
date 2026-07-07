import spi_master_pkg::*;

class apb_sequence_item extends uvm_sequence_item;
    `uvm_object_utils(apb_sequence_item)
        
    function new(string name = "apb_sequence_item");
            super.new(name);
    endfunction //new()

    logic       PRESETn;
    logic        PSEL;
    logic        PENABLE;
    logic        PWRITE;
    logic [7:0]  PADDR;
    logic [31:0] PWDATA;
    logic [31:0] PRDATA;
    logic        PREADY;
    logic        PSLVERR;


endclass
