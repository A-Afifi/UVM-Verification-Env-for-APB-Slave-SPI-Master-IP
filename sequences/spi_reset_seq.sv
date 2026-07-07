class spi_reset_seq extends uvm_sequence #(spi_sequence_item);
    `uvm_object_utils(spi_reset_seq)

    spi_sequence_item spi_item;

    function new(string name = "spi_reset_seq");
        super.new(name);
    endfunction

    task body();
        spi_item = spi_sequence_item::type_id::create("spi_item");
        start_item(spi_item);
        spi_item.MISO = 1'b1; // MISO idle high
        finish_item(spi_item);

    endtask


endclass
