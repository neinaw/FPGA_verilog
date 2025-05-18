## Discrete Cosine Transform (DCT) over Ethernet

### Overview

This project implements a hardware-accelerated 64-point Discrete Cosine Transform (DCT) over Ethernet using a pure Layer 2 (IEEE 802.3) network. A host PC sends a 64-byte signed input vector to an FPGA (Nexys A7-100T), which computes the DCT and returns the result over Ethernet. Communication occurs directly over Ethernet using LLC frames without IP or TCP/UDP.

### System Architecture
1. **Ethernet MAC**: The Ethernet MAC processes raw IEEE 802.3 frames. It includes internal 1024-byte FIFOs on both the receive and transmit paths and exposes AXI-Stream interfaces in both directions. Incoming frames are streamed to downstream logic via an 8-bit AXI-Stream receiver interface. The transmitter accepts outgoing data via a matching AXI-Stream interface and sends it in 64-byte payload chunks.
2. **AXI-Stream DCT**: This core performs a 64-point DCT on signed 16-bit input values. Since the MAC streams 8-bit data, the DCT core receives 128 bytes, reconstructs them into 64 signed 16-bit integers, and computes the transform. The result is then streamed to the transmit-side AXI-Stream interface of the MAC for transmission back to the host. The core is implemented using Vitis HLS 2024.2 and located in ```hw/HLS```.

3. **Host Application**: The host software is written in Python. It constructs raw Ethernet frames using ```scapy``` and transmits them over a raw socket interface. Upon receiving a response, the payload is parsed into signed integers and printed to the terminal.


### Usage

#### Running the Host Script

To send an input vector and receive the computed DCT: (Under ```sw/dct.py```)

    $ sudo python3 dct.py

The DCT result will be printed to the terminal upon receipt.
#### Debugging

- **Logic Debugging**: Performed using Vivado ILA for monitoring internal signals.
- **Ethernet Traffic Monitoring**: Wireshark is used to observe raw Ethernet frame exchanges.