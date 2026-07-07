
class spi_agent extends uvm_agent;
    `uvm_component_utils(spi_agent)
    spi_driver spi_drvr;
    spi_monitor spi_mntr;
    spi_config spi_cfg;
    spi_sequencer spi_sqr;
    uvm_analysis_port #(spi_sequence_item) spi_agt_ap;
        
    function new(string name="spi_agent", uvm_component parent = null);
        super.new(name,parent);
    endfunction //new()
        
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        spi_mntr = spi_monitor::type_id::create("spi_monitor",this);
        
        if(!uvm_config_db #(spi_config) :: get(this,"","CFG",spi_cfg))
        `uvm_fatal("build_phase","error in getting config object");
        
        if(spi_cfg.is_active==UVM_ACTIVE)
            begin
            spi_drvr = spi_driver::type_id::create("spi_driver",this);
            spi_sqr = spi_sequencer::type_id::create("spi_sequencer",this);   
            end
        spi_agt_ap = new("spi_agt_ap",this);
    endfunction
        
    function void connect_phase (uvm_phase phase);
        super.connect_phase(phase);
        spi_mntr.spi_vif=spi_cfg.spi_vif;
        if(spi_cfg.is_active==UVM_ACTIVE)
            begin
                spi_drvr.spi_vif=spi_cfg.spi_vif;
                spi_drvr.seq_item_port.connect(spi_sqr.seq_item_export);    
            end

        spi_mntr.spi_mon_ap.connect(spi_agt_ap);
    endfunction 
endclass //className extends superClass