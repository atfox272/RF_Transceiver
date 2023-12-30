`timescale 1ns / 1ps
`define CASE_1
`define CASE_2
`define CASE_3
`define CASE_4
`define CASE_5
//`define CASE_6

module RF_transceiver_tb;
    localparam DATA_WIDTH       = 8;
    localparam BD9600_8N1       = 8'b00100011;
    localparam BD115200_8N1     = 8'b11100011;
    
    localparam INTERNAL_CLOCK   = 115200 * 100;
    
    // Delay 
    localparam MODE_SWITCH_DELAY = 7500;
    reg clk;
    reg rst_n;
    // RF Transceiver
    wire                    RX_node;
    wire                    TX_node;
    wire                    RX_mcu;
    wire                    TX_mcu;
    reg                     M1;
    reg                     M0;
    wire                    AUX;
    wire                    M1_sync_out;
    wire                    M0_sync_out;
    // External MCU
    wire                    RX_exmcu;
    wire                    TX_exmcu;
    reg  [DATA_WIDTH - 1:0] data_in_uart_exmcu;
    wire [DATA_WIDTH - 1:0] data_out_uart_exmcu;
    wire [DATA_WIDTH - 1:0] config_register_exmcu;
    reg                     TX_use_exmcu;
    wire                    RX_flag_exmcu;
    // External Node
    wire                    RX_exnode;
    wire                    TX_exnode;
    reg  [DATA_WIDTH - 1:0] data_in_uart_exnode;
    wire [DATA_WIDTH - 1:0] data_out_uart_exnode;
    wire [DATA_WIDTH - 1:0] config_register_exnode;
    reg                     TX_use_exnode;
    wire                    RX_flag_exnode;
    
    assign RX_node          = TX_exnode;
    assign RX_exnode        = TX_node;
    assign RX_mcu           = TX_exmcu;
    assign RX_exmcu         = TX_mcu;
    
    assign config_register_exmcu  = ({M1_sync_out,M0_sync_out} == 3) ? BD9600_8N1 : BD115200_8N1;
    assign config_register_exnode = BD115200_8N1;
    
    uart_peripheral
        #(
        .FIFO_DEPTH(32)
        ,.INTERNAL_CLOCK(INTERNAL_CLOCK)
        ,.RX_FLAG_TYPE(1'b0)
        ) uart_exmcu (
        .clk(clk),
        .RX(RX_exmcu),
        .TX(TX_exmcu),
        .RX_config_register(config_register_exmcu),
        .TX_config_register(config_register_exmcu),
        .data_in(data_in_uart_exmcu),
        .data_out(data_out_uart_exmcu),
        .RX_use(),
        .TX_use(TX_use_exmcu),
        .RX_flag(RX_flag_exmcu),
        .rst_n(rst_n)
        );
    uart_peripheral
        #(
        .FIFO_DEPTH(32)
        ,.INTERNAL_CLOCK(INTERNAL_CLOCK)
        ,.RX_FLAG_TYPE(1'b0)
        ) uart_exnode (
        .clk(clk),
        .RX(RX_exnode),
        .TX(TX_exnode),
        .RX_config_register(config_register_exnode),
        .TX_config_register(config_register_exnode),
        .data_in(data_in_uart_exnode),
        .data_out(data_out_uart_exnode),
        .TX_use(TX_use_exnode),
        .RX_flag(RX_flag_exnode),
        .rst_n(rst_n)
        );
    RF_transceiver
        #(
        .INTERNAL_CLOCK(INTERNAL_CLOCK),
        .BD9600_8N1(BD9600_8N1),
        .BD115200_8N1(BD115200_8N1)
        ) fake_e32 (
        .clk(clk),
        .RX_node(RX_node),
        .TX_node(TX_node),
        .RX_mcu(RX_mcu),
        .TX_mcu(TX_mcu),
        .M1(M1),
        .M0(M0),
        .M1_sync_out(M1_sync_out),
        .M0_sync_out(M0_sync_out),
        .AUX(AUX),
        .rst(~rst_n)
        );   
    initial begin
        clk <= 0;
        rst_n <= 1;
        M1 <= 0;
        M0 <= 0;
        data_in_uart_exmcu <= 0;
        TX_use_exmcu <= 0;
        data_in_uart_exnode <= 0;
        TX_use_exnode <= 0;
        #1 rst_n <= 0;
        #9 rst_n <= 1;
    end    
    initial begin
        forever #1 clk <= ~clk;
    end
    `ifdef CASE_1
    initial begin
        #11;
        
        
        #100; 
        {M1,M0} <= 2;
        #100; 
        {M1,M0} <= 3;
        
        #13100;
        data_in_uart_exmcu <= 8'hC0;    // HEAD
        #1 TX_use_exmcu <= 1;
        #2 TX_use_exmcu <= 0;
        
        data_in_uart_exmcu <= 8'h27;    // ADDH
        #1 TX_use_exmcu <= 1;
        #2 TX_use_exmcu <= 0;
        
        data_in_uart_exmcu <= 8'h02;    // ADDL
        #1 TX_use_exmcu <= 1;
        #2 TX_use_exmcu <= 0;
        
        data_in_uart_exmcu <= 8'h20;    // SPED 
        #1 TX_use_exmcu <= 1;
        #2 TX_use_exmcu <= 0;
        
        data_in_uart_exmcu <= 8'h03;    // CHAN
        #1 TX_use_exmcu <= 1;
        #2 TX_use_exmcu <= 0;
        
        data_in_uart_exmcu <= 8'h99;    // OPTION
        #1 TX_use_exmcu <= 1;
        #2 TX_use_exmcu <= 0;
        
        #60000;
        
//        #MODE_SWITCH_DELAY;
//        data_in_uart_exmcu <= 8'hAA;    
//        #1 TX_use_exmcu <= 1;
//        #2 TX_use_exmcu <= 0;
        
//        data_in_uart_exmcu <= 8'hBB;    
//        #1 TX_use_exmcu <= 1;
//        #2 TX_use_exmcu <= 0;
        
//        data_in_uart_exmcu <= 8'hCC;    // ADDL
//        #1 TX_use_exmcu <= 1;
//        #2 TX_use_exmcu <= 0;
        
//        data_in_uart_exmcu <= 8'hDD;    // SPED 
//        #1 TX_use_exmcu <= 1;
//        #2 TX_use_exmcu <= 0;
        
//        data_in_uart_exmcu <= 8'hEE;    // CHAN
//        #1 TX_use_exmcu <= 1;
//        #2 TX_use_exmcu <= 0;
        
//        data_in_uart_exmcu <= 8'hFF;    // OPTION
//        #1 TX_use_exmcu <= 1;
//        #2 TX_use_exmcu <= 0;
        
//        #60000;
        
//        data_in_uart_exnode <= 8'h11;    
//        #1 TX_use_exnode <= 1;
//        #2 TX_use_exnode <= 0;
        
//        data_in_uart_exnode <= 8'h22;    
//        #1 TX_use_exnode <= 1;
//        #2 TX_use_exnode <= 0;
        
//        data_in_uart_exnode <= 8'h33;    
//        #1 TX_use_exnode <= 1;
//        #2 TX_use_exnode <= 0;
        
//        data_in_uart_exnode <= 8'h44;    
//        #1 TX_use_exnode <= 1;
//        #2 TX_use_exnode <= 0;
        
//        data_in_uart_exnode <= 8'h55;    
//        #1 TX_use_exnode <= 1;
//        #2 TX_use_exnode <= 0;
        
//        data_in_uart_exnode <= 8'h66;    
//        #1 TX_use_exnode <= 1;
//        #2 TX_use_exnode <= 0;
        
//        data_in_uart_exnode <= 8'h77;    
//        #1 TX_use_exnode <= 1;
//        #2 TX_use_exnode <= 0;
        
//        data_in_uart_exnode <= 8'h88;    
//        #1 TX_use_exnode <= 1;
//        #2 TX_use_exnode <= 0;
    end 
    `endif
    
    initial begin
    
        #400000;
        
    
    `ifdef CASE_2    
        #100;
        {M1,M0} <= 1;
        #100;
        {M1,M0} <= 0;
        #MODE_SWITCH_DELAY;
        data_in_uart_exmcu <= 8'hAA;    
        #1 TX_use_exmcu <= 1;
        #2 TX_use_exmcu <= 0;
        
        data_in_uart_exmcu <= 8'hBB;    
        #1 TX_use_exmcu <= 1;
        #2 TX_use_exmcu <= 0;
        
        data_in_uart_exmcu <= 8'hCC;    // ADDL
        #1 TX_use_exmcu <= 1;
        #2 TX_use_exmcu <= 0;
        
        data_in_uart_exmcu <= 8'hDD;    // SPED 
        #1 TX_use_exmcu <= 1;
        #2 TX_use_exmcu <= 0;
        
        data_in_uart_exmcu <= 8'hEE;    // CHAN
        #1 TX_use_exmcu <= 1;
        #2 TX_use_exmcu <= 0;
        
        data_in_uart_exmcu <= 8'h99;    // OPTION
        #1 TX_use_exmcu <= 1;
        #2 TX_use_exmcu <= 0;
         
    `endif
    
    `ifdef CASE_3
        #130000;
        for(int i = 0; i < 20; i = i + 1) begin
            #1;
            data_in_uart_exnode <= 8'hFF - i;    
            #1 TX_use_exnode <= 1;
            #2 TX_use_exnode <= 0;
        end 
    `endif        
        
    end   
    `ifdef CASE_4
    initial begin
        #800000;
        #100; 
        {M1,M0} <= 3;
        #MODE_SWITCH_DELAY;
        
        for(int i = 0; i < 3; i = i + 1) begin
        data_in_uart_exmcu <= 8'hC1;    // RETURN INFORMATION
        #1 TX_use_exmcu <= 1;
        #2 TX_use_exmcu <= 0;
        end 
        
    `ifdef CASE_5
        #320000;
        for(int i = 0; i < 3; i = i + 1) begin
        data_in_uart_exmcu <= 8'hC3;    // RETURN INFORMATION
        #1 TX_use_exmcu <= 1;
        #2 TX_use_exmcu <= 0;
        end 
    `endif     
        
    end
    `endif 
             
    initial begin
        #(100000 * 2);
        #(100000 * 2);
        #(100000 * 2);
        #(100000 * 2);
        #(100000 * 2);
        #400000;
        $stop;
        #1000000;
        $stop;
    end              
endmodule
