module RF_transceiver
    #(  // Device parameter
        parameter INTERNAL_CLK = 10000000,
        // UART configuration parament
        parameter UART_CONFIG_WIDTH = 8,
        parameter BAUDRATE_SEL_MSB = 7, // Index of this bit in reg
        parameter BAUDRATE_SEL_LSB = 5, // Index of this bit in reg
        parameter STOP_BIT_CONFIG = 4, // Index of this bit in reg
        parameter PARITY_BIT_CONFIG_MSB = 3, // Index of this bit in reg
        parameter PARITY_BIT_CONFIG_LSB = 2, // Index of this bit in reg
        parameter DATA_BIT_CONFIG_MSB = 1, // Index of this bit in reg
        parameter DATA_BIT_CONFIG_LSB = 0, // Index of this bit in reg
        // UART_node & UART_mcu (mode3) config register
        parameter TX_UART_NODE_CONFIG = 8'b00100011,       // baud38400 - 1stop - 0parity - 8bitData
        parameter RX_UART_NODE_CONFIG = 8'b01100011,       // baud38400 - 1stop - 0parity - 8bitData
        parameter UART_MCU_MODE3_CONFIG = 8'b00100011,  // baud9600  - 1stop - 0parity - 8bitData
        // Controller
        // Transaction
        parameter TRANSACTION_WIDTH = 8,
        // Detect Instruction
        parameter HEAD_DETECT_1 = 8'hC0,        // Load config
        parameter HEAD_DETECT_2 = 8'hC2,        // 
        parameter RET_CONFIG_DETECT = 8'hC1,    // Return config
        parameter RET_VERSION_DETECT = 8'hC3,    // Return version
        parameter RESET_DETECT = 8'hC4,
        // Version
        parameter VERSION_PACKET_1 = 8'hC3,     // Format (default)
        parameter VERSION_PACKET_2 = 8'h32,     // Format (default)
        parameter VERSION_PACKET_3 = 8'h27,     // My config
        parameter VERSION_PACKET_4 = 8'h02,     // My config
        // 512bytes FIFO buffer
        parameter FIFO512_DEPTH = 10'd512,
        parameter START_WIRELESS_TRANS_VALUE = 8'd58,   // If data in buffer is up to <58> bytes, wireless transmission will start
        // Delay unit
        parameter DELAY_UNIT_CLK = 100,
        // Data
        parameter DATA_WIDTH = 8,
        // Waiting module for 3 times empty transaction
        parameter END_COUNTER_RX_PACKET = 500000,    // count (END_COUNTER - START_COUNTER) clock cycle
        parameter START_COUNTER_RX_PACKET = 0,
        parameter END_WAITING_SEND_WLESS_DATA = 200000,
        parameter START_COUNTER_SEND_WLESS_DATA = 0,
        parameter END_SELF_CHECKING = 5000,
        // Mode controller
        parameter DEFAULT_MODE = 3
    )
    (
    input internal_clk,
    // MCU
    input M0,
    input M1,
    output TX_mcu,
    input RX_mcu,
    output AUX,
    // UART-Node
    output TX_node,
    input RX_node,
    input [UART_CONFIG_WIDTH - 1:0] Node_UART_config,   // TX_node module and RX_node module use same configuration parament
    
    input rst_n
    
    // Debug 
    // Add pin out for Testbench
//    ,output [DATA_WIDTH - 1:0] data_bus_out_node
//    ,output [DATA_WIDTH - 1:0] data_in_uart_mcu_wire
//    ,output RX_flag_node_wire
//    ,output TX_use_mcu_wire
    ,output [1:0] state_counter_mode0_receive_wire
//    ,output RX_flag_mcu_wire 
    );
    // Mode controller 
    wire M1_sync;
    wire M0_sync;
    wire AUX_mode_ctrl;
    wire AUX_state_ctrl;
    // Controller to UART_mcu interface
    wire TX_use_mcu;
    wire TX_flag_mcu;
    wire RX_use_mcu;
    wire RX_flag_mcu;
    wire [DATA_WIDTH - 1: 0] data_out_uart_mcu;
    wire [DATA_WIDTH - 1: 0] data_in_uart_mcu;
    wire [UART_CONFIG_WIDTH - 1:0] uart_mcu_config_reg;
    wire [UART_CONFIG_WIDTH - 1:0] uart_mcu_my_config_reg;
    wire [UART_CONFIG_WIDTH - 1:0] uart_mcu_SPED_config_reg;
    // Controller to UART_node interface 
    wire [DATA_WIDTH - 1: 0] data_in_uart_node;
    wire [DATA_WIDTH - 1: 0] data_out_uart_node;
    wire TX_use_node;
    wire RX_use_node;
    wire RX_flag_node;
    wire TX_flag_node;
    
    // AUX controller
    assign AUX = AUX_mode_ctrl & AUX_state_ctrl;
    
    // Mode controller
    mode_controller_RF_transceiver 
                #(
                .DEFAULT_MODE(DEFAULT_MODE)
                )mode_controller(
                .internal_clk(internal_clk),
                .AUX_state_ctrl(AUX_state_ctrl),
                .AUX_mode_ctrl(AUX_mode_ctrl),
                .M0(M0),
                .M1(M1),
                .M1_sync(M1_sync),
                .M0_sync(M0_sync),
                .rst_n(rst_n)
                );
    
    // In this block, I will convert SPED_encode_config to my encode config 
    // Baudrate speed 
    assign uart_mcu_my_config_reg[7:5] = uart_mcu_SPED_config_reg[5:3] - 3'b010; 
    // Stop bit
    assign uart_mcu_my_config_reg[4] = 0;                               
    // Parity bit 
    assign uart_mcu_my_config_reg[3] = uart_mcu_SPED_config_reg[7] ^ uart_mcu_SPED_config_reg[6];
    // Even or Odd parity
    assign uart_mcu_my_config_reg[2] = uart_mcu_SPED_config_reg[7];
    // Data bit 
    assign uart_mcu_my_config_reg[1:0] = 2'b11; // = 8 bits
    //////////////////////////////////////////////////////////////////////////////
    assign uart_mcu_config_reg = (M1_sync == 1 & M0_sync == 1) ? UART_MCU_MODE3_CONFIG : uart_mcu_my_config_reg;
    // UART to MCU
    com_uart #(
              .UART_CONFIG_WIDTH(UART_CONFIG_WIDTH),
              .BAUDRATE_SEL_MSB(BAUDRATE_SEL_MSB),
              .BAUDRATE_SEL_LSB(BAUDRATE_SEL_LSB),
              .STOP_BIT_CONFIG(STOP_BIT_CONFIG),
              .PARITY_BIT_CONFIG_MSB(PARITY_BIT_CONFIG_MSB),
              .PARITY_BIT_CONFIG_LSB(PARITY_BIT_CONFIG_LSB),
              .DATA_BIT_CONFIG_MSB(DATA_BIT_CONFIG_MSB),
              .DATA_BIT_CONFIG_LSB(DATA_BIT_CONFIG_LSB)
              )uart_to_mcu(
              .clk(internal_clk),
              .TX(TX_mcu),
              .RX(RX_mcu),
              .TX_use(TX_use_mcu),
              .TX_flag(TX_flag_mcu),
              .RX_use(RX_use_mcu),
              .RX_flag(RX_flag_mcu),
              .TX_config_register(uart_mcu_config_reg),
              .RX_config_register(uart_mcu_config_reg),
              .data_bus_in(data_in_uart_mcu),
              .data_bus_out(data_out_uart_mcu),
              .rst_n(rst_n)
              );
    
    
    // UART_node 
    com_uart #(
              .UART_CONFIG_WIDTH(UART_CONFIG_WIDTH),
              .BAUDRATE_SEL_MSB(BAUDRATE_SEL_MSB),
              .BAUDRATE_SEL_LSB(BAUDRATE_SEL_LSB),
              .STOP_BIT_CONFIG(STOP_BIT_CONFIG),
              .PARITY_BIT_CONFIG_MSB(PARITY_BIT_CONFIG_MSB),
              .PARITY_BIT_CONFIG_LSB(PARITY_BIT_CONFIG_LSB),
              .DATA_BIT_CONFIG_MSB(DATA_BIT_CONFIG_MSB),
              .DATA_BIT_CONFIG_LSB(DATA_BIT_CONFIG_LSB)
              )uart_to_node(
              .clk(internal_clk),
              .TX(TX_node),
              .RX(RX_node),
              .TX_use(TX_use_node),
              .RX_use(RX_use_node),
              .RX_flag(RX_flag_node),
              .TX_flag(TX_flag_node),
              .TX_config_register(TX_UART_NODE_CONFIG),
              .RX_config_register(RX_UART_NODE_CONFIG),
              .data_bus_in(data_in_uart_node),
              .data_bus_out(data_out_uart_node),
              .rst_n(rst_n)
             );
                           
    
    
    
    // Controller
    controller_RF_transceiver   #(
                                .DATA_WIDTH(DATA_WIDTH),
                                .UART_CONFIG_WIDTH(UART_CONFIG_WIDTH),
                                .BAUDRATE_SEL_MSB(BAUDRATE_SEL_MSB),
                                .BAUDRATE_SEL_LSB(BAUDRATE_SEL_LSB),
                                .STOP_BIT_CONFIG(STOP_BIT_CONFIG),
                                .PARITY_BIT_CONFIG_MSB(PARITY_BIT_CONFIG_MSB),
                                .PARITY_BIT_CONFIG_LSB(PARITY_BIT_CONFIG_LSB),
                                .DATA_BIT_CONFIG_MSB(DATA_BIT_CONFIG_MSB),
                                .DATA_BIT_CONFIG_LSB(DATA_BIT_CONFIG_LSB),
                                .TRANSACTION_WIDTH(TRANSACTION_WIDTH),
                                .HEAD_DETECT_1(HEAD_DETECT_1),
                                .HEAD_DETECT_2(HEAD_DETECT_2),
                                .RET_CONFIG_DETECT(RET_CONFIG_DETECT),
                                .RET_VERSION_DETECT(RET_VERSION_DETECT),
                                .RESET_DETECT(RESET_DETECT),
                                .VERSION_PACKET_1(VERSION_PACKET_1),
                                .VERSION_PACKET_2(VERSION_PACKET_2),
                                .VERSION_PACKET_3(VERSION_PACKET_3),
                                .VERSION_PACKET_4(VERSION_PACKET_4),
                                .FIFO512_DEPTH(FIFO512_DEPTH),
                                .START_WIRELESS_TRANS_VALUE(START_WIRELESS_TRANS_VALUE),
                                .END_COUNTER_RX_PACKET(END_COUNTER_RX_PACKET),
                                .END_WAITING_SEND_WLESS_DATA(END_WAITING_SEND_WLESS_DATA),
                                .END_SELF_CHECKING(END_SELF_CHECKING)
                                )controller(
                                .internal_clk(internal_clk),
                                .AUX(AUX_state_ctrl),
                                // UART_mcu
                                .data_from_uart_mcu(data_out_uart_mcu),
                                .data_to_uart_mcu(data_in_uart_mcu),
                                .TX_use_mcu(TX_use_mcu),
                                .TX_flag_mcu(TX_flag_mcu),
                                .RX_flag_mcu(RX_flag_mcu),
                                .uart_mcu_config_reg(uart_mcu_SPED_config_reg),
                                .TX_use_node(TX_use_node),
                                .TX_flag_node(TX_flag_node),
                                .RX_use_node(RX_use_node),
                                .RX_flag_node(RX_flag_node),
                                .data_from_uart_node(data_out_uart_node),
                                .data_to_uart_node(data_in_uart_node),
                                .M0_sync(M0_sync),
                                .M1_sync(M1_sync),
                                .rst_n(rst_n)
                                // debug 
                                ,.state_counter_mode0_receive_wire(state_counter_mode0_receive_wire)
                                );
    // Debug 
//    assign data_bus_out_node = data_out_uart_node;
//    assign RX_flag_node_wire = RX_flag_node;
//    assign data_in_uart_mcu_wire = data_in_uart_mcu;
//    assign TX_use_mcu_wire = TX_use_mcu;
//    assign RX_flag_mcu_wire = RX_flag_mcu;
endmodule
