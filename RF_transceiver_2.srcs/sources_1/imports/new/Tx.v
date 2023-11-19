`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/02/2023 04:01:00 PM
// Design Name: 
// Module Name: Tx
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


module Tx(
    input [7:0] data,
    input mode, nrst, enable,
    input clk,
    output reg tx,
    output reg [3:0]bit_counter,
    output reg reciever
    );
    
    //Baurate_clk uut1 (.b_clk(clk));
    //FIFO uut2 (.out(data), .empty(mode));
    
    reg count_1st;
    
    always @(posedge clk or negedge nrst) begin
        if (!nrst) begin
//            count_1st <=0;
            bit_counter <= 0;
            tx <=1;
            reciever <=1;
        end
        else if (mode && bit_counter ==0) begin
            tx <=1;
            bit_counter <=0;
        end
        
//        if (count_1st) begin
//            if(bit_counter==0 && !enable) tx<=1;
//        end 
        
        else if (!mode || bit_counter != 0) begin
            if (count_1st && !enable && bit_counter ==0) begin //count_1st &&
                if(bit_counter==0 && !enable) tx<=1;
            end 
            else begin
                tx <=0;
                if(bit_counter ==0)begin
                    bit_counter <=1;
                    reciever <=0;
                end
                else begin        
                    if (bit_counter>0 && bit_counter<=8) begin
                        tx <= data[bit_counter-1]; 
    //                    tx = shift_left;
                        bit_counter <= bit_counter + 1;
                    end
                    else begin
                        if (bit_counter>=9 && bit_counter<10) begin
                            tx <=1;
                            bit_counter <= bit_counter+1;
//                            reciever<=1;
                        end
                        else if (bit_counter ==10) begin
                                bit_counter <= 0;
                                tx <= 1;
                                count_1st <=1;
                                reciever <=1;
                        end 
                    end
    //                else if (bit_counter ==10) begin
    //                    bit_counter <= 0;
    //                end
                end 
            end
        end
    end
    
//    assign reciever = (bit_counter ==10)? 1 :(nrst? 1:0);
endmodule
