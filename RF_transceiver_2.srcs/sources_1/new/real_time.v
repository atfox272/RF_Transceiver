`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/04/2023 04:55:43 PM
// Design Name: 
// Module Name: real_time
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


module real_time
    #(
    parameter MAX_COUNTER       = 10000,
    parameter MAX_COUNTER_WIDTH = $clog2(MAX_COUNTER)
    )
    (
    input                           clk,
    input                           counter_enable,
    input [MAX_COUNTER_WIDTH - 1:0] limit_counter,
    output                          limit_flag,
    
    input rst_n
    );
    
    reg [MAX_COUNTER_WIDTH - 1:0] counter;
    reg                           limit_flag_reg;
    
    assign limit_flag = limit_flag_reg;
    
    logic[MAX_COUNTER_WIDTH - 1:0]  counter_n;
    logic                           limit_flag_reg_n;
    
    always_comb begin
        counter_n = counter;
        limit_flag_reg_n = limit_flag_reg;
        
        if(counter_enable) begin
            limit_flag_reg_n = (counter == limit_counter) ? 1'b1 : limit_flag_reg;   // Greater than => Set high
            counter_n = counter + 1;
        end
        else begin
            limit_flag_reg_n = 1'b0;
            counter_n = 0;
        end
    end
    
    always @(posedge clk) begin
        if(!rst_n) begin
            counter <= 0;
            limit_flag_reg <= 0;
        end
        else begin
            counter <= counter_n;
            limit_flag_reg <= limit_flag_reg_n;
        end
    end
    
    
endmodule
