class spi_monitor extends uvm_monitor;
    `uvm_component_utils(spi_monitor)

    spi_sequence_item item;
    virtual spi_if.monitor spi_vif;
    uvm_analysis_port #(spi_sequence_item) spi_mon_ap;

    function new(string name = "spi_monitor", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        spi_mon_ap = new("spi_mon_ap", this);
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);

        forever begin
            @(spi_vif.cb_mon);

            item = spi_sequence_item::type_id::create("item");

            item.SCLK = spi_vif.cb_mon.SCLK;
            item.MOSI = spi_vif.cb_mon.MOSI;
            item.MISO = spi_vif.cb_mon.MISO;
            item.SS_n = spi_vif.cb_mon.SS_n;
            item.IRQ  = spi_vif.cb_mon.IRQ;

            spi_mon_ap.write(item);
        end
    endtask
endclass