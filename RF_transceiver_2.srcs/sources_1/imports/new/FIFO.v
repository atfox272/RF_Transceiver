`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/25/2023 11:18:03 AM
// Design Name: 
// Module Name: FIFO
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

module FIFO(in, nrst, sent, out, empty, full, reciever, clk);
    input  [7:0]in;
    input  nrst,
           sent, clk; 
    
    input  reciever;       
    output [7:0]out;
    output  reg empty,
            full;
    
    parameter capacity = 32;
    parameter counter_width = $clog2(capacity);
    reg [7:0]ram[0: capacity-1];
    reg [0:counter_width-1] rear, front;
    reg s_en, r_en;
    reg [0:counter_width] length;
    wire[0:counter_width] length_incr;
    wire[0:counter_width] length_decr;
    
    assign length_incr = length + 1;
    assign length_decr = length - 1;
    
    always @(posedge clk or negedge nrst) begin
        if(!nrst) begin
            front =0;
            rear =0;
    
            empty <= 1'b1;
            full <= 1'b0;
            
            s_en <=1;
            r_en <=1;
            length <=0;
        end
        
        else begin
            if ((sent && s_en) && (reciever && r_en)) begin
                rear <= rear + 1;
                ram[rear] <= in;
                front <= front+1;
                s_en <= 0;
                r_en <= 0;
            end
            
            else if ((sent && s_en)  && !full) begin
                rear <= rear + 1;
                length <= length +1;
                ram[rear] <= in;
                s_en <= 0;
//                r_en =1;
                if (length_incr  == capacity) begin
                    empty <= 1'b0;
                    full <= 1'b1;
                end
                else begin
//                    s_en = 1;
//                    r_en =1;
                    empty <= 0;
                    full <= 0;
                end
            end
            else if ((reciever && r_en) && !empty) begin
//                out = ram[front];
                front <= front +1;
//                s_en = 1;
                r_en <=0;
                length <= length -1;
                if (length_decr  == 0) begin
                    empty <= 1'b1;
                    full <= 1'b0;
                end
                else begin
                    empty <= 0;
                    full <= 0;
//                    s_en = 1;
//                    r_en =1;
                end
            end
            else begin
                if (sent ==1)s_en <=0;
                else s_en <=1;
                if (reciever ==1)r_en <=0;
                else r_en <=1;

//                s_en <=1;
//                r_en <=1;
            end
        end
    end
    
    assign out = empty? 0 : ram[front];
endmodule
////////////////////////////////////////////////////////////////////////////////////

//module FIFO(in, nrst, sent, out, empty, full, almost_empty, almost_full, reciever);
//    input  [7:0]in;
//    input  nrst,
//           sent; 
    
//    input wire reciever;       
//    output [7:0]out;
//    output  reg empty,
//            full,
//            almost_empty,
//            almost_full;
    
//    parameter capacity = 16;
//    parameter counter_width = $clog2(capacity);
//    reg [7:0]ram[0: capacity-1];
//    reg [0:counter_width-1] rear, front;
    
    
// //   Tx uut3(.reciever(reciever)); posedge sent, posedge reciever, negedge nrst
    
//    always @(posedge sent or negedge nrst or posedge reciever) begin
//        if (!nrst) begin //n reset
////            ram =0;
//            front =0;
//            rear =0;
////            if (front == rear) begin
//                empty = 1'b0;
//                full = 1'b0;
//                almost_full = 1'b0;
//                almost_empty = 1'b0;
////            end
//        end
//        else begin
        
//            if (sent && reciever) begin
//                rear = rear + 1;
//                ram[rear] <= in;
//                front <= front+1;
//            end
//            else if (sent == 1'b1 && !full) begin
//                rear = rear + 1;
//                ram[rear] <= in;
//                if (rear == front) begin
//                    empty = 1'b0;
//                    full = 1'b1;
//                    almost_full = 1'b0;
//                    almost_empty = 1'b0;
//                end
//                else begin
//                    empty = 0;
//                    full = 0;
//                end
//            end
//            else if (reciever == 1'b1 && !empty) begin
////                out = ram[front];
//                front <= front +1;
//                if (rear == front) begin
//                    empty = 1'b1;
//                    full = 1'b0;
//                    almost_full = 1'b0;
//                    almost_empty = 1'b0;
//                end
//                else begin
//                    empty = 0;
//                    full = 0;
//                end
//            end
////            if (rear != front) begin
////                empty = 0;
////                full = 0;
////            end
//        end
//    end
    
////    always @(posedge reciever) begin
////        if (!nrst) begin //n reset
//////            ram =0;
////            front =0;
//////            rear =0;
//////            if (front == rear) begin
////                empty = 1'b0;
//////                full = 1'b0;
//////                almost_full = 1'b0;
//////                almost_empty = 1'b0;
//////            end
////        end
////        else begin
//////            if (sent == 1'b1 && !full) begin
//////                rear = rear + 1;
//////                ram[rear] <= in;
//////                if (rear == front) begin
//////                    empty = 1'b0;
//////                    full = 1'b1;
//////                    almost_full = 1'b0;
//////                    almost_empty = 1'b0;
//////                end
//////                else begin
//////                    empty = 0;
//////                    full = 0;
//////                end
//////            end
////            if (reciever == 1'b1 && !empty) begin
//////                out = ram[front];
////                front = front +1;
////                if (rear == front) begin
////                    empty = 1'b1;
//////                    full = 1'b0;
//////                    almost_full = 1'b0;
//////                    almost_empty = 1'b0;
////                end
////                else begin
////                    empty = 0;
//////                    full = 0;
////                end
////            end
//////            if (rear != front) begin
//////                empty = 0;
//////                full = 0;
//////            end
////        end    
////    end
//    assign out = ram[front];

//endmodule
