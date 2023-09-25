# 16bit YRV-Plus RISC-V CPU for OMDAZZ board with  PS/2 port and Serial port

## Scripts description
In  Plus/boards/omdazz/ run
```
  01_clean.bash                   Clean project
  05_synthesize_for_fpga.bash     Synthesize project and load ro FPGA
  06_configure_fpga.bash          Load project to FPGA
  07_upload_soft_to_fpga.bash     Upload binary using UART
  
```
You need USB-to-Serial adapter for loading binary to the FPGA Board.


## Programs Description
```
  01_hello_text        Serial port example
  01_tetris            ASCII based tetris game
```

After build you copy  _code_demo.mem16_ to the _Plus/design_ directory

You can run ./07_upload_soft_to_fpga.bash directly form source folder

## Toolchain 

Toolchain shoul be installed in:  _/opt/riscv_native_

Minimal version of GCC should be 12.1.0


## Serial port:
To use serial port switch on S1 jumper

Original serial port 

https://github.com/fpga-logi/logi-pong-chu-examples/tree/master/pong-chu-logi-edu-examples-verilog

https://onlinelibrary.wiley.com/doi/epdf/10.1002/9780470374283.ch8


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

__python bin2hex/freedom-bin2hex.py -w16 app.bin >code.mem16__

rustc -Z unstable-options --target=riscv32imac-unknown-none-elf --print target-spec-json

riscv-none-elf-objcopy.exe  -O binary ../target/riscv32ic-unknown-none-elf/release/app  app.bin

To load in FPGA

__load.bat__


