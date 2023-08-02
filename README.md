# Fake Transceiver
_e32-ttl-1w v1.3_
## Requirement
- Same interface of real transceiver
- Same response time
- Output of Fake Transceiver is uart module (connect to USB to TTL -> USB hub -> Laptop)
- UART interface (to MCU/Node controller) is TTL level   (Optional)
- For some MCU works at 5VDC, it may need to add 4-10K pull-up resistor for the TXD & AUX (2 output pin) pin  (Optional)

## General behavior:
- Fake transceiver will receive config packets (from MCU/Node controller). After config module, fake transceiver will forward data from MCU/Node controller to UART_out (is antenna in real transceiver)
  
## Interface of UART transceiver:
### 1. Description of Pin:
- M0 (input):
  + Input Work with M1 & decide the four operating modes
  + Weak pullup: Floating is not allowed, can be GND
- M1 (input):
  + Input Work with M1 & decide the four operating modes
  + Weak pullup: Floating is not allowed, can be GND
- TX(Output)/RX(Input):
  + TTL UART inputs/output, connects to external TXD output pin.
  + Can be configured as open-drain or pull-up input/output.
- AUX (output):
  + To indicate module working status & wakes up the external MCU. During the procedure  of self-check initialization, the pin outputs low level. Can be configured as open-drain  output or push-pull output (floating is allowed).
