class apb_agent extends uvm_agent;
    `uvm_component_utils(apb_agent)
    apb_driver apb_drvr;
    apb_monitor apb_mntr;
    apb_config apb_cfg;
    apb_sequencer apb_sqr;
    uvm_analysis_port #(apb_sequence_item) apb_agt_ap;
        
    function new(string name="apb_agent", uvm_component parent = null);
            super.new(name,parent);
    endfunction //new()
        
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        apb_mntr = apb_monitor::type_id::create("apb_monitor",this);
        
        if(!uvm_config_db #(apb_config) :: get(this,"","CFG",apb_cfg))
        `uvm_fatal("build_phase","error in getting config object");
        
        if(apb_cfg.is_active==UVM_ACTIVE)
            begin
                apb_drvr = apb_driver::type_id::create("apb_driver",this);
                apb_sqr = apb_sequencer::type_id::create("apb_sqr",this);   
            end
        apb_agt_ap = new("apb_agt_ap",this);
    endfunction
        
    function void connect_phase (uvm_phase phase);
        super.connect_phase(phase);
        apb_mntr.apb_vif=apb_cfg.apb_vif;
        if(apb_cfg.is_active==UVM_ACTIVE)
            begin
                apb_drvr.apb_vif = apb_cfg.apb_vif;
                apb_drvr.seq_item_port.connect(apb_sqr.seq_item_export);    
            end

        apb_mntr.apb_mon_ap.connect(apb_agt_ap);
    endfunction 
endclass //className extends superClass