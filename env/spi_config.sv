class spi_config extends uvm_object;
    `uvm_object_utils(spi_config)
    virtual spi_if spi_vif;
    uvm_active_passive_enum is_active;
        
    function new(string name = "spi_config" );
        super.new(name);
    endfunction
endclass //className extends superClass
