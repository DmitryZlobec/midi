#![no_std]
#![no_main]

extern crate panic_halt;
extern crate riscv_rt;
mod serial;
mod timer;
mod adc;
mod midi;
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
   println!();
   println!("Midi sender started:");

   loop {
    let note = adc::get_data();
    if note >0 {
    println!(" Note:{}",note);
    match note {
            1 => midi::write(NOTE_A),
            2 => midi::write(NOTE_B),
            3 => midi::write(NOTE_C),
            4 => midi::write(NOTE_D),
            5 => midi::write(NOTE_E),
            6 => midi::write(NOTE_F),
            7 => midi::write(NOTE_G),
            _ =>  sleep(1),
        };
        k = note;
        sleep(500000);
    }
   }

   loop {
   }
}

#[export_name = "_mp_hook"]
pub extern "Rust" fn mp_hook(_hartid: usize) -> bool {
    true
}

fn sleep( cycles:i32) {
    for _ in 0..cycles {
        unsafe { core::arch::asm!("nop"); }
    }  
}

