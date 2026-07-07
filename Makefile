# ==============================================================================
# Makefile for SPI Master Verification - Team24
# Simulator: QuestaSim
# ==============================================================================

SIMULATOR  ?= questa
SEED       ?= 1
TEST       ?= sanity_test
WAVES      ?= 0

# -- Root paths ----------------------------------------------------------------
PROJ_ROOT  ?= .
TB_DIR     ?= $(PROJ_ROOT)/tb

# -- DUT sources ---------------------------------------------------------------
DUT_SRCS   ?= \
    $(PROJ_ROOT)/golden_rtl/spi_core.sv \
    $(PROJ_ROOT)/golden_rtl/apb_regfile.sv \
    $(PROJ_ROOT)/golden_rtl/spi_master.sv

ifneq ($(DUT_SRC),)
    DUT_SRCS := $(DUT_SRC)
endif

# -- Environment source files --------------------------------------------------
ENV_SRCS = env/spi_master_pkg.sv
SEQ_SRCS = 
ASSERT_SRCS = assertions/spi_sva.sv
TEST_SRCS = 

# -- Testbench & Interfaces ----------------------------------------------------
TB_SRCS = \
    tb/apb_interface.sv \
    tb/spi_interface.sv \
    tb/tb_top.sv

# -- Regression configuration --------------------------------------------------
REGRESSION_TESTS = sanity_test full_req_test
REGRESSION_SEEDS ?= 5

# -- Compiler flags ------------------------------------------------------------
INC_DIRS = \
    +incdir+$(TB_DIR) \
    +incdir+./env \
    +incdir+./env/agents \
    +incdir+./env/drivers \
    +incdir+./env/monitors \
    +incdir+./env/scoreboard \
    +incdir+./env/sequence_items \
    +incdir+./env/sequencers \
    +incdir+./sequences \
    +incdir+./tests \
    +incdir+./tb

VLOG_FLAGS = \
    -sv \
    -timescale 1ns/1ps \
    +acc=rn \
    +define+SIM \
    $(INC_DIRS) \
    -L mtiUvm

COV_FLAG = +cover=bcestf

BONUS_TEST ?= ral_hw_reset_test

# ==============================================================================
# TARGETS
# ==============================================================================

clean:
	rm -rf work build *.wlf *.ucdb transcript coverage_report.txt

compile:
	mkdir -p build
	vlib work
	vlog $(VLOG_FLAGS) $(COV_FLAG) \
		$(DUT_SRCS) \
		$(ENV_SRCS) \
		$(SEQ_SRCS) \
		$(ASSERT_SRCS) \
		$(TEST_SRCS) \
		$(TB_SRCS)

run:
	mkdir -p build
	vsim -coverage -c work.spi_master_top \
		-do "coverage save -onexit build/cov_$(TEST)_$(SEED).ucdb; run -all; quit -f" \
		+TESTNAME=$(TEST) \
		+UVM_TESTNAME=$(TEST) \
		+SEED=$(SEED) \
		$(if $(filter 1,$(WAVES)),-wlf build/waves_$(TEST)_$(SEED).wlf,) \
		> build/log_$(TEST)_$(SEED).log 2>&1

regress: compile
	make run TEST=sanity_test SEED=1
	make run TEST=sanity_test SEED=2
	make run TEST=sanity_test SEED=3
	make run TEST=sanity_test SEED=4
	make run TEST=sanity_test SEED=5
	make run TEST=full_req_test SEED=1
	make run TEST=full_req_test SEED=2
	make run TEST=full_req_test SEED=3
	make run TEST=full_req_test SEED=4
	make run TEST=full_req_test SEED=5
	vcover merge -out build/merged.ucdb build/cov_*.ucdb

cov:
	vcover report -details -output coverage_report.txt build/merged.ucdb

run_bonus:
	vsim -c work.spi_master_top \
		-do "run -all; quit -f" \
		+UVM_TESTNAME=$(BONUS_TEST) \
		+SEED=$(SEED)