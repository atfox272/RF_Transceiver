module RF_transceiver
    #(  // Device parameter
        parameter INTERNAL_CLK      = 50000000,
		  
		  // Use for Arty-Z7
        parameter PRESCALER_UART    = 8'd10,             // Use clock divider (prescaler) to reduce power consumption
        parameter PRESCALER_CTRL    = 8'd50,             // Use clock divider (prescaler) to reduce power consumption
        // Use for DE10 Nano
//        parameter PRESCALER_UART    = 8'd4,             // Use clock divider (prescaler) to reduce power consumption
//        parameter PRESCALER_CTRL    = 8'd20,             // Use clock divider (prescaler) to reduce power consumption
        
	parameter CLOCK_DIVIDER_UART     =  8'd5,
        parameter CLOCK_DIVIDER_UNIQUE_1 =  8'd55,    // <value> = ceil(Internal clock / (<BAUDRATE_SPEED> * 2))  (115200)
        parameter CLOCK_DIVIDER_UNIQUE_2 =  10'd652,   // <value> = ceil(Internal clock / (<BAUDRATE_SPEED> * 2))  (9600)
        // Sleep mode configutation (When you are in sleep-mode, the module will delay 1 clock cycle to the wake-up module)
        parameter SLEEP_MODE_UART_MCU   = 1,  
        parameter SLEEP_MODE_UART_NODE  = 1,
        
        // UART configuration parament
        parameter UART_CONFIG_WIDTH     = 8,
        // UART_node & UART_mcu (mode3) config register
        parameter TX_UART_NODE_CONFIG   = 8'b10000011,  // baud38400 - 1stop - 0parity - 8bitData
        parameter RX_UART_NODE_CONFIG   = 8'b10000011,  // baud38400 - 1stop - 0parity - 8bitData
        parameter UART_MCU_MODE3_CONFIG = 8'b10100011,  // baud9600  - 1stop - 0parity - 8bitData
        
        // Controller
        // Transaction
        parameter TRANSACTION_WIDTH = 8,
        // Detect Instruction
        parameter HEAD_DETECT_1     =   8'hC0,    // Head (~volatile)
        parameter HEAD_DETECT_2     =   8'hC2,    // Head (volatile)
        parameter RET_CONFIG_DETECT =   8'hC1,    // Return config
        parameter RET_VERSION_DETECT=   8'hC3,    // Return version
        parameter RESET_DETECT      =   8'hC4,
        // Version
        parameter VERSION_PACKET_1 = 8'hC3,     // Format (default)
        parameter VERSION_PACKET_2 = 8'h32,     // Format (default)
        parameter VERSION_PACKET_3 = 8'h27,     // My config
        parameter VERSION_PACKET_4 = 8'h02,     // My config
        // 512bytes FIFO buffer
//        parameter FIFO512_DEPTH = 10'd63,   
//      Top parameter for power testing 
        parameter BUFFER_512_DEPTH           = 10'd512,   
        parameter START_WIRELESS_TRANS_VALUE = 8'd58,   // If data in buffer is up to <58> bytes, wireless transmission will start
        // UART FIFO 
        parameter FIFO_DEPTH = 10'd64,
        // State of module ENCODER (One-hot state-machine encoding)
        parameter MODULE_IDLE_STATE     = 3,    // (wireless_trans and wireless_recei is not woking 
        parameter MODULE_WTRANS_STATE   = 2,    // (wireless_trans is working )
        parameter MODULE_WRECEIVE_STATE = 1,    // (wireless_receiver is working)
        parameter MODULE_PROGRAM_STATE  = 0,    // (programed state is working
        // Data
        parameter DATA_WIDTH = 8,
        // Waiting module for 3 times empty transaction
        //        <divider_name>  = <divider_value>
        // waiting_time = (<divider_value> * 2) / INTERNAL_CLK
