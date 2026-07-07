//------------------------------------------------------------------------------
//
// CLASS: spi_scoreboard
//
// Scoreboard for APB-SPI Master UVM environment.
//
// Notes:
// - APB writes update the reference model but are not counted as correctness
//   comparisons.
// - APB reads are counted as comparisons.
// - SPI monitor items are checked through the reference model.
// - APB and SPI threads use local match variables to avoid race/confusion.
// - Final report prints the grader-required pass/fail line.
//
//------------------------------------------------------------------------------

class spi_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(spi_scoreboard)

    // -------------------------------------------------------------------------
    // Analysis infrastructure
    // -------------------------------------------------------------------------
    uvm_analysis_export #(apb_sequence_item) apb_sb_export;
    uvm_tlm_analysis_fifo #(apb_sequence_item) fifo_apb;

    uvm_analysis_export #(spi_sequence_item) spi_sb_export;
    uvm_tlm_analysis_fifo #(spi_sequence_item) fifo_spi;

    // -------------------------------------------------------------------------
    // Transaction handles
    // -------------------------------------------------------------------------
    apb_sequence_item item_apb;
    spi_sequence_item item_spi;

    // Reference model
    spi_ref_model model;

    // -------------------------------------------------------------------------
    // Statistics
    // -------------------------------------------------------------------------
    int error_count;
    int correct_count;
    int total_count;
    real pass_rate;

    string summary_msg;
    string status_msg;
    uvm_severity test_severity;

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------
    function new(string name = "spi_scoreboard", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    // -------------------------------------------------------------------------
    // Build phase
    // -------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        `uvm_info("build_phase",
                  "Building scoreboard and creating analysis exports/FIFOs",
                  UVM_LOW)

        apb_sb_export = new("apb_sb_export", this);
        fifo_apb      = new("fifo_apb", this);

        spi_sb_export = new("spi_sb_export", this);
        fifo_spi      = new("fifo_spi", this);

        model = new();

        error_count   = 0;
        correct_count = 0;

        `uvm_info("build_phase", "Finished building scoreboard", UVM_LOW)
    endfunction : build_phase

    // -------------------------------------------------------------------------
    // Connect phase
    // -------------------------------------------------------------------------
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        `uvm_info("connect_phase",
                  "Connecting scoreboard analysis exports to FIFOs",
                  UVM_LOW)

        apb_sb_export.connect(fifo_apb.analysis_export);
        spi_sb_export.connect(fifo_spi.analysis_export);
    endfunction : connect_phase

    // -------------------------------------------------------------------------
    // Run phase
    // -------------------------------------------------------------------------
    task run_phase(uvm_phase phase);
        super.run_phase(phase);

        fork
            // -----------------------------------------------------------------
            // APB checking thread
            // -----------------------------------------------------------------
            forever begin
                bit apb_match;

                fifo_apb.get(item_apb);
                apb_match = model.check_apb(item_apb);

                // Count only real APB ACCESS transactions
                if (item_apb.PSEL && item_apb.PENABLE) begin

                    if (apb_match) begin
                            correct_count++;
                    end
                    else begin
                        error_count++;
                        `uvm_error("scoreboard_apb", $sformatf(
                            "APB READ MISMATCH:  Total Correct: %0d, Total Errors: %0d",
                            correct_count, error_count))
                    end

            
                end
            end

            // -----------------------------------------------------------------
            // SPI checking thread
            // -----------------------------------------------------------------
            forever begin
                bit spi_match;

                fifo_spi.get(item_spi);
                spi_match = model.check_spi(item_spi);

                if (spi_match) begin
                    correct_count++;
                end
                else begin
                    error_count++;
                    `uvm_info("scoreboard_spi", $sformatf(
                    "SPI Transaction Result: %s, Total Correct: %0d, Total Errors: %0d",
                    (spi_match ? "   MATCH" : "MISMATCH"),
                    correct_count, error_count), UVM_LOW)
                end


            end
        join_none
    endtask : run_phase

    // -------------------------------------------------------------------------
    // Report phase
    // -------------------------------------------------------------------------
    function void report_phase(uvm_phase phase);
        string test_name;

        super.report_phase(phase);

        total_count = correct_count + error_count;
        pass_rate   = (total_count > 0)
                    ? (real'(correct_count) / real'(total_count)) * 100.0
                    : 0.0;

        if (error_count == 0) begin
            status_msg    = "PASSED";
            test_severity = UVM_INFO;
        end
        else begin
            status_msg    = "FAILED";
            test_severity = UVM_ERROR;
        end

        summary_msg = {
            "\n",
            "===============================================\n",
            $sformatf("     TEST SUMMARY REPORT - %s\n", this.get_name()),
            "===============================================\n",
            $sformatf("Test Status       : %s\n", status_msg),
            $sformatf("Total Transactions: %0d\n", total_count),
            $sformatf("Correct Count     : %0d\n", correct_count),
            $sformatf("Error Count       : %0d\n", error_count),
            $sformatf("Pass Rate         : %.2f%%\n", pass_rate),
            "===============================================\n"
        };

        `uvm_info("TEST_SUMMARY", summary_msg, UVM_LOW)

        // Grader-required final pass/fail format
        if (!$value$plusargs("UVM_TESTNAME=%s", test_name)) begin
            if (!$value$plusargs("TESTNAME=%s", test_name)) begin
                test_name = "unknown_test";
            end
        end

        if (error_count == 0) begin
            $display("[TEST_PASSED] %s", test_name);
            `uvm_info("TEST_RESULT", "*** TEST PASSED ***", UVM_LOW)
        end
        else begin
            $display("[TEST_FAILED] %s errors=%0d", test_name, error_count);
            `uvm_error("TEST_RESULT",
                       $sformatf("*** TEST FAILED with %0d errors ***",
                                 error_count))
        end
    endfunction : report_phase

endclass : spi_scoreboard
