`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/15/2023 11:39:30 PM
// Design Name: 
// Module Name: RF_transceiver_3module
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


module RF_transceiver_3module(
    input   wire        clk,
    
    // RF_transceiver 1
    input   wire        M0_1,
    input   wire        M1_1,
    input   wire        RX_mcu_1,
    output  wire        TX_mcu_1,
    output  wire        AUX_1,
    output  wire        TX_node_1,
    input   wire        RX_node_1,
    
    // RF_transceiver 2
    input   wire        M0_2,
    input   wire        M1_2,
    input   wire        RX_mcu_2,
    output  wire        TX_mcu_2,
    output  wire        AUX_2,
    output  wire        TX_node_2,
    input   wire        RX_node_2,
    
    // RF_transceiver 3
    input   wire        M0_3,
    input   wire        M1_3,
    input   wire        RX_mcu_3,
    output  wire        TX_mcu_3,
    output  wire        AUX_3,
    output  wire        TX_node_3,
    input   wire        RX_node_3,

    // Common reset
    input   wire        rst
    );
    
    (* dont_touch = "yes" *)  
    RF_transceiver  
        #(
        )rf_transceiver_1(
        .clk(clk),
        .TX_mcu(TX_mcu_1),
        .RX_mcu(RX_mcu_1),
        .M0(M0_1),
        .M1(M1_1),
        .AUX(AUX_1),
        .TX_node(TX_node_1),
        .RX_node(RX_node_1),
        .rst(rst)
        );
    (* dont_touch = "yes" *)  
    RF_transceiver  
        #(
        )rf_transceiver_2(
        .clk(clk),
        .TX_mcu(TX_mcu_2),
        .RX_mcu(RX_mcu_2),
        .M0(M0_2),
        .M1(M1_2),
        .AUX(AUX_2),
        .TX_node(TX_node_2),
        .RX_node(RX_node_2),
        .rst(rst)
        );
    (* dont_touch = "yes" *)  
    RF_transceiver  
        #(
        )rf_transceiver_3(
        .clk(clk),
        .TX_mcu(TX_mcu_3),
        .RX_mcu(RX_mcu_3),
        .M0(M0_3),
        .M1(M1_3),
        .AUX(AUX_3),
        .TX_node(TX_node_3),
        .RX_node(RX_node_3),
        .rst(rst)
        );
    
endmodule
