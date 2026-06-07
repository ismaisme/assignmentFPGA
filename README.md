# This is a group assignment from the course KKEE2163

I am from faculty of engineering from Universiti Kebangsaan Malaysia, UKM. In this course we are task to build a system using the FPGA provided. 

# Key Features
- Dynamic VGA Display: Supports 1280 × 1024 resolution @ 60Hz refresh rate.
- Features full text/emoji rendering with left-right scrolling and pause functionality.
- Dual Audio Output: Drives 2 speaker buzzers using Pulse Width Modulation (PWM) via PMOD ports for synchronous real-time audio playback.
- Manual Hardware Controls: Physical switches govern system states, paired with on-board LEDs and two 7-segment displays to track live device status.

# System Architecture & Files

The project consolidates modular logic functions into a unified core design:

main.v: 
- The top-level Verilog module instantiating and connecting the three core sub-modules:
- Display Module (Display.v): Comprises 7 modules total (3 for VGA control/synchronization, 3 for text/symbol pixel generation). Features a char_rom and font_rom lookup matrix.
- Speaker Module (Speaker.v): Manages tune frequencies, note progression arrays, and duration variables.
- Control Module (control.v): Interconnects the manual physical I/O mapping.
  
cons_2.xdc:
- Pin constraint configuration maps signals directly to Nexys 4 DDR physical switches, LEDs, 7-segment pins, PMOD pins, and the VGA port.

testbench_main3.v:
- Testbench logic introducing an alternating 10ns clock cycle and timed step-triggers for hardware switches over a 1.5 ms baseline window.
