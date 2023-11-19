`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/22/2023 04:59:32 PM
// Design Name: 
// Module Name: Rx
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


//module Rx(
//    input rx,
//    input nrst,
//    input clk,
//    output reg [7:0]data,
//    output reg [3:0]bit_counter,
//    output reg sent
//    );
    
//    reg [3:0]clk_counter;
    
//    always @(posedge clk) begin
//        if (!nrst) begin
//            //tx =1;
//            clk_counter <=0;
//            bit_counter <= 0;
//            data <=0;
//            sent<=0;
//        end
        
//        else begin
//            if (bit_counter==0) begin
//                if (rx == 0) bit_counter <= bit_counter+1;
                
//                else begin
//                    if (bit_counter>0 && bit_counter<=8) begin
//                        clk_counter <= clk_counter+1;
//                        if (clk_counter+1 == 7) begin
//                            data[bit_counter-1] <= rx;
//                            bit_counter<= bit_counter+1;
//                        end
//                    end
//                    else if(bit_counter>=9 && bit_counter<10) begin
//                        clk_counter <= clk_counter+1;
//                        if (clk_counter+1 == 7) begin
//                            bit_counter<= bit_counter+1;
//                            sent <=1;
//                        end
//                    end
//                    else if(bit_counter ==10) begin
//                        clk_counter <= clk_counter+1;
//                        if (clk_counter+1 == 7) begin
//                            bit_counter <=0;
//                            data <=0;
//                            sent<=0;
//                        end
//                    end
//                end
//            end
//        end
//    end
//endmodule 

/////////////////////////////////////////////////////////////////////////////////


module Rx(
    input rx,
    input nrst,
    input clk,
    output reg [7:0]data,
    output reg [3:0]bit_counter,
    output reg sent
    );
    
    reg [3:0]clk_counter;
    
    always @(posedge clk or negedge nrst) begin
        if (!nrst) begin
            //tx =1;
            bit_counter <= 0;
            data <=0;
            sent<=0;
            clk_counter <=0;
        end
        
        else begin
            if (bit_counter==0) begin
                if (rx==0) bit_counter<= bit_counter+1;
            end
//            else if (bit_counter == 0) begin
//                if (rx==0) bit_counter <=1;
//            end
            else begin
                if(bit_counter>0 && bit_counter<=8) begin
                        clk_counter <= clk_counter+1;
                        if (clk_counter ==7) begin
                            bit_counter <= bit_counter+1;
                            data[bit_counter-2] <= rx;
//                            bit_counter<= bit_counter+1;
                        end
                end
                
                else if (bit_counter>=9 && bit_counter<10) begin
                    clk_counter <= clk_counter+1;
                    if (clk_counter ==7) begin
                        bit_counter <= bit_counter+1;
                        sent<=1;
                    end
                end
                else if(bit_counter ==10) begin
                    clk_counter <= clk_counter+1;
                    if (clk_counter ==15) begin
                        bit_counter <=0;
                        data <=0;
                        sent<=0;
                    end
                end
            end
            /* check parity
            if(bit_counter == 9) begin
            end
            */
        end
    end
endmodule
