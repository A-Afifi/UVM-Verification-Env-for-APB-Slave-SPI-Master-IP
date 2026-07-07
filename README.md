# UVM Verification Environment for APB-Slave SPI Master IP

## Project Overview
This repository contains a comprehensive Universal Verification Methodology (UVM) verification environment for an APB-slave SPI Master Controller. The project was developed as a Final Project for the Digital Design Verification course at Ain Shams University.

## Design Under Test (DUT)
The DUT is a synthesizable SPI Master Controller featuring a 32-bit APB slave interface that bridges the processor-side APB bus with external SPI devices. Key hardware features include:
* Support for 8-bit, 16-bit, and 32-bit transfer widths.
* Compatibility with all four standard SPI operating modes.
* Programmable clock division and four active-low slave-select outputs.
* Loopback operation, dedicated TX/RX FIFOs, and programmable inter-transfer delay.
* Masked sticky interrupt generation with Write-1-to-Clear (W1C) clearing behavior.

## Verification Architecture
The verification environment implements a modular, layered UVM architecture:
* **APB Agent:** Generates and monitors register transactions across the APB interface.
* **SPI Agent:** Monitors serial communication behavior and protocol timing on the SPI interface.
* **Reference Model:** Provides a cycle-independent prediction of expected DUT behavior, serving as the golden model for functional checking.
* **Scoreboard:** Executes automated end-to-end validation by comparing DUT outputs against reference model predictions.
* **SystemVerilog Assertions (SVA):** Externally bound to the DUT hierarchy to validate protocol compliance, MOSI timing relationships, loopback functionality, and SCLK idle-state restoration.

## Test Plan & Sequences
The verification plan is mapped directly to 25 specification requirements (R1-R25) utilizing a reusable sequence library:
* `r1_r2_reg_seq`: Verifies register read/write operations and reset-value integrity.
* `r4_r8_spi_protocol_seq`: Validates SPI mode behavior, MOSI timing, bit ordering, transfer width, and SCLK divider configurations.
* `r9_r15_fifo_seq`: Evaluates TX/RX FIFO ordering, depth boundaries, full/empty conditions, and overflow handling.
* `r16_r18_irq_seq`: Tests interrupt masking, sticky status bits, W1C operations, and W1C race condition handling.
* **Main Tests:** Comprises `sanity_test` for initial bring-up and `full_req_test` as the primary regression test encompassing all functional requirements.

## Coverage & Regression Results
Coverage closure was achieved via directed sequences, functional coverage collection, and assertion-based verification.
* **Regression Pass Rate:** 100.00% across 31,907 total transactions with zero reported errors.
* **Functional Covergroup Coverage:** 100.00%.
* **Assertion Coverage:** 100.00% for both the Register File and SPI Core blocks.
* **Top-Level Statement Coverage:** 100.00%.
* **DUT Toggle Coverage:** 98.69%.

## Contributors
* Hesham Nabil Hosny Maher
* Mahmoud Hesham Abdelmoniem
* Ahmed Hamdy Elhusseiny
* Mohamed Ibrahim Elmonier
* Ahmed Mohamed Afifi
* Moamen Ali Gad
* Kareem Mousa Mahmoud
