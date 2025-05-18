from scapy.all import Ether, sendp, Raw
import struct
import socket

ETH_P_ALL = 0x0003
iface = "enp0s31f6"

# MAC addresses
dest_mac = "00:18:3e:04:b3:f2"
src_mac = "54:e1:ad:33:0d:32"

# Ethernet header to match on reply
expected_header = bytes.fromhex(
    src_mac.replace(":", "") + dest_mac.replace(":", ""))


def create_raw_socket(interface):
    try:
        s = socket.socket(socket.AF_PACKET, socket.SOCK_RAW,
                          socket.htons(ETH_P_ALL))
        s.bind((interface, 0))
        return s
    except PermissionError:
        print("Permission denied: Run as root or with sudo.")
        exit(1)


def encode_payload(int_list):
    return b''.join(struct.pack('>h', val) for val in int_list)


def decode_payload(payload_bytes):
    if len(payload_bytes) % 2 != 0:
        payload_bytes = payload_bytes[:-1]
    return [struct.unpack('>h', payload_bytes[i:i+2])[0] for i in range(0, len(payload_bytes), 2)]


def send_input_vector(input_vector):
    payload = encode_payload(input_vector)
    frame = Ether(dst=dest_mac, src=src_mac,
                  type=len(payload)) / Raw(load=payload)
    print(f"calculating dct for {input_vector}")
    print("sending over ethernet")
    sendp(frame, iface=iface, verbose=False)


def listen_for_dct(sock):
    while True:
        data = sock.recv(65535)
        if data[:12] != expected_header:
            continue
        rx_frame = Ether(data)
        raw_bytes = bytes(rx_frame)
        # byte_list = list(raw_bytes)
        return decode_payload(raw_bytes[14:])


def main():
    input_vector = list(range(64))  # Values 0 to 63
    raw_socket = create_raw_socket(iface)

    send_input_vector(input_vector)
    dct_result = listen_for_dct(raw_socket)
    print(f"dct is {dct_result}")


if __name__ == "__main__":
    main()
