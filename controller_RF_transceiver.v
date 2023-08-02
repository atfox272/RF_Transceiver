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
        parameter INIT_BUFFER_SPED = {8{1'b0}},
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
        parameter MODE_3 = 3,
        // 512bytes FIFO buffer
        parameter FIFO512_DEPTH = 512,
        localparam COUNTER_FIFO512_WIDTH = $clog2(FIFO512_DEPTH + 1),
        parameter START_WIRELESS_TRANS_VALUE = 58
    )
    (
    input   wire internal_clk,
    input   wire M0_sync,
    input   wire M1_sync,
    output  wire AUX,
    // UART to MCU
    output                                      TX_use_mcu,
    input                                       RX_flag_mcu,
    input   wire    [DATA_WIDTH - 1:0]          data_from_uart_mcu,
    output  reg     [DATA_WIDTH - 1:0]          data_to_uart_mcu,  
    output  wire    [UART_CONFIG_WIDTH - 1:0]   uart_mcu_config_reg,
    // UART to NODE 
    output  wire                                TX_use_node,
    input   wire                                RX_flag_node,      
    input   wire    [DATA_WIDTH - 1:0]          data_from_uart_node,
    output  wire    [DATA_WIDTH - 1:0]          data_to_uart_node,
    
    
    input   wire rst_n
    );
    // Configuartion register 
    reg [TRANSACTION_WIDTH - 1:0] HEAD;
    reg [TRANSACTION_WIDTH - 1:0] ADDH;
    reg [TRANSACTION_WIDTH - 1:0] ADDL;
    reg [UART_CONFIG_WIDTH - 1:0] SPED; 
    reg [TRANSACTION_WIDTH - 1:0] CHAN;
    reg [TRANSACTION_WIDTH - 1:0] OPTION;
    wire mode3_en = (M0_sync == 1) & (M1_sync == 1);
    wire mode3_clk = (mode3_en) ? RX_flag_mcu : 1'b0;
    assign uart_mcu_config_reg = SPED;
    // Reply 
    // Config parameter 
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
    reg AUX_controller_3;
    assign AUX = AUX_controller_1 & AUX_controller_2 & AUX_controller_3;
    
    reg [3:0] state_counter_mode3;
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
   
    reg [1:0] return_case;          
    // Return Instruction encode
    localparam RETURN_CONFIG_CASE = 0;        // Return configuration
    localparam RETURN_VERSION_CASE = 1;       // Return version
    localparam RETURN_NOTHING_CASE = 2;       // Reset command case
    always @(posedge mode3_clk, negedge rst_n) begin
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
                            state_counter_mode3 <= IDLE_STATE;
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
                default: state_counter_mode3 <= IDLE_STATE;
            endcase 
            
        end
    end
    // Synchronous enable flag of return_config instruction
    reg return_start_syn;
    reg return_stop_syn;
    wire return_en_syn = return_start_syn ^ return_stop_syn;
    // Synchromous start & stop Enable flag
    always @(posedge internal_clk, negedge rst_n) begin
        if(!rst_n) begin
            return_start_syn <= 0;
        end
        else begin
            return_start_syn <= return_start_asyn;
        end
    end
    always @(negedge internal_clk, negedge rst_n) begin
        if(!rst_n) begin
            return_stop_syn <= 0;
        end
        else begin
            return_stop_syn <= return_stop_asyn;
        end
    end
    reg [3:0] state_counter_mode3_return;
    localparam RET_HEAD_STATE = 1;
    localparam RET_ADDH_STATE = 2;
    localparam RET_ADDL_STATE = 3;
    localparam RET_SPED_STATE = 4;
    localparam RET_CHAN_STATE = 5;
    localparam RET_OPTION_STATE = 6;
    localparam RET_VERSION_STATE_1 = 7;   
    localparam RET_VERSION_STATE_2 = 8;   
    localparam RET_VERSION_STATE_3 = 9;   
    localparam RET_VERSION_STATE_4 = 10;   
    wire return_clk = (return_en_syn) ? internal_clk : 1'b0;
    always @(posedge return_clk, negedge rst_n) begin
        if(!rst_n) begin
            state_counter_mode3_return <= IDLE_STATE;
            return_stop_asyn <= 0;
            // Data 
            data_to_uart_mcu <= {8{1'b0}};
        end
        else begin
            case(state_counter_mode3_return) 
                IDLE_STATE: begin
                    case(return_case) 
                        RETURN_CONFIG_CASE: begin
                            state_counter_mode3_return <= RET_HEAD_STATE; 
                            data_to_uart_mcu <= HEAD;
                        end
                        RETURN_VERSION_CASE: begin
                            state_counter_mode3_return <= RET_VERSION_STATE_1;
                            data_to_uart_mcu <= VERSION_PACKET_1;
                        end
                        default: state_counter_mode3_return <= IDLE_STATE;
                    endcase
                end
                RET_HEAD_STATE: begin
                    state_counter_mode3_return <= RET_ADDH_STATE;
                    data_to_uart_mcu <= ADDH;
                end
                RET_ADDH_STATE: begin
                    state_counter_mode3_return <= RET_ADDL_STATE;
                    data_to_uart_mcu <= ADDL;
                end
                RET_ADDL_STATE: begin
                    state_counter_mode3_return <= RET_SPED_STATE;
                    data_to_uart_mcu <= SPED;
                end
                RET_SPED_STATE: begin
                    state_counter_mode3_return <= RET_CHAN_STATE;
                    data_to_uart_mcu <= CHAN;
                end
                RET_CHAN_STATE: begin
                    state_counter_mode3_return <= IDLE_STATE;
                    data_to_uart_mcu <= OPTION;
                    // Stop return_clk
                    return_stop_asyn <= return_start_asyn;
                end
                RET_VERSION_STATE_1: begin
                    state_counter_mode3_return <= RET_VERSION_STATE_2;
                    data_to_uart_mcu <= VERSION_PACKET_2;
                end
                RET_VERSION_STATE_2: begin
                    state_counter_mode3_return <= RET_VERSION_STATE_3;
                    data_to_uart_mcu <= VERSION_PACKET_3;
                end
                RET_VERSION_STATE_3: begin
                    state_counter_mode3_return <= IDLE_STATE;
                    data_to_uart_mcu <= VERSION_PACKET_4;
                    // Stop return clock
                    return_stop_asyn <= return_start_asyn;
                end
                
                default: state_counter_mode3_return <= IDLE_STATE;
            endcase 
        end
    end
    wire mode0_en = (M0_sync == 0) & (M1_sync == 0);
    wire mode0_rx_clk = (mode0_en) ? RX_flag_mcu : 1'b0;
    // Notice:
    // Module is receiving (mode 0 or 1) -> AUX is LOW (state of module)
    wire [COUNTER_FIFO512_WIDTH - 1:0] counter_buffer_512byte;
    wire buffer_512bytes_full;
    wire buffer_512bytes_empty;
    fifo_module     #(
                    .DEPTH(FIFO512_DEPTH),
                    .WIDTH(DATA_WIDTH)
                    )buffer_512bytes(
                    .data_bus_in(data_from_uart_mcu),
                    .data_bus_out(data_to_uart_node),
                    .write_ins(mode0_rx_clk),
//                    .read_ins(/////////////////////////////////////////////////////////////////
                    .counter_elem(counter_buffer_512byte),
                    .full(buffer_512bytes_full),
                    .empty(buffer_512bytes_empty),
                    .rst_n(rst_n)
                    );
    // Load data into RFIC 
    reg [3:0] state_counter_mode0_trans;
    reg start_wireless_trans;
    wire mode0_clk = (mode0_en) ? internal_clk : 1'b0;
    wire start_wireless_trans_cond = (counter_buffer_512byte >= START_WIRELESS_TRANS_VALUE);
    assign AUX_controller_2 = (state_counter_mode0_trans == IDLE_STATE);    // Just free in IDLE_STATE
    localparam WIRELESS_TRANS_STATE = 1; 
    localparam START_READ_STATE = 2; 
    always @(posedge mode0_clk, negedge rst_n) begin
        if(!rst_n) begin
            state_counter_mode0_trans <= IDLE_STATE;
            start_wireless_trans <= 0;
        end
        else begin
            case(state_counter_mode0_trans)
                IDLE_STATE: begin
                    if(buffer_512bytes_empty) begin
                        state_counter_mode0_trans <= START_READ_STATE;
                    end
                    else state_counter_mode0_trans <= IDLE_STATE;
                end
                START_READ_STATE: begin
                    if(start_wireless_trans_cond) begin
                        state_counter_mode0_trans <= WIRELESS_TRANS_STATE;
                        // Add: Starting take-out data from BUFFER512
                    end
                    else state_counter_mode0_trans <= START_READ_STATE;
                end
                WIRELESS_TRANS_STATE: begin
                    if(buffer_512bytes_empty) begin
                        state_counter_mode0_trans <= IDLE_STATE;
                    end
                    else state_counter_mode0_trans <= WIRELESS_TRANS_STATE;
                end
            endcase             
        end
    end
    
    // Test mode3 
    assign TX_use_mcu = !return_clk;
//    assign TX_use_mcu = (mode_controller == MODE_3) !return_clk : ;
endmodule
