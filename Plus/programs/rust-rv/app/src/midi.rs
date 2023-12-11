
pub struct Message {
    pub size: usize,
    pub command: [u8;3],
}

impl Message {
    pub fn new(command:[u8;3], size:u8) -> Message {
        Message {command, size: size.into()}
    }
}

pub struct StatusMessage {
    pub msg:[u8;2],
}

pub fn write(byte: u8) {
    unsafe { 
        core::arch::asm!(
        "lui     t0,0xffff0",
        "mv t1, {0}",
        "sb t1, 20(t0)",
        in(reg) byte	
    ); }
    for _ in 0..700 {
        unsafe { core::arch::asm!("nop"); }
    } 
}

pub fn send_message(message:&Message) {
    for n in 0..message.size {
        write(message.command[n]);
    }
}
