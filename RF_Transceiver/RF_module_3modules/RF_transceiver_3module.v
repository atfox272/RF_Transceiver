module RF_transceiver_3module
    #(
    // Device parameter
        parameter INTERNAL_CLK = 50000000,
        parameter PRESCALER_UART  = 8'd10,             // Use clock divider (prescaler) to reduce power consumption
        parameter PRESCALER_CTRL  = 8'd50,             // Use clock divider (prescaler) to reduce power consumption
        // CLOCK_DIVIDER_UART = INTERNAL_CLK / ((9600 * 256) * 2)
        parameter CLOCK_DIVIDER_UART     =  8'd5,
        parameter CLOCK_DIVIDER_UNIQUE_1 =  8'd55,    // <value> = ceil(Internal clock / (<BAUDRATE_SPEED> * 2))  (115200)
        parameter CLOCK_DIVIDER_UNIQUE_2 =  10'd652,   // <value> = ceil(Internal clock / (<BAUDRATE_SPEED> * 2))  (9600)
        
        parameter END_COUNTER_RX_PACKET         = 651,    // 3 transaction time (for 115200)
        parameter END_WAITING_SEND_WLESS_DATA   = 6250,   // 2-3ms	(Assume: 2.5)
        parameter END_SELF_CHECKING             = 450000, // No information (Following real E32: 180ms)
        parameter END_POWER_ON_CHECK            = 750000, // Asume: 500ms
        parameter END_MODE_SWITCH               = 15000,  // Average: 6ms
        parameter END_PROCESS_COMMAND           = 12500,  // 5ms
        parameter END_PROCESS_RESET             = 2500000 // 1s
    )
    (
        input   wire        device_clk,
        
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
        
//        // RF_transceiver 3
        input   wire        M0_3,
        input   wire        M1_3,
        input   wire        RX_mcu_3,
        output  wire        TX_mcu_3,
        output  wire        AUX_3,
        output  wire        TX_node_3,
        input   wire        RX_node_3,

        // Common reset
        input   wire        rst
        
        //
//        , output wire [1:0] mode_controller_wire
    );
    ///////////////////////////////////
//    wire M0_2 = M0_1;
//    wire M1_2 = M1_1;
//    wire RX_mcu_2 = RX_mcu_1;
//    wire RX_node_2 = RX_node_1;
    
    
//    wire M0_3 = M0_1;
//    wire M1_3 = M1_1;
//    wire RX_mcu_3 = RX_mcu_1;
//    wire RX_node_3 = RX_node_1;
    
    /////////////////////////////////
    // RF_transceiver 1
    RF_transceiver  #(
                    .PRESCALER_UART(PRESCALER_UART),
                    .PRESCALER_CTRL(PRESCALER_CTRL)
                    
                    ,.END_SELF_CHECKING(END_SELF_CHECKING)
                    ,.END_POWER_ON_CHECK(END_POWER_ON_CHECK)
                    ,.END_PROCESS_RESET(END_PROCESS_RESET)
                    
                    )rf_transceiver_1(
                    .device_clk(device_clk),
                    .TX_mcu(TX_mcu_1),
                    .RX_mcu(RX_mcu_1),
                    .M0(M0_1),
                    .M1(M1_1),
                    .AUX(AUX_1),
                    .TX_node(TX_node_1),
                    .RX_node(RX_node_1),
                    .rst(rst)
                    
                    // Debug
//                    ,.mode_controller_wire(mode_controller_wire)
                    );
                    
    // RF_transceiver 2
    RF_transceiver  #(
                    .PRESCALER_UART(PRESCALER_UART),
                    .PRESCALER_CTRL(PRESCALER_CTRL)
                    
                    ,.END_SELF_CHECKING(END_SELF_CHECKING)
                    ,.END_POWER_ON_CHECK(END_POWER_ON_CHECK)
                    ,.END_PROCESS_RESET(END_PROCESS_RESET)
                    
                    )rf_transceiver_2(
                    .device_clk(device_clk),
                    .TX_mcu(TX_mcu_2),
                    .RX_mcu(RX_mcu_2),
                    .M0(M0_2),
                    .M1(M1_2),
                    .AUX(AUX_2),
                    .TX_node(TX_node_2),
                    .RX_node(RX_node_2),
                    .rst(rst)
                    );
                    
    // RF_transceiver 3                
    RF_transceiver  #(
                    .PRESCALER_UART(PRESCALER_UART),
                    .PRESCALER_CTRL(PRESCALER_CTRL)
                    
                    ,.END_SELF_CHECKING(END_SELF_CHECKING)
                    ,.END_POWER_ON_CHECK(END_POWER_ON_CHECK)
                    ,.END_PROCESS_RESET(END_PROCESS_RESET)
                    
                    )rf_transceiver_3(
                    .device_clk(device_clk),
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
