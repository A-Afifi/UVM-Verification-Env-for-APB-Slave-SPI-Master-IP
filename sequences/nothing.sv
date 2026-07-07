class nothing extends uvm_sequence #(apb_sequence_item);
    `uvm_object_utils(nothing)

    apb_sequence_item apb_item;

    function new(string name = "nothing");
        super.new(name);
    endfunction


    task body();
        apb_item = apb_sequence_item::type_id::create("apb_item");
        
        start_item(apb_item);
        apb_item.PRESETn = 1;
        apb_item.PSEL = 1;
        apb_item.PENABLE = 0;
        apb_item.PWRITE = 0;
        apb_item.PADDR = 8'h00;
        apb_item.PWDATA = 32'h00000000;
        finish_item(apb_item);

    endtask


endclass
