import sys
import binascii

data = sys.stdin.buffer.read()
if len(data) % 4 != 0:
    raise Exception("Bad length")

for i in range(0, 4096, 4):
    if i < len(data):
        part = bytes([
            data[i+3], data[i+2], data[i+1], data[i]
        ])
    else:
        part = bytes([0, 0, 0, 0])
    print(binascii.hexlify(part).decode("utf-8"))
