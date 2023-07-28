# JustNotation
## Fake Transceiver
_e32-ttl-1w v1.3_
### Requirement
- Same interface of real transceiver
- Same response time
- Output of Fake Transceiver is uart module (connect to USB to TTL -> USB hub -> Laptop)
- UART interface (to MCU/Node controller) is TTL level   (Optional)
- For some MCU works at 5VDC, it may need to add 4-10K pull-up resistor for the TXD & AUX (2 output pin) pin  (Optional)

### General behavior:
- Fake transceiver will receive config packets (from MCU/Node controller). After config module, fake transceiver will forward data from MCU/Node controller to UART_out (is antenna in real transceiver)
  
### Interface of UART transceiver:
#### 1. Description of Pin:
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
#### 2. Circuit diagram
  ![image](https://github.com/atfox272/JustNotation/assets/99324602/3b51333e-44a0-4b22-be61-e726d68fae4b)

#### 3. Behavior:
* Module reset:
  - When the module is powered on, AUX outputs low level immediately, conducts hardware self-check and sets the operating mode on the basis of the user parameters. During the process, the AUX keeps low level. After the process completed, the AUX outputs high level and starts to work as per the operating mode combined by M1 and M0. Therefore, the user needs to wait the AUX rising edge as the starting point of module’s normal work

* AUX description:
  - AUX Pin can be used as indication for wireless send & receive buffer and self-check. It can indicate whether there are data that are yet to send via wireless way, or whether all wireless data has been sent through UART, or whether the module is still in the process  of self-check initialization.
  - Wake up MCU/Node controller:
  ![image](https://github.com/atfox272/JustNotation/assets/99324602/416b39d2-34b5-4ef0-b577-f30ac3b24dd7)

* Wireless Transmission
  - Buffer (empty): the internal 512 bytes data in the buffer are written to the RFIC (auto sub-packing).
  - When AUX=1, the user can input data less than 512 bytes continuously without overflow. when AUX=0, the internal 512 bytes data in the buffer have not been written to the RFIC completely. If the user starts to transmit data at this circumstance, it may cause overtime when the module is waiting for the user data, or transmitting wireless sub package
 ### Config UART interface
 - "(Only support 9600 and 8N1 format when setting - mode sleep) "
   
 ### Note to-do list:
 - Clone Behavior (only behavior which interact with interface (timing - format) - without inside computing)
 - Clone interface
 - Clone timing 
 - Clone Buffer
 - Save config data, because MCU will "ask" and fake transceiver must be "reply" this information. (Below figure)
    + ![image](https://github.com/atfox272/JustNotation/assets/99324602/9fb880a4-3c10-45d9-9ab4-69bea14ca11b)
    + 
### Workflow:
* Using FPGA case:
- MODE 0 (normal mode):
* Transmitter:
  - Real behavior:
    + Transceiver receive data from serial port (RX) 58 bytes. When data inputted up to 58bytes, the module will start wireless transmission 
    + When data inputted by user is less than 58bytes, the module will wait 3bytes time (may be waiting RX port for 3 transaction) and treat it as data termination unless continuos data inputted by user
    + When module receives first data packet from user -> AUX will be LOW
    + After all data (meaning "all data in buffer" or "58 bytes"??) is transmitted to RF chip and transmission start, AUX is HIGH   
  - Fake behavior:
    + 

* Receiving
- Mode 1: 
* Use MCU case
