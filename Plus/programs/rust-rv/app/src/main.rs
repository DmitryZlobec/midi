#![no_std]
#![no_main]

extern crate panic_halt;
extern crate riscv_rt;
mod serial;
mod timer;
mod dht11;
use riscv_rt::entry;

const NOTE_A:u8 =0x41;
const NOTE_B:u8 =0x42;
const NOTE_C:u8 =0x43;
const NOTE_D:u8 =0x44;
const NOTE_E:u8 =0x45;
const NOTE_F:u8 =0x46;
const NOTE_G:u8 =0x47;
const Bb:u8 =0x73;
const NOTE_ZERO:u8 =0x5F;


#[entry]
fn main() -> ! {
   let mut k =0;  
   let mut temp; //= dht11::temperature();
   println!();
   println!("Music recognition started:");

   loop {
    unsafe { 
        core::arch::asm!(
                       "lui    t0,0xffff0",
                       "lh {}, 16(t0)",
                       out(reg) temp	
    ); }
    if temp >0 {
    println!(" Note:{}",temp);
    match temp {
            1 => serial::write(NOTE_B),
            2 => {serial::write(NOTE_A); serial::write(Bb)},
            4 => serial::write(NOTE_A),
            8 => {serial::write(NOTE_G); serial::write(Bb)},
            16 => serial::write(NOTE_G),
            32 => {serial::write(NOTE_F); serial::write(Bb)},
            64 => serial::write(NOTE_F),
            128 => serial::write(NOTE_E),
            256 => {serial::write(NOTE_D); serial::write(Bb)},
            512 => serial::write(NOTE_D),
            1024 => {serial::write(NOTE_C); serial::write(Bb)},
            2048 => serial::write(NOTE_C),
            _ =>  unsafe { core::arch::asm!("nop"); },
        };
        k = temp;
        // for i in 0..100000 {
        //     unsafe { core::arch::asm!("nop"); }
        // }   
    }
    for i in 0..50000 {
        unsafe { core::arch::asm!("nop"); }
    }   
   }

   loop {
   }
}

#[export_name = "_mp_hook"]
pub extern "Rust" fn mp_hook(_hartid: usize) -> bool {
    true
}

