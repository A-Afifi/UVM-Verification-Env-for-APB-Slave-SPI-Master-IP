class apb_reset_seq extends uvm_sequence #(apb_sequence_item);
    `uvm_object_utils(apb_reset_seq)

    apb_sequence_item apb_item;

    function new(string name = "apb_reset_seq");
        super.new(name);
    endfunction

    task body();
        apb_item = apb_sequence_item::type_id::create("apb_item");
        
        start_item(apb_item);
        apb_item.PRESETn = 0;
        apb_item.PSEL = 0;
        apb_item.PENABLE = 0;
        apb_item.PWRITE = 0;
        apb_item.PADDR = 8'h00;
        apb_item.PWDATA = 32'h00000000;
        finish_item(apb_item);

    endtask


endclass
