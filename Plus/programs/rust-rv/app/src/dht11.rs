pub fn temperature()-> u16 {    
       // let  buffer: &mut u16 = unsafe {  &mut *(0xFFFF0010 as *const u16) };
       // *buffer
       let mut out_half;
       unsafe { 
              core::arch::asm!(
                             "lui    t0,0xffff0",
                             "lh {}, 16(t0)",
                             out(reg) out_half	
          ); }
       out_half
}


pub fn himmidity()-> u16 {    
       let  buffer: &mut u16 = unsafe { &mut *(0xFFFF0012 as *mut u16) };
       *buffer
}