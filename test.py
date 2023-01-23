import serial

s = serial.Serial()
s.baudrate = 115200
s.port = 'COM5'

def send(data: bytes):
    s.open()
    s.write(data)
    s.close()

def receive(data_length: int):
    s.open()
    data = []
    read = 0
    while read < data_length:
        x = s.read(1)
        read += 1
        print(x)
    s.close()
