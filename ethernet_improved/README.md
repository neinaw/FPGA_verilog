# Improved Ethernet MAC with Echo Server

A simple, lightweight Ethernet MAC (Media Access Controller) implemented in VHDL/SystemVerilog. The top-level design is a dummy echo server that reflects all valid received packets back to the sender.

---

## 1. Changes Over the Previous Version

### 1.1 All FIFOs synthesized to BRAMs
* On the receive side, improved the AXIS-FIFO to be fully atomic and to synthesize to BRAM, without the awkward roll-back by 4 logic to trim the FCS from the data payload.
* Accordingly modified the receiver to implement a 4-stage pipeline for buffering the FCS

### 1.2 Added zero-pad support for the transmitter.
* The receiver now presents all the protected fields to the output. The payload is stored in an AXIS-FIFO as usual, and an additional header FIFO is implemented which buffers the header.
* Likewise, the transmitter can accept a header and transmit accordingly, for which there is a zero-pad state added to the FSM to handle those payloads whose lengths are less than the minimum size.

### 1.3 Added proper timing constraints
* Added proper setup, hold timing constraints for the PHY inputs to the FPGA taken from the PHY's datasheet
* There was a 45deg phase shifted clock that was sent to the PHY to account for timing which is now removed. The PHY and MAC are on the same clock
* I don't think this is proper, forums online suggest doing the latter, and latching the output signals on the negedge of the phase shifted clock, will need to check on this further.

### 1.4 Verified using transaction level testbenches
* The atomic AXIS FIFO and the receiver now have full transaction level testbenches, with a transaction generator, driver, predictor, and comparator. 
* There are no proper scenarios or a testplan as such. Instead I have tasks which model typical scenarios and edge cases.

### 1.5 Host changed to Windows from Ubuntu 20.04
* My Ubuntu Laptop broke down. The simulation is now fully through Vivado's batch mode, but with a Windows batch file (.bat) instead of the conventional shell script (.sh).
* I have more experience with shell scripts and Unix environments in general, will be migrating from Windows soon and will update the build scripts appropriately.
---

## 2. Limitations and Pitfalls

### 2.1 Echo top echoes zeros
* Because the outputs of the receiver and connected directly to the transmitter, extra zeros will slip through if the payload is shorter than the minimum size, hence corrupting all subsequent frames.
* This is as expected, as the MAC's role is finished once the frame is received. The transport layer now needs to interpret the payload, and in this case the transport layer is faulty.
---

## 3. Future Improvements and Thoughts

This is a high-level roadmap of planned features and tasks.

* **Core Logic:**
    * [ ] Implement ARP, and have it respond to arping requests.

* **Interface:**
    * [ ] Add some kind of control interface (like AXI-Lite) for control/status registers (e.g., setting MAC address, viewing statistics). A high level idea is to have a UART core be able to write to the MAC's registers.

* **Testbench:**
    * [ ] Transaction-level testbenches for the transmitter and echo top.

* **Miscellaneous**
    * I have found limited support for SystemVerilog's features with the Vivado Simulator. I have often times seen crashes of the GUI for code that works fine on VCS or other simulators that are available on EDA Playground.
    * The changes to the synthesizable subset of Verilog-2001 are minimal in my opinion, and I would rather stick to Verilog-2001 for synthesis. The only feature that I might miss is enums.
    * I'm interest in trying verilator and/or Cocotb+PyUVM for verification. They sound perfect for hobbyist level projects like mine.