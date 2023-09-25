LD=riscv-none-elf-gcc 
GCC=riscv-none-elf-gcc
OBJ=riscv-none-elf-objcopy
B2H = ../common/bin2hex

B2H = ../common/bin2hex
export objcopy := $(OBJ)
export bin2hex := $(B2H)

CFLAGS= -I./barebones -I. -c -march=rv32izbs -mabi=ilp32 -O2 -ffreestanding -fno-zero-initialized-in-bss -DPERFORMANCE_RUN=1 -DITERATIONS=150
CCFLAGS= -I./barebones -I. -c -march=rv32iczbs -mabi=ilp32 -O2  -ffreestanding -fno-zero-initialized-in-bss -DPERFORMANCE_RUN=1 -DITERATIONS=150
LDFLAGS=  -nostdlib -Tyrv.ld  -nostartfiles -nostdlib
#-mcmodel=medany
all:code_demo.mem32
trap_ack.o:trap_ack.s
	$(GCC) $(CFLAGS) -o $@ $^

eset_led.o:eset_led.s
	$(GCC) $(CFLAGS) -o $@ $^

nmi_vec.o:nmi_vec.s
	$(GCC) $(CFLAGS) -o $@ $^

dbg_vec.o:dbg_vec.s
	$(GCC) $(CFLAGS) -o $@ $^

crt0.o:crt0.s
	$(GCC) $(CFLAGS) -o $@ $^

core_list_join.o:core_list_join.c
	$(GCC) $(CFLAGS) -o $@ $^

core_main.o:core_main.c
	$(GCC) $(CCFLAGS) -DFLAGS_STR="" -DCOMPILER_FLAGS="\"\"" -o $@ $^

core_matrix.o:core_matrix.c
	$(GCC) $(CCFLAGS) -o $@ $^

core_state.o:core_state.c
	$(GCC) $(CCFLAGS) -o $@ $^

core_util.o:core_util.c
	$(GCC) $(CCFLAGS) -o $@ $^

memset.o:memset.c
	$(GCC) $(CFLAGS) -o $@ $^

memcpy.o:memcpy.c
	$(GCC) $(CFLAGS) -o $@ $^

bcopy.o:bcopy.c
	$(GCC) $(CFLAGS) -o $@ $^

memmove.o:memmove.c
	$(GCC) $(CFLAGS) -o $@ $^

strlen.o:strlen.c
	$(GCC) $(CFLAGS) -o $@ $^

core_portme.o:barebones/core_portme.c
	$(GCC) $(CFLAGS) -o $@ $^

ee_printf.o:barebones/ee_printf.c
	$(GCC) $(CCFLAGS) -o $@ $^

cvt.o:barebones/cvt.c
	$(GCC) $(CFLAGS) -o $@ $^

div.o:div.S
	$(GCC) $(CFLAGS) -o $@ $^

muldi3.o:muldi3.S
	$(GCC) $(CCFLAGS) -o $@ $^


#final.elf:crt0.o eset_led.o trap_ack.o nmi_vec.o dbg_vec.o core_list_join.o core_main.o core_matrix.o core_state.o core_util.o core_portme.o ee_printf.o memset.o memcpy.o bcopy.o memmove.o strlen.o
#	$(GCC) $(LDFLAGS) -o $@ $^ static/_divsi3.o static/_modsi3.o static/_mulsi3.o static/_udivmodsi4.o static/_udivsi3.o static/_umodsi3.o 


final.elf:crt0.o eset_led.o trap_ack.o nmi_vec.o dbg_vec.o core_list_join.o core_main.o core_matrix.o core_state.o core_util.o core_portme.o ee_printf.o memset.o memcpy.o bcopy.o memmove.o strlen.o  div.o muldi3.o
	$(GCC) $(LDFLAGS) -o $@ $^ 

final:final.elf
	$(OBJ) -O binary final.elf final

code_demo.mem32: final
	python ../common/freedom-bin2hex.py  -w32  final > code_demo.mem32
	python ../common/freedom-bin2hex.py  -w16  final > code_demo.mem16

clean:
	rm -rf *.o *.elf final code_demo.mem32 code_demo.mem16