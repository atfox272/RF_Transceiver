module controller_RF_transceiver
    #(  
        // Data
        parameter DATA_WIDTH = 8,
        // UART configuration parament
        parameter UART_CONFIG_WIDTH = 8,
        parameter BAUDRATE_SEL_MSB = 7, // Index of this bit in reg
        parameter BAUDRATE_SEL_LSB = 5, // Index of this bit in reg
        parameter STOP_BIT_CONFIG = 4, // Index of this bit in reg
        parameter PARITY_BIT_CONFIG_MSB = 3, // Index of this bit in reg
        parameter PARITY_BIT_CONFIG_LSB = 2, // Index of this bit in reg
        parameter DATA_BIT_CONFIG_MSB = 1, // Index of this bit in reg
        parameter DATA_BIT_CONFIG_LSB = 0, // Index of this bit in reg
        parameter TX_USE_IDLE_STATE = 0,
        // Transaction
        parameter TRANSACTION_WIDTH = 8,
        // INIT parameter setting command buffer  
        parameter INIT_BUFFER_HEAD = {8{1'b0}},
        parameter INIT_BUFFER_ADDH = {8{1'b0}},
        parameter INIT_BUFFER_ADDL = {8{1'b0}},
        parameter INIT_BUFFER_SPED = 8'b00011000,   // 8N1 - 9600
        parameter INIT_BUFFER_CHAN = {8{1'b0}},
        parameter INIT_BUFFER_OPTION = {8{1'b0}},
        // Detect Instruction
        parameter HEAD_DETECT_1 = 8'hC0,        // Load config
        parameter HEAD_DETECT_2 = 8'hC2,        // 
        parameter RET_CONFIG_DETECT = 8'hC1,    // Return config
        parameter RET_VERSION_DETECT = 8'hC3,    // Return version
        parameter RESET_DETECT = 8'hC4,
        // Version
        parameter VERSION_PACKET_1 = 8'hC3,     // Format (default)
        parameter VERSION_PACKET_2 = 8'h32,     // Format (default)
        parameter VERSION_PACKET_3 = 8'h27,     // My config
        parameter VERSION_PACKET_4 = 8'h02,     // My config
        // Mode encode
        parameter MODE_0 = 0,
        parameter MODE_1 = 1,
        parameter MODE_2 = 2,
        parameter MODE_3 = 3,
        // State of module encoder (One-hot state-machine encoding)
        parameter MODULE_IDLE_STATE = 3,    // (wireless_trans and wireless_recei is not woking 
        parameter MODULE_WTRANS_STATE = 2,  // (wireless_trans is working )
        parameter MODULE_WRECEIVE_STATE = 1,// (wireless_receiver is working)
        parameter MODULE_PROGRAM_STATE = 0, // (programed state is working
        // 512bytes FIFO buffer
        parameter FIFO512_DEPTH = 512,
        parameter COUNTER_FIFO512_WIDTH = $clog2(FIFO512_DEPTH + 1),
        parameter START_WIRELESS_TRANS_VALUE = 58,        
        parameter COUNTER_58BYTES_WIDTH = $clog2(START_WIRELESS_TRANS_VALUE + 1),
        parameter COUNTER_START_TRANS_WIDTH = $clog2(COUNTER_58BYTES_WIDTH + 1),
        // Waiting module for 3 times empty transaction
        parameter END_COUNTER_RX_PACKET = 500000,    // count (END_COUNTER - START_COUNTER) clock cycle
        parameter START_COUNTER_RX_PACKET = 0,
        parameter END_WAITING_SEND_WLESS_DATA = 20000,
        parameter START_COUNTER_SEND_WLESS_DATA = 0,
        parameter END_SELF_CHECKING = 10000
    )
    (
    input   wire internal_clk,
    input   wire M0_sync,
    input   wire M1_sync,
    output  wire AUX,
    // UART to MCU
    output                                      TX_use_mcu,
    input   wire                                TX_flag_mcu,
    input                                       RX_flag_mcu,    // RX module is in IDLE state
    input   wire    [DATA_WIDTH - 1:0]          data_from_uart_mcu,
    output  wire    [DATA_WIDTH - 1:0]          data_to_uart_mcu,  
    output  wire    [UART_CONFIG_WIDTH - 1:0]   uart_mcu_config_reg,
    // UART to NODE 
    output  wire                                TX_use_node,     
    input   wire                                TX_flag_node, 
    output  wire                                RX_use_node,
    input   wire                                RX_flag_node,    
    input   wire                                TX_complete_mcu,    // All packet in TX fifo has been send  
    input   wire    [DATA_WIDTH - 1:0]          data_from_uart_node,
    output  wire    [DATA_WIDTH - 1:0]          data_to_uart_node,
    // State of module 
    output [3:0] state_module,         
    
    input   wire rst_n
    
    // debug 
//    ,output [1:0] state_counter_mode0_receive_wire
    );
    // Configuartion register 
    reg [TRANSACTION_WIDTH - 1:0] HEAD;
    reg [TRANSACTION_WIDTH - 1:0] ADDH;
    reg [TRANSACTION_WIDTH - 1:0] ADDL;
    reg [UART_CONFIG_WIDTH - 1:0] SPED; 
    reg [TRANSACTION_WIDTH - 1:0] CHAN;
    reg [TRANSACTION_WIDTH - 1:0] OPTION;
    assign uart_mcu_config_reg = SPED;
    // Reply     // Config parameter 
    reg return_start_asyn;
    reg return_stop_asyn;
    // Version of device 
    reg return_version_start;
    reg return_version_stop;
    // Mode controller
    wire [1:0] mode_controller = {M1_sync, M0_sync};
    // AUX controller
    reg AUX_controller_1;
    wire AUX_controller_2;
    wire AUX_controller_3;
    // Mode 3 state-machine 
    reg [3:0] state_counter_mode3;
    reg [1:0] return_case;        
    reg [4:0] state_counter_mode3_return;
    // Synchronous enable flag of return_config instruction
    // Mode 0 controller 
    wire mode0_en = (M0_sync == 0) & (M1_sync == 0);
    // Module is receiving (mode 0 or 1) -> AUX is LOW (state of module)  
    wire start_wireless_trans_cond_1;
    // 512bytes Buffer 
    wire buffer_512bytes_full;
    wire buffer_512bytes_empty;                
    // Waiting_module to waiting for "3-time empty transaction"
    wire start_wireless_trans_cond_2;
    wire waiting_pulse;
    reg [3:0] state_counter_wireless_trans;
    reg start_wireless_trans;
    wire mode0_clk = (mode0_en) ? internal_clk : 1'b0;
    wire start_wireless_trans_cond;
    
    
    localparam IDLE_STATE = 0;
    localparam READ_SPED_STATE = 6;
    localparam READ_HEAD_STATE = 1;
    localparam READ_ADDH_STATE = 2;
    localparam READ_ADDL_STATE = 3;
    localparam READ_CHAN_STATE = 4;
    localparam READ_OPTION_STATE = 5;
    localparam INS_CONFIG_STATE_2 = 7;
    localparam INS_CONFIG_STATE_3 = 8;
    localparam INS_VERSION_STATE_2 = 9;
    localparam INS_VERSION_STATE_3 = 10;
    localparam INS_RESET_STATE_2 = 12;
    localparam INS_RESET_STATE_3 = 13;
     
    // Return Instruction encode
    localparam RETURN_CONFIG_CASE = 0;        // Return configuration
    localparam RETURN_VERSION_CASE = 1;       // Return version
    localparam RETURN_NOTHING_CASE = 2;       // Reset command case
    
    // AUX controller
    assign AUX = AUX_controller_1 & AUX_controller_2 & AUX_controller_3;                
    
    // Mode3 enable 
    wire mode3_clk;
    wire mode3_receive_clk;
    wire mode3_en;
    
    assign mode3_en = (mode_controller == MODE_3);
    assign mode3_clk = (mode3_en) ? internal_clk : 1'b0;
    assign mode3_receive_clk = (mode3_en) ? RX_flag_mcu : 1'b0;
    
    always @(posedge mode3_receive_clk, negedge rst_n) begin
        if(!rst_n) begin
            state_counter_mode3 <= IDLE_STATE;
//            TX_mcu_use <= TX_USE_IDLE_STATE;
            HEAD <= INIT_BUFFER_HEAD;
            ADDH <= INIT_BUFFER_ADDH;
            ADDL <= INIT_BUFFER_ADDL;
            SPED <= INIT_BUFFER_SPED;
            CHAN <= INIT_BUFFER_CHAN;
            OPTION <= INIT_BUFFER_OPTION;
            // Return signal
            return_start_asyn <= 0;
            return_version_start <= 0;
            return_case <= RETURN_NOTHING_CASE;
        end
        else begin
            case(state_counter_mode3) 
                IDLE_STATE: begin
                    case (data_from_uart_mcu) 
                        HEAD_DETECT_1: begin
                            state_counter_mode3 <= READ_HEAD_STATE;
                            HEAD <= data_from_uart_mcu;
                        end
                        HEAD_DETECT_2: begin
                            state_counter_mode3 <= READ_HEAD_STATE;
                            HEAD <= data_from_uart_mcu;
                        end
                        RET_CONFIG_DETECT: begin
                            state_counter_mode3 <= INS_CONFIG_STATE_2;
                        end
                        RET_VERSION_DETECT: begin
                            state_counter_mode3 <= INS_VERSION_STATE_2;
                        end
                        RESET_DETECT: begin
                            state_counter_mode3 <= INS_RESET_STATE_2;
                        end
                        default: state_counter_mode3 <= IDLE_STATE;
                    endcase
                end
                READ_HEAD_STATE: begin
                    state_counter_mode3 <= READ_ADDH_STATE;
                    ADDH <= data_from_uart_mcu;
                end
                READ_ADDH_STATE: begin
                    state_counter_mode3 <= READ_ADDL_STATE;
                    ADDL <= data_from_uart_mcu;
                end
                READ_ADDL_STATE: begin
                    state_counter_mode3 <= READ_SPED_STATE;
                    SPED <= data_from_uart_mcu;
                end
                READ_SPED_STATE: begin
                    state_counter_mode3 <= READ_CHAN_STATE;
                    CHAN <= data_from_uart_mcu;
                end
                READ_CHAN_STATE: begin
                    state_counter_mode3 <= IDLE_STATE;
                    OPTION <= data_from_uart_mcu;
                end
                INS_CONFIG_STATE_2: begin
                    if(data_from_uart_mcu == RET_CONFIG_DETECT) state_counter_mode3 <= INS_CONFIG_STATE_3;
                    else state_counter_mode3 <= IDLE_STATE;
                end
                INS_CONFIG_STATE_3: begin
                    state_counter_mode3 <= IDLE_STATE;
                    if(data_from_uart_mcu == RET_CONFIG_DETECT) begin
                        return_start_asyn <= ~return_stop_asyn;
                        return_case <= RETURN_CONFIG_CASE;
                    end
                    else return_start_asyn <= return_start_asyn;
                end 
                INS_VERSION_STATE_2: begin
                    if(data_from_uart_mcu == RET_VERSION_DETECT) state_counter_mode3 <= INS_VERSION_STATE_3;
                    else state_counter_mode3 <= IDLE_STATE;
                end
                INS_VERSION_STATE_3: begin
                    state_counter_mode3 <= IDLE_STATE;
                    if(data_from_uart_mcu == RET_VERSION_DETECT) begin
                        return_start_asyn <= ~return_stop_asyn;
                        return_case <= RETURN_VERSION_CASE;
                    end
                    else return_start_asyn <= return_start_asyn;
                end 
                INS_RESET_STATE_2: begin
                    if(data_from_uart_mcu == RESET_DETECT) state_counter_mode3 <= INS_RESET_STATE_3;
                    else state_counter_mode3 <= IDLE_STATE;
                end
                INS_RESET_STATE_3: begin
                    state_counter_mode3 <= IDLE_STATE;
                    if(data_from_uart_mcu == RESET_DETECT) begin
                        return_start_asyn <= ~return_stop_asyn;
                        return_case <= RETURN_NOTHING_CASE;
                    end
                end
                default: state_counter_mode3 <= IDLE_STATE;
            endcase 
            
        end
    end
    reg return_start_sync;
    reg return_stop_sync;
    wire return_clk_enable;
    wire return_clk;
    
    assign return_clk_enable = return_start_sync ^ return_stop_sync;
    assign return_clk = (return_clk_enable) ? internal_clk : 1'b0;
    
    always @(posedge mode3_clk, negedge rst_n) begin
        if(!rst_n) begin
            return_start_sync <= 0;
        end
        else begin
            return_start_sync <= return_start_asyn;
        end
    end
    always @(negedge mode3_clk, negedge rst_n) begin
        if(!rst_n) begin
            return_stop_sync <= 0;
        end
        else begin
            return_stop_sync <= return_stop_asyn;
        end
    end
    
    
    localparam RET_HEAD_STATE = 1;
    localparam SEND_RET_HEAD_STATE = 11;
    localparam RET_ADDH_STATE = 2;
    localparam SEND_RET_ADDH_STATE = 12;
    localparam RET_ADDL_STATE = 3;
    localparam SEND_RET_ADDL_STATE = 13;
    localparam RET_SPED_STATE = 4;
    localparam SEND_RET_SPED_STATE = 14;
    localparam RET_CHAN_STATE = 5;
    localparam SEND_RET_CHAN_STATE = 15;
    localparam RET_OPTION_STATE = 6;
    localparam SEND_RET_OPTION_STATE = 16;
    localparam RET_VERSION_STATE_1 = 7;   
    localparam SEND_RET_VERSION_STATE_1 = 17;   
    localparam RET_VERSION_STATE_2 = 8;   
    localparam SEND_RET_VERSION_STATE_2 = 18;   
    localparam RET_VERSION_STATE_3 = 9;   
    localparam SEND_RET_VERSION_STATE_3 = 19;   
    localparam RET_VERSION_STATE_4 = 10;  
    localparam SEND_RET_VERSION_STATE_4 = 20;
    localparam SELF_CHECK_STATE = 21;
    localparam WAITING_UART_TRANS_STATE = 22;
    reg TX_use_mcu_mode3;
    reg [DATA_WIDTH - 1:0] data_to_uart_mcu_mode3;
    wire stop_self_check_signal;
    waiting_module #(
                    .END_COUNTER(END_SELF_CHECKING),
                    .WAITING_TYPE(0),
                    .LEVEL_PULSE(0)
                    )waiting_self_check(
                    .clk(mode3_clk),
                    .start_counting(AUX_controller_1),
                    .reach_limit(stop_self_check_signal),
                    .rst_n(rst_n)
                    );
    always @(posedge return_clk, negedge rst_n) begin
        if(!rst_n) begin
            state_counter_mode3_return <= IDLE_STATE;
            return_stop_asyn <= 0;
            // Data 
            data_to_uart_mcu_mode3 <= {8{1'b0}};
            // TX use (to MCU)
            TX_use_mcu_mode3 <= 0;
            // AUX controller 
             AUX_controller_1 <= 1;
        end
        else begin
            case(state_counter_mode3_return) 
                IDLE_STATE: begin
                    TX_use_mcu_mode3 <= 0;
                    case(return_case) 
                        RETURN_CONFIG_CASE: begin
                            state_counter_mode3_return <= SEND_RET_HEAD_STATE; 
                            data_to_uart_mcu_mode3 <= HEAD;
                        end
                        RETURN_VERSION_CASE: begin
                            state_counter_mode3_return <= SEND_RET_VERSION_STATE_1;
                            data_to_uart_mcu_mode3 <= VERSION_PACKET_1;
                        end
                        RETURN_NOTHING_CASE: begin
                            state_counter_mode3_return <= SELF_CHECK_STATE;
                            AUX_controller_1 <= 0;
                        end
                        default: state_counter_mode3_return <= IDLE_STATE;
                    endcase
                end
                SELF_CHECK_STATE: begin
                    if(stop_self_check_signal) begin
                        state_counter_mode3_return <= IDLE_STATE;
                        AUX_controller_1 <= 1;
                        return_stop_asyn <= return_start_asyn;
                    end
                end
                RET_HEAD_STATE: begin
                    state_counter_mode3_return <= SEND_RET_ADDH_STATE;
                    data_to_uart_mcu_mode3 <= ADDH;
                    TX_use_mcu_mode3 <= 0;
                end
                RET_ADDH_STATE: begin
                    state_counter_mode3_return <= SEND_RET_ADDL_STATE;
                    data_to_uart_mcu_mode3 <= ADDL;
                    TX_use_mcu_mode3 <= 0;
                end
                RET_ADDL_STATE: begin
                    state_counter_mode3_return <= SEND_RET_SPED_STATE;
                    data_to_uart_mcu_mode3 <= SPED;
                    TX_use_mcu_mode3 <= 0;
                end
                RET_SPED_STATE: begin
                    state_counter_mode3_return <= SEND_RET_CHAN_STATE;
                    data_to_uart_mcu_mode3 <= CHAN;
                    TX_use_mcu_mode3 <= 0;
                end
                RET_CHAN_STATE: begin
                    state_counter_mode3_return <= SEND_RET_OPTION_STATE;
                    data_to_uart_mcu_mode3 <= OPTION;
                    TX_use_mcu_mode3 <= 0;
                end
                RET_VERSION_STATE_1: begin
                    state_counter_mode3_return <= SEND_RET_VERSION_STATE_2;
                    data_to_uart_mcu_mode3 <= VERSION_PACKET_2;
                    TX_use_mcu_mode3 <= 0;
                end
                RET_VERSION_STATE_2: begin
                    state_counter_mode3_return <= SEND_RET_VERSION_STATE_3;
                    data_to_uart_mcu_mode3 <= VERSION_PACKET_3;
                    TX_use_mcu_mode3 <= 0;
                end
                RET_VERSION_STATE_3: begin
                    state_counter_mode3_return <= SEND_RET_VERSION_STATE_4;
                    data_to_uart_mcu_mode3 <= VERSION_PACKET_4;
                    TX_use_mcu_mode3 <= 0;
                end
                SEND_RET_HEAD_STATE: begin
                    state_counter_mode3_return <= RET_HEAD_STATE;
                    TX_use_mcu_mode3 <= 1;
                end
                SEND_RET_ADDH_STATE: begin
                    state_counter_mode3_return <= RET_ADDH_STATE;
                    TX_use_mcu_mode3 <= 1;
                end
                SEND_RET_ADDL_STATE: begin
                    state_counter_mode3_return <= RET_ADDL_STATE;
                    TX_use_mcu_mode3 <= 1;
                end
                SEND_RET_SPED_STATE: begin
                    state_counter_mode3_return <= RET_SPED_STATE;
                    TX_use_mcu_mode3 <= 1;
                end
                SEND_RET_CHAN_STATE: begin
                    state_counter_mode3_return <= RET_CHAN_STATE;
                    TX_use_mcu_mode3 <= 1;
                end
                SEND_RET_OPTION_STATE: begin
                    state_counter_mode3_return <= IDLE_STATE; 
                    TX_use_mcu_mode3 <= 1;
                    // Stop return clock
                    return_stop_asyn <= return_start_asyn;
                end
                SEND_RET_VERSION_STATE_1: begin
                    state_counter_mode3_return <= RET_VERSION_STATE_1;
                    TX_use_mcu_mode3 <= 1;
                end
                SEND_RET_VERSION_STATE_2: begin
                    state_counter_mode3_return <= RET_VERSION_STATE_2;
                    TX_use_mcu_mode3 <= 1;
                end
                SEND_RET_VERSION_STATE_3: begin
                    state_counter_mode3_return <= RET_VERSION_STATE_3;
                    TX_use_mcu_mode3 <= 1;
                end        
                SEND_RET_VERSION_STATE_4: begin
                    state_counter_mode3_return <= IDLE_STATE; 
                    TX_use_mcu_mode3 <= 1;
                    // Stop return clock
                    return_stop_asyn <= return_start_asyn;
                end
                WAITING_UART_TRANS_STATE : begin
                    if(TX_complete_mcu) state_counter_mode3_return <= IDLE_STATE;
                end
                default: state_counter_mode3_return <= IDLE_STATE;
            endcase 
        end
    end
    // Wireless-Transission module
    wire wakeup_wireless_trans_clk;
    reg wireless_trans_enable_start;
    reg wireless_trans_enable_stop;
    wire wireless_trans_enable;//
    wire wireless_trans_clk;
    
    // Only in mode_0 and mode_1, wireless_transmission module is enable
    assign wireless_trans_enable = wireless_trans_enable_start ^ wireless_trans_enable_stop;
    assign wakeup_wireless_trans_clk = (mode_controller == MODE_0 | mode_controller == MODE_1) ? internal_clk : 1'b0;
    assign wireless_trans_clk = (wireless_trans_enable) ? internal_clk : 1'b0;
    
    // In sleep mode of wireless_transmission: Only 1 wireless_trans_en is work
    // Enable when RX has new data
    wire RX_flag_mcu_sync;
    edge_detector wake_up_wtrans_module(    
                            .clk(internal_clk),
                            .sig_in(RX_flag_mcu),
                            .out(RX_flag_mcu_sync),
                            .rst_n(rst_n));
    always @(posedge wakeup_wireless_trans_clk, negedge rst_n) begin
        if(!rst_n) begin
            wireless_trans_enable_start <= 0;
        end 
        else begin
            if(RX_flag_mcu_sync) wireless_trans_enable_start <= ~wireless_trans_enable_stop;
        end
    end
    always @(negedge wakeup_wireless_trans_clk, negedge rst_n) begin
        if(!rst_n) begin
            wireless_trans_enable_stop <= 0;
        end
        else begin
            if(state_counter_wireless_trans == IDLE_STATE) wireless_trans_enable_stop <= wireless_trans_enable_start;
        end
    end
    fifo_module     #(
                    .DEPTH(FIFO512_DEPTH),
                    .WIDTH(DATA_WIDTH),
                    .LIMIT_COUNTER(START_WIRELESS_TRANS_VALUE),
                    .SLEEP_MODE(1'b1)
                    )buffer_512bytes(
                    .data_bus_in(data_from_uart_mcu),
                    .data_bus_out(data_to_uart_node),
                    .write_ins(RX_flag_mcu),
                    .read_ins(TX_use_node),
                    .reach_limit(start_wireless_trans_cond_1),
                    .enable(wireless_trans_enable),
                    .full(buffer_512bytes_full),
                    .empty(buffer_512bytes_empty),
                    .rst_n(rst_n)
                    );
    
    localparam WIRELESS_TRANS_STATE = 1; 
    localparam START_READ_STATE = 2; 
    localparam STOP_RX_STATE = 3; 
    assign AUX_controller_2 = (state_counter_wireless_trans == IDLE_STATE);    // Just free in IDLE_STATE
    assign waiting_pulse = RX_flag_mcu & (state_counter_wireless_trans == START_READ_STATE);
    
    waiting_module #(
                    .END_COUNTER(END_COUNTER_RX_PACKET),
                    .START_COUNTER(START_COUNTER_RX_PACKET),
                    .WAITING_TYPE(0),
                    .LEVEL_PULSE(1)
                    )waiting_RX_packet(
                    .clk(wireless_trans_clk),
                    .start_counting(waiting_pulse),
                    .reach_limit(start_wireless_trans_cond_2),
                    .rst_n(rst_n)
                    );
    // Load data into RFIC 
    reg wireless_trans_start;
    reg wireless_trans_stop;
    wire wireless_trans_en;     // IDLE state of wireless_trans_en is HIGH
    assign start_wireless_trans_cond = start_wireless_trans_cond_1 | start_wireless_trans_cond_2;
    assign wireless_trans_en = wireless_trans_start ^ wireless_trans_stop;
    always @(posedge wireless_trans_clk, negedge rst_n) begin
        if(!rst_n) begin
            state_counter_wireless_trans <= IDLE_STATE;
            start_wireless_trans <= 0;
            wireless_trans_start <= 1;      // (IDLE state of wireless_trans_en = 1)Different from wireless_trans_stop
        end
        else begin
            case(state_counter_wireless_trans)
                IDLE_STATE: begin
                    if(!buffer_512bytes_empty) begin
                        state_counter_wireless_trans <= START_READ_STATE;
                    end
                    else state_counter_wireless_trans <= IDLE_STATE;
                end
                START_READ_STATE: begin
                    if(start_wireless_trans_cond) begin
                        state_counter_wireless_trans <= WIRELESS_TRANS_STATE;
                        // Add: Starting take-out data from BUFFER512
                    end
                    else state_counter_wireless_trans <= START_READ_STATE;
                end
                WIRELESS_TRANS_STATE: begin
                    // if(!wireless_trans_en | buffer512_empty)
                    if(wireless_trans_en & !buffer_512bytes_empty) begin     // Need to change this condition 
                        state_counter_wireless_trans <= WIRELESS_TRANS_STATE;
                    end
                    else begin
                        if(buffer_512bytes_empty) begin
                            state_counter_wireless_trans <= IDLE_STATE;                        
                        end
                        else begin
                            state_counter_wireless_trans <= START_READ_STATE;
                        end
                        // Below statement is used for debugging
//                        state_counter_wireless_trans <= IDLE_STATE;
                        /////    
                        // Prepare for next wireless transmission
                        wireless_trans_start <= ~wireless_trans_stop;
                    end 
                end
                default: state_counter_wireless_trans <= IDLE_STATE;
            endcase             
        end
    end
    // Counting take-out module 
    reg [COUNTER_58BYTES_WIDTH - 1:0] _58bytes_counter;
    always @(negedge TX_use_node, negedge rst_n) begin
        if(!rst_n) begin
            _58bytes_counter <= 0;
            wireless_trans_stop <= 0;
        end
        else begin
            // Add counter_fifo -> if(counter_fifo == 1) 
            if(buffer_512bytes_empty) begin
                _58bytes_counter <= 0;
                // wireless-transmitter has changed state already, so you dont need add state-switching signal here 
            end
            else if((_58bytes_counter == START_WIRELESS_TRANS_VALUE)) begin
                _58bytes_counter <= 0;
                wireless_trans_stop <= wireless_trans_start;
            end
            else _58bytes_counter <= _58bytes_counter + 1;
        end
    end
    // TX to UART node
    // WIRELESS_TRANS_STATE ____/-----------------------       -----\___________________
    // TX_node_idle         -----\________/------\______/     \____/-----\______/----------
    //                      ____/\________/------\______/     \____/\_________
    //                          ^                                  ^
    //                (Up to 58bytes in FIFO)             (Read last byte in FIFO)
    assign TX_use_node = (state_counter_wireless_trans == WIRELESS_TRANS_STATE) & TX_flag_node;
    
    // Wireless_receiver module
    wire wakeup_wireless_receiver_clk;
    reg wireless_receiver_enable_start;
    reg wireless_receiver_enable_stop;
    wire wireless_receiver_enable;
    wire wireless_receiver_clk;
    wire start_send_wireless_data_cond;
    wire start_waiting_send_wireless_data;
    wire [DATA_WIDTH - 1:0] data_to_uart_mcu_mode0;
    wire buffer_wireless_receiver_empty;
    reg [1:0] state_counter_wireless_receive;
    wire TX_use_mcu_mode0;
    
    assign wireless_receiver_enable = wireless_receiver_enable_start ^ wireless_receiver_enable_stop;
    assign wakeup_wireless_receiver_clk = (mode_controller == MODE_0 | mode_controller == MODE_1 | mode_controller == MODE_2) ?
                                       internal_clk : 1'b0;
    assign wireless_receiver_clk = (wireless_receiver_enable) ? internal_clk : 1'b0;                                   
    
    
    wire RX_flag_node_sync;
    edge_detector wake_up_wreceiver_module(    
                            .clk(internal_clk),
                            .sig_in(RX_flag_node),
                            .out(RX_flag_node_sync),
                            .rst_n(rst_n));
                            
    always @(posedge wakeup_wireless_receiver_clk, negedge rst_n) begin
        if(!rst_n) begin
            wireless_receiver_enable_start <= 0;
        end
        else begin
            if(RX_flag_node_sync) wireless_receiver_enable_start <= ~wireless_receiver_enable_stop;
        end
    end       
    always @(negedge wakeup_wireless_receiver_clk, negedge rst_n) begin
        if(!rst_n) begin
            wireless_receiver_enable_stop  <= 0;
        end
        else begin
            if(state_counter_wireless_receive == IDLE_STATE) wireless_receiver_enable_stop <= wireless_receiver_enable_start;
        end
    end
    localparam START_RECEIVE_STATE = 1;        
    localparam SEND_WIRELESS_DATA_STATE = 2; 
    localparam SEND_ALL_STATE = 3; 
    
    assign TX_use_mcu_mode0 = (state_counter_wireless_receive == SEND_WIRELESS_DATA_STATE) & TX_flag_mcu;
    fifo_module     #(
                    .DEPTH(FIFO512_DEPTH),
                    .WIDTH(DATA_WIDTH),
                    .SLEEP_MODE(1'b1)
                    )buffer_wireless_receiver(
                    .data_bus_in(data_from_uart_node),
                    .data_bus_out(data_to_uart_mcu_mode0),
                    .write_ins(RX_flag_node),
                    .read_ins(TX_use_mcu_mode0),
                    .enable(wireless_receiver_enable),
                    .empty(buffer_wireless_receiver_empty),
                    .rst_n(rst_n)
                    );
                    
    // TX to UART node
    //Internal clock            /\/\/\/\/\/\/\/\/\/\/\/\/\/\/\     \/\/\/\/\
    // AUX                      _____________________________________________________/----------
    // SEND_WIRELESS_DATA_STATE ____/-----------------------       -------\___________________
    // TX_flag_mcu (idle_state) ------\_______/------\______/     \_____/-----\______/----------
    //                          ____/-\_______/------\______/     \_____/-\_________
    //                              ^                                  ^
    //               (Wait 5ms when receive frist packet)      (Read last byte in FIFO) 
    // Buffer_empty_n           ----------------------------------------\___________               
    waiting_module #(
                    .END_COUNTER(END_WAITING_SEND_WLESS_DATA),
                    .START_COUNTER(START_COUNTER_SEND_WLESS_DATA),
                    .WAITING_TYPE(0),
                    .LEVEL_PULSE(1)
                    )waiting_send_wireless_data(
                    .clk(wireless_receiver_clk),
                    .start_counting(start_waiting_send_wireless_data),
                    .reach_limit(start_send_wireless_data_cond),
                    .rst_n(rst_n)
                    );
    
    assign AUX_controller_3 = (state_counter_wireless_receive == IDLE_STATE);
    assign start_waiting_send_wireless_data = (state_counter_wireless_receive == START_RECEIVE_STATE);
    always @(posedge wireless_receiver_clk, negedge rst_n) begin
        if(!rst_n) begin
            state_counter_wireless_receive <= IDLE_STATE;
        end
        else begin
            case(state_counter_wireless_receive) 
                IDLE_STATE: begin
                    if(!buffer_wireless_receiver_empty) begin
                        state_counter_wireless_receive <= START_RECEIVE_STATE;
                    end
                    else state_counter_wireless_receive <= IDLE_STATE;
                end
                START_RECEIVE_STATE: begin
                    if(start_send_wireless_data_cond) begin
                        state_counter_wireless_receive <= SEND_WIRELESS_DATA_STATE;
                    end
                    else state_counter_wireless_receive <= START_RECEIVE_STATE;
                end 
                SEND_WIRELESS_DATA_STATE: begin
                    if(buffer_wireless_receiver_empty & (!TX_flag_mcu)) begin
                        state_counter_wireless_receive <= SEND_ALL_STATE;
                    end
                    else state_counter_wireless_receive <= SEND_WIRELESS_DATA_STATE;
                end
                SEND_ALL_STATE: begin
                    if(TX_flag_mcu) begin
                        state_counter_wireless_receive <= IDLE_STATE;
                    end
                    else state_counter_wireless_receive <= SEND_ALL_STATE;
                end
            endcase 
        end
    end
    
    // One-hot encoding    
    assign state_module[MODULE_IDLE_STATE] = ~(wireless_trans_enable | wireless_receiver_enable | (mode_controller == MODE_3)); // IDLE state is always HIGH, when ohter bits is LOW
    assign state_module[MODULE_WTRANS_STATE] = wireless_trans_enable;
    assign state_module[MODULE_WRECEIVE_STATE] = wireless_receiver_enable;
    assign state_module[MODULE_PROGRAM_STATE] = (mode_controller == MODE_3);

    assign TX_use_mcu = (mode_controller == MODE_0) ? TX_use_mcu_mode0 : TX_use_mcu_mode3;
    assign data_to_uart_mcu = (mode_controller == MODE_0) ? data_to_uart_mcu_mode0 : data_to_uart_mcu_mode3;
//        parameter MODULE_IDLE_STATE = 3,    // (wireless_trans and wireless_recei is not woking 
//        parameter MODULE_WTRANS_STATE = 2,  // (wireless_trans is working )
//        parameter MODULE_WRECEIVE_STATE = 1,// (wireless_receiver is working)
//        parameter MODULE_PROGRAM_STATE = 0, // (programed state is working
        
        // Power checking (wireless_receiver is on)
//        assign state_module = 4'b0100;
        // Power checking (wireless_transmission is on)
//        assign state_module = 4'b0010;
        // Power checking (programmed state)
//        assign state_module = 4'b1000;

endmodule
