//------------------------------------------------------------------------------
// Title      : SPI Master Project
// Project    : SPI Master
// File       : spi_driver.sv
//------------------------------------------------------------------------------
// Description: This file contains the implementation of the SPI driver class, which is responsible for driving the SPI signals based on the sequence items received from the sequencer. The driver interacts with the SPI
//              interface to perform the necessary operations for the SPI communication using clocking blocks for synchronization.
//------------------------------------------------------------------------------
class spi_driver extends uvm_driver#(spi_sequence_item);
    `uvm_component_utils(spi_driver)
    spi_sequence_item spi_item;
    virtual spi_if.driver spi_vif;
        
    function new(string name="spi_driver",uvm_component parent = null);
        super.new(name,parent);
    endfunction //new()
    
    function void build_phase (uvm_phase phase);
        super.build_phase(phase);
    endfunction 
    
    task run_phase (uvm_phase phase);
            super.run_phase(phase);
            forever begin
                spi_item = spi_sequence_item::type_id::create("spi_item");
                seq_item_port.get_next_item(spi_item);
                
                // Drive MISO through clocking block
                spi_vif.cb_slave.MISO <= spi_item.MISO;
                
                // Wait for clock edge - clocking block handles timing
                @(spi_vif.cb_slave);
                seq_item_port.item_done();
            end
    endtask //run_phase
endclass //className extends superClass
