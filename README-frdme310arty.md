=======================================================================================

Build procedure

This is standard RTEMS build procedure followed from following link
https://docs.rtems.org/branches/master/user/start/index.html

1. Step1: build RTEMS builder
	
	Get the RTEMS builder
	# cd <WORK_DIR>
	# mkdir rsb
	# git clone git://git.rtems.org/rtems-source-builder.git rsb
	# cd rsb
	# ./source-builder/sb-check
	# cd rtems
	# ../source-builder/sb-set-builder --prefix=<RTEMSTOOLS_INSTALL_PATH> 5/rtems-riscv

	After installation
	# export PATH=<PREFERED INSTALL PATH>/bin:$PATH

2. Step2: Build RTEMS kernel
	
	Note: skip following 4 steps if BSP is already available
	# cd <WORK_DIR>
	# mkdir kernel
	# git clone git://git.rtems.org/rtems.git rtems
	# cd rtems

	# ./bootstrap -c && <RSB PATH>/rsb/source-builder/sb-bootstrap
	# cd ..
	# mkdir frdme310_build
	# cd frdme310_build
	# ../rtems/configure --prefix=<RTEMSTOOLS_INSTALL_PATH> --target=riscv-rtems5 \
	--enable-rtemsbsp=frdme310arty --enable-tests --enable-posix --disable-networking --disable-itron
	#make

	It takes a while to build

	Make RTEMS binary from RTEMS exe
	
	objcopy -O ihex <RTEMS_EXE> tmp.hex 
	objcopy -I ihex -O binary tmp.hex <RTEMS_BINARY_Name>.bin

	e.g.
	# objcopy -O ihex riscv-rtems5/c/frdme310arty/testsuites/samples/hello.exe tmp.hex
	# objcopy -I ihex -O binary tmp.hex hello.bin

=======================================================================================

Test procedure

1) Arty Bit file Flashing

Program Arty_A7_FE310.bit using Vivado OR TRenz utility

http://www.trenz-electronic.de/fileadmin/docs/Trenz_Electronic/Software/ToolZ/ToolZ-1-0-
0-4.zip

ToolZ->JTAG->Detect
Toolz->Program

2) OpenOCD JTAG connection

Please refer FreedomStudio\SiFive\Documentation\SiFive-E310-arty-gettingstarted-
v1.0.5.pdf for connection of JTAG debugger (Olimex) to PMOD

Please referee RTEMS documentation for more details
https://docs.rtems.org/branches/master/user/tools/tester.html

This is tested as per "GDB and JTAG" configuration specified here
https://docs.rtems.org/branches/master/user/testing/index.html#tester-configuration

Download OpenOCD for RISC-V
https://static.dev.sifive.com/dev-tools/riscv-openocd-0.10.0-2019.08.2-x86_64-linux-ubuntu14.tar.gz

3. Connect OpenOCD

Flash the Bootloader in Arty A7
sudo openocd -f sifive-e31-arty.cfg -c "program bootloader.hex verify reset exit"

Flash the Device tree in Arty A7
sudo openocd -f sifive-e31-arty.cfg -c "program frdme310arty.dtb verify reset exit 0x40500000"

Flash the RTEMS binary <RTEMS_BINARY_Name>.bin in Arty A7
sudo openocd -f sifive-e31-arty.cfg -c "program <RTEMS_BINARY_Name>.bin verify reset exit 0x40600000"

