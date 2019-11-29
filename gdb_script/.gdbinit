set arch riscv:rv64
target remote localhost:3333
monitor reset halt
set pagination off
#set mem inaccessible-by-default off
#set remotetimeout 1000




#set mem inaccessible-by-default off
#set remotetimeout 250
#set $pc =0x80000000

