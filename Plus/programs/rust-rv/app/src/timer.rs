pub fn tm()-> u16 {    
       let  buffer: &mut u16 = unsafe { &mut *(0xFFFF000A as *mut u16) };
       *buffer
}
