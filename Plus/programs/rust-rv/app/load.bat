rem The port number should be adjusted
set a=6
mode com%a% baud=57600 parity=n data=8 stop=1 to=off xon=off odsr=off octs=off dtr=off rts=off idsr=off
type code.mem16 >\.\COM%a%
