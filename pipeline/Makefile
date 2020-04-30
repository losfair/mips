all: simulate bootcode

simulate:
	iverilog -o mips -c project.txt

synthesis:
	yosys synthesis.ys

bootcode:
	mipsel-linux-gnu-as -o ./bootcode/boot.o ./bootcode/boot.S
	mipsel-linux-gnu-ld -T ./scripts/linker.ld -o code.elf ./bootcode/boot.o
	mipsel-linux-gnu-objcopy -O binary code.elf code.bin
	python3 ./scripts/hexencode.py < code.bin > code.txt

clean:
	rm *.elf *.bin ./bootcode/*.o mips synth.v netlist.json

.PHONY: simulate synthesis bootcode clean
