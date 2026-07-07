
//------------------------------------------------------------------------------
// Title      : SPI Master Project
// Project    : SPI Master
// File       : apb_driver.sv
//------------------------------------------------------------------------------
// Description: This file contains the implementation of the APB driver class, which is responsible for driving the APB signals based on the sequence items received from the sequencer. The driver interacts with the APB
//              interface to perform the necessary operations for the APB communication using clocking blocks for synchronization.
//------------------------------------------------------------------------------
class apb_driver extends uvm_driver#(apb_sequence_item);
    `uvm_component_utils(apb_driver)
    apb_sequence_item apb_item;
    virtual apb_if.driver apb_vif;
        
    function new(string name="apb_driver",uvm_component parent = null);
        super.new(name,parent);
    endfunction //new()
    
    function void build_phase (uvm_phase phase);
        super.build_phase(phase);
    endfunction 

    task run_phase (uvm_phase phase);
        super.run_phase(phase);
        
        // Initialize Idle state
        apb_vif.cb_master.PSEL <= 0;
        apb_vif.cb_master.PENABLE <= 0;

        forever begin
            apb_item = apb_sequence_item::type_id::create("apb_item");
            seq_item_port.get_next_item(apb_item);
            
            // Check if it's an active transfer
            if (apb_item.PSEL === 1'b1) begin
                // --- 1. SETUP PHASE ---
                apb_vif.cb_master.PSEL <= 1'b1;
                apb_vif.cb_master.PENABLE <= 1'b0; // Enforce Setup phase
                apb_vif.cb_master.PRESETn <= apb_item.PRESETn;
                apb_vif.cb_master.PWRITE <= apb_item.PWRITE;
                apb_vif.cb_master.PADDR <= apb_item.PADDR;
                apb_vif.cb_master.PWDATA <= apb_item.PWDATA;
                
                @(apb_vif.cb_master); // Wait for 1st clock edge

                // --- 2. ACCESS PHASE ---
                apb_vif.cb_master.PENABLE <= 1'b1; // Enforce Access phase
                // Notice we do NOT update PADDR/PWDATA/PWRITE here! They stay stable.
                
                @(apb_vif.cb_master); // Wait for 2nd clock edge

                // Capture read data and send it back to the sequence
                if (apb_item.PWRITE === 1'b0) begin
                    apb_item.PRDATA = apb_vif.cb_master.PRDATA;
                end

                // Return to Idle
                apb_vif.cb_master.PSEL <= 1'b0;
                apb_vif.cb_master.PENABLE <= 1'b0;

            end else begin
                // Handle Reset or Idle items driven by sequences
                apb_vif.cb_master.PSEL <= apb_item.PSEL;
                apb_vif.cb_master.PENABLE <= apb_item.PENABLE;
                apb_vif.cb_master.PRESETn <= apb_item.PRESETn;
                @(apb_vif.cb_master);
            end

            seq_item_port.item_done();
        end
    endtask //run_phase

endclass //className extends superClass