### 2. Circuit diagram
  ![image](https://github.com/atfox272/JustNotation/assets/99324602/3b51333e-44a0-4b22-be61-e726d68fae4b)

### 3. Behavior:
* Module reset:
  - When the module is powered on, AUX outputs low level immediately, conducts hardware self-check and sets the operating mode on the basis of the user parameters. During the process, the AUX keeps low level. After the process completed, the AUX outputs high level and starts to work as per the operating mode combined by M1 and M0. Therefore, the user needs to wait the AUX rising edge as the starting point of module’s normal work

* AUX description:
  - AUX Pin can be used as indication for wireless send & receive buffer and self-check. It can indicate whether there are data that are yet to send via wireless way, or whether all wireless data has been sent through UART, or whether the module is still in the process  of self-check initialization.
  - Wake up MCU/Node controller:
  ![image](https://github.com/atfox272/JustNotation/assets/99324602/416b39d2-34b5-4ef0-b577-f30ac3b24dd7)

* Wireless Transmission
  - Buffer (empty): the internal 512 bytes data in the buffer are written to the RFIC (auto sub-packing).
  - When AUX=1, the user can input data less than 512 bytes continuously without overflow. when AUX=0, the internal 512 bytes data in the buffer have not been written to the RFIC completely. If the user starts to transmit data at this circumstance, it may cause overtime when the module is waiting for the user data, or transmitting wireless sub package
 ## Config UART interface
 - "(Only support 9600 and 8N1 format when setting - mode sleep) "
   
 ## Note to-do list:
 - Clone Behavior (only behavior which interact with interface (timing - format) - without inside computing)
 - Clone interface
 - Clone timing 
 - Clone Buffer
 - Save config data, because MCU will "ask" and fake transceiver must be "reply" this information. (Below figure)
    + ![image](https://github.com/atfox272/JustNotation/assets/99324602/9fb880a4-3c10-45d9-9ab4-69bea14ca11b)
    + 
## Workflow:
### 0. Mode switching:
- Decide the operating mode by combination of 2 pin M0 and M1
- After modifying M0 and M1, **it will start new mode 1ms-2ms later, if module is free**.
  
    (Source: _After modifying M1 or M0, it will start to work in new mode 1ms later if the module is free. For example, in mode 0 or mode 1, if the user inputs massive data consecutively and switches operating mode at the same time, the 
mode-switch operation is invalid. New mode checking can only be started after all the user’s data process completed. It is 
recommended to check AUX pin out status and wait 2ms after AUX outputs high level before switching the mode_)
- MCU will detect AUX pin (when AUX is HIGH) to switch mode
   
- Mode-switching is valid when AUX is HIGH (module is free), otherwise it will wait for finishing
- When the transmitter works in mode 0, after the **external MCU transmits data “12345”**, it can switch to sleep mode immediately without waiting the rising edge of the AUX pin. (Example: The MCU is transmit all packet data to Module and last packet is "12345", the module will transmit all wireless data through wireless transmission & go sleep mode 1ms later)  
### 1. MODE 0 (normal mode):
* Transmitter:
  - Real behavior:
    + Transceiver receive data from serial port (RX) 58 bytes. When data inputted up to 58bytes, the module will start wireless transmission 
    + When data inputted by user is less than 58bytes, the module will wait 3bytes time (may be waiting RX port for 3 transaction) and treat it as data termination unless continuos data inputted by user
    + When module receives first data packet from user -> **AUX** will be LOW
    + After all data (meaning "all data in buffer" or "58 bytes"??) is transmitted to RF chip and transmission start, **AUX** is HIGH
    + **The data packet is transmitted from module in MODE 0**
  - Fake behavior:
    + Must clone:
      -> Buffer 512 bytes
      -> Behavior: Start transmit (from buffer RX) data to RFIC (wireless transmitter) after waiting 3byte-empty (waiting 3 transactions)
      -> Behavior: **AUX** is LOW when the module receive first packet from MCU , connect directly to empty_port of  FIFO_in 
* Receiving
  - Real behavior:
    + The wireless receiving function is on in this mode
    + After the packet A (example packet) is received -> AUX is LOW -> 5ms later, the module start transmitt this packet A to MCU by TX port
    -> In this case, this module just can transmit or receive at the same time (half-duplex)
    + After wireless data has beeen transmited, AUX is HIGH
    + **The module can receive packet in MODE 0 or MODE 1** 
-> This module transceiver just can transmit or receive at same time (half-duplex) -> AUX will be controled by RX or TX module 
### 2. Mode 1 (Wake-up mode)(The same as MODE 0): 
- Do not implement preamble code
### 3. Mode 2 (Power-saving mode)
### 4. Mode 4 (Sleep mode): 
- In "Implement" title
### 2. Implement:
#### a. Block diagram:
  ![image](https://github.com/atfox272/RF_Transceiver-/assets/99324602/a9bde74b-02c4-40b0-93ba-12b830ec82eb)


#### a. Implement MODE 3 (configuration mode): 
- Transaction format: 9600 - 8N1 (8bits - no parity - 1bit stop)
- Format:
  - Configuration:
    + No0:
      ![image](https://github.com/atfox272/JustNotation/assets/99324602/6eb2e85b-5487-4cd6-8ac6-deec86767dcd)
      * **Save value**
      * No reply
    + No1-2:
      ![image](https://github.com/atfox272/JustNotation/assets/99324602/ec4989c6-376b-401f-a7ca-aa319816a98b)
      * **Save value to address buffer** (Device address)
      * No reply
    + No3:
      ![image](https://github.com/atfox272/JustNotation/assets/99324602/1987af7e-5457-4e43-8040-207e1975e6df)
      * **Save value and config baudrate and transaction format**
      * No reply
    + No4:
      ![image](https://github.com/atfox272/JustNotation/assets/99324602/3cda3418-46cd-42df-bc14-1f39a762955e)
      * **Save value**
      * No reply
    + No5:
      
      ![image](https://github.com/atfox272/JustNotation/assets/99324602/05297d7c-7d8e-41b4-8789-db69963fb3dc)
      * **Save value**
      * No reply
  - Read configuration data:
    + Read present configuration (**Must have**):
      ![image](https://github.com/atfox272/JustNotation/assets/99324602/81ac3743-5d1d-4353-a823-0a884a34f5bd)
      * No save
      * Reply: all configuration transactions in "Configuration" (above title)

    + Read e32 version (**Set up read-only buffer**):
      ![image](https://github.com/atfox272/JustNotation/assets/99324602/705165d0-2dce-41df-8a19-fc8f5a6dcff5)
      * No save
      * No reply

    + Read reset command (**Ignore**):
      ![image](https://github.com/atfox272/JustNotation/assets/99324602/e8ac0ebd-6a02-48e5-8ddc-bb8dac66065e)
      * No save
      * No reply
       
- Buffer:
  + Parity config  (O - E - N)                         (2bit - [7:6])
  + Baudrate_sel config (4800 - 9600 - 19200 - 38400)  (3bit - [5:3])
  + AirDataRate config (Just save)                     (3bit - [2:0])


## Note:
- No implement DELAY UNIT in air, its not behavior of board E32 (Delay transmission in air will be generated by Computer) 
- AUX in receiving data from serial port of UART_mcu:
  + First: Buffer512 of E32 is empty and AUX is HIGH, then user can start serial transmission (Not more than 512 bytes continous). At this time, when module receive first packet (1 byte), AUX will be LOW.
  + Second: + When data in buffer512 is up to 58bytes, the wireless transmission (RFIC) is start, during which the user can input data continously for transmission. + When data in buffer512 is less than 58bytes and no more transaction for 3-frame time, the wireless transmission (RFIC) is start

## Check-List:
- Mode3               ✔️
- Mode0_trans         ✔️
- Mode0_recei         ✖️
- Combine mode        ✖️
- On FPGA             ✖️ 
## Experiences distilled:
- When you build state-machine to replace for programmed-MCU, you should seperate "_controller_" in "Block Diagram" into sub-modules _as more as possible_   
