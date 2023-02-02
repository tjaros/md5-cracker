#!/usr/bin/python
#-------------------------------------------------------------------------------
# PROJECT: SIMPLE UART FOR FPGA
#-------------------------------------------------------------------------------
# AUTHORS: Jakub Cabal <jakubcabal@gmail.com>
# LICENSE: The MIT License, please read LICENSE file
# WEBSITE: https://github.com/jakubcabal/uart-for-fpga
#-------------------------------------------------------------------------------

import serial

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

    print("\nREAD from 0x3:")
    rd = wb.read(0x2)
    print("0x%04X" % rd)
    print("".join([chr(x) for x in bytearray(rd.to_bytes(4,"big"))]))

    wb.close()
    print("\nThe UART is closed.")
