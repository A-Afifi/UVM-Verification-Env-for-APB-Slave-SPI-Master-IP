# UVM Verification Environment for APB-Slave SPI Master IP

## 📖 Project Overview
This repository contains a complete Universal Verification Methodology (UVM) verification environment for an APB-slave SPI Master Controller[cite: 3]. The project was developed as a Final Project for the Digital Design Verification course at Ain Shams University (Spring 2026)[cite: 3].

## 🎯 Design Under Test (DUT)
The DUT is a synthesizable SPI Master Controller with a 32-bit APB slave interface that bridges the processor-side APB bus with external SPI devices[cite: 3]. Key features include:
*   Support for 8-bit, 16-bit, and 32-bit transfer widths[cite: 3].
*   Support for all four SPI operating modes[cite: 3].
*   Programmable clock division and four active-low slave-select outputs[cite: 3].
*   Loopback operation, dedicated TX/RX FIFOs, and programmable inter-transfer delay[cite: 3].
*   Masked sticky interrupt generation with W1C (Write 1 to Clear) clearing behavior[cite: 3].

## 🏗️ Verification Architecture
The environment is built using a modular, layered UVM architecture[cite: 3]:
*   **APB Agent:** Generates and monitors register transactions over the APB interface[cite: 3].
*   **SPI Agent:** Monitors serial communication behavior and protocol timing from the SPI pins[cite: 3].
*   **Reference Model:** Provides cycle-independent prediction of expected DUT behavior and serves as the golden model for functional checking[cite: 3].
*   **Scoreboard:** Performs automated end-to-end validation by comparing DUT outputs against reference model predictions[cite: 3].
*   **SystemVerilog Assertions (SVA):** Bound externally to the DUT hierarchy to validate protocol compliance, MOSI timing relationships, loopback functionality, and SCLK idle-state restoration[cite: 3].

## 🧪 Test Plan & Sequences
The verification plan is strictly mapped to 25 specification requirements (R1-R25) using a reusable sequence library[cite: 3]:
*   `r1_r2_reg_seq`: Verifies register read/write behavior and reset-value correctness[cite: 3].
*   `r4_r8_spi_protocol_seq`: Verifies SPI mode behavior, MOSI timing, bit ordering, transfer width, and SCLK divider operation[cite: 3].
*   `r9_r15_fifo_seq`: Validates TX/RX FIFO ordering, depth boundary testing, full/empty behavior, and overflow handling[cite: 1, 3].
*   `r16_r18_irq_seq`: Tests interrupt masking, sticky status bits, W1C behavior, and W1C race priority[cite: 3].
*   **Main Tests:** Includes `sanity_test` for basic bring-up and `full_req_test` as the main regression test targeting all functional requirements[cite: 3].

## 📊 Coverage & Regression Results
Coverage closure was successfully achieved through a combination of directed sequences, functional coverage collection, and assertion-based verification[cite: 3].
*   **Regression Pass Rate:** 100.00% across 31,907 total transactions with 0 errors reported[cite: 3].
*   **Functional Covergroup Coverage:** 100.00%[cite: 2, 3].
*   **Assertion Coverage:** 100.00% for both the Register File and SPI Core blocks[cite: 2, 3].
*   **Top-Level Statement Coverage:** 100.00%[cite: 2, 3].
*   **DUT Toggle Coverage:** 98.69%[cite: 2, 3].

## 👥 Contributors
*   Hesham Nabil Hosny Maher[cite: 3]
*   Mahmoud Hesham Abdelmoniem[cite: 3]
*   Ahmed Hamdy Elhusseiny[cite: 3]
*   Mohamed Ibrahim Elmonier[cite: 3]
*   Ahmed Mohamed Afifi[cite: 3]
*   Moamen Ali Gad[cite: 3]
*   Kareem Mousa Mahmoud[cite: 3]
