===================================================================================================

Build procedure

This is standard RTEMS build procedure followed from following link
https://docs.rtems.org/branches/master/user/start/index.html

1. Build RTEMS builder
	
	Get the RTEMS builder  
	$ cd <WORK_DIR>  
	$ mkdir rsb  
	$ git clone git://git.rtems.org/rtems-source-builder.git rsb  
	$ cd rsb  
	$ ./source-builder/sb-check  
	$ cd rtems  
	$ ../source-builder/sb-set-builder --prefix=<RTEMSTOOLS_INSTALL_PATH> 5/rtems-riscv  

	After installation  
	$ export PATH=<RTEMSTOOLS_INSTALL_PATH>/bin:$PATH

2. Build RTEMS kernel
	
	Note: skip following 4 steps if BSP is already available  
	$ cd <WORK_DIR>  
	$ mkdir kernel  
	$ git clone git://git.rtems.org/rtems.git rtems  
	$ cd rtems  

	$ ./bootstrap -c && <RSB PATH>/rsb/source-builder/sb-bootstrap  
	$ cd ..  
	$ mkdir frdme310_build  
	$ cd frdme310_build  
	$ ../rtems/configure --prefix=<RTEMSTOOLS_INSTALL_PATH> --target=riscv-rtems5 --enable-rtemsbsp=frdme310arty --enable-tests --enable-posix --disable-networking --disable-itron  
	$ make  

	It takes a while to build  

	Make RTEMS binary from RTEMS exe  
	
	objcopy -O ihex <RTEMS_EXE> tmp.hex   
	objcopy -I ihex -O binary tmp.hex <RTEMS_BINARY_Name>.bin  

	e.g.  
	$ objcopy -O ihex riscv-rtems5/c/frdme310arty/testsuites/samples/hello.exe tmp.hex  
	$ objcopy -I ihex -O binary tmp.hex hello.bin  

===================================================================================================

Test procedure  

1) Arty Bit file Flashing  

Program Arty_A7_FE310.bit using Vivado OR TRenz utility  

http://www.trenz-electronic.de/fileadmin/docs/Trenz_Electronic/Software/ToolZ/ToolZ-1-0-0-4.zip  

ToolZ->JTAG->Detect  
Toolz->Program  

2) OpenOCD JTAG connection  

Please refer FreedomStudio\SiFive\Documentation\SiFive-E310-arty-gettingstarted-v1.0.5.pdf 
for connection of JTAG debugger (Olimex) to PMOD

Please referee RTEMS documentation for more details  
https://docs.rtems.org/branches/master/user/tools/tester.html  

This is tested as per "GDB and JTAG" configuration specified here  
https://docs.rtems.org/branches/master/user/testing/index.html#tester-configuration  

Download OpenOCD for RISC-V  
https://static.dev.sifive.com/dev-tools/riscv-openocd-0.10.0-2019.08.2-x86_64-linux-ubuntu14.tar.gz  

3. Connect OpenOCD  

Flash the Bootloader in Arty A7  
$ git clone git@github.com:pragnesh26992/rtems.git rtems_install
$ sudo openocd -f rtems_install/openocd-config/sifive-e31-arty.cfg -c "program bootloader.hex verify reset exit"  

Flash the Device tree in Arty A7  
$ sudo openocd -f rtems_install/openocd-config/sifive-e31-arty.cfg -c "program frdme310arty.dtb verify reset exit 0x40500000"  

Flash the RTEMS binary <RTEMS_BINARY_Name>.bin in Arty A7  
$ sudo openocd -f rtems_install/openocd-config/sifive-e31-arty.cfg -c "program <RTEMS_BINARY_Name>.bin verify reset exit 0x40600000" 

User can see the Output on UART through minicom with the baudrate of 115200 (8N1)  
$ sudo minicom -D /dev/ttyUSB

===================================================================================================

If user wants to run all RTEMS testsuites (all test cases) then follow this steps

1. Flash the Device tree in Arty A7  
$ sudo openocd -f rtems_install/openocd-config/sifive-e31-arty.cfg -c "program frdme310arty.dtb verify reset exit 0x40500000"  

2. Change start.S of RTEMS kernel for RISCV as shown below

<rtems-root>bsps/riscv/shared/start/start.S  
	 #ifdef BSP_START_COPY_FDT_FROM_U_BOOT  
	+       LADDR a1, 0x40500000  
        mv      a0, a1  
        call    bsp_fdt_copy  
	 #endif  
	
Repeat Step 2 of Build procedure to build the RTEMS kernel.

3. Linux host ser2net:  
run command. 
$ sudo ./ser2net -n -d -C 5001:telnet:0:/dev/ttyUSB:115200  
make sure your UART port is correct  

4. Copy test user config file and ini file to installed path ‘s share folder.  
$ cp rtems_install/config-ini/frdme310arty.ini <RTEMSTOOLS_INSTALL_PATH>/share/rtems/tester/rtems/testing/bsps/  
$ cp rtems_install/config-ini/frdme310arty.cfg <RTEMSTOOLS_INSTALL_PATH>/share/rtems/tester/rtems/testing/  

5. Connect OpenOCD and start GDB server on separate terminal  
$ sudo openocd -f rtems_install/openocd-config/sifive-e31-arty.cfg  

Log on terminal  
Open On-Chip Debugger 0.10.0+dev-g7550e7e-dirty (2018-09-19-15:16)  
Licensed under GNU GPL v2  
For bug reports, read  
http://openocd.org/doc/doxygen/bugs.html  
adapter speed: 10000 kHz  
Info : auto-selecting first available session transport "jtag". To override  
use 'transport select <transport>'.  
Info : ftdi: if you experience problems at higher adapter clocks, try the  
command "ftdi_tdo_sample_edge falling"  
Info : clock speed 10000 kHz  
Info : JTAG tap: riscv.cpu tap/device found: 0x20000913 (mfg: 0x489 (SiFive,  
Inc.), part: 0x0000, ver: 0x2)  
Info : datacount=2 progbufsize=16  
Info : Disabling abstract command reads from CSRs.  
Info : Disabling abstract command writes to CSRs.  
Info : Examined RISC-V core; found 1 harts  
Info : hart 0: XLEN=32, misa=0x40001105  
Info : Listening on port 3333 for gdb connections  

6. Copy gdbinit script to home directory  
$ cp rtems_install/gdb_script/.gdbinit ~/  

7. Run Test  
$ cd frdm310_build  
$ export RISCV=<RTEMSTOOLS_INSTALL_PATH>/bin  
$ rtems-test --rtems-bsp=frdme310arty --rtems-tools=$RISCV --report-mode=all --jobs=1 --warn-all --log=rtems-test-all-log.txt ./riscv-rtems5/c/frdme310arty/testsuites

result should look like this
[1/3] p:0 f:0 u:0 e:0 I:0 B:0 t:0 i:0 W:0 | riscv/frdm310: dhrystone.exe
[2/3] p:0 f:0 u:0 e:0 I:0 B:1 t:0 i:0 W:0 | riscv/frdm310: linpack.exe
[3/3] p:0 f:0 u:0 e:0 I:0 B:2 t:0 i:0 W:0 | riscv/frdm310: whetstone.exe


