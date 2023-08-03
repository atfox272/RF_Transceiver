`timescale 1ns / 1ps
module controller_RF_transceiver_mode0_tb;  
        // Data
        parameter DATA_WIDTH = 8;
        parameter END_WAITING_SEND_WLESS_DATA = 2000;
        parameter START_COUNTER_SEND_WLESS_DATA = 0;
        parameter FIFO512_DEPTH = 512;
    
    
    reg internal_clk;
    reg M0_sync;
    reg M1_sync;
    wire AUX;
    
    reg RX_flag_node;
    reg [DATA_WIDTH - 1:0] data_from_uart_node;
    wire TX_use_mcu;
    wire TX_flag_mcu;
    wire [DATA_WIDTH - 1:0] data_to_uart_mcu;
    
    wire TX_mcu;
    wire RX_mcu;
    
    reg rst_n;
    // Build 1 uart_mcu and build fake signal of external MCU
    // Controller
    controller_RF_transceiver   #(
                                .END_WAITING_SEND_WLESS_DATA(END_WAITING_SEND_WLESS_DATA),
                                .START_COUNTER_SEND_WLESS_DATA(START_COUNTER_SEND_WLESS_DATA),
                                .FIFO512_DEPTH(FIFO512_DEPTH)
                                )controller(
                                .internal_clk(internal_clk),
                                .AUX(AUX),
                                .M0_sync(M0_sync),
                                .M1_sync(M1_sync),
                                //////
                                .RX_flag_node(RX_flag_node),
                                .data_from_uart_node(data_from_uart_node),
                                .TX_flag_mcu(TX_flag_mcu),
                                .TX_use_mcu(TX_use_mcu),
                                .data_to_uart_mcu(data_to_uart_mcu),
                                /////
                                .rst_n(rst_n)
                                );
    // UART to MCU
    wire [7:0] TX_config_register_external = 8'b00100011;
    com_uart uart_mcu( 
                    .clk(internal_clk), 
                    .TX_config_register(TX_config_register_external),
                    .RX(RX_mcu), 
                    .TX(TX_mcu), 
                    .data_bus_in(data_to_uart_mcu), 
                    .TX_use(TX_use_mcu),
                    .TX_flag(TX_flag_mcu),
                    .rst_n(rst_n)
                    );
    
    initial begin
        internal_clk <= 0;
        M0_sync <= 0;
        M1_sync <= 0;
        RX_flag_node <= 0;
        data_from_uart_node <= 0;
        rst_n <= 1;
        #1 rst_n <= 0;
        #9 rst_n <= 1;
    end
    initial begin
        #11;
        
        data_from_uart_node <= 8'hFF;    // HEAD 
        #1 RX_flag_node <= 0;
        #1 RX_flag_node <= 1;
        #1 RX_flag_node <= 0;
        
        data_from_uart_node <= 8'h11;    // HEAD 
        #1 RX_flag_node <= 0;
        #1 RX_flag_node <= 1;
        #1 RX_flag_node <= 0;
        
        data_from_uart_node <= 8'h22;    // HEAD 
        #1 RX_flag_node <= 0;
        #1 RX_flag_node <= 1;
        #1 RX_flag_node <= 0;
        
        data_from_uart_node <= 8'h33;    // HEAD 
        #1 RX_flag_node <= 0;
        #1 RX_flag_node <= 1;
        #1 RX_flag_node <= 0;
        
        data_from_uart_node <= 8'h44;    // HEAD 
        #1 RX_flag_node <= 0;
        #1 RX_flag_node <= 1;
        #1 RX_flag_node <= 0;
        
        data_from_uart_node <= 8'h55;    // HEAD 
        #1 RX_flag_node <= 0;
        #1 RX_flag_node <= 1;
        #1 RX_flag_node <= 0;
        
        data_from_uart_node <= 8'h66;    // HEAD 
        #1 RX_flag_node <= 0;
        #1 RX_flag_node <= 1;
        #1 RX_flag_node <= 0;
    end
    
    initial begin
        forever #1 internal_clk <= ~internal_clk;
    end
    
    
endmodule