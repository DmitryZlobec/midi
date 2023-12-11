#![no_std]
#![no_main]

extern crate panic_halt;
extern crate riscv_rt;
mod serial;
mod timer;
mod adc;
mod midi;
use riscv_rt::entry;
use midi::Message;

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

   
   let note_A_on = Message::new( [0x90,0x45,0x40], 3);
   let note_B_on = Message::new( [0x90,0x47,0x40], 3);
   let note_C_on = Message::new( [0x90,0x3C,0x40], 3);
   let note_D_on = Message::new( [0x90,0x3E,0x40], 3);
   let note_E_on = Message::new( [0x90,0x40,0x40], 3);
   let note_F_on = Message::new( [0x90,0x41,0x40], 3);
   let note_G_on = Message::new( [0x90,0x43,0x40], 3);

   let note_A_off = Message::new( [0x80,0x45,0x00], 3);
   let note_B_off = Message::new( [0x80,0x47,0x00], 3);
   let note_C_off = Message::new( [0x80,0x3C,0x00], 3);
   let note_D_off = Message::new( [0x80,0x3E,0x00], 3);
   let note_E_off = Message::new( [0x80,0x40,0x00], 3);
   let note_F_off = Message::new( [0x80,0x41,0x00], 3);
   let note_G_off = Message::new( [0x80,0x43,0x00], 3);

   let set_piano = Message::new([0xc0, 0x00,0x00],2); 

   midi::send_message(&set_piano);
   loop {
    let note = adc::get_data();
    if note >0 {
    println!(" Key:{}",note);
    if note !=k  {
        println!(" Note On:{}",note);
        match note {
            1 => midi::send_message(&note_A_on),
            2 => midi::send_message(&note_B_on),
            3 => midi::send_message(&note_C_on),
            4 => midi::send_message(&note_D_on),
            5 => midi::send_message(&note_E_on),
            6 => midi::send_message(&note_F_on),
            7 => midi::send_message(&note_G_on),
            _ =>  sleep(1),
        };
        if k>0 {
            println!(" Note Off:{}",k);
            match k {
                1 => midi::send_message(&note_A_off),
                2 => midi::send_message(&note_B_off),
                3 => midi::send_message(&note_C_off),
                4 => midi::send_message(&note_D_off),
                5 => midi::send_message(&note_E_off),
                6 => midi::send_message(&note_F_off),
                7 => midi::send_message(&note_G_off),
                _ =>  sleep(1),
            };       
        }
    }
        k = note;
        sleep(250000);
     } else {
        if k>0  {
            println!(" Note Off:{}",k);
            match k {
                1 => midi::send_message(&note_A_off),
                2 => midi::send_message(&note_B_off),
                3 => midi::send_message(&note_C_off),
                4 => midi::send_message(&note_D_off),
                5 => midi::send_message(&note_E_off),
                6 => midi::send_message(&note_F_off),
                7 => midi::send_message(&note_G_off),
                _ =>  sleep(1),
            };    
        }
        k=0;
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

