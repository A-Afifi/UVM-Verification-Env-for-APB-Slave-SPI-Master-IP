class sanity_test extends test_base;
    `uvm_component_utils(sanity_test)
    main_seq main_sequence;
    apb_reset_seq apb_reset_sequence;
    spi_reset_seq spi_reset_sequence;
    nothing nothing_sequence;
    
    function new(string name = "sanity_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction //new()

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        main_sequence = main_seq::type_id::create("main_sequence");
        apb_reset_sequence = apb_reset_seq::type_id::create("apb_reset_sequence");
        spi_reset_sequence = spi_reset_seq::type_id::create("spi_reset_sequence");
        nothing_sequence = nothing::type_id::create("nothing_sequence");
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        
        phase.raise_objection(this);
        repeat(5)begin
        apb_reset_sequence.start(env.apb_agt.apb_sqr);
        end

        main_sequence.start(env.apb_agt.apb_sqr);
        spi_reset_sequence.start(env.spi_agt.spi_sqr);
        repeat(20)begin
       // `uvm_info("SANITY_TEST", "Starting nothing sequence to keep simulation running", UVM_LOW)    
        nothing_sequence.start(env.apb_agt.apb_sqr);
        end

        phase.drop_objection(this);
    endtask //run_phase()



endclass //sanity_test extends test_base