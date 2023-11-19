`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/10/2023 10:38:56 AM
// Design Name: 
// Module Name: Baurate_clk_Rx
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


module Baudrate_clk_Rx(
    input [1:0]option_baudrate,
    input clk, nrst,
    output reg b_clk_Rx
    );
    
    parameter max_no_count = 67; // 125MHz/115200/16
    reg [11:0] no_count, half_no_count;
    
    
    always @(*) begin
        case (option_baudrate)
            2'b11 : no_count <= 67;
            2'b01 : no_count <= 61;
            2'b10 : no_count <= 30;
            2'b00 : no_count <= 813; //testbench
        endcase
        
        half_no_count <= no_count /2;
    end
    
    reg [11:0]count; // 125MHz/115200
    
    always @(posedge clk) begin
        if (!nrst) begin
            count =0;
            b_clk_Rx =1;
        end
        else begin
            if (count <= half_no_count) begin //542/16
                count <= count +1;
                b_clk_Rx <=1;
            end
            else if (count <no_count) begin //1085/16
                count <= count +1;
                b_clk_Rx <=0;
            end
            else if (count ==no_count) begin
                count <= 0;
                b_clk_Rx <=1;
            end
        end
    end
endmodule
