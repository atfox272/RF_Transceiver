`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/03/2023 03:59:28 PM
// Design Name: 
// Module Name: mode_controller_RF_transceiver
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


module mode_controller_RF_transceiver
    #(
        parameter DEFAULT_MODE = 2'd3
    )
    (
    input   wire    internal_clk,
    input   wire    M0,
    input   wire    M1,
    input   wire    AUX,
    
    output  reg     M0_sync,
    output  reg     M1_sync,
    
    input   wire    rst_n
    );
    always @(posedge internal_clk) begin
        if(!rst_n) begin
            M1_sync <= DEFAULT_MODE[1];
            M0_sync <= DEFAULT_MODE[0];
        end
        else begin
            if(AUX) begin
                M1_sync <= M1;
                M0_sync <= M0;
            end
            else begin
                M1_sync <= M1_sync;
                M0_sync <= M0_sync;
            end
        end
    end
endmodule
