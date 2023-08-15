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
- END_SELF_CHECKING: time of self-checking (No information)
## Calculate value of Parameter:
_Internal Clock of DE10-Nano: 50Mhz_

_Internal Clock of Arty-Z7: 125Mhz_

### 1.Format: parameter <divider_name> = <divider_value>:
Example: parameter END_COUNTER_RX_PACKET = 26041

### 2.Equation: 
#### a. Waiting time: 
_waiting_time = (<divider_value> * 2) / INTERNAL_CLK_

Example: Assume internal clock is 50MHz, waiting time of END_WAITING_SEND_WLESS_DATA is 2-3ms (assume 2.5ms), so divider_value of END_WAITING_SEND_WLESS_DATA is 26041
#### b. Divider of UART: 
_CLOCK_DIVIDER_UART = INTERNAL_CLK / ((4800 * 2) * (128 * 2))_ 
_CLOCK_DIVIDER_UNIQUE_1 = INTERNAL_CLK / (115200 * 2)_ 
_CLOCK_DIVIDER_UNIQUE_2 = INTERNAL_CLK / (9600 * 2)_

### 3. Table of divider_value:
- _Arty-Z7 (INTERNAL_CLK == 125MHz)_
         
| divider_name | divider_value |
|-------|-------|
| CLOCK_DIVIDER_UART | 51 |
| CLOCK_DIVIDER_UNIQUE_1 | 542 |
| CLOCK_DIVIDER_UNIQUE_2 | 6511 | 
| END_COUNTER_RX_PACKET | 16276 |
| END_WAITING_SEND_WLESS_DATA | 156250 |
| END_SELF_CHECKING | 78125 |


- _DE10-Nano (INTERNAL_CLK == 50MHz)_
         
| divider_name | divider_value |
|-------|-------|
| CLOCK_DIVIDER_UART | 21 |
| CLOCK_DIVIDER_UNIQUE_1 | 218 |
| CLOCK_DIVIDER_UNIQUE_2 | 2605 | 
| END_COUNTER_RX_PACKET | 6511 |
| END_WAITING_SEND_WLESS_DATA | 625000 |
| END_SELF_CHECKING | 31250 |
