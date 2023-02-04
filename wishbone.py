#!/usr/bin/python
#-------------------------------------------------------------------------------
# PROJECT: SIMPLE UART FOR FPGA
#-------------------------------------------------------------------------------
# AUTHORS: Jakub Cabal <jakubcabal@gmail.com>
# LICENSE: The MIT License, please read LICENSE file
# WEBSITE: https://github.com/jakubcabal/uart-for-fpga
#-------------------------------------------------------------------------------

import serial
import time

byteorder="little"

class wishbone:
    def __init__(self, port="COM5", baudrate=115200):
        self.uart = serial.Serial(port, baudrate, timeout=2)
        print("The UART on " + self.uart.name + " is open.")
        print("The wishbone bus is ready.\n")

    def read(self,addr):
        cmd = 0x0
        cmd = cmd.to_bytes(1,byteorder)
        self.uart.write(cmd)
        addr = addr.to_bytes(2,byteorder)
        self.uart.write(addr)
        rbytes=self.uart.read(1)
        rbytes=self.uart.read(4)
        drd=int.from_bytes(rbytes,byteorder)
        return drd

    def write(self, addr, data):
        cmd = 0x1
        cmd = cmd.to_bytes(1,byteorder)
        self.uart.write(cmd)
        addr = addr.to_bytes(2,byteorder)
        self.uart.write(addr)
        data = data.to_bytes(4,byteorder)
        self.uart.write(data)
        rbytes=self.uart.read(1)

    def close(self):
        self.uart.close()

if __name__ == '__main__':
    print("Test of access to CSR (control status registers) via UART2WBM module...")
    print("=======================================================================")
    wb = wishbone("COM5")

    print("\nREAD from 0x0:")
    rd = wb.read(0x0)
    print("0x%04X" % rd)
    print("".join([chr(x) for x in bytearray(rd.to_bytes(4,"big"))]))

    print("\nREAD from 0x1:")
    rd = wb.read(0x1)
    print("0x%04X" % rd)
    print("".join([chr(x) for x in bytearray(rd.to_bytes(4,"big"))]))


    # Enable writing
    wb.write(0xff, 0xffffffff)

    # Now we write target digest MD5("ab") = 187ef4436122d1cc2f40dc2b92f0eba0

    # 0 187ef443
    # 1 6122d1cc
    # 2 2f40dc2b
    # 3 92f0eba0
    wb.write(0x10, 0x187ef443)
    wb.write(0x11, 0x6122d1cc)
    wb.write(0x12, 0x2f40dc2b)
    wb.write(0x13, 0x92f0eba0)

    # Disable writing
    wb.write(0xff, 0x0)

    # This didnt work so there is chance i f* up the design
    print("\nREAD from 0x10:")
    rd = wb.read(0x10)
    print("0x%04X" % rd)

    print("\nREAD from 0x11:")
    rd = wb.read(0x11)
    print("0x%04X" % rd)

    print("\nREAD from 0x12:")
    rd = wb.read(0x12)
    print("0x%04X" % rd)

    print("\nREAD from 0x13:")
    rd = wb.read(0x13)
    print("0x%04X" % rd)

    print("\nREAD from 0xff:")
    rd = wb.read(0xff)
    print("0x%04X" % rd)


    # Suppose it did work, abc should be cracked very fast

    # Enable writing
    wb.write(0xff, 0xffffffff)
    # crack_en
    wb.write(0x0f, 0xffffffff)

    wb.write(0xff, 0x0)


    # We now busywait
    rd = wb.read(0x0e)
    while rd == 0:
        time.sleep(1)
        rd = wb.read(0x0e)

    print(35 * '=' + "\nFound\n" + 35 * '=')

    print("\nREAD from 0x20:")
    rd = wb.read(0x20)
    print("0x%04X" % rd)

    print("\nREAD from 0x21:")
    rd = wb.read(0x21)
    print("0x%04X" % rd)






    wb.close()
    print("\nThe UART is closed.")
