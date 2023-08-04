`timescale 1s / 1ns
module RF_transceiver_general_tb;
    parameter DATA_WIDTH = 8;
    parameter START_WIRELESS_TRANS_VALUE = 8'd5;
    // Waiting module for 3 times empty transaction
        parameter END_COUNTER_RX_PACKET = 50000;    // count (END_COUNTER - START_COUNTER) clock cycle
        parameter START_COUNTER_RX_PACKET = 0;
        parameter END_WAITING_SEND_WLESS_DATA = 50000;
        parameter START_COUNTER_SEND_WLESS_DATA = 0;
        parameter END_SELF_CHECKING = 100000;
    
    // Common            
    reg M0;
    reg M1;
    reg internal_clk;
    reg rst_n;
    wire AUX;
    wire [7:0] all_common_config = 8'b00100011;
    wire [7:0] TX_node_external_config = 8'b01100011;
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
    reg simulate_flag;
    // Debug
        wire [DATA_WIDTH - 1:0] data_bus_out_node_internal;
    wire RX_flag_node_wire;
    wire [1:0] state_counter_mode0_receive_wire;
    wire [DATA_WIDTH - 1:0] data_in_uart_mcu_wire;
    wire TX_use_mcu_wire;
    
    com_uart uart_mcu_external
                    (.clk(internal_clk), 
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
    com_uart uart_node_external
                    (.clk(internal_clk), 
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
                    .START_WIRELESS_TRANS_VALUE(START_WIRELESS_TRANS_VALUE),
                    .END_COUNTER_RX_PACKET (END_COUNTER_RX_PACKET),
                    .START_COUNTER_RX_PACKET(START_COUNTER_RX_PACKET),
                    .END_WAITING_SEND_WLESS_DATA(END_WAITING_SEND_WLESS_DATA),
                    .START_COUNTER_SEND_WLESS_DATA(START_COUNTER_SEND_WLESS_DATA),
                    .END_SELF_CHECKING(END_SELF_CHECKING)
                    )rf_transceiver(
                    .internal_clk(internal_clk),
                    .TX_mcu(TX_to_mcu),
                    .RX_mcu(RX_to_mcu),
                    .M0(M0),
                    .M1(M1),
                    .AUX(AUX),
                    .TX_node(TX_to_node),
                    .RX_node(RX_to_node),
                    .rst_n(rst_n)
                    // Debug
                    ,.data_bus_out_node(data_bus_out_node_internal)
                    ,.RX_flag_node_wire(RX_flag_node_wire)
                    ,.state_counter_mode0_receive_wire(state_counter_mode0_receive_wire)
                    ,.data_in_uart_mcu_wire(data_in_uart_mcu_wire)
                    ,.TX_use_mcu_wire(TX_use_mcu_wire)
                    );
    initial begin
        internal_clk <= 0;
        rst_n <= 1;
        // Wireless-receiver test 
        TX_use_mcu_external <= 0;
        data_in_mcu_external <= 8'h00;
        /////////
        TX_use_node_external <= 0;
        data_in_node_external <= 8'h00;
        //////////////////////
        M0 <= 0;
        M1 <= 0;
        // Simulate falg
        simulate_flag <= 0;
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
        
        
        data_in_mcu_external <= 8'h27;
        #1 TX_use_mcu_external <= 1;
        #1 TX_use_mcu_external <= 0;
        
        data_in_mcu_external <= 8'h11;
        #1 TX_use_mcu_external <= 1;
        #1 TX_use_mcu_external <= 0;
        
        data_in_mcu_external <= 8'h22;
        #1 TX_use_mcu_external <= 1;
        #1 TX_use_mcu_external <= 0;
        
        data_in_mcu_external <= 8'h33;
        #1 TX_use_mcu_external <= 1;
        #1 TX_use_mcu_external <= 0;
        
        data_in_mcu_external <= 8'h44;
        #1 TX_use_mcu_external <= 1;
        #1 TX_use_mcu_external <= 0;
        
        data_in_mcu_external <= 8'h55;
        #1 TX_use_mcu_external <= 1;
        #1 TX_use_mcu_external <= 0;
        
        data_in_mcu_external <= 8'h66;
        #1 TX_use_mcu_external <= 1;
        #1 TX_use_mcu_external <= 0;
        
        data_in_mcu_external <= 8'h77;
        #1 TX_use_mcu_external <= 1;
        #1 TX_use_mcu_external <= 0;
        
//        #1000;
//        M0 <= 1;
//        M1 <= 1;
        
        
//        data_in_mcu_external <= 8'h77;
//        #1 TX_use_mcu_external <= 1;
//        #1 TX_use_mcu_external <= 0;
        
        
        
    end
    
    initial begin
        forever #1 internal_clk <= ~internal_clk;
    end
    always @(negedge AUX) begin
        #10000;
        M0 <= 1;
        M1 <= 1;
    end
    always @(posedge AUX) begin
        #1000; 
        
        if(simulate_flag) begin
            data_in_mcu_external <= 8'hC0;
            #1 TX_use_mcu_external <= 1;
            #1 TX_use_mcu_external <= 0;
            
            data_in_mcu_external <= 8'h27;
            #1 TX_use_mcu_external <= 1;
            #1 TX_use_mcu_external <= 0;
            
            data_in_mcu_external <= 8'h02;
            #1 TX_use_mcu_external <= 1;
            #1 TX_use_mcu_external <= 0;
            
            data_in_mcu_external <= 8'hFF;
            #1 TX_use_mcu_external <= 1;
            #1 TX_use_mcu_external <= 0;
            
            data_in_mcu_external <= 8'h00;
            #1 TX_use_mcu_external <= 1;
            #1 TX_use_mcu_external <= 0;
            
            data_in_mcu_external <= 8'hAA;
            #1 TX_use_mcu_external <= 1;
            #1 TX_use_mcu_external <= 0;
            
            
            data_in_mcu_external <= 8'hC4;
            #1 TX_use_mcu_external <= 1;
            #1 TX_use_mcu_external <= 0;
            
            data_in_mcu_external <= 8'hC4;
            #1 TX_use_mcu_external <= 1;
            #1 TX_use_mcu_external <= 0;
            
            data_in_mcu_external <= 8'hC4;
            #1 TX_use_mcu_external <= 1;
            #1 TX_use_mcu_external <= 0;
        end
        else simulate_flag <= 1;
    end
endmodule
