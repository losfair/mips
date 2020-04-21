all: hardware bootcode

hardware:
	iverilog -o mips -c project.txt

bootcode:
	mipsel-linux-gnu-gcc -ffreestanding -nostdlib -c -o ./bootcode/boot.o ./bootcode/boot.S
	mipsel-linux-gnu-ld -T ./scripts/linker.ld -o code.elf ./bootcode/boot.o
	mipsel-linux-gnu-objcopy -O binary code.elf code.bin
	python3 ./scripts/hexencode.py < code.bin > code.txt

clean:
	rm *.elf *.bin ./bootcode/*.o code.txt mips

.PHONY: bootcode clean
