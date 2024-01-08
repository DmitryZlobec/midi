use core::fmt;
use lazy_static::lazy_static;
use spin::Mutex;
use volatile::Volatile;

pub struct Writer {}

lazy_static! {
    pub static ref WRITER: Mutex<Writer> = Mutex::new(Writer {});
}

impl Writer {
    pub fn write_byte(&mut self, byte: u8) {
                unsafe { 
                    core::arch::asm!(
					"lui     t0,0xffff0",
					// "mv t1, {0}",
					"sb {0}, 14(t0)",
					in(reg) byte	
                ); }
                for _ in 0..2000 {
                    unsafe { core::arch::asm!("nop"); }
                }  	   
             }

    fn write_string(&mut self, s: &str) {
        for byte in s.bytes() {
            match byte {
                _ => self.write_byte(byte),
            }
        }
    }
}

impl fmt::Write for Writer {
    fn write_str(&mut self, s: &str) -> fmt::Result {
        self.write_string(s);
        Ok(())
    }
}

#[macro_export]
macro_rules! print {
    ($($arg:tt)*) => ($crate::serial::_print(format_args!($($arg)*)));
}

#[macro_export]
macro_rules! println {
    () => ($crate::print!("\n"));
    ($($arg:tt)*) => ($crate::print!("{}\n", format_args!($($arg)*)));
}

/// Prints the given formatted string
#[doc(hidden)]
pub fn _print(args: fmt::Arguments) {
    use core::fmt::Write;
    // let mut writer = Writer {};
    WRITER.lock().write_fmt(args).unwrap();
    // writer.write_fmt(args).unwrap();
}


pub fn write(byte: u8) {
    unsafe { 
        core::arch::asm!(
        "lui     t0,0xffff0",
        "mv t1, {0}",
        "sb t1, 14(t0)",
        in(reg) byte	
    ); }
    
}




