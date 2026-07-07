//------------------------------------------------------------------------------
// Title      : SPI Master Project
// Project    : SPI Master
// File       : apb_monitor.sv
//------------------------------------------------------------------------------
// Description: This file contains the implementation of the APB monitor class, which is responsible for monitoring the APB signals based on the sequence items received from the sequencer. The monitor interacts with the APB
//              interface to perform the necessary operations for the APB communication using clocking blocks for synchronization.
//------------------------------------------------------------------------------


class apb_monitor extends uvm_monitor;
     `uvm_component_utils(apb_monitor)
    apb_sequence_item apb_item;
    virtual apb_if.monitor apb_vif;
    uvm_analysis_port #(apb_sequence_item) apb_mon_ap;
       
    function new(string name = "apb_monitor",uvm_component parent = null);
        super.new(name,parent);
    endfunction //new()
        
    function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        apb_mon_ap=new("apb_mon_ap",this);
    endfunction 
    
    task run_phase(uvm_phase phase);
            super.run_phase(phase);
            forever begin
                    apb_item = apb_sequence_item::type_id::create("apb_item");
                    @(apb_vif.cb_monitor);
                    apb_item.PRESETn = apb_vif.PRESETn;
                    apb_item.PSEL    = apb_vif.cb_monitor.PSEL;
                    apb_item.PENABLE = apb_vif.cb_monitor.PENABLE;
                    apb_item.PWRITE  = apb_vif.cb_monitor.PWRITE;
                    apb_item.PADDR   = apb_vif.cb_monitor.PADDR;
                    apb_item.PWDATA  = apb_vif.cb_monitor.PWDATA;
                    apb_item.PRDATA  = apb_vif.cb_monitor.PRDATA;
                    apb_item.PREADY  = apb_vif.cb_monitor.PREADY;
                    apb_item.PSLVERR = apb_vif.cb_monitor.PSLVERR;
                    
                    apb_mon_ap.write(apb_item);

            end
        endtask
endclass