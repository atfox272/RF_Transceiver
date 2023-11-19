`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/02/2023 11:43:16 AM
// Design Name: 
// Module Name: Baurate_clk
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

module UART
    #(
        parameter RX_FLAG_TYPE = 1
    )   
    (
        input [1:0]config_uart,
        input [7:0] data_in,
        input clk, nrst,
        input RX_use,
        input TX_use,
        input Rx,
        output Tx,
        output RX_flag,
        output RX_available,
        output TX_available,
        output TX_complete,
        output [7:0] data_out
    );

    wire [7:0] ff3_out, ff6_in;
    wire full_tx;
    wire empty_rx;
    wire mode;
    wire Tx_req, Rx_sent;
    wire Tx_clk, Rx_clk;
    wire [3:0]bit_counter;
    wire [1:0]option_baudrate;
    
    if(RX_FLAG_TYPE) begin
        assign RX_flag = ~empty_rx;
    
        FIFO RX_buffer(.in(ff6_in), .out(data_out), .nrst(nrst), .reciever(RX_use), .full(), .empty(empty_rx), .sent(Rx_sent),
                  .clk(clk));    
    end
    else begin
        assign RX_flag = Rx_sent;
        assign data_out = ff6_in;
    end
    assign RX_available = (bit_counter == 0);
    assign TX_available = ~full_tx;
    assign TX_complete  = mode;
    
    assign option_baudrate = config_uart[1:0];
    assign option_bytes = config_uart[0];
    
    Baudrate_clk TX_baudrate_generator(.clk(clk), .nrst(nrst), .b_clk(Tx_clk), .option_baudrate(option_baudrate));
    Baudrate_clk_Rx RX_baudrate_generator(.clk(clk), .nrst(nrst), .b_clk_Rx(Rx_clk), .option_baudrate(option_baudrate));
    
    FIFO TX_buffer(.in(data_in), .out(ff3_out), .nrst(nrst), .reciever(Tx_req), .full(full_tx), .empty(mode), .sent(TX_use),
              .clk(clk));
    Tx TX_controller(.data(ff3_out), .tx(Tx), .reciever(Tx_req), .clk(Tx_clk), .mode(mode), .enable(Tx_req), .nrst(nrst), .bit_counter());
    
    Rx RX_controller(.rx(Rx), .clk(Rx_clk), .nrst(nrst), .data(ff6_in), .sent(Rx_sent), .bit_counter(bit_counter));
    
    if(RX_FLAG_TYPE) begin
    
    
    end
    
    
endmodule