# RF Transceiver: Clone of E32 

# Tổng quan:
## Giới thiệu
- Xây dựng module nhằm mô phỏng hành vi của E32 và đưa dữ liệu không dây qua 1 bộ giao tiếp có nối tiếp khác để truy xuất dữ liệu, cũng như mô phỏng việc nhận dữ liệu không dây từ giao tiếp nối tiếp
- Module RF transceiver này sẽ thay thế RFIC truyền nhận không dây của E32 thành module giao tiếp nối tiếp là UART (có ký hiệu RX_node và TX_node) (gọi là UART_node).

## Sơ đồ khối:
![image](https://github.com/atfox272/RF_Transceiver/assets/99324602/888afd9d-7144-4151-b300-e8befefb04fd)


## Sơ đồ chân
### Dựa trên PinOut Arty-z7
![image](https://github.com/atfox272/RF_Transceiver/assets/99324602/ae6439f8-50b9-4b69-8f9a-380b8a19a3b8)
![image](https://github.com/atfox272/RF_Transceiver/assets/99324602/295b23b4-2b4f-4c44-8be3-f3416668f8a3)
- Thông tin chi tiết xem thêm ở phần "Thông tin các chân kết nối"

## Thông tin các chân kết nối:
* Kết nối với Controller
  - AUX: Xác định trạng thái của E32 (Idle/Working)
  - M0: Điều chỉnh mode của E32 
  - M1: Điều chỉnh mode của E32
  - RX_mcu: Chân giao tiếp với Controller
  - TX_mcu: Chân giao tiếp với Controller
* Kết nối với RF tranceiver (node) khác
  - RX_node: Chân giao tiếp 
  - TX_node: Chân giao tiếp 

# Hành vi được mô phỏng:
## Các hành vi được mô phỏng:

* Hành vi của MODE3 (SLEEP MODE):
  - Hành vi self-check khi khởi động
  - Hành vi cấu hình thông số khi có lệnh CONFIG (C0/C2 + <5 bytes>)
  - Hành vi đọc thông số cấu hình hiện tại khi có lệnh READ (C1 + C1 + C1)
  - Hành vi đọc thông số của phiên bản E32 hiện tại (C3 + C3 + C3)


* Hành vi của MODE0 (NORMAL MODE)
  - Các hành vi khi gửi dữ liệu không dây
  - Các hành vi khi nhận dữ liệu không dây
  - Các thông số về buffer của việc gửi nhận

* Hành vi SWITCHING MODE:
  - Hành vi ngăn chặn việc chuyển mode khi chưa hoàn thanh xong tác vụ hiện tại
  - Hành vi tự động self-check khi chuyển mode thành công

* Ngoài ra, các hành vi của MODE1 và MODE2 sẽ không được hiện thực ở đây vì việc cải thiện Power Consumption nằm ngoài khả năng mô phỏng của board hiện tại 

# Mô tả chi tiết hành vi:
## Hành vi chung:
- Khi nhận 1 gói dữ liệu bất kỳ từ controller (kể cả trong mode0 hay mode3) thì chân AUX cũng sẽ xuống mức thấp ngay sau khi gói dữ liệu được gửi hoàn toàn.

## Hành vi self-check khi khởi động:
- Ở đây khi khởi động (lưu ý: không phải khi khởi động board Arty-z7 mà là khi button RESET được nhấn) thì chân AUX sẽ ở mức LOW một khoảng thời gian là 6ms
- Và sau đó mode của module sẽ tùy theo mode của người dùng thiết lập trên chân M1 và M0

## Hành vi cấu hình thông số khi nhận có lệnh CONFIG

- Baudrate: 9600
- Thông tin định dạng lệnh
      ![image](https://github.com/atfox272/JustNotation/assets/99324602/6eb2e85b-5487-4cd6-8ac6-deec86767dcd)
      ![image](https://github.com/atfox272/JustNotation/assets/99324602/ec4989c6-376b-401f-a7ca-aa319816a98b)
      ![image](https://github.com/atfox272/JustNotation/assets/99324602/1987af7e-5457-4e43-8040-207e1975e6df)
      ![image](https://github.com/atfox272/JustNotation/assets/99324602/3cda3418-46cd-42df-bc14-1f39a762955e)
      ![image](https://github.com/atfox272/JustNotation/assets/99324602/05297d7c-7d8e-41b4-8789-db69963fb3dc)

- Sau khi hoàn thành việc cấu hình thì module E32 sẽ tự động gửi lại thông tin vừa được cấu hình sau đúng 5ms
- Tiếp theo, chân AUX sẽ lên mức HIGH sau khi hoàn thành việc phản hồi dữ liệu cuối cùng
  ![COMMAND_config](https://github.com/atfox272/RF_Transceiver/assets/99324602/51288fe7-d6e0-4424-a189-d3c4855a3153)


## Hành vi đọc thông số cấu hình hiện tại khi có lệnh READ 
- Baudrate: 9600
- Thông tin định dạng lệnh
  ![image](https://github.com/atfox272/JustNotation/assets/99324602/81ac3743-5d1d-4353-a823-0a884a34f5bd)

- Sau khi hoàn thành việc nhận lệnh thì sau 5ms module E32 sẽ phản hồi lại thông tin thống số cấu hình hiện tại theo định dạng HEAD + ADDH + ADDL + SPED + CHAN + OPTION, và sau đó chân AUX sẽ lên mức HIGH
  ![COMMAND_readConfig](https://github.com/atfox272/RF_Transceiver/assets/99324602/a062523c-e525-42ff-ba07-97486c3aa02c)


## Hành vi đọc thông số của phiên bản E32 hiện tại
- Baudrate: 9600
- Thông định dạng lệnh
  ![image](https://github.com/atfox272/JustNotation/assets/99324602/705165d0-2dce-41df-8a19-fc8f5a6dcff5)

- Sau khi hoàn thành việc nhận lệnh thì sau 5ms module E32 sẽ phản hồi lại thông tin thông số về phiên bản E32 hiện tại (C3 32 27 02)

## Các hành vi khi gửi dữ liệu không dây:
- Mode: 0 
- Baudrate: 115200

- Sau khi nhận được gói dữ liệu đầu tiên thì chân AUX sẽ xuống mức thấp, và thực hiện lưu dữ liệu vào buffer (buffer 512 bytes).
- Việc gửi dữ liệu không dây qua UART_node sẽ được bắt đầu khi thỏa 1 trong 2 điều khiện sau:
  + Module không nhân được bất kỳ dữ liệu nào trong thời gian 3 frame (~5ms)
  + Module nhận dc đủ 58 bytes chứa trong buffer
- Tiếp theo là đến quá trình gửi dữ liệu không dây, module UART_node sẽ tiến hành đọc dữ liệu trong buffer và gửi thông quá chân TX_node với tốc độ baudrate là 115200.
- Sau khi lấy dữ liệu cuối cùng ra khỏi buffer và bắt đầu gửi, thì chân AUX sẽ lên mức HIGH

- Ví dụ về trường hợp Controller gửi hơn 58bytes vào E32
  ![MODE0_wirelessSend_gt58](https://github.com/atfox272/RF_Transceiver/assets/99324602/d5976b5e-8c0a-4de0-8f60-917c9af1187e)


## Các hành vi nhận dữ liệu không dây:
- Mode: 0
- Baudrate: 115200

- Việc nhận dữ liệu sẽ không dây sẽ thông qua chân RX_node của UART_node
- Sau khi nhận gói dữ liệu đầu tiên, chân AUX sẽ xuống mức LOW và sau 2.5ms thì Module sẽ tiến hành gửi gói dữ liệu không dây đó cho Controller qua chân TX_mcu
- Sau khi gửi gói dữ liệu cuối cùng thì chân AUX sẽ lên mức HIGH ngay lập tực
  ![MODE0_wirelessReceive](https://github.com/atfox272/RF_Transceiver/assets/99324602/2f12e512-6c71-43bb-b9b8-85c5c978a475)

## Hành vi chuyển MODE:
- Khi người dùng thiết lập mode khác so với mode trước đó, thì module sẽ đổi mode sau khi module vào trạng thái IDLE (chân AUX lên mức HIGH)
- 
# Các thông số giao tiếp mặc định
- UART_mcu:
	+ MODE0: 115200 (8N1)
	+ MODE3: 9600 (8N1)
- UART_node:
  + MODE0: 115200 (8N1)
  + MODE3: 115200 (8N1)

# Các thông khác
## Tổng số tài nguyên sử dụng của FPGA
- LUTs: 2507 LUTs
- FlipFlop: 4593 FFs
## Critical Path
- Path of: read_512buffer(~9 MUXs of MEM) &#8594; MUXs &#8594; FSM_MUXs
- Total Delay: 6.62 ns
	+ Logic Delay 2.161 ns 
	+ Net Delay 4.459 ns


# Hướng dẫn sử dụng:
- Bước 1: Kết nối các chân tương ứng của Arty-z7 với Board Controller (các chân AUX - M1 - M0 - RX_mcu - TX_mcu) và các module đọc thông tin dữ liệu không dây (các chân RX_node - TX_node)
- Bước 2: Nạp Bitstream lên board Arty-z7 (RF_transceiver_2.runs/impl_1/RF_transceiver_3module.bit)
  + [Bitstream File](https://github.com/atfox272/RF_Transceiver/blob/main/RF_transceiver_2.runs/impl_1/RF_transceiver_3module.bit)
- Bước 3: Sau khi nạp bitstream lên board thì tiến hành reset board thông qua nut nhấn BUTTON[0] trên board Arty-z7
  + Ở đây, hành vi của chân AUX sẽ giống như hành vi khởi động của E32
- Bước 4: Tiếp theo Mode của trạng thái sẽ phụ thuộc vào chân M1 và M0 mà người dùng thiết lập

# Lưu ý: 
- Về sơ đồ nối chân: chú ý các chân RX-TX sẽ lần lượt là chân RX-TX của node (không phải chân RX-TX tương ứng với controller)
- Button RESET được cấu hình ở BUTTON[0] ở board Arty-z7
- Người dùng không nên cố gắng thiết lập module thành MODE 1 và MODE 2, mặc dù module sẽ đưa tất cả về MODE 0 nhưng "Mode controller" sẽ luôn vào trạng thái đổi mode và chân AUX sẽ liên tục vào đưa xuống mức LOW (Working state), do đó, để "Mode controller" hoạt động ổn định thì người dùng nên thay đổi mode (điều chỉnh M1 và M0) trước khi module sang trạng thái IDLE (trước khi AUX lên mức HIGH)
