# de1-system
**This is a (completed) project of mine with the ultimate goal of running the original 
[DOOM](https://en.wikipedia.org/wiki/Doom_(1993_video_game))
video game on the [DE1-SoC](https://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&No=836) development board with hardware-accelerated rendering.**

The DE1-SoC board is a development board from Altera (Intel). It houses the Cyclone V chip, which contains an ARM Cortex A9 CPU and an FPGA. The CPU and the FPGA also has an interconnect to communicate with each other, which makes a huge chunk of this project possible. We were required to buy this board for a few courses in the UBC computer engineering curriculum. Usually people re-sell their boards after taking these courses, but I found more interesting things to do with it:




## Repository Overview
I started this project off by implementing a classic **Snake** game, where the game logic ran on the CPU, and the rendering was done by the FPGA. Then, confident that this system will work, I ported the **DOOM** source code to be compatible with the DE1-SoC. So, in this repository, you can find:
- `de1_soc_computer/*`, which contains files ran by the FPGA. These are mostly auto-generated files from Quartus. This FPGA system is adapted form the system that the Intel FPGA Monitor Program. This system was heavily modified to make it lighter (2x faster to compile) and compatible with my custom FPGA modules.
- `doom/*`, which contains SystemVerilog code for my custom DOOM hardware renderer module. FPGA modules like this is integrated into the FPGA system in `de1_soc_computer/*`
- `snake/*`, which contains C++ and SystemVerilog code for my implementation of the snake game.
- `proof_of_concept_1_lights/*`, which contains a basic demo of establishing communication between the CPU and FPGA.

Note that the DOOM C source code is not in this repo. Instead, you can find it here: **https://github.com/m1chellelinn/de1_doom**. Note that this is a (detached) fork of the official [DOOM source code release](https://github.com/id-Software/DOOM). 


## Implementation Overview (DOOM)
The Snake game implementation is very similar to DOOM's but less complex. Thus, I'll only cover DOOM's implementation.




## External documentation
- [Specification for the Intel FPGA Monitor Program's "De1-SoC computer system"](https://ftp.intel.com/Public/Pub/fpgaup/pub/Intel_Material/18.1/Computer_Systems/DE1-SoC/DE1-SoC_Computer_ARM.pdf). My implementations derive from this system. This was extremely helpful in documenting how to access and manipulate DE1-SoC peripherals. 
- [An online blog about compiling the original DOOM on 64-bit modern Ubuntu](https://www.deusinmachina.net/p/lets-compile-linux-doom). Our De1-SoC runs a 32-bit, custom, very old Linux image. However, the steps were extremely helpful in debugging away compilation errors.
- [Altera's user manuals for the De1-SoC](https://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&CategoryNo=205&No=836&PartNo=4#contents) (they call it the CD-ROM).



## How To: Setup the DE1-SoC System

I found a really helpful guide that Intel published on how to run a Linux image (which Intel also published). You can read the guide 
[here](https://ftp.intel.com/Public/Pub/fpgaup/pub/Intel_Material/17.0/Tutorials/Linux_On_DE_Series_Boards.pdf), 
and view the Linux image downloads 
[here](https://www.intel.com/content/dam/develop/public/us/en/include/fpga-academic/fpga-academic-sdcard-images-download.html). 
There are additional Linux images supplied by Altera available 
[here](https://download.terasic.com/downloads/cd-rom/de1-soc/),
but in my experience these aren't as functional as the ones Intel provides. 

One step in the "Running Linux on DE1-SoC" guide requires you to download USB-UART drivers. The drivers they ask for are really hard to narrow down and find. I just used 
[these](https://www.silabs.com/developer-tools/usb-to-uart-bridge-vcp-drivers?tab=downloads). 

**The next two sections assumes that you have your DE1-SoC already set-up with Linux, serial connection, and either internet access or file transfer capability.** But hey if you're just reading this to see what my project was about, these things don't matter anyways




## How To: Run DOOM or Snake
#### Requirements:
- De1-SoC, and all the cables that came with it
- Windows (preferred) or Linux/Mac (untested) computer
- Ethernet cable
- VGA cable
- VGA-compatible monitor
- Wired USB keyboard

#### Steps:

1. Power up the DE1-SoC, and get it to a state where you can access its shell and transfer files from this repository to it (whether that's by letting it pull from github, or doing some FTP stuff).
2. Also connect the VGA cable, VGA monitor, and a USB keyboard to the DE1-SoC.
3. Transfer this repository, de1_system, (as well as the DOOM repository, de1_doom, if you want to run DOOM), to the board.
4. Hop over to the shell terminal of DE1-SoC
5. Set-up to program the FPGA. 
    (We'll just use the finished FPGA binaries I've provided in this repo. If you want to compile it for yourself, the Quartus project file can be found at `de1_soc_computer/verilog/DE1_SoC_Computer.qpf`).

    The Linux image already automatically programs the FPGA on every startup using the onboard `~/DE1_SoC_Computer.rbf`. To load a different system upon bootup, we'll just need to replace this file.

    This repository has raw binary files at `de1_soc_computer/raw_binary_files`. Pick either `doom_2.rbf` or `snake_4.rbf`, and `cp` its content into the file `~/DE1_SoC_Computer.rbf`.
6. Reboot the board: run `reboot` in its shell.
7. Build the C/C++ source files. Since CMakeLists.txt have already been setup for both games, in either `de1_system/snake` or `de1_doom/linuxdoom`, run:
    ```bash
    mkdir build; cd build; cmake ..; make
    ```
8. If you're building DOOM, also do the following:
    1. Go to `de1_doom/linuxdoom/loadable_kernel_module`
    2. Run 
        ```bash
        make
        ```
        This compiles a loadable kernel module. The kernel module does only one thing: reserve a chunk of physical memory that we can share with our FPGA. This will be used for FPGA's direct memory access functions.
    3. Load the kernel module: 
        ```bash
        insmod mem_allocator.ko
        ```
        Note: this only needs to be done once per system bootup
9. Run the game! Execute either `de1_system/snake/build/snake` or `de1_doom/linuxdoom/build/linux/linuxdoom`. 
    - The DOOM executable is pretty location-dependent because it needs to search for its game data file. Ideally try running it in the `de1_doom/linuxdoom/build/linux` directory
    - Both games use keyboard controls and outputs to the VGA monitor. 
        - For snake: "enter" to start the game, and arrow keys to change directions
        - For DOOM: press any key at initial screen to bring up menu. Arrow keys and "enter" to navigate menu. In game, "w"/"a"/"s"/"d" to move, "alt"+"a" to strafe left, "alt"+"d" to strafe right, "space" to shoot, "e" to interact, and "escape" to bring up the pause menu.