//        parameter END_COUNTER_RX_PACKET = 1627,         // 3 transaction time (for 115.200)
        parameter END_COUNTER_RX_PACKET         = 651,    // 3 transaction time (for 115200)
        parameter END_WAITING_SEND_WLESS_DATA   = 6250,   // 2-3ms	(Assume: 2.5)
        parameter END_SELF_CHECKING             = 450000, // No information (Following real E32: 180ms)
        parameter END_POWER_ON_CHECK            = 750000, // Asume: 500ms
        parameter END_MODE_SWITCH               = 15000,  // Average: 6ms
        parameter END_PROCESS_COMMAND           = 12500,  // 5ms
        parameter END_PROCESS_RESET             = 2500000,// 1s
        // Mode controller  
        parameter DEFAULT_MODE = 0
    )
    (
    input   wire        device_clk,
    // MCU
    input   wire        M0,
    input   wire        M1,
    output  wire        TX_mcu,
    input   wire        RX_mcu,
    output  wire        AUX,
    // UART-Node
    output  wire        TX_node,
    input   wire        RX_node,
  
    input   wire        rst
    
    // Debug 
    
//    ,output wire [3:0]  state_module_wire
    // Add pin out for Testbench
//    ,output [DATA_WIDTH - 1:0] data_bus_out_node
////    ,output RX_flag_node_wire
//    ,output TX_use_mcu_wire
//    ,output [1:0] state_counter_mode0_receive_wire
//    ,output [0:0] debug_ctrl_1
    // New debugger
//    ,output [DATA_WIDTH - 1:0] data_out_uart_mcu_wire
//    ,output RX_flag_mcu_wire 
//    ,output TX_use_node_wire
//    ,output [DATA_WIDTH - 1:0] data_in_uart_node_wire
//    ,output internal_clk_wire
//     ,output [1:0] mode_controller_wire
    );
    wire rst_n = ~rst;
    // Clock
    wire internal_clk_uart;
    wire internal_clk_ctrl;
    // Mode controller 
    wire M1_sync;
    wire M0_sync;
    wire AUX_mode_ctrl;
    wire AUX_state_ctrl;
    wire AUX_uart_ctrl;
    wire AUX_power_on_ctrl;
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
    // UART_node 
    wire RX_node_enable;
    wire TX_node_enable;
    wire TX_complete_mcu;   // Send all packet in fifo
    // UART to MCU
    wire TX_mcu_complete;
    wire TX_mcu_enable;
    wire RX_mcu_enable;
    // State of module
    wire [3:0] state_module;
    
    // Add Prescaler_module to reduce power consumption
