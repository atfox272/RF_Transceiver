# Report
## Mode 0:
### Wireless-transmitter:
- Testcase: Send data
  | Info | Value |
  | :---:   | :---: | 
  | Data | 60 bytes (0 -> 59) |
  | Channel | 27 |
  | Address | 02 |
- Check list:
  | Check case | Yes/No |
  | :---:   | :---: | 
  | AUX is LOW when RF-transceiver receive first byte | ✔️ |
  | Start wireless-transmission (buffer reacch 58 bytes) | ✔️ |
  | AUX is HIGH while module is sending last byte in packet | ✔️ |
  
  + Situation 1:
    ![image](https://github.com/atfox272/RF_Transceiver/assets/99324602/2fe5d13e-c3b4-4ef3-bc84-b3f9cfa39111)

  + Situation 2:
    ![image](https://github.com/atfox272/RF_Transceiver/assets/99324602/e22f2a23-bc53-4d11-b322-4ea9cf641a30)

  + Situation 3:
    ![image](https://github.com/atfox272/RF_Transceiver/assets/99324602/9405b7e9-82b1-4ff9-b853-0dcc9b10d282)
    
- Power comsumption:
  | Info | Max value |
  | :---:   | :---: | 
  | Current |  0.8 A |  
  | Voltage |  5V |  
  | Power |  4.0W |

  
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
  | Check case | Yes/No |
  | :---:   | :---: | 
  | Save all parameter | ✔️ |
  | Return parameter (C1 C1 C1) | ✔️ |
  | Use parameters to configure UART | ➖ |

  ![image](https://github.com/atfox272/RF_Transceiver/assets/99324602/9b122c8b-a579-4aa3-bdfe-7b2078f48d13)
  ![image](https://github.com/atfox272/RF_Transceiver/assets/99324602/873a2b6b-1a03-43b9-b8b8-e6ab9f8eb45b)


  
