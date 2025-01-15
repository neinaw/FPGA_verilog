from scapy.all import Ether, hexdump, sendp
# 00183e04b3f2
broadcast = "00:18:3e:04:b3:f2"  # broadcast this frame
my_src = "54:e1:ad:33:0d:32"  # MAC address of this computer
# payload = "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
# payload = "(A 64 byte payload) Sending (Hello, World!) to FPGA from this PC"
payload = "A different 64 byte payload -> Hi, This is my first FPGA project"
length = len(payload)
# payload = 64*chr(65)

eth_frame = Ether(dst=broadcast, src=my_src, type=length)

eth_frame = eth_frame / payload

eth_frame.show()

hexdump(eth_frame)

sendp(eth_frame, iface="enp0s31f6")