//    assign internal_clk = device_clk;
    // Prescaler for UART 
    prescaler_module#(
                    .IDLE_CLK(1'b0),
                    .REVERSE_CLK(1'b0),
                    .MULTI_PRESCALER(1'b0),
                    .HARDCONFIG_DIV(PRESCALER_UART)
                    )UART_prescaler(
                    .clk_in(device_clk),
                    .prescaler_enable(1'b1),
                    .clk_1(internal_clk_uart),
                    .rst_n(rst_n)
                    );
    // Prescaler for Controller
    prescaler_module#(
                    .IDLE_CLK(1'b0),
                    .REVERSE_CLK(1'b0),
                    .MULTI_PRESCALER(1'b0),
                    .HARDCONFIG_DIV(PRESCALER_CTRL)
                    )Controller_prescaler(
                    .clk_in(device_clk),
                    .prescaler_enable(1'b1),
                    .clk_1(internal_clk_ctrl),
                    .rst_n(rst_n)
                    );
    // AUX controller
    assign AUX = AUX_mode_ctrl & AUX_state_ctrl & AUX_uart_ctrl & AUX_power_on_ctrl;
    // Mode controller
    mode_controller_RF_transceiver 
                #(
                .DEFAULT_MODE(DEFAULT_MODE),
                .END_POWER_ON_CHECK(END_POWER_ON_CHECK),               
                .END_MODE_SWITCH(END_MODE_SWITCH)               
                )mode_controller(
                .internal_clk(internal_clk_ctrl),
                .AUX_state_ctrl(AUX_state_ctrl),
                .AUX_mode_ctrl(AUX_mode_ctrl),
                .AUX_uart_ctrl(AUX_uart_ctrl),
                .AUX_power_on_ctrl(AUX_power_on_ctrl),
                .UART_mcu_complete(TX_mcu_complete),
                .M0(M0),
                .M1(M1),
                .M1_sync(M1_sync),
                .M0_sync(M0_sync),
                .rst_n(rst_n)
                );
    // Power checking area            
//    assign M0_sync = 1'b0;
//    assign M1_sync = 1'b0;
    //
    // In this block, I will convert SPED_encode_config to my encode config 
    // Baudrate speed 
    assign uart_mcu_my_config_reg[7:5] = 3'b100;    // baudrate_speed is always 115200 (except: in mode 3)
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
    
    
    assign RX_mcu_enable = (state_module[MODULE_IDLE_STATE] | state_module[MODULE_WTRANS_STATE] | state_module[MODULE_PROGRAM_STATE]);
    assign TX_mcu_enable = (state_module[MODULE_WRECEIVE_STATE] | state_module[MODULE_PROGRAM_STATE]);
        
    assign AUX_uart_ctrl = TX_mcu_complete;
    
    com_uart #(
              .CLOCK_DIVIDER(CLOCK_DIVIDER_UART),
              .CLOCK_DIVIDER_UNIQUE_1(CLOCK_DIVIDER_UNIQUE_1),
              .CLOCK_DIVIDER_UNIQUE_2(CLOCK_DIVIDER_UNIQUE_2),
              .FIFO_DEPTH(FIFO_DEPTH),
              .SLEEP_MODE(SLEEP_MODE_UART_MCU)
              )uart_to_mcu(
              .clk(internal_clk_uart),
              .TX(TX_mcu),
              .RX(RX_mcu),
              .TX_use(TX_use_mcu),
              .TX_flag(TX_flag_mcu),
              .TX_complete(TX_mcu_complete),
              .RX_use(RX_use_mcu),
              .RX_flag(RX_flag_mcu),
              .TX_config_register(uart_mcu_config_reg),
              .RX_config_register(uart_mcu_config_reg),
              .data_bus_in(data_in_uart_mcu),
              .data_bus_out(data_out_uart_mcu),
              .TX_enable(TX_mcu_enable),
              .RX_enable(RX_mcu_enable),
              .rst_n(rst_n)
              );
    
    
    
    assign RX_node_enable = (state_module[MODULE_IDLE_STATE] | state_module[MODULE_WRECEIVE_STATE]);
    assign TX_node_enable = (state_module[MODULE_WTRANS_STATE] | !TX_complete_mcu);
    // If TX_node module hasn't finished transaction yet, TX_node still enable until TX_complete
    
    com_uart #(
              .CLOCK_DIVIDER(CLOCK_DIVIDER_UART),
              .CLOCK_DIVIDER_UNIQUE_1(CLOCK_DIVIDER_UNIQUE_1),
              .CLOCK_DIVIDER_UNIQUE_2(CLOCK_DIVIDER_UNIQUE_2),
              .FIFO_DEPTH(FIFO_DEPTH),
              .SLEEP_MODE(SLEEP_MODE_UART_NODE)
              )uart_to_node(
              .clk(internal_clk_uart),
              .TX(TX_node),
              .RX(RX_node),
              .TX_use(TX_use_node),
              .RX_use(RX_use_node),
              .RX_flag(RX_flag_node),
              .TX_flag(TX_flag_node),
              .TX_complete(TX_complete_mcu),
              .TX_config_register(TX_UART_NODE_CONFIG),
              .RX_config_register(RX_UART_NODE_CONFIG),
              .data_bus_in(data_in_uart_node),
              .data_bus_out(data_out_uart_node),
              .TX_enable(TX_node_enable),
              .RX_enable(RX_node_enable),
              .rst_n(rst_n)
             );
                           
    
    
    
    // Controller
    controller_RF_transceiver   #(
                                .DATA_WIDTH(DATA_WIDTH),
                                .UART_CONFIG_WIDTH(UART_CONFIG_WIDTH),
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
                                .FIFO512_DEPTH(BUFFER_512_DEPTH),
                                .START_WIRELESS_TRANS_VALUE(START_WIRELESS_TRANS_VALUE),
                                .END_COUNTER_RX_PACKET(END_COUNTER_RX_PACKET),
                                .END_WAITING_SEND_WLESS_DATA(END_WAITING_SEND_WLESS_DATA),
                                .END_SELF_CHECKING(END_SELF_CHECKING),
                                .END_PROCESS_COMMAND(END_PROCESS_COMMAND),
                                .END_PROCESS_RESET(END_PROCESS_RESET)
                                )controller(
                                .internal_clk(internal_clk_ctrl),
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
                                .TX_complete_mcu(TX_complete_mcu),
                                .RX_use_node(RX_use_node),
                                .RX_flag_node(RX_flag_node),
                                .data_from_uart_node(data_out_uart_node),
                                .data_to_uart_node(data_in_uart_node),
                                .M0_sync(M0_sync),
                                .M1_sync(M1_sync),
                                // State of module
                                .state_module(state_module),
                                .rst_n(rst_n)
                                // debug 
//                                ,.state_counter_mode0_receive_wire(state_counter_mode0_receive_wire)
//                                ,.debug_ctrl_1(debug_ctrl_1)
                                );
    // Debug 
//    assign data_bus_out_node = data_out_uart_node;
//    assign RX_flag_node_wire = RX_flag_node;
//    assign data_in_uart_mcu_wire = data_in_uart_mcu;
//    assign TX_use_mcu_wire = TX_use_mcu;
    
    // New debugger
//    assign data_out_uart_mcu_wire = data_out_uart_mcu;
//    assign RX_flag_mcu_wire = RX_flag_mcu;
    
//    assign TX_use_node_wire = TX_use_node;
//    assign data_in_uart_node_wire = data_in_uart_node;
//    assign state_module_wire = state_module;
//    assign internal_clk_wire = internal_clk;
    assign mode_controller_wire = {M1_sync, M0_sync};
endmodule
