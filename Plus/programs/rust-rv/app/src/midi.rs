
struct MidiMessage {
    lenth: i32,
    buff:[u32;1], 
}


pub fn write(byte: u8) {
    unsafe { 
        core::arch::asm!(
        "lui     t0,0xffff0",
        "mv t1, {0}",
        "sb t1, 20(t0)",
        in(reg) byte	
    ); }
    for _ in 0..2000 {
        unsafe { core::arch::asm!("nop"); }
    } 
}
