//------------------------------------------------------------------------------
//
// CLASS: test_base
//
// The test_base class provides common test infrastructure for the
// SPI Master project. It includes the build, run, and final phases of the test.
//
//-------------------------------------------------------------------------------



class test_base extends uvm_test;
    `uvm_component_utils(test_base)

    spi_env env; 
    spi_config spi_cfg;
    apb_config apb_cfg;

    function new(string name = "spi_test_base", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);


        // create environment and configuration objects
        env = spi_env::type_id::create("env", this);
        spi_cfg = spi_config::type_id::create("spi_cfg", this);
        apb_cfg = apb_config::type_id::create("apb_cfg", this);

        if(!uvm_config_db#(virtual spi_if)::get(this, "", "SPI_IF", spi_cfg.spi_vif))
        `uvm_fatal("build_phase", "TEST - Unable to get the SPI_IF from the uvm_config_db")

        if(!uvm_config_db#(virtual apb_if)::get(this, "", "APB_IF", apb_cfg.apb_vif))
        `uvm_fatal("build_phase", "TEST - Unable to get the APB_IF from the uvm_config_db")

        spi_cfg.is_active = UVM_ACTIVE;
        apb_cfg.is_active = UVM_ACTIVE;

        uvm_config_db#(spi_config)::set(this, "*", "CFG", spi_cfg);
        uvm_config_db#(apb_config)::set(this, "*", "CFG", apb_cfg);

    endfunction : build_phase

    function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        
        uvm_top.print_topology(); // Prints entire testbench hierarchy 
    endfunction : end_of_elaboration_phase

endclass : test_base




