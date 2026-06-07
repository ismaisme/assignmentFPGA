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

## Hardware Pin Mapping (Nexys 4 DDR)

The physical inputs and outputs are mapped to the FPGA board using the following configurations defined in `cons_2.xdc`:

### Inputs

| Signal Name | Physical Component | FPGA Pin | I/O Standard | Description |
| :--- | :--- | :--- | :--- | :--- |
| `clk` | System Clock (100MHz) | `E3` | `LVCMOS33` | Master synchronization clock (10ns period) |
| `sw` | Slide Switch 0 | `J15` | `LVCMOS33` | Display control toggle |
| `sw_2` | Slide Switch 1 | `L16` | `LVCMOS33` | Audio / Speaker control toggle |

### Outputs

| Signal Name | Physical Component | FPGA Pin | I/O Standard | Description |
| :--- | :--- | :--- | :--- | :--- |
| `led` | LED 0 | `H17` | `LVCMOS33` | Status Indicator 1 |
| `led_2` | LED 1 | `K15` | `LVCMOS33` | Status Indicator 2 |
| `left` | PMOD JA Pin 1 | `C17` | `LVCMOS33` | Audio PWM channel (Left buzzer) |
| `right` | PMOD JA Pin 2 | `D18` | `LVCMOS33` | Audio PWM channel (Right buzzer) |
| `seg[0:6]` | 7-Segment Cathodes | `T10` to `L18` | `LVCMOS33` | Renders device status characters (a to g) |
| `an[0:7]` | 7-Segment Anodes | `J17` to `U13` | `LVCMOS33` | Controls specific display digit activation |
