import sys
import binascii

data = sys.stdin.buffer.read()
if len(data) % 4 != 0:
    raise Exception("Bad length")

for i in range(0, len(data), 4):
    print(binascii.hexlify(data[i:i+4]).decode("utf-8"))
