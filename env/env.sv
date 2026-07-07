class spi_env extends uvm_env;
    `uvm_component_utils(spi_env)
    spi_agent spi_agt;
    apb_agent apb_agt;
    spi_scoreboard sb;
    spi_coverage cov;

    function new(string name = "spi_env" , uvm_component parent = null);
        super.new(name,parent);
    endfunction

    function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        spi_agt = spi_agent::type_id::create("spi_agt",this);
        apb_agt = apb_agent::type_id::create("apb_agt",this);
        sb = spi_scoreboard::type_id::create("sb",this);
        cov = spi_coverage::type_id::create("cov",this);
    endfunction 
    
    function void connect_phase (uvm_phase phase);
        super.connect_phase(phase);
        spi_agt.spi_agt_ap.connect(sb.spi_sb_export);
        spi_agt.spi_agt_ap.connect(cov.spi_cov_export);
        apb_agt.apb_agt_ap.connect(sb.apb_sb_export);
        apb_agt.apb_agt_ap.connect(cov.apb_cov_export);
    endfunction 
endclass 
    
