.section .text.init
.global _start
.global _run
.global redo
.global digit

           .equ  mie,    0x304
           .equ  mtvec,  0x305
           .equ  mcause, 0x342

           .equ  iobase, 0xffff0     # i/o at 0xffff0000

_start :   li    t1, 0x3f            # all leds on
eset_led:  lui   a7, iobase          # i/o page
           lhu   t0, 6(a7)           # read port3
           slli  t1, t1, 7           # align bit set data
           or    t0, t0, t1          # set status led
           sh    t0, 6(a7)           # write port3
            beq   zero, zero, _run

#############################################################
#                                                           #
#	TRAP_ACK Section                                        #
#                                                           #
#############################################################
		   
		   .org 0x040

trap_ack:  .word 0x342023f3          # csrr t2, mcause
           blt   t2, x0, int_ack

           slli  t2, t2, 1           # discard msb
           li    t1, 0x16            # ecall
           bne   t1, t2, n_ecall

           li    t1, 0x20            # bit 12
           beq   zero, zero, set_led

n_ecall:   li    t1, 0x2             # bit 8
           beq   zero, zero, set_led

int_ack:   slli  t2, t2, 1           # discard msb
           li    t1, 0x16            # eint
           bne   t1, t2, n_eint

clr_int:   lui   a7, iobase          # i/o page
           lhu   t0, 6(a7)           # read port3
           .word 0x28f29293          # bseti t0, t0, 15
           sh    t0, 6(a7)           # write port3
           .word 0x48f29293          # bclri t0, t0, 15
           sh    t0, 6(a7)           # write port3
           .word 0x30200073          # mret

n_eint:    li    t1, 0x20            # li
           blt   t2, t1, n_li

           li    t1, 0x8             # bit 10
           beq   zero, zero, main

n_li:      li    t1, 0x4             # bit 9
           beq   zero, zero, set_led

#############################################################
#                                                           #
#	NMI_VECT Section                                        #
#                                                           #
#############################################################

           .org 0x100

nmi_vec:    beq   zero, zero, _run            # bit 11

set_led:   lui   a7, iobase          # i/o page
           lhu   t0, 6(a7)           # read port3
           slli  t1, t1, 7           # align bit set data
           or    t0, t0, t1          # set status led
           sh    t0, 6(a7)           # write port3
           beq   zero, zero, main

#############################################################
#                                                           #
#	DBG_VEC Section                                         #
#                                                           #
#############################################################
		   
		   .org 0x140
		   
dbg_vec:   li    t1, 0x40            # bit 13
dset_led:  lui   a7, iobase          # i/o page
           lhu   t0, 6(a7)           # read port3
           slli  t1, t1, 7           # align bit set data
           or    t0, t0, t1          # set status led
           sh    t0, 6(a7)           # write port3
           .word 0x7b200073          # dret

#############################################################
#                                                           #
#	DEX_VEC Section                                         #
#                                                           #
#############################################################

           .org 0x1c0
		   
dex_vec:   li    t1, 0x50            # bits 13 and 11
           beq   zero, zero, dset_led

#############################################################
#                                                           #
#	RST_BASE Section                                        #
#                                                           #
#############################################################
           
		   .org 0x200


_run:
redo:
loop:

.cfi_startproc
.cfi_undefined ra
.option push
.option norelax
	  la gp, __global_pointer$
.option pop
	  la sp, __stack_top
	  add s0, sp, zero
	  jal zero, _start_rust
.cfi_endproc

