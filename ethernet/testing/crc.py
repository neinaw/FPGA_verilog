import sys


def crc_gen(crcIn, data):
    class bitwrapper:
        def __init__(self, x):
            self.x = x

        def __getitem__(self, i):
            return (self.x >> i) & 1

        def __setitem__(self, i, x):
            self.x = (self.x | (1 << i)) if x else (self.x & ~(1 << i))

    crcIn = bitwrapper(crcIn)
    data = bitwrapper(data)
    ret = bitwrapper(0)
    ret[0] = crcIn[2]
    ret[1] = crcIn[3]
    ret[2] = crcIn[4]
    ret[3] = crcIn[5]
    ret[4] = crcIn[0] ^ crcIn[6] ^ data[0]
    ret[5] = crcIn[1] ^ crcIn[7] ^ data[1]
    ret[6] = crcIn[8]
    ret[7] = crcIn[0] ^ crcIn[9] ^ data[0]
    ret[8] = crcIn[0] ^ crcIn[1] ^ crcIn[10] ^ data[0] ^ data[1]
    ret[9] = crcIn[1] ^ crcIn[11] ^ data[1]
    ret[10] = crcIn[12]
    ret[11] = crcIn[13]
    ret[12] = crcIn[14]
    ret[13] = crcIn[15]
    ret[14] = crcIn[0] ^ crcIn[16] ^ data[0]
    ret[15] = crcIn[1] ^ crcIn[17] ^ data[1]
    ret[16] = crcIn[18]
    ret[17] = crcIn[19]
    ret[18] = crcIn[0] ^ crcIn[20] ^ data[0]
    ret[19] = crcIn[0] ^ crcIn[1] ^ crcIn[21] ^ data[0] ^ data[1]
    ret[20] = crcIn[0] ^ crcIn[1] ^ crcIn[22] ^ data[0] ^ data[1]
    ret[21] = crcIn[1] ^ crcIn[23] ^ data[1]
    ret[22] = crcIn[0] ^ crcIn[24] ^ data[0]
    ret[23] = crcIn[0] ^ crcIn[1] ^ crcIn[25] ^ data[0] ^ data[1]
    ret[24] = crcIn[1] ^ crcIn[26] ^ data[1]
    ret[25] = crcIn[0] ^ crcIn[27] ^ data[0]
    ret[26] = crcIn[0] ^ crcIn[1] ^ crcIn[28] ^ data[0] ^ data[1]
    ret[27] = crcIn[1] ^ crcIn[29] ^ data[1]
    ret[28] = crcIn[0] ^ crcIn[30] ^ data[0]
    ret[29] = crcIn[0] ^ crcIn[1] ^ crcIn[31] ^ data[0] ^ data[1]
    ret[30] = crcIn[0] ^ crcIn[1] ^ data[0] ^ data[1]
    ret[31] = crcIn[1] ^ data[1]
    return ret.x


if __name__ == "__main__":
    if len(sys.argv) == 1:
        print("In two bit at a time mode")
        crcIn = 0xFFFFFFFF
        while True:
            datain_2bit = int(input("[0=0b00, 1=0b01, 2=0b10, 3=0b11] ?: "))
            if datain_2bit in [0, 1, 2, 3]:
                crcout = crc_gen(crcIn, datain_2bit)
                print(hex(crcout ^ 0xFFFFFFFF))

            else:
                print("Input an interger in [0, 1, 2, 3] only!")

    else:
        arg = sys.argv[1]
        if arg == "-r":
            print("In running crc mode")
            crcIn = 0xFFFFFFFF
            while True:
                datain_2bit = int(input("[0, 1, 2, 3] ?:\t"))
                if datain_2bit in [0, 1, 2, 3]:
                    crcout = crc_gen(crcIn, datain_2bit)
                    print(hex(crcout ^ 0xFFFFFFFF))
                    crcIn = crcout

                else:
                    print("Input an interger in [0, 1, 2, 3] only!")

        else:
            print("ERROR! -r for running CRC mode!")
