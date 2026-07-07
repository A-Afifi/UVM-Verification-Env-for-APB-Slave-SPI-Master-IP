
package spi_master_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"


    // Sequence Items
    `include "sequence_items/spi_sequence_item.sv"
    `include "sequence_items/apb_sequence_item.sv"

    // Sequencers
    `include "sequencers/apb_sequencer.sv"
    `include "sequencers/spi_sequencer.sv"
      

    // Configurations
    `include "spi_config.sv"
    `include "apb_config.sv"
    
    // Monitors
    `include "monitors/apb_monitor.sv"
    `include "monitors/spi_monitor.sv"
    
    // Drivers
    `include "drivers/apb_driver.sv"
    `include "drivers/spi_driver.sv"

    // Agents 
    `include "agents/apb_agent.sv"
    `include "agents/spi_agent.sv"

    //reference model
    `include "ref_model.sv"


    // scoreboard
    `include "scoreboard/scoreboard.sv"

    // coverage
    `include "spi_coverage.sv"

    // Environment
    `include "env.sv"
 


    // ---- Base sequences ----
    `include "sequences/sequence_base.sv"
    `include "sequences/spi_reset_seq.sv"
    `include "sequences/apb_reset_seq.sv"
    `include "sequences/main_sequence.sv"
    `include "sequences/nothing.sv"

    // ---- Requirement sequences (R1-R25) ----
    `include "sequences/r1_r2_reg_seq.sv"
    `include "sequences/r3_ctrl_en_seq.sv"
    `include "sequences/r4_r8_spi_protocol_seq.sv"
    `include "sequences/r9_r15_fifo_seq.sv"
    `include "sequences/r16_r18_irq_seq.sv"
    `include "sequences/r19_r23_misc_seq.sv"
    `include "sequences/coverage_closure_seq.sv"   

    
    
    // Tests
    `include "tests/spi_test_base.sv"
    `include "tests/sanity_test.sv"
    `include "tests/full_req_test.sv"
    
endpackage : spi_master_pkg
