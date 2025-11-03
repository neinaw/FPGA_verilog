#### Name: AXIS-FIFO
#### Version: 0.1
#### Author: Ansh Waikar

#### Overview:

An atomic FIFO Unit with AXI-S interface. Supports dropping a frame entirely. A frame is a data segment complete with a first and last. For use in situations where an entire packet/frame needs to be buffered. No partial frames. A frame is either in the buffer in its entireity or not.

A frame is presented at the output only after it is completely buffered in the FIFO.
#### Port/Interface list

Write channel
1. -> `TVALID`
2. -> `TDATA [1:n]`
3. <- `TREADY`
4. -> `TLAST`
5. -> `bad_frame (TUSER)`

Read channel
1. <- `TVALID`
2. <- `TDATA [1:n]`
3. -> `TREADY`
4. <- `TLAST`

#### Drop Frame Behaviour

1. If `bad_frame` is asserted at any time between the first valid and last

2. If FIFO gets full before `TLAST`