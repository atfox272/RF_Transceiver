`timescale 1ps / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/11/2023 09:51:50 PM
// Design Name: 
// Module Name: com_uart_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module com_uart_tb;
//    module com_uart(
//    input clk,                  // Internal clock
//    input [1:0] baudrate_sel,   // From another device
//    input RX,                   // From another device
//    input rst_n,                // Reset_negetive
//    output TX,
//    output [7:0] send_byte_CPU,
//    output write_CPU_en         // When u push all data to buffer ("storage" in "com_uart_receiver"), write_CPU_en will set HIGH and write data from buffer to "send_byte_CPU"
//    );
    
    // UART module 1
    reg clk_1;
    
    reg [7:0] TX_config_register_1;
    reg TX_use_1;                       // Signal from CPU -> register is enable to read (0 <-> disable & 1 <-> enable)
    reg [7:0] buffer_tx_1;           // Take data from CPU and send it to another UART module
    
    reg [7:0] RX_config_register_1;
    wire [7:0] buffer_rx_1;
    wire RX_flag_1;
    reg RX_use_1;
    
    reg rst_n;
    wire wire_1;
    wire wire_2;
    // UART module 2
    reg clk_2;
    
    reg [7:0] TX_config_register_2;
    reg TX_use_2;                       // Signal from CPU -> register is enable to read (0 <-> disable & 1 <-> enable)
    reg [7:0] buffer_tx_2;           // Take data from CPU and send it to another UART module
    
    reg [7:0] RX_config_register_2;
    wire [7:0] buffer_rx_2;
    wire RX_flag_2;
    reg RX_use_2;
    // DEbug
//    wire timer_baudrate_trans;
//    wire timer_baudrate_receiver;
//    wire [2:0] state_debug_2;
//    wire TX_enable_clone_1;
//    wire TX_enable_clone_2;
//    wire TX_free_clone_1;
//    wire TX_free_clone_2;
    com_uart uut_1( .clk(clk_1), 
                    .TX_config_register(TX_config_register_1),
                    .RX_config_register(RX_config_register_1), 
                    .RX(wire_1), 
                    .TX(wire_2), 
                    .data_bus_out(buffer_rx_1),
                    .data_bus_in(buffer_tx_1), 
                    .RX_flag(RX_flag_1), 
                    .RX_use(RX_use_1), 
                    .TX_use(TX_use_1),
                    .rst_n(rst_n)
                    // Debug
//                    ,.TX_enable_clone(TX_enable_clone_1)
//                    ,.TX_free_clone(TX_free_clone_1)
                    );
    com_uart uut_2( .clk(clk_2), 
                    .TX_config_register(TX_config_register_2),
                    .RX_config_register(RX_config_register_2), 
                    .RX(wire_2), 
                    .TX(wire_1), 
                    .data_bus_out(buffer_rx_2),
                    .data_bus_in(buffer_tx_2), 
                    .RX_flag(RX_flag_2), 
                    .RX_use(RX_use_2), 
                    .TX_use(TX_use_2),
                    .rst_n(rst_n)
                    // Debug 
//                    ,.timer_baudrate_trans_clone(timer_baudrate_trans)
//                    ,.timer_baudrate_receiver(timer_baudrate_receiver)
//                    ,.state_debug(state_debug_2)
//                    ,.TX_enable_clone(TX_enable_clone_2)
    
                    );
                    
    
    initial begin
        forever #1 clk_1 <= ~clk_1;
    end
    initial begin
        forever #1 clk_2 <= ~clk_2;
    end
    
    initial begin
        clk_1 <= 0;
        clk_2 <= 0;
        
//        rst_n <= 1;
        
        TX_config_register_1 <= 8'b00100011;
//        RX_config_register_1 <= 8'b11111111;
        RX_config_register_1 <= 8'b00001111;
        
        TX_config_register_2 <= 8'b00001111;
        RX_config_register_2 <= 8'b00100011;
        
        
        TX_use_1 <= 0;
        TX_use_2 <= 0;
        RX_use_1 <= 0;
        RX_use_2 <= 0;
        buffer_tx_1 <= 8'b11111111;
        buffer_tx_2 <= 8'b01010101;
        rst_n <= 1;
        #1 rst_n <= 0;
        #9 rst_n <= 1;
    end
    initial begin
        #11;
        
        buffer_tx_1 <= 8'b11111111;
        #1 TX_use_1 <= 1;
        #1 TX_use_1 <= 0;
        
        buffer_tx_1 <= 120;
        #1 TX_use_1 <= 1;
        #1 TX_use_1 <= 0;
        
        buffer_tx_1 <= 33;
        #1 TX_use_1 <= 1;
        #1 TX_use_1 <= 0;
        
//        buffer_tx_1 <= 33;
//        #1 RX_use_2 <= 1;
//        #1 RX_use_2 <= 0;
        
    end
    always @(posedge RX_flag_2) begin
        #100000 RX_use_2 <= 1;
        #1 RX_use_2 <= 0;
    end
//    always @(posedge TX_enable_clone_1) begin
////        buffer_tx_1 <= $random % 256;
//        buffer_tx_1 <= $random % 256;
//        #100000 TX_use_1 <= 1;
//        #2 TX_use_1 <= 0;
//    end
    
//    always @(posedge TX_enable_clone_2) begin    
//        buffer_tx_2 <= $random % 256;
//        #1000 TX_use_2 <= 1;
//        #2 TX_use_2 <= 0;
//    end
endmodule