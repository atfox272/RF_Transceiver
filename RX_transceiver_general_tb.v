`timescale 1s / 1ns
module RF_transceiver_general_tb;
    parameter DATA_WIDTH = 8;
    parameter START_WIRELESS_TRANS_VALUE = 8'd58;
    
    // UART configuration
    parameter CLK_DIVIDER  = 8'd10;             // Use clock divider (prescaler) to reduce power consumption
    // CLOCK_DIVIDER_UART = INTERNAL_CLK / ((9600 * 256) * 2)
    parameter CLOCK_DIVIDER_UART     =  8'd5;
    parameter CLOCK_DIVIDER_UNIQUE_1 =  8'd55;    // <value> = ceil(Internal clock / (<BAUDRATE_SPEED> * 2))  (115200)
    parameter CLOCK_DIVIDER_UNIQUE_2 =  10'd652;   // <value> = ceil(Internal clock / (<BAUDRATE_SPEED> * 2))  (9600)
    
    // Waiting module for 3 times empty transaction
//        parameter END_COUNTER_RX_PACKET = 50000;    // count (END_COUNTER - START_COUNTER) clock cycle
//        parameter START_COUNTER_RX_PACKET = 0;
//        parameter END_WAITING_SEND_WLESS_DATA = 50000;
//        parameter START_COUNTER_SEND_WLESS_DATA = 0;
//        parameter END_SELF_CHECKING = 100000;

    // Common            
    reg M0;
    reg M1;
    reg device_clk;
    wire internal_clk;
    reg rst_n;
    wire AUX;                               //             BD_9600      BD_115200
    wire [7:0] all_common_config = (M0 == 1 & M1 == 1) ? 8'b10100011 : 8'b10000011;
    wire [7:0] TX_node_external_config = 8'b10000011;
    // UART mcu
    reg [7:0] data_in_mcu_external;
    reg TX_use_mcu_external;
    wire [7:0] data_out_mcu_external;
    wire RX_flag_mcu_external;
    wire TX_to_mcu;
    wire RX_to_mcu;
    // UART node
    reg [7:0] data_in_node_external;
    reg TX_use_node_external;
    wire [7:0] data_out_node_external;
    wire RX_flag_node_external;
    wire TX_to_node;
    wire RX_to_node;
    
    // Initial reg
//    reg simulate_flag;
//    // Debug
//    wire [DATA_WIDTH - 1:0] data_bus_out_node_internal;
//    wire RX_flag_node_wire;
    wire RX_flag_mcu_wire;
//    wire [1:0] state_counter_mode0_receive_wire;
    wire [DATA_WIDTH - 1:0] data_out_uart_mcu_wire;
    wire TX_use_mcu_wire;
    
    wire TX_use_node_wire;
    wire [DATA_WIDTH - 1:0] data_in_uart_node_wire;
    
    wire [3:0] state_module_wire;
    
    prescaler_module#(
                    .IDLE_CLK(1'b0),
                    .REVERSE_CLK(1'b0),
                    .MULTI_PRESCALER(1'b0),
                    .HARDCONFIG_DIV(CLK_DIVIDER)
                    )uut(
                    .clk_in(device_clk),
                    .prescaler_enable(1'b1),
                    .clk_1(internal_clk),
                    .rst_n(rst_n)
                    );
                    
    com_uart        #(
                    .CLOCK_DIVIDER(CLOCK_DIVIDER_UART),
                    .CLOCK_DIVIDER_UNIQUE_1(CLOCK_DIVIDER_UNIQUE_1),
                    .CLOCK_DIVIDER_UNIQUE_2(CLOCK_DIVIDER_UNIQUE_2),
                    .FIFO_DEPTH(11'd1024)
                    )uart_mcu_external(
                    .clk(internal_clk), 
                    .TX_config_register(all_common_config),
                    .RX_config_register(all_common_config),
                    .RX(TX_to_mcu), 
                    .TX(RX_to_mcu), 
                    .data_bus_in(data_in_mcu_external), 
                    .TX_use(TX_use_mcu_external),
                    .data_bus_out(data_out_mcu_external),
                    .RX_flag(RX_flag_mcu_external),
                    .rst_n(rst_n)
                    );
    com_uart        #(
                    .CLOCK_DIVIDER(CLOCK_DIVIDER_UART),
                    .CLOCK_DIVIDER_UNIQUE_1(CLOCK_DIVIDER_UNIQUE_1),
                    .CLOCK_DIVIDER_UNIQUE_2(CLOCK_DIVIDER_UNIQUE_2),
                    .FIFO_DEPTH(11'd1024)
                    )uart_node_external(
                    .clk(internal_clk), 
                    .TX_config_register(TX_node_external_config),
                    .RX_config_register(all_common_config),
                    .RX(TX_to_node), 
                    .TX(RX_to_node), 
                    .data_bus_in(data_in_node_external), 
                    .TX_use(TX_use_node_external),
                    .data_bus_out(data_out_node_external),
                    .RX_flag(RX_flag_node_external),
                    .rst_n(rst_n)
                    );
    RF_transceiver  #(
                    .CLK_DIVIDER(CLK_DIVIDER),
                    .START_WIRELESS_TRANS_VALUE(START_WIRELESS_TRANS_VALUE)
//                    ,.END_COUNTER_RX_PACKET (END_COUNTER_RX_PACKET)
//                    ,.START_COUNTER_RX_PACKET(START_COUNTER_RX_PACKET)
//                    ,.END_WAITING_SEND_WLESS_DATA(END_WAITING_SEND_WLESS_DATA)
//                    ,.START_COUNTER_SEND_WLESS_DATA(START_COUNTER_SEND_WLESS_DATA)
//                    ,.END_SELF_CHECKING(END_SELF_CHECKING)
                    )rf_transceiver(
                    .device_clk(device_clk),
                    .TX_mcu(TX_to_mcu),
                    .RX_mcu(RX_to_mcu),
                    .M0(M0),
                    .M1(M1),
                    .AUX(AUX),
                    .TX_node(TX_to_node),
                    .RX_node(RX_to_node),
//                    .state_module_wire(state_module_wire),
                    .rst_n(rst_n)
                    // Debug
//                    ,.data_bus_out_node(data_bus_out_node_internal)
//                    ,.RX_flag_node_wire(RX_flag_node_wire)
//                    ,.state_counter_mode0_receive_wire(state_counter_mode0_receive_wire)
//                    ,.TX_use_mcu_wire(TX_use_mcu_wire)
                    // New Debugger 
//                    ,.RX_flag_mcu_wire(RX_flag_mcu_wire)
//                    ,.data_out_uart_mcu_wire(data_out_uart_mcu_wire)
//                    ,.TX_use_node_wire(TX_use_node_wire)
//                    ,.data_in_uart_node_wire(data_in_uart_node_wire)
//                    ,.internal_clk_wire(internal_clk)
                    );
    initial begin
        device_clk <= 0;
        rst_n <= 1;
        // Wireless-receiver test 
        TX_use_mcu_external <= 0;
        data_in_mcu_external <= 8'h00;
        /////////
        TX_use_node_external <= 0;
        data_in_node_external <= 8'h00;
        //////////////////////
        M0 <= 1;
        M1 <= 1;
        #2 rst_n <= 0;
        #8 rst_n <= 1;
    end
    // For wireless-transmitter
//    initial begin
//        #12;
        
//        data_in_mcu_external <= 8'h27;
//        #1 TX_use_mcu_external <= 1;
//        #1 TX_use_mcu_external <= 0;
        
//        data_in_mcu_external <= 8'h11;
//        #1 TX_use_mcu_external <= 1;
//        #1 TX_use_mcu_external <= 0;
        
//        data_in_mcu_external <= 8'h22;
//        #1 TX_use_mcu_external <= 1;
//        #1 TX_use_mcu_external <= 0;
        
//        data_in_mcu_external <= 8'h33;
//        #1 TX_use_mcu_external <= 1;
//        #1 TX_use_mcu_external <= 0;
        
//        data_in_mcu_external <= 8'h44;
//        #1 TX_use_mcu_external <= 1;
//        #1 TX_use_mcu_external <= 0;
        
//        data_in_mcu_external <= 8'h55;
//        #1 TX_use_mcu_external <= 1;
//        #1 TX_use_mcu_external <= 0;
        
//        data_in_mcu_external <= 8'h66;
//        #1 TX_use_mcu_external <= 1;
//        #1 TX_use_mcu_external <= 0;
        
//        data_in_mcu_external <= 8'h77;
//        #1 TX_use_mcu_external <= 1;
//        #1 TX_use_mcu_external <= 0;
//    end
    // Test wireless-receiver
//    initial begin
//        #12;
        
//        data_in_node_external <= 8'hFF;
//        #1 TX_use_node_external <= 1;
//        #1 TX_use_node_external <= 0;
        
//        data_in_node_external <= 8'h11;
//        #1 TX_use_node_external <= 1;
//        #1 TX_use_node_external <= 0;
        
//        data_in_node_external <= 8'h22;
//        #1 TX_use_node_external <= 1;
//        #1 TX_use_node_external <= 0;
        
//        data_in_node_external <= 8'h33;
//        #1 TX_use_node_external <= 1;
//        #1 TX_use_node_external <= 0;
        
//        data_in_node_external <= 8'h44;
//        #1 TX_use_node_external <= 1;
//        #1 TX_use_node_external <= 0;
        
//        data_in_node_external <= 8'h55;
//        #1 TX_use_node_external <= 1;
//        #1 TX_use_node_external <= 0;
        
//        data_in_node_external <= 8'h00;
//        #1 TX_use_node_external <= 1;
//        #1 TX_use_node_external <= 0;
//    end
    initial begin
        #12;
        
        
//        data_in_mcu_external <= 8'h27;
//        #1 TX_use_mcu_external <= 1;
//        #1 TX_use_mcu_external <= 0;
        
//        data_in_mcu_external <= 8'h11;
//        #1 TX_use_mcu_external <= 1;
//        #1 TX_use_mcu_external <= 0;
        
//        data_in_mcu_external <= 8'h22;
//        #1 TX_use_mcu_external <= 1;
//        #1 TX_use_mcu_external <= 0;
        
//        data_in_mcu_external <= 8'h33;
//        #1 TX_use_mcu_external <= 1;
//        #1 TX_use_mcu_external <= 0;
        
//        data_in_mcu_external <= 8'h44;
//        #1 TX_use_mcu_external <= 1;
//        #1 TX_use_mcu_external <= 0;
        
//        data_in_mcu_external <= 8'h55;
//        #1 TX_use_mcu_external <= 1;
//        #1 TX_use_mcu_external <= 0;
        
//        data_in_mcu_external <= 8'h66;
//        #1 TX_use_mcu_external <= 1;
//        #1 TX_use_mcu_external <= 0;
        
//        data_in_mcu_external <= 8'h77;
//        #1 TX_use_mcu_external <= 1;
//        #1 TX_use_mcu_external <= 0;
        
//        #1000;
//        M0 <= 1;
//        M1 <= 1;
        
        
//        data_in_mcu_external <= 8'h77;
//        #1 TX_use_mcu_external <= 1;
//        #1 TX_use_mcu_external <= 0;
        
        
        
    end
    
    initial begin
        forever #1 device_clk <= ~device_clk;
    end
    reg [6:0] state_counter;
    localparam IDLE_STATE = 0;
    localparam INIT_STATE = 1;
    localparam TRANS_STATE = 2;
    localparam RECEIVE_STATE = 3;
    localparam MODE_SWITCHING_STATE = 5;
    localparam CONFIG_STATE = 4;
    localparam READY_STATE = 6;
    localparam END_STATE = 7;
    
    
//    initial begin
//        state_counter <= IDLE_STATE;
//        #10000;
//        #100000;
//        M0 <= 0;
//        M1 <= 0;
//        #1000000;
       
//        M1 <= 1;
//        M0 <= 1;
//        #10;
//        // Ask transceiver
//                data_in_mcu_external <= 8'hC0;  // HEAD
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
                
//                data_in_mcu_external <= 8'hCD;  // ADDH
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
                    
//                data_in_mcu_external <= 8'hAB;  // ADDL
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
                
//                data_in_mcu_external <= 8'h3D;  // SPED
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
                
//                data_in_mcu_external <= 8'h17;  // CHAN
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
                
//                data_in_mcu_external <= 8'hC4;  // OPTION 
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
                
                
//               #900000;
//               M1 <= 0;
//               M0 <= 0;
               
//               #450000;
//               M1 <= 1;
//               M0 <= 1;
               
//               #100000;
//                data_in_mcu_external <= 8'hC1;
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
                
//                data_in_mcu_external <= 8'hC1;
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
                
//                data_in_mcu_external <= 8'hC1;
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
                
                
//                // Send testing
                
//                #1000000;
               
//                M1 <= 0;
//                M0 <= 0;
//                #100;
//                data_in_mcu_external <= 8'h27;
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
                
//                data_in_mcu_external <= 8'h11;
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
                
//                data_in_mcu_external <= 8'h22;
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
                
//                data_in_mcu_external <= 8'h33;
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
                
//                data_in_mcu_external <= 8'h44;
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
                
//                data_in_mcu_external <= 8'h55;
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
                
//                data_in_mcu_external <= 8'h66;
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
                
//                data_in_mcu_external <= 8'h77;
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
                
//                // receive testing
//                 #1000000;
//                 #1000;
//                data_in_node_external <= 8'hFF;
//                #1 TX_use_node_external <= 1;
//                #1 TX_use_node_external <= 0;
                
//                data_in_node_external <= 8'h11;
//                #1 TX_use_node_external <= 1;
//                #1 TX_use_node_external <= 0;
                
//                data_in_node_external <= 8'h22;
//                #1 TX_use_node_external <= 1;
//                #1 TX_use_node_external <= 0;
                
//                data_in_node_external <= 8'h33;
//                #1 TX_use_node_external <= 1;
//                #1 TX_use_node_external <= 0;
                
//                data_in_node_external <= 8'h44;
//                #1 TX_use_node_external <= 1;
//                #1 TX_use_node_external <= 0;
                
//                data_in_node_external <= 8'h55;
//                #1 TX_use_node_external <= 1;
//                #1 TX_use_node_external <= 0;
                
//                data_in_node_external <= 8'h00;
//                #1 TX_use_node_external <= 1;
//                #1 TX_use_node_external <= 0;
//    end
    
    // Prescaler case
    initial begin
        state_counter <= IDLE_STATE;
        #100000;
        M0 <= 0;
        M1 <= 0;
        #1000000;
       
        M1 <= 1;
        M0 <= 1;
        #100;
        // Ask transceiver
                data_in_mcu_external <= 8'hC0;  // HEAD
                #1 TX_use_mcu_external <= 1;
                #1 TX_use_mcu_external <= 0;
                
                data_in_mcu_external <= 8'hCD;  // ADDH
                #1 TX_use_mcu_external <= 1;
                #1 TX_use_mcu_external <= 0;
                    
                data_in_mcu_external <= 8'hAB;  // ADDL
                #1 TX_use_mcu_external <= 1;
                #1 TX_use_mcu_external <= 0;
                
                data_in_mcu_external <= 8'h3D;  // SPED
                #1 TX_use_mcu_external <= 1;
                #1 TX_use_mcu_external <= 0;
                
                data_in_mcu_external <= 8'h17;  // CHAN
                #1 TX_use_mcu_external <= 1;
                #1 TX_use_mcu_external <= 0;
                
                data_in_mcu_external <= 8'hC4;  // OPTION 
                #1 TX_use_mcu_external <= 1;
                #1 TX_use_mcu_external <= 0;
                
                
               #9000000;
               M1 <= 0;
               M0 <= 0;
               
               #4500000;
               M1 <= 1;
               M0 <= 1;
               
               #1000000;
                data_in_mcu_external <= 8'hC1;
                #1 TX_use_mcu_external <= 1;
                #1 TX_use_mcu_external <= 0;
                
                data_in_mcu_external <= 8'hC1;
                #1 TX_use_mcu_external <= 1;
                #1 TX_use_mcu_external <= 0;
                
                data_in_mcu_external <= 8'hC1;
                #1 TX_use_mcu_external <= 1;
                #1 TX_use_mcu_external <= 0;
                
                
                // Send testing
                
                #10000000;
               
                M1 <= 0;
                M0 <= 0;
                #1000;
                for(integer i = 0; i < 512; i = i + 1) begin
                    data_in_mcu_external <= i;
                    #1 TX_use_mcu_external <= 1;
                    #1 TX_use_mcu_external <= 0;
                end
//                data_in_mcu_external <= 8'h27;
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
                
//                data_in_mcu_external <= 8'h11;
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
                
//                data_in_mcu_external <= 8'h22;
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
                
//                data_in_mcu_external <= 8'h33;
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
                
//                data_in_mcu_external <= 8'h44;
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
                
//                data_in_mcu_external <= 8'h55;
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
                
//                data_in_mcu_external <= 8'h66;
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
                
//                data_in_mcu_external <= 8'h77;
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
                
                // receive testing
                 #30000000;
                 #10000;
                 
                for(integer i = 0; i < 512; i = i + 1) begin
                    data_in_node_external <= i;
                    #1 TX_use_node_external <= 1;
                    #1 TX_use_node_external <= 0;
                end
//                data_in_node_external <= 8'hFF;
//                #1 TX_use_node_external <= 1;
//                #1 TX_use_node_external <= 0;
                
//                data_in_node_external <= 8'h11;
//                #1 TX_use_node_external <= 1;
//                #1 TX_use_node_external <= 0;
                
//                data_in_node_external <= 8'h22;
//                #1 TX_use_node_external <= 1;
//                #1 TX_use_node_external <= 0;
                
//                data_in_node_external <= 8'h33;
//                #1 TX_use_node_external <= 1;
//                #1 TX_use_node_external <= 0;
                
//                data_in_node_external <= 8'h44;
//                #1 TX_use_node_external <= 1;
//                #1 TX_use_node_external <= 0;
                
//                data_in_node_external <= 8'h55;
//                #1 TX_use_node_external <= 1;
//                #1 TX_use_node_external <= 0;
                
//                data_in_node_external <= 8'h00;
//                #1 TX_use_node_external <= 1;
//                #1 TX_use_node_external <= 0;
    end
//    always @(posedge AUX) begin
//        case(state_counter) 
//            // XXX/----
//            IDLE_STATE: begin
//                state_counter <= INIT_STATE;
//            end
//            // XXX/----\______/---
//            INIT_STATE: begin
//                state_counter <= TRANS_STATE;
//                // Transmission test
////                state_counter <= RECEIVE_STATE;
//                #1000;
                
//                data_in_mcu_external <= 8'h27;
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
                
//                data_in_mcu_external <= 8'h11;
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
                
//                data_in_mcu_external <= 8'h22;
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
                
//                data_in_mcu_external <= 8'h33;
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
                
//                data_in_mcu_external <= 8'h44;
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
                
//                data_in_mcu_external <= 8'h55;
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
                
//                data_in_mcu_external <= 8'h66;
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
                
//                data_in_mcu_external <= 8'h77;
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
//            end
//            // XXX/----\______/--------\____WIRELESS_TRANS____/---
//            TRANS_STATE: begin
//                state_counter <= RECEIVE_STATE;
                
//                #1000;
//                data_in_node_external <= 8'hFF;
//                #1 TX_use_node_external <= 1;
//                #1 TX_use_node_external <= 0;
                
//                data_in_node_external <= 8'h11;
//                #1 TX_use_node_external <= 1;
//                #1 TX_use_node_external <= 0;
                
//                data_in_node_external <= 8'h22;
//                #1 TX_use_node_external <= 1;
//                #1 TX_use_node_external <= 0;
                
//                data_in_node_external <= 8'h33;
//                #1 TX_use_node_external <= 1;
//                #1 TX_use_node_external <= 0;
                
//                data_in_node_external <= 8'h44;
//                #1 TX_use_node_external <= 1;
//                #1 TX_use_node_external <= 0;
                
//                data_in_node_external <= 8'h55;
//                #1 TX_use_node_external <= 1;
//                #1 TX_use_node_external <= 0;
                
//                data_in_node_external <= 8'h00;
//                #1 TX_use_node_external <= 1;
//                #1 TX_use_node_external <= 0;
                
//            end
//            RECEIVE_STATE: begin
//                state_counter <= MODE_SWITCHING_STATE;
                
//                #10000;
//                M0 <= 1;
//                M1 <= 1;
                
//            end
//            MODE_SWITCHING_STATE: begin
//                state_counter <= CONFIG_STATE;
//                #10000;
//                data_in_mcu_external <= 8'hC0;
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
                
//                data_in_mcu_external <= 8'h27;
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
                
//                data_in_mcu_external <= 8'h02;
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
                
//                data_in_mcu_external <= 8'hFF;
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
                
//                data_in_mcu_external <= 8'h00;
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
                
//                data_in_mcu_external <= 8'hAA;
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
                
//                // Ask transceiver
//                data_in_mcu_external <= 8'hC1;
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
                
//                data_in_mcu_external <= 8'hC1;
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
                
//                data_in_mcu_external <= 8'hC1;
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
//            end
//            CONFIG_STATE: begin
            
//            end
//        endcase 
//    end

//        always @(posedge AUX) begin
//        case(state_counter) 
//            // XXX/----
//            IDLE_STATE: begin
//                state_counter <= INIT_STATE;
//            end
//            INIT_STATE: begin
//                state_counter <= CONFIG_STATE;
                
//                #1000;
//                data_in_mcu_external <= 8'hC0;
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
                
//                data_in_mcu_external <= 8'h27;
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
                
//                data_in_mcu_external <= 8'h02;
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
                
//                data_in_mcu_external <= 8'hFF;
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
                
//                data_in_mcu_external <= 8'h00;
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
                
//                data_in_mcu_external <= 8'hAA;
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
                
////                // Ask transceiver
////                data_in_mcu_external <= 8'hC1;
////                #1 TX_use_mcu_external <= 1;
////                #1 TX_use_mcu_external <= 0;
                
////                data_in_mcu_external <= 8'hC1;
////                #1 TX_use_mcu_external <= 1;
////                #1 TX_use_mcu_external <= 0;
                
////                data_in_mcu_external <= 8'hC1;
////                #1 TX_use_mcu_external <= 1;
////                #1 TX_use_mcu_external <= 0;
                
                
//                // Ask transceiver
//                data_in_mcu_external <= 8'hC4;
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
                
//                data_in_mcu_external <= 8'hC4;
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
                
//                data_in_mcu_external <= 8'hC4;
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
//            end
//            CONFIG_STATE: begin
//                state_counter <= READY_STATE;
//                #1000;
//                M1 <= 0;
//                M0 <= 0;
//            end
//            READY_STATE: begin
//                state_counter <= RECEIVE_STATE;
//                #1000;    
//                data_in_node_external <= 8'hFF;
//                #1 TX_use_node_external <= 1;
//                #1 TX_use_node_external <= 0;
                
//                data_in_node_external <= 8'h11;
//                #1 TX_use_node_external <= 1;
//                #1 TX_use_node_external <= 0;
                
//                data_in_node_external <= 8'h22;
//                #1 TX_use_node_external <= 1;
//                #1 TX_use_node_external <= 0;
                
//                data_in_node_external <= 8'h33;
//                #1 TX_use_node_external <= 1;
//                #1 TX_use_node_external <= 0;
                
//                data_in_node_external <= 8'h44;
//                #1 TX_use_node_external <= 1;
//                #1 TX_use_node_external <= 0;
                
//                data_in_node_external <= 8'h55;
//                #1 TX_use_node_external <= 1;
//                #1 TX_use_node_external <= 0;
                
//                data_in_node_external <= 8'h00;
//                #1 TX_use_node_external <= 1;
//                #1 TX_use_node_external <= 0;
                
                
////                data_in_mcu_external <= 8'h27;
////                #1 TX_use_mcu_external <= 1;
////                #1 TX_use_mcu_external <= 0;
                
////                data_in_mcu_external <= 8'h11;
////                #1 TX_use_mcu_external <= 1;
////                #1 TX_use_mcu_external <= 0;
                
////                data_in_mcu_external <= 8'h22;
////                #1 TX_use_mcu_external <= 1;
////                #1 TX_use_mcu_external <= 0;
                
////                data_in_mcu_external <= 8'h33;
////                #1 TX_use_mcu_external <= 1;
////                #1 TX_use_mcu_external <= 0;
                
////                data_in_mcu_external <= 8'h44;
////                #1 TX_use_mcu_external <= 1;
////                #1 TX_use_mcu_external <= 0;
                
////                data_in_mcu_external <= 8'h55;
////                #1 TX_use_mcu_external <= 1;
////                #1 TX_use_mcu_external <= 0;
                
////                data_in_mcu_external <= 8'h66;
////                #1 TX_use_mcu_external <= 1;
////                #1 TX_use_mcu_external <= 0;
                
////                data_in_mcu_external <= 8'h77;
////                #1 TX_use_mcu_external <= 1;
////                #1 TX_use_mcu_external <= 0;
//            end
//            RECEIVE_STATE: begin
//                state_counter <= END_STATE;
//                #100000;
//                data_in_mcu_external <= 8'h27;
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
                
//                data_in_mcu_external <= 8'h11;
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
                
//                data_in_mcu_external <= 8'h22;
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
                
//                data_in_mcu_external <= 8'h33;
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
                
//                data_in_mcu_external <= 8'h44;
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
                
//                data_in_mcu_external <= 8'h55;
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
                
//                data_in_mcu_external <= 8'h66;
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
                
//                data_in_mcu_external <= 8'h77;
//                #1 TX_use_mcu_external <= 1;
//                #1 TX_use_mcu_external <= 0;
//            end
//            END_STATE: begin
            
//            end
//        endcase 
//    end
endmodule
