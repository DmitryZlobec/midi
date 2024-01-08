OUTPUT_ARCH( "riscv" )
ENTRY(_start)
MEMORY
{
  BRAM     (rx) : ORIGIN = 0x00000000, LENGTH = 64K
}
_TRAP_ACK = 0x040;
_NMI_VECT = 0x100;
_DBG_VEC =  0x140;
_DEX_VEC =  0x1c0;
_RST_BASE = 0x200;

 SECTIONS
 {

 PROVIDE(__stack_top = ORIGIN(BRAM) + LENGTH(BRAM));
 PROVIDE(__pre_init = default_pre_init);
 PROVIDE(_mp_hook = default_mp_hook);
 PROVIDE(_heap_size = 2k);

 .text :
 {
    *(.text.init)
    *(.init.rust)
	*(.text.main)
    *(.text)
 }>BRAM 

 .rodata :
 {  
    . = ALIGN(4);
    *(.rodata)
 }> BRAM

 .data :
 {  _sidata = LOADADDR(.data);
    _sdata = .;
    *(.data)
    _edata = .;
 }> BRAM

 .sdata :
 {  
    . = ALIGN(4);
    PROVIDE( __global_pointer$ = . + 0x800);
    *(.sdata)
 }> BRAM

 .bss :
 {  _sbss = .;
    . = ALIGN(4);
    *(.bss)
    _ebss = .;
 }> BRAM

 .sbss :
 {  
    . = ALIGN(4);
    *(.sbss)
 }> BRAM


  .heap (NOLOAD) :
  {
    _sheap = .;
    . += _heap_size;
    . = ALIGN(4);
    _eheap = .;
  } > BRAM

  /DISCARD/ :
  {
    *(.note.gnu.build-id)
    *(.riscv.attributes)
    *(.comment)
  }
 

_end = .;
 }