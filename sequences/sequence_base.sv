class sequence_base extends uvm_sequence #(apb_sequence_item);
    `uvm_object_utils(sequence_base)

    apb_sequence_item apb_item;

    function new(string name = "sequence_base");
        super.new(name);
    endfunction


    task apb_write(input bit [7:0] addr, input bit [31:0] data);
        apb_item = apb_sequence_item::type_id::create("apb_item");
        start_item(apb_item);
        apb_item.PSEL = 1;
        apb_item.PENABLE = 0; // setup phase
        apb_item.PWRITE = 1;
        apb_item.PRESETn = 1;
        apb_item.PADDR = addr;
        apb_item.PWDATA = data;
        finish_item(apb_item);

        // Access phase
        start_item(apb_item);
        apb_item.PSEL = 1;
        apb_item.PENABLE = 1; // access phase
        apb_item.PWRITE = 1;
        apb_item.PRESETn = 1;
        apb_item.PADDR = addr;
        apb_item.PWDATA = data;
        finish_item(apb_item);
    endtask

    task apb_read(input bit [7:0] addr);
        apb_item = apb_sequence_item::type_id::create("apb_item");
        start_item(apb_item);
        apb_item.PSEL = 1;
        apb_item.PENABLE = 0; // setup
        apb_item.PWRITE = 0;
        apb_item.PRESETn = 1;
        apb_item.PADDR = addr;
        apb_item.PWDATA = 32'h00000000; // not used for read, but set to 0
        finish_item(apb_item);

        // Access phase
        start_item(apb_item);
        apb_item.PSEL = 1;
        apb_item.PENABLE = 1; // access
        apb_item.PWRITE = 0;
        apb_item.PRESETn = 1;
        apb_item.PADDR = addr;
        apb_item.PWDATA = 32'h00000000; // not used for read, but set to 0
        finish_item(apb_item);
    endtask

endclass
