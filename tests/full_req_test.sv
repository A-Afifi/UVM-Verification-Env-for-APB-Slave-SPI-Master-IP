// =============================================================================
// full_req_test.sv
// Runs ALL requirement sequences R1-R25 in order.
// This is the main regression test for the grader.
// =============================================================================
class full_req_test extends test_base;
    `uvm_component_utils(full_req_test)

    // Reset sequences
    apb_reset_seq    apb_rst_seq;
    spi_reset_seq    spi_rst_seq;

    // Requirement sequences
    r1_r2_reg_seq         seq_r1_r2;
    r3_ctrl_en_seq        seq_r3;
    r4_r8_spi_protocol_seq seq_r4_r8;
    r9_r15_fifo_seq       seq_r9_r15;
    r16_r18_irq_seq       seq_r16_r18;
    r19_r23_misc_seq      seq_r19_r23;
coverage_closure_seq  seq_cov_closure;
    function new(string name = "full_req_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        apb_rst_seq   = apb_reset_seq::type_id::create("apb_rst_seq");
        spi_rst_seq   = spi_reset_seq::type_id::create("spi_rst_seq");
        seq_r1_r2     = r1_r2_reg_seq::type_id::create("seq_r1_r2");
        seq_r3        = r3_ctrl_en_seq::type_id::create("seq_r3");
        seq_r4_r8     = r4_r8_spi_protocol_seq::type_id::create("seq_r4_r8");
        seq_r9_r15    = r9_r15_fifo_seq::type_id::create("seq_r9_r15");
        seq_r16_r18   = r16_r18_irq_seq::type_id::create("seq_r16_r18");
        seq_r19_r23   = r19_r23_misc_seq::type_id::create("seq_r19_r23");
        seq_cov_closure = coverage_closure_seq::type_id::create("seq_cov_closure"); 

    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        phase.raise_objection(this);

        `uvm_info("FULL_REQ_TEST", "========================================", UVM_LOW)
        `uvm_info("FULL_REQ_TEST", "  Starting Full Requirements Test R1-R25", UVM_LOW)
        `uvm_info("FULL_REQ_TEST", "========================================", UVM_LOW)

        // Apply reset before everything
        `uvm_info("FULL_REQ_TEST", "Applying reset...", UVM_LOW)
        repeat(3) apb_rst_seq.start(env.apb_agt.apb_sqr);
        spi_rst_seq.start(env.spi_agt.spi_sqr);

        // R1 + R2: Register R/W and reset values
        `uvm_info("FULL_REQ_TEST", "--- R1/R2: Register read/write + reset values ---", UVM_LOW)
        seq_r1_r2.start(env.apb_agt.apb_sqr);

        // Reset between test groups
        repeat(2) apb_rst_seq.start(env.apb_agt.apb_sqr);

        // R3: CTRL.EN=0 behavior
        `uvm_info("FULL_REQ_TEST", "--- R3: CTRL.EN=0 behavior ---", UVM_LOW)
        seq_r3.start(env.apb_agt.apb_sqr);

        repeat(2) apb_rst_seq.start(env.apb_agt.apb_sqr);

        // R4-R8 + R24 + R25: SPI protocol timing
        `uvm_info("FULL_REQ_TEST", "--- R4-R8,R24,R25: SPI protocol timing ---", UVM_LOW)
        seq_r4_r8.start(env.apb_agt.apb_sqr);

        repeat(2) apb_rst_seq.start(env.apb_agt.apb_sqr);

        // R9-R15: FIFO tests
        `uvm_info("FULL_REQ_TEST", "--- R9-R15: FIFO tests ---", UVM_LOW)
        seq_r9_r15.start(env.apb_agt.apb_sqr);

        repeat(2) apb_rst_seq.start(env.apb_agt.apb_sqr);

        // R16-R18: Interrupt tests
        `uvm_info("FULL_REQ_TEST", "--- R16-R18: Interrupt tests ---", UVM_LOW)
        seq_r16_r18.start(env.apb_agt.apb_sqr);

        repeat(2) apb_rst_seq.start(env.apb_agt.apb_sqr);

        // R19-R23: Loopback, SS_n, Delay, APB misc
        `uvm_info("FULL_REQ_TEST", "--- R19-R23: Loopback/SS_n/Delay/APB misc ---", UVM_LOW)
        seq_r19_r23.start(env.apb_agt.apb_sqr);

        repeat(2) apb_rst_seq.start(env.apb_agt.apb_sqr);
        `uvm_info("FULL_REQ_TEST", "--- Coverage closure ---", UVM_LOW)
        seq_cov_closure.start(env.apb_agt.apb_sqr);

        `uvm_info("FULL_REQ_TEST", "========================================", UVM_LOW)
        `uvm_info("FULL_REQ_TEST", "  Full Requirements Test COMPLETE", UVM_LOW)
        `uvm_info("FULL_REQ_TEST", "========================================", UVM_LOW)



        phase.drop_objection(this);
    endtask

endclass
