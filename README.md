# MIDI Sender with 16bit YRV-Plus RISC-V CPU for DE0-CV

## Scripts description
In  Plus/boards/de0-cv/ run
```
  01_clean.bash                   Clean project
  05_synthesize_for_fpga.bash     Synthesize project and load ro FPGA
  06_configure_fpga.bash          Load project to FPGA
  07_upload_soft_to_fpga.bash     Upload binary using UART
  
```
You need USB-to-Serial adapter for loading binary to the FPGA Board.


## Programs Description
```
  rust-rv        Rust RISC-V YRV Framework
```

It based on https://github.com/rust-embedded/riscv-rt 

After build you copy  _code_demo.mem16_ to the _Plus/design_ directory

You can run ./07_upload_soft_to_fpga.bash directly form source folder

## Toolchain 

Toolchain shoul be installed in:  _/opt/riscv_native_

Minimal version of GCC should be 12.1.0


## Serial port:
To use serial port switch on S1 jumper

Original serial port 

https://github.com/DmitryZlobec/uart


## Related books:
"Inside An Open-Source Processor" ISBN 978-3-89576-443-1 Author, Monte Dalrymple

"Modern C." Manning, 2019, 9781617295812. ffhal-02383654 Jens Gustedt. 

FPGA Prototyping by Verilog Examples Author(s):Pong P. Chu First published:11 June 2008

## YRV directory Rust directory
Contains Rust code of riscv_rt crate

```cpp
  $ mkdir .cargo && edit .cargo/config && cat $_
  [target.riscv32ic-unknown-none-elf]
  rustflags = [
    "-C", "link-arg=-Tlink.x"
  ]

  [build]
  target = "riscv32ic-unknown-none-elf"
```
You need to install __cargo binutils__

and

__rustup targe add riscv32i-unknown-none-elf__

to build run in __app__:

__cargo objcopy --release -- -O binary app.bin__

 __rustup toolchain install nightly__

 __rustup override set nightly__

__cargo build -Z build-std=core --target riscv32ic-unknown-none-elf.json --release__


Main build steps

__rustc -Z unstable-options --target=riscv32imac-unknown-none-elf --print target-spec-json__

__riscv-none-elf-objcopy.exe  -O binary ../target/riscv32ic-unknown-none-elf/release/app  app.bin__

__python bin2hex/freedom-bin2hex.py -w16 app.bin >code.mem16__

To load in FPGA

__load.bat__

Another build

__cargo build -Z build-std=core --target riscv32i-unknown-none-elf --release__

__riscv-none-elf-objcopy.exe  -O binary ../target/riscv32i-unknown-none-elf/release/app  app.bin__

__python bin2hex/freedom-bin2hex.py -w16 app.bin >code.mem16__



## Example
https://youtube.com/shorts/3Girmdu2oNI




Octave 	Note Numbers

   C	 C#	 D	D#	 E	F	  F#	    G	  G#	A	  A#	B

-1	0	1	2	3	4	5	6	7	8	9	10	11

0	12	13	14	15	16	17	18	19	20	21	22	23

1	24	25	26	27	28	29	30	31	32	33	34	35

2	36	37	38	39	40	41	42	43	44	45	46	47

3	48	49	50	51	52	53	54	55	56	57	58	59

4	60	61	62	63	64	65	66	67	68	69	70	71

5	72	73	74	75	76	77	78	79	80	81	82	83

6	84	85	86	87	88	89	90	91	92	93	94	95

7	96	97	98	99	100	101	102	103	104	105	106	107

8	108	109	110	111	112	113	114	115	116	117	118	119

9	120	121	122	123	124	125	126	127



cargo build -Z build-std=core --target riscv32ia-unknown-none-elf.json --release


riscv-none-elf-objcopy.exe -O binary ../target/riscv32ia-unknown-none-elf/release/app app.bin

cargo build -Z build-std=core,alloc --target riscv32ia-unknown-none-elf.json --release


