`timescale 1ns / 1ps
module controller_RF_transceiver_mode3_tb;  
        // Data
        parameter DATA_WIDTH = 8;
        // UART configuration parament
        parameter UART_CONFIG_WIDTH = 8;
        parameter BAUDRATE_SEL_MSB = 7; // Index of this bit in reg
        parameter BAUDRATE_SEL_LSB = 5; // Index of this bit in reg
        parameter STOP_BIT_CONFIG = 4; // Index of this bit in reg
        parameter PARITY_BIT_CONFIG_MSB = 3; // Index of this bit in reg
        parameter PARITY_BIT_CONFIG_LSB = 2; // Index of this bit in reg
        parameter DATA_BIT_CONFIG_MSB = 1; // Index of this bit in reg
        parameter DATA_BIT_CONFIG_LSB = 0; // Index of this bit in reg
        parameter TX_USE_IDLE_STATE = 0;
        // Transaction
        parameter TRANSACTION_WIDTH = 8;
        // INIT parameter setting command buffer  
        parameter INIT_BUFFER_HEAD = {8{1'b0}};
        parameter INIT_BUFFER_ADDH = {8{1'b0}};
        parameter INIT_BUFFER_ADDL = {8{1'b0}};
        parameter INIT_BUFFER_SPED = {8{1'b0}};
        parameter INIT_BUFFER_CHAN = {8{1'b0}};
        parameter INIT_BUFFER_OPTION = {8{1'b0}};
        // Detect Instruction
        parameter HEAD_DETECT_1 = 8'hC0;        // Load config
        parameter HEAD_DETECT_2 = 8'hC2;        // 
        parameter RET_CONFIG_DETECT = 8'hC1;    // Return config
        parameter RET_VERSION_DETECT = 8'hC3;    // Return version
        parameter RESET_DETECT = 8'hC4;
        // Version
        parameter VERSION_PACKET_1 = 8'hC3;     // Format (default)
        parameter VERSION_PACKET_2 = 8'h32;     // Format (default)
        parameter VERSION_PACKET_3 = 8'h27;     // My config
        parameter VERSION_PACKET_4 = 8'h02;     // My config
        // Mode encode
        parameter MODE_3 = 3;
        // 512bytes FIFO buffer
        parameter FIFO512_DEPTH = 512;
        parameter START_WIRELESS_TRANS_VALUE = 58;
    
    
    reg internal_clk;
    reg M0_sync;
    reg M1_sync;
    wire AUX;
    // UART to MCU
    wire TX_use_mcu;
    reg RX_flag_mcu;
    reg [DATA_WIDTH - 1:0]          data_from_uart_mcu;
    wire [DATA_WIDTH - 1:0]          data_to_uart_mcu;
    wire [UART_CONFIG_WIDTH - 1:0]   uart_mcu_config_reg;
    // UART to NODE 
//    wire                                TX_use_node;
//    wire                                RX_flag_node;      
//    input   wire    [DATA_WIDTH - 1:0]          data_from_uart_node,
//    output  wire    [DATA_WIDTH - 1:0]          data_to_uart_node,
    
    
    reg rst_n;
    // Build 1 uart_mcu and build fake signal of external MCU
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
                                .START_WIRELESS_TRANS_VALUE(START_WIRELESS_TRANS_VALUE)
                                )controller(
                                .internal_clk(internal_clk),
                                .AUX(AUX),
                                // UART_mcu
                                .data_from_uart_mcu(data_from_uart_mcu),
                                .data_to_uart_mcu(data_to_uart_mcu),
                                .TX_use_mcu(TX_use_mcu),
                                .RX_flag_mcu(RX_flag_mcu),
                                .uart_mcu_config_reg(uart_mcu_config_reg),
//                                .TX_use_node(TX_use_node),
//                                .RX_flag_node(RX_flag_node),
//                                .data_from_uart_node(data_out_uart_node),
//                                .data_to_uart_node(data_in_uart_node),
                                .M0_sync(M0_sync),
                                .M1_sync(M1_sync),
                                .rst_n(rst_n)
                                );
    
    initial begin
        internal_clk <= 0;
        M0_sync <= 1;
        M1_sync <= 1;
        RX_flag_mcu <= 0;
        data_from_uart_mcu <= 0;
        rst_n <= 1;
        #1 rst_n <= 0;
        #9 rst_n <= 1;
    end
    initial begin
        #11;
        
        data_from_uart_mcu <= 8'hC2;    // HEAD 
        #1 RX_flag_mcu <= 0;
        #1 RX_flag_mcu <= 1;
        #1 RX_flag_mcu <= 0;
        
        data_from_uart_mcu <= 8'h27;    // ADDH
        #1 RX_flag_mcu <= 0;
        #1 RX_flag_mcu <= 1;
        #1 RX_flag_mcu <= 0;
        
        data_from_uart_mcu <= 8'h02;    // ADDL
        #1 RX_flag_mcu <= 0;
        #1 RX_flag_mcu <= 1;
        #1 RX_flag_mcu <= 0;
        
        data_from_uart_mcu <= 8'hFF;    // SPED 
        #1 RX_flag_mcu <= 0;
        #1 RX_flag_mcu <= 1;
        #1 RX_flag_mcu <= 0;
        
        data_from_uart_mcu <= 8'h00;    // CHAN
        #1 RX_flag_mcu <= 0;
        #1 RX_flag_mcu <= 1;
        #1 RX_flag_mcu <= 0;
        
        data_from_uart_mcu <= 8'hAA;
        #1 RX_flag_mcu <= 0;
        #1 RX_flag_mcu <= 1;
        #1 RX_flag_mcu <= 0;
        
        // MCU ask case
        
        data_from_uart_mcu <= 8'hC3;
        #1 RX_flag_mcu <= 0;
        #1 RX_flag_mcu <= 1;
        #1 RX_flag_mcu <= 0;
        
        data_from_uart_mcu <= 8'hC3;
        #1 RX_flag_mcu <= 0;
        #1 RX_flag_mcu <= 1;
        #1 RX_flag_mcu <= 0;
        
        data_from_uart_mcu <= 8'hC3;
        #1 RX_flag_mcu <= 0;
        #1 RX_flag_mcu <= 1;
        #1 RX_flag_mcu <= 0;
    end
    
    initial begin
        forever #1 internal_clk <= ~internal_clk;
    end
    
    
endmodule
