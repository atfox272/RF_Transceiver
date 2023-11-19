# Report
## Mode 0:
### Wireless-transmitter:
- Testcase: Send data
  | Info | Verify _Behaviors of Fake RF_transceiver_ |
  | :---:   | :---: | 
  | Data | 60 bytes (0 -> 59) |
  | Channel | 27 |
  | Address | 02 |
- Check list:
  | Check case | Verify _Behaviors of Fake RF_transceiver_ |
  | :---:   | :---: | 
  | AUX is LOW when RF-transceiver receive first byte | ✔️ |
  | Start wireless-transmission (buffer reacch 58 bytes) | ✔️ |
  | AUX is HIGH while module is sending last byte in packet | ✔️ |
  
  + Case 1 (_AUX is LOW when RF-transceiver receive first byte_):
    <p align="center">
    <img src="https://github.com/atfox272/RF_Transceiver/assets/99324602/2fe5d13e-c3b4-4ef3-bc84-b3f9cfa39111" width=70% height=70%>
    </p> 

  + Case 2 (_Start wireless-transmission (buffer reacch 58 bytes)_):
    <p align="center">
    <img src="https://github.com/atfox272/RF_Transceiver/assets/99324602/e22f2a23-bc53-4d11-b322-4ea9cf641a30" width=70% height=70%>
    </p> 

  + Case 3 (_AUX is HIGH while module is sending last byte in packet_):
    <p align="center">
    <img src="https://github.com/atfox272/RF_Transceiver/assets/99324602/9405b7e9-82b1-4ff9-b853-0dcc9b10d282" width=70% height=70%>
    </p> 
    
- Power comsumption:
  | Info | Max value |
  | :---:   | :---: | 
  | Current |  0.8 A |  
  | Voltage |  5V |  
  | Power |  4.0W |

### Wireless-receiver:
- Testcase: Send data
  | Info | Verify _Behaviors of Fake RF_transceiver_ |
  | :---:   | :---: | 
  | Data | 60 bytes (0 -> 59) |

- Check list:
  | Check case | Verify _Behaviors of Fake RF_transceiver_ |
  | :---:   | :---: | 
  | AUX is LOW when RF-transceiver receive first wireless-data | ✔️ |
  | Start sending wireless-data to MCU after 2-3ms | ✔️ |
  | AUX is HIGH when the RF-transceiver finishes sending last wireless-data to MCU | ✔️ |  

  + Case 1 (_AUX is LOW when RF-transceiver receive first wireless-data_):
    ![image](https://github.com/atfox272/RF_Transceiver/assets/99324602/b22d5a2e-de17-4af9-8be7-2a3f473c5959)

  + Case 2 (_Start sending wireless-data to MCU after 2-3ms_):
    ![image](https://github.com/atfox272/RF_Transceiver/assets/99324602/a7f6cdd4-76be-4a4d-9a29-0f4e9b468d9e)

  + Case 3 (_AUX is HIGH when the RF-transceiver finishes sending last wireless-data to MCU_)
    ![image](https://github.com/atfox272/RF_Transceiver/assets/99324602/4131dbc7-4190-479d-8dd1-3eafddfbbbfe)

- Power comsumption:
  | Info | Max value |
  | :---:   | :---: | 
  | Current |  ➖ A |  
  | Voltage |  5V |  
  | Power |  ➖ W |
  
## Mode 3:
### Set/Get parameter:
- Testcase: Set parameter and Get parameter from transceiver
  | Info | Value |
  | :---:   | :---: | 
  | HEAD | C0 |
  | ADDH | CD |
  | ADDL | AB |
  | SPED | 3D |
  | CHAN | 17 |
  | OPTION | C4 |

- Check-list:
  | Check case | Verify _Behaviors of Fake RF_transceiver_ | Note |
  | :---:  | :---: | :---: | 
  | Save all parameter (C0 - 5 param) | ✔️ | Volatile |
  | Save all parameter (C2 - 5 param) | ✔️ | Volatile |
  | Return parameter (C1 C1 C1) | ✔️ | **Bug of _E32_TTL.h_** : Mode switch (mode3 to others) before receiving all return-parameters |
  | Return version (C3 C3 C3) | ➖ | Not use |
  | Reset (C4 C4 C4) | ✔️ | **Bug of _E32_TTL.h_** : Mode switch (mode3 to others) before reseting completely  |

  * Send & Get parameter (C0 - 5param) (C1 C1 C1):
    <p align="center">
    <img src="https://github.com/atfox272/RF_Transceiver/assets/99324602/9b122c8b-a579-4aa3-bdfe-7b2078f48d13" width=70% height=70%>
    <img src="https://github.com/atfox272/RF_Transceiver/assets/99324602/0e0ff64f-2adb-4c62-be8b-611e3326c9dd" width=70% height=70%>
    </p> 


  * Reset case (C4 C4 C4)
  <p align="center">
    <img src="https://github.com/atfox272/RF_Transceiver/assets/99324602/f9b8cfd5-bf67-48ef-a7ed-b12555a0208c" width=70% height=70%>
    </p> 

  
