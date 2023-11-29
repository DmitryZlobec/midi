// Different ways to read ports
pub fn get_data()-> u16 {    
       let mut out_half;
       unsafe { 
              core::arch::asm!(
                             "lui    t0,0xffff0",
                             "lh {}, 16(t0)",
                             out(reg) out_half	
          ); }
       out_half
}


pub fn get_data_mem()-> u16 {    
       let addr = 0xFFFF0016u32;
       unsafe {
           (addr as *mut u16).read_volatile()
       }
}