from scapy.all import Ether, hexdump, sendp, get_if_list, get_if_hwaddr
# Target and source MAC addresses
my_dest = "00:18:3e:04:b3:f2"
my_src = "00:E0:4C:68:07:D8"

# Payload
# payload = "A different 64 byte payload -> Hi, This is my first FPGA project"
payload = "A smaller payload! Checking zero pad"
length = len(payload)

# Build Ethernet frame
eth_frame = Ether(dst=my_dest, src=my_src, type=length) / payload

# Display the frame info
eth_frame.show()
hexdump(eth_frame)

iface = None

for i in get_if_list():
    try:
        if get_if_hwaddr(i).lower() == my_src.lower():
            iface = i
            break
    except:
        continue

if not iface:
    raise ValueError("Could not find interface with target MAC")

sendp(eth_frame, iface=iface, verbose=True)
