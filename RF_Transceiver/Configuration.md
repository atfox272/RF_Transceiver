# Configure before programming FPGA
## Parameter of timming defination:
- INTERNAL_CLK: internal clock of FPGA

**Parameter of UART timing**
- CLOCK_DIVIDER_UART: divide unit of UART module
- CLOCK_DIVIDER_UNIQUE_1: Timer for baudrate 115200
- CLOCK_DIVIDER_UNIQUE_2: Timer for baudrate 9600

**Waiting time defination**:
- END_COUNTER_RX_PACKET: waiting **3-frame of transaction** before wireless-transmiter working
- END_WAITING_SEND_WLESS_DATA: AUX is LOW **2-3ms** before wireless-receiver working
- END_SELF_CHECKING: is 180ms in real E32 
- END_MODE_SWITCH: is 5ms - 7ms in real E32 (average = 6ms)
- END_PROCESS_COMMAND: is 5ms in real E32
- END_PROCESS_RESET: is ~1s in real E32
- 
## Calculate value of Parameter:
_Internal Clock of DE10-Nano: 50Mhz_

_Internal Clock of Arty-Z7: 125Mhz_

### 1.Format: parameter <divider_name> = <divider_value>:
Example: parameter END_COUNTER_RX_PACKET = 26041

### 2.Equation: 
#### a. Waiting time: 
_waiting_time = <divider_value> / INTERNAL_CLK (Clock Use) 

Example: Assume internal clock is 50MHz, waiting time of END_WAITING_SEND_WLESS_DATA is 2-3ms (assume 2.5ms), so divider_value of END_WAITING_SEND_WLESS_DATA is 26041
#### b. Divider of UART: 
_CLOCK_DIVIDER_UART = INTERNAL_CLK / ((4800 * 2) * (128 * 2))_ 
_CLOCK_DIVIDER_UNIQUE_1 = INTERNAL_CLK / (115200 * 2)_ 
_CLOCK_DIVIDER_UNIQUE_2 = INTERNAL_CLK / (9600 * 2)_

### 3. Table of divider_value:
- _Arty-Z7 (DEVICE_CLK == 125MHz)_
  + Prescaler_UART_10          (INTERNAL_CLK_UART == 12.5MHz)
  + Prescaker_CTRL_50          (INTERNAL_CLK_CTRL == 2.50Mhz)
  
| divider_name | divider_value | Clock Use |
|-------|-------|-------|
| CLOCK_DIVIDER_UART | 5 | Use INTERNAL_CLK_UART |
| CLOCK_DIVIDER_UNIQUE_1 | 55 | Use INTERNAL_CLK_UART |
| CLOCK_DIVIDER_UNIQUE_2 | 652 | Use INTERNAL_CLK_UART |
| END_COUNTER_RX_PACKET | 651 | Use INTERNAL_CLK_CTRL |
| END_WAITING_SEND_WLESS_DATA | 6250 | Use INTERNAL_CLK_CTRL |
| END_SELF_CHECKING | 450000 | Use INTERNAL_CLK_CTRL |
| END_MODE_SWITCH | 15000 | Use INTERNAL_CLK_CTRL |
| END_PROCESS_COMMAND | 12500 | Use INTERNAL_CLK_CTRL |
| END_MODE_SWITCH | 2500000 | Use INTERNAL_CLK_CTRL |


- _DE10-Nano (INTERNAL_CLK == 50MHz)_
  + Prescaler_UART_4              (INTERNAL_CLK_UART == 12.5Mhz)
  + Prescaler_CTRL_20             (INTERNAL_CLK_UART == 1.25Mhz) 

  * Same as Arty's parameter 
