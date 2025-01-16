## Ethernet Echo Server

### Overview

This project implements an Ethernet echo server, compliant with IEEE 802.3. It can echo a payload of at least 64 bytes. The design is purely Layer 2 (LLC). Uses wireshark for data visualization. Much of this project is taken from HDLForBeginners [github](https://github.com/HDLForBeginners/Toolbox/blob/main/ip_repo/rmii_axis_1_0/src/packet_gen.sv).

1. **CRC Validation**: The receiver has a built-in CRC (Cyclic Redundancy Check) validation mechanism. Frames with bad CRCs are discarded entirely.

2. **Payload Echo**: Only the data payload intended for the FPGA is echoed back. Other fields in the Ethernet frame are not echoed.
3. **Buffering**: At the receiver, The data payloads of the incoming frames are buffered in a FIFO. The FIFO has an AXI-Stream interface to read the payload. At the transmitter, there is an input buffer (FIFO). Data is streamed into the FIFO using AXI-S again. We wait for the payload to be at least 64 bytes.


### Usage

#### Sending a frame (echo out)

Use the send_packet.py script to send Ethernet frames to the FPGA (requires scapy). Monitor traffic on the interface using wireshark.

    $ sudo python3 send_packet.py

#### Receiving (echo in)

Use wireshark to see the received packet on the network interface.

### Example

Sent frame (echo out)

```
###[ Ethernet ]###
  dst       = 00:18:3e:04:b3:f2
  src       = 54:e1:ad:33:0d:32
  type      = 0x40
###[ Raw ]###
     load      = b'(A 64 byte payload) Sending (Hello, World!) to FPGA from this PC'

Hexdump:

0000  00 18 3E 04 B3 F2 54 E1 AD 33 0D 32 00 40 28 41  ..>...T..3.2.@(A
0010  20 36 34 20 62 79 74 65 20 70 61 79 6C 6F 61 64   64 byte payload
0020  29 20 53 65 6E 64 69 6E 67 20 28 48 65 6C 6C 6F  ) Sending (Hello
0030  2C 20 57 6F 72 6C 64 21 29 20 74 6F 20 46 50 47  , World!) to FPG
0040  41 20 66 72 6F 6D 20 74 68 69 73 20 50 43        A from this PC

```

Received frame (echo in). Note the switched ```dst``` and ```src``` fields.
```
###[ Ethernet ]###
  dst       = 54:e1:ad:33:0d:32
  src       = 00:18:3e:04:b3:f2
  type      = 0x40
###[ Raw ]###
     load      = b'(A 64 byte payload) Sending (Hello, World!) to FPGA from this PC'

Hexdump:

0000  54 E1 AD 33 0D 32 00 18 3E 04 B3 F2 00 40 28 41  T..3.2..>....@(A
0010  20 36 34 20 62 79 74 65 20 70 61 79 6C 6F 61 64   64 byte payload
0020  29 20 53 65 6E 64 69 6E 67 20 28 48 65 6C 6C 6F  ) Sending (Hello
0030  2C 20 57 6F 72 6C 64 21 29 20 74 6F 20 46 50 47  , World!) to FPG
0040  41 20 66 72 6F 6D 20 74 68 69 73 20 50 43        A from this PC

```

### Dependencies

1. ```scapy``` - python library for crafting and sending packets

2. Clock Wizard IP - AMD/Xilinx provided IP for clock generation at the desired frequency.

### Future Improvements:

1. The transmitter is limited because it can only trasmit a payload that is at least 64 bytes long. It does not support padding.
2. I want to make this robust enough to implement higher layers of the network stack on top of this (ARP, ICMP, etc.)
