#!/bin/bash

set -euxo pipefail

crate=riscv-rt

# remove existing blobs because otherwise this will append object files to the old blobs
rm -f bin/*.a

exts=('i')

for ext in ${exts[@]}
do
    case $ext in

        *'d'*)
            abi='d'
            ;;
        
        *'f'*)
            abi='f'
            ;;
        
        *)
            abi=''
            ;;
    esac

    riscv-none-elf-gcc -ggdb3 -fdebug-prefix-map=$(pwd)=/riscv-rt -c -mabi=ilp32${abi} -march=rv32${ext} asm/yrv.s -o bin/yrv.o
    riscv-none-elf-ar crs bin/riscv32i-unknown-none-elf.a bin/yrv.o 

    
done

rm bin/yrv.o
