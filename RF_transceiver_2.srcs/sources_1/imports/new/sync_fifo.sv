`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/14/2023 11:12:27 PM
// Design Name: 
// Module Name: fifo_sync
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

module sync_fifo
    #(
    parameter  DATA_WIDTH    = 8,
    parameter  FIFO_DEPTH    = 32,
    
    localparam ADDR_WIDTH    = $clog2(FIFO_DEPTH)
    )
    (
    input clk,
    
    input       [DATA_WIDTH - 1:0]  data_in,
    output wire [DATA_WIDTH - 1:0]  data_out,
    
    input                           wr_req,
    input                           rd_req,
    
    output                          empty,
    output                          full,
    output                          almost_empty,
    output                          almost_full,
    
    input       [ADDR_WIDTH:0]      counter_threshold,
    output                          counter_threshold_flag,
    
    input                           rst_n
    );
    reg [DATA_WIDTH - 1:0]  buffer [0:FIFO_DEPTH - 1];
    reg [ADDR_WIDTH:0]      wr_addr;
    wire[ADDR_WIDTH:0]      wr_addr_inc;
    wire[ADDR_WIDTH - 1:0]  wr_addr_map;
    reg [ADDR_WIDTH:0]      rd_addr;
    wire[ADDR_WIDTH:0]      rd_addr_inc;
    wire[ADDR_WIDTH - 1:0]  rd_addr_map;
    wire[ADDR_WIDTH:0]      counter;
    
    assign data_out = buffer[rd_addr_map];
    
    assign wr_addr_inc = wr_addr + 1'b1;
    assign rd_addr_inc = rd_addr + 1'b1;
    assign wr_addr_map = wr_addr[ADDR_WIDTH - 1:0];
    assign rd_addr_map = rd_addr[ADDR_WIDTH - 1:0];
    
    assign empty = wr_addr == rd_addr;
    assign almost_empty = rd_addr_inc ==  wr_addr;
    assign full = (wr_addr_map == rd_addr_map) & (wr_addr[ADDR_WIDTH] ^ rd_addr[ADDR_WIDTH]);
    assign almost_full = wr_addr_map + 1'b1 == rd_addr_map;
    
    assign counter = wr_addr - rd_addr;
    assign counter_threshold_flag = counter == counter_threshold;
    
    logic[DATA_WIDTH - 1:0]  buffer_n [0:FIFO_DEPTH - 1];
    logic[ADDR_WIDTH:0]      wr_addr_n;
    logic[ADDR_WIDTH:0]      wr_addr_inc_n;
    logic[ADDR_WIDTH - 1:0]  wr_addr_map_n;
    logic[ADDR_WIDTH:0]      rd_addr_n;
    logic[ADDR_WIDTH:0]      rd_addr_inc_n;
    logic[ADDR_WIDTH - 1:0]  rd_addr_map_n;
    logic[ADDR_WIDTH:0]      counter_n;
    
    always_comb begin
        wr_addr_n = wr_addr;
        buffer_n = buffer;
        if(wr_req & !full) begin
            buffer_n[wr_addr_map] = data_in;
            wr_addr_n = wr_addr_inc;
        end
        
        rd_addr_n = rd_addr;
        if(rd_req & !empty) begin
            rd_addr_n = rd_addr_inc;
        end
    end
    
    always @(posedge clk) begin
        if(!rst_n) begin 
            wr_addr <= 0;        
        end
        else begin
            buffer <= buffer_n;
            wr_addr <= wr_addr_n;
        end
    end
    always @(posedge clk) begin
        if(!rst_n) begin
            rd_addr <= 0;
        end
        else begin
            rd_addr <= rd_addr_n;
        end
        
    end
endmodule
//    sync_fifo 
//        #(
//        .FIFO_DEPTH(32)
//        ) fifo_sync (
//        .clk(clk),
//        .data_in(),
//        .data_out(),
//        .rd_req(),
//        .wr_req(),
//        .empty(),
//        .full(),
//        .almost_empty(),
//        .almost_full(),
//        .counter_threshold(),
//        .counter_threshold_flag(),
//        .rst_n(rst_n)
//        );