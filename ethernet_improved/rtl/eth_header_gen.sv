import ethernet_header_pkg::*;

module eth_header_gen (
    input logic [47:0] src_mac = 48'he86a64e7e830,
    input logic [47:0] dst_mac = 48'he86a64e7e829,
    input logic [15:0] ethertype = 128,
    output ethernet_header output_header
);

  ethernet_header header;

  // Endian switch parameters
  endian_switch #(
      .BYTE_SIZE  (8),
      .INPUT_BYTES(6)
  ) endian_switch_src_mac (
      .in(src_mac),
      .out_array(header.mac_source)
  );
  endian_switch #(
      .BYTE_SIZE  (8),
      .INPUT_BYTES(6)
  ) endian_switch_dest_mac (
      .in(dst_mac),
      .out_array(header.mac_destination)
  );
  endian_switch #(
      .BYTE_SIZE  (8),
      .INPUT_BYTES(2)
  ) endian_switch_ipv4_length (
      .in(ethertype),
      .out_array(header.eth_type_length)
  );

  assign output_header = header;

endmodule
