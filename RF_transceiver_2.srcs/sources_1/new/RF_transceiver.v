`define DEBUG
module RF_transceiver
    #(
    parameter DATA_WIDTH        = 8,
    parameter UART_BUFFER       = 32,
    // Fixed configuration of UART
    parameter BD9600_8N1        = 8'b00100011,
    parameter BD115200_8N1      = 8'b11100011,
    parameter INTERNAL_CLOCK    = 125000000
    )
    (
    input       clk,
    
    input       RX_node,
    output      TX_node,
    
    input       RX_mcu,
    output      TX_mcu,
    
    input       M1,
    input       M0,
    
    output      AUX,
    
    input       rst
    
    `ifdef DEBUG 
//    ,output      M1_sync_out
//    ,output      M0_sync_out
    `endif
    );
    
    localparam  MODE_0 = 0;
    localparam  MODE_3 = 3;
    
    // Common 
    wire                    M0_sync;
    wire                    M1_sync;
    // UART MCU
    wire                    TX_use_mcu;
    wire                    TX_flag_mcu;
    wire                    TX_complete_mcu;
    wire                    TX_available_mcu;
    wire                    RX_use_mcu;
    wire                    RX_flag_mcu;
    wire                    RX_available_mcu;
    wire [DATA_WIDTH - 1:0] data_to_uart_mcu;
    wire [DATA_WIDTH - 1:0] data_from_uart_mcu;
    wire [DATA_WIDTH - 1:0] TX_config_register_mcu;
    wire [DATA_WIDTH - 1:0] RX_config_register_mcu;
    // UART NODE
    wire                    TX_use_node;
    wire                    TX_flag_node;
    wire                    TX_complete_node;
    wire                    RX_use_node;
    wire                    RX_flag_node;
    wire [DATA_WIDTH - 1:0] data_to_uart_node;
    wire [DATA_WIDTH - 1:0] data_from_uart_node;
    wire [DATA_WIDTH - 1:0] TX_config_register_node;
    wire [DATA_WIDTH - 1:0] RX_config_register_node;
    wire                    rst_n = ~rst;
    assign RX_config_register_mcu  = ({M1_sync,M0_sync} == MODE_3) ? BD9600_8N1 : BD115200_8N1;
    assign TX_config_register_mcu  = ({M1_sync,M0_sync} == MODE_3) ? BD9600_8N1 : BD115200_8N1;
    assign RX_config_register_node = BD115200_8N1;
    assign TX_config_register_node = BD115200_8N1;
//    (* dont_touch = "yes" *)   
    uart_peripheral 
        #(
        .FIFO_DEPTH(UART_BUFFER),
        .RX_FLAG_TYPE(0)
        ,.INTERNAL_CLOCK(INTERNAL_CLOCK)
        `ifdef DEBUG
//        ,.CLOCK_DIVIDER_UNIQUE_1(CLOCK_BD115200)
//        ,.CLOCK_DIVIDER_UNIQUE_2(CLOCK_BD9600)
        `endif
        )uart_mcu(
        .clk(clk),
        .data_in(data_to_uart_mcu),
        .data_out(data_from_uart_mcu),
        .TX_config_register(TX_config_register_mcu),
        .RX_config_register(RX_config_register_mcu),
        .RX(RX_mcu),
        .TX(TX_mcu),
        .RX_use(RX_use_mcu),
        .RX_flag(RX_flag_mcu),
        .RX_available(RX_available_mcu),
        .TX_use(TX_use_mcu),
        .TX_flag(TX_flag_mcu),
        .TX_complete(TX_complete_mcu),
        .TX_available(TX_available_mcu),
        .rst_n(rst_n)
        );
   
//    (* dont_touch = "yes" *)       
    uart_peripheral 
        #(
        .FIFO_DEPTH(UART_BUFFER),
        .RX_FLAG_TYPE(1)
        ,.INTERNAL_CLOCK(INTERNAL_CLOCK)
        `ifdef DEBUG
//        ,.CLOCK_DIVIDER_UNIQUE_1(CLOCK_BD115200)
//        ,.CLOCK_DIVIDER_UNIQUE_2(CLOCK_BD9600)
        `endif
        )uart_node(
        .clk(clk),
        .data_in(data_to_uart_node),
        .data_out(data_from_uart_node),
        .TX_config_register(TX_config_register_node),
        .RX_config_register(RX_config_register_node),
        .RX(RX_node),
        .TX(TX_node),
        .RX_use(RX_use_node),
        .RX_flag(RX_flag_node),
        .RX_available(),
        .TX_use(TX_use_node),
        .TX_flag(TX_flag_node),
        .TX_complete(TX_complete_node),
//        .TX_available(TX_available_node),
        .rst_n(rst_n)
        );    
     (* dont_touch = "yes" *)      
     controller
        #(
        `ifdef DEBUG
//        .RESET_TIMING(70000)
//        ,.MODE_SWITCH_TIMING(50)
//        ,._3_TRANSACTION_TIMING(50000)
        `endif
        )controller(
        .clk(clk),
        // Interface
        .AUX(AUX),
        .M0(M0),
        .M1(M1),
        .M0_sync(M0_sync),
        .M1_sync(M1_sync),
        
        // MCU
        .data_to_uart_mcu(data_to_uart_mcu),
        .data_from_uart_mcu(data_from_uart_mcu),
        .RX_use_mcu(RX_use_mcu),
        .RX_flag_mcu(RX_flag_mcu),
        .RX_available_mcu(RX_available_mcu),
        .TX_use_mcu(TX_use_mcu),
        .TX_flag_mcu(TX_flag_mcu),
        .TX_complete_mcu(TX_complete_mcu),
        .TX_available_mcu(TX_available_mcu),
        // NODE 
        .data_to_uart_node(data_to_uart_node),
        .data_from_uart_node(data_from_uart_node),
        .RX_use_node(RX_use_node),
        .RX_flag_node(RX_flag_node),
        .TX_use_node(TX_use_node),
        .TX_flag_node(TX_flag_node),
        .TX_complete_node(TX_complete_node),
        
        .rst_n(rst_n)
        );   
            
    `ifdef DEBUG
//    assign M1_sync_out = M1_sync;
//    assign M0_sync_out = M0_sync;
    `endif            
endmodule
