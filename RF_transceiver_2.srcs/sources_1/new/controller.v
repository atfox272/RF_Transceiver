
module controller
    #(
    parameter DATA_WIDTH                = 8,
    parameter BUFFER_WIRELESS_TRANS     = 64,
    parameter PACKET_ACTIVE             = 58,
    // Real-time counter
    parameter RESET_TIMING              = 20833333,    // 180ms
    parameter MODE_SWITCH_TIMING        = 753012,    // 6ms
    parameter _3_TRANSACTION_TIMING     = 625000,     // 5ms
    
    parameter HEAD_DETECT_1             = 8'hC0,    // Head (~volatile)
    parameter HEAD_DETECT_2             = 8'hC2,    // Head (volatile)
    parameter RET_CONFIG_DETECT         = 8'hC1,    // Return config
    parameter RET_VERSION_DETECT        = 8'hC3,    // Return version
    parameter RESET_DETECT              = 8'hC4,
    parameter MATCH_INSTRUCTION_AMOUNT  = 3,
    // Version
    parameter VERSION_PACKET_1          = 8'hC3,     // Format (default)
    parameter VERSION_PACKET_2          = 8'h32,     // Format (default)
    parameter VERSION_PACKET_3          = 8'h27,     // My config
    parameter VERSION_PACKET_4          = 8'h02,     // My config         
    parameter TIMING_COUNTER_WIDTH      = $clog2(RESET_TIMING)
    )
    (
    input clk,
    
    output AUX,
    input  M0,
    input  M1,
    
    output M0_sync,
    output M1_sync,
    // Uart mcu
    output [DATA_WIDTH - 1:0] data_to_uart_mcu,
    input  [DATA_WIDTH - 1:0] data_from_uart_mcu,
    
    output RX_use_mcu,
    input  RX_flag_mcu,
    input  RX_available_mcu,
    
    output TX_use_mcu,
    input  TX_flag_mcu,
    input  TX_complete_mcu,
    input  TX_available_mcu,
    
    // uart node 
    output [DATA_WIDTH - 1:0] data_to_uart_node,
    input  [DATA_WIDTH - 1:0] data_from_uart_node,
    
    output RX_use_node,
    input  RX_flag_node,
    
    output TX_use_node,
    input  TX_flag_node,
    input  TX_complete_node,
    
    input rst_n
    );
    localparam IDLE_STATE       = 0;
    // Mode-switching
    localparam RESET_STATE      = 1;
    localparam WORKING_STATE    = 2;
    // Mode 3 (sleep mode)
    localparam CONFIGURE_STATE  = 2;
    localparam DET_CONFIG_STATE = 3;
    localparam DET_VERSION_STATE= 4;
    localparam RET_CONFIG_STATE = 5;
    localparam RET_VERSION_STATE= 6;
    localparam FAKE_RESET_STATE = 7;
    localparam SELF_CHECK_STATE = 8;
    
    localparam READY_WTRAN_STATE = 1;
    localparam READY_WRECV_STATE = 2;
    
    // Normal mode
    localparam WIRELESS_TRANS_STATE = 3;
    localparam WIRELESS_RECV_STATE  = 4;
    
    localparam MODE_0       = 0;  // Normal mode
    localparam MODE_3       = 3;  // Sleep mode  
    localparam MODE_SWITCH  = 1;  // Sleep mode  
    localparam ERROR_MODE   = 2;
    
    localparam REAL_TIME_RESET_ENCODE           = 0;
    localparam REAL_TIME_MODE_SWITCH_ENCODE     = 1;
    localparam REAL_TIME_3_TRANSACTION_ENCODE   = 2;
    
    reg [1:0] cur_mode;
    reg [2:0] mode_0_state;
    reg [3:0] mode_3_state;
    reg [2:0] mode_switch_state;
    // Configuration register 
    reg [DATA_WIDTH - 1:0]  HEAD;
    reg [DATA_WIDTH - 1:0]  ADDH;
    reg [DATA_WIDTH - 1:0]  ADDL;
    reg [DATA_WIDTH - 1:0]  SPED;
    reg [DATA_WIDTH - 1:0]  CHAN;
    reg [DATA_WIDTH - 1:0]  OPTION;
    //
    reg AUX_reg;
    
    // UART MCU
    reg TX_use_mcu_reg;
    reg [DATA_WIDTH - 1:0]  data_to_uart_mcu_reg;
    // UART node
    reg TX_use_node_reg;
    reg RX_use_node_reg;
    reg [DATA_WIDTH - 1:0]  data_to_uart_node_reg;
    // Buffer
    wire [DATA_WIDTH - 1:0] data_from_buffer_mcu;
    reg wr_buffer_mcu;
    reg rd_buffer_mcu;
    wire buffer_mcu_empty;
    reg [2:0] instruction_match_counter;
    reg [2:0] data_counter;
    reg waiting_finish_transactions;
    // Real-time counter
    reg                                 real_time_enable;
    reg  [2:0]                          real_time_limit_mux;
    logic[TIMING_COUNTER_WIDTH - 1:0]   real_time_limit_value;
    wire                                real_time_flag;
    // Wireless-Transmit condition
    wire wireless_trans_cond;
    wire wireless_trans_cond_1;
    wire wireless_trans_cond_2;
    
    assign AUX = (mode_3_state == IDLE_STATE) & (mode_0_state == IDLE_STATE) & (mode_switch_state == RESET_STATE);
    assign {M1_sync, M0_sync} = cur_mode;
     
    assign TX_use_mcu = TX_use_mcu_reg;
    assign data_to_uart_mcu = data_to_uart_mcu_reg;
    assign TX_use_node = TX_use_node_reg;
    assign RX_use_node = RX_use_node_reg;
    assign data_to_uart_node = data_to_uart_node_reg;
     
    assign wireless_tran_cond = wireless_trans_cond_1 | wireless_trans_cond_2;
    assign wireless_trans_cond_2 = real_time_flag;
    always_comb begin
        case(real_time_limit_mux)
            REAL_TIME_RESET_ENCODE: begin
                real_time_limit_value = RESET_TIMING;
            end
            REAL_TIME_MODE_SWITCH_ENCODE: begin
                real_time_limit_value = MODE_SWITCH_TIMING;
            end
            REAL_TIME_3_TRANSACTION_ENCODE: begin
                real_time_limit_value = _3_TRANSACTION_TIMING;
            end
            default: begin
                real_time_limit_value = {TIMING_COUNTER_WIDTH{1'b1}};
            end
        endcase
    end
    
    (* dont_touch = "yes" *)     
    sync_fifo       #(
                    .FIFO_DEPTH(BUFFER_WIRELESS_TRANS)
                    ) buffer_mcu (
                    .clk(clk),
                    .data_in(data_from_uart_mcu),
                    .data_out(data_from_buffer_mcu),
                    .wr_req(RX_flag_mcu),
                    .rd_req(rd_buffer_mcu),
                    .empty(buffer_mcu_empty),
                    .counter_threshold(PACKET_ACTIVE),
                    .counter_threshold_flag(wireless_trans_cond_1),
                    .full(),
                    .almost_empty(),
                    .almost_full(),
//                    .reach_limit(),
//                    .enable(),
                    .rst_n(rst_n)
                    );
    
    (* dont_touch = "yes" *)                     
    real_time       #(
                    .MAX_COUNTER(RESET_TIMING)
                    ) waiting_module (
                    .clk(clk),
                    
                    .counter_enable(real_time_enable),
                    .limit_counter(real_time_limit_value),
                    .limit_flag(real_time_flag),
                    
                    .rst_n(rst_n)
                    );
                
    always @(posedge clk) begin
        if(!rst_n) begin
            // control register
            cur_mode <= MODE_SWITCH;
            AUX_reg <= 0;
            mode_switch_state <= IDLE_STATE;
            mode_0_state <= IDLE_STATE;
            mode_3_state <= IDLE_STATE;
            TX_use_mcu_reg <= 0;
            RX_use_node_reg <= 0;
            TX_use_node_reg <= 0;
            data_to_uart_mcu_reg <= 0;
            data_to_uart_node_reg <= 0;
            rd_buffer_mcu <= 0;
            waiting_finish_transactions <= 0;
            data_counter <= 0;
            // Instruction in sleep mode 
            instruction_match_counter <= 0;
            // Real time
            real_time_enable <= 0;
            real_time_limit_mux <= 0;
            HEAD <= 0;
            ADDH <= 0;
            ADDL <= 0;
            SPED <= 0;
            CHAN <= 0;
            OPTION <= 0;
        end
        else begin
            case(cur_mode)
                MODE_SWITCH: begin
                    case(mode_switch_state) 
                        RESET_STATE: begin
                            mode_switch_state <= IDLE_STATE;
                            real_time_enable <= 0;
                            AUX_reg <= 1;
                        end
                        IDLE_STATE: begin
                            mode_switch_state <= WORKING_STATE;
                        end
                        WORKING_STATE: begin
                            if(real_time_flag) begin
                                // Prevent from jumping to MODE_1 or MODE_2
                                cur_mode <= ({M1, M0} == MODE_3) ? MODE_3 : MODE_0;
                                mode_switch_state <= RESET_STATE;
                                real_time_enable <= 0;
                                AUX_reg <= 1;
                            end
                            else begin
                                real_time_enable <= 1;
                                real_time_limit_mux <= REAL_TIME_MODE_SWITCH_ENCODE; // 6ms
                                AUX_reg <= 0;
                            end
                        end
                    endcase
                    
                end
                MODE_3: begin
                    case(mode_3_state)
                        IDLE_STATE: begin
                            if({M1, M0} != MODE_3) begin
                                cur_mode <= MODE_SWITCH;
                                AUX_reg <= 0;
                            end
                            else if(!buffer_mcu_empty) begin
                                real_time_limit_mux <= REAL_TIME_3_TRANSACTION_ENCODE;
                                rd_buffer_mcu <= 1; // Confirm
                                case(data_from_buffer_mcu) 
                                    HEAD_DETECT_1: begin
                                        mode_3_state <= CONFIGURE_STATE;
                                        HEAD <= HEAD_DETECT_1;
                                    end  
                                    HEAD_DETECT_2: begin
                                        mode_3_state <= CONFIGURE_STATE;
                                        HEAD <= HEAD_DETECT_2;
                                    end     
                                    RET_CONFIG_DETECT: begin
                                        mode_3_state <= DET_CONFIG_STATE;
                                    end
                                    RET_VERSION_DETECT: begin
                                        mode_3_state <= DET_VERSION_STATE;
                                    end
                                    RESET_DETECT: begin
                                        mode_3_state <= FAKE_RESET_STATE;
                                    end
                                    default: begin
                                    end                   
                                endcase     
                            end
                        end
                        DET_CONFIG_STATE: begin
                            if(real_time_flag) begin
                                mode_3_state <= (instruction_match_counter >= MATCH_INSTRUCTION_AMOUNT - 1) ? RET_CONFIG_STATE : IDLE_STATE;
//                                real_time_enable <= 0;
                                rd_buffer_mcu <= 0;
                                instruction_match_counter <= 0;
                                // Prepare data 
                                data_to_uart_mcu_reg <= HEAD;
                                TX_use_mcu_reg <= 0;
                                data_counter <= 0;
                            end
                            else if(!buffer_mcu_empty) begin
//                                real_time_enable <= buffer_mcu_empty;
                                if(rd_buffer_mcu) begin // Get data
                                    rd_buffer_mcu <= 0;
                                end
                                else begin              // Sample signal
                                    instruction_match_counter <= (data_from_buffer_mcu == RET_CONFIG_DETECT) ? instruction_match_counter + 1 : 0;
                                    rd_buffer_mcu <= 1;
                                end
                            end
                            if(real_time_flag) begin
                                real_time_enable <= 0;
                            end
                            else begin
                                real_time_enable <= buffer_mcu_empty;
                            end
                        end
                        DET_VERSION_STATE: begin
                            if(real_time_flag) begin
                                mode_3_state <= (instruction_match_counter >= MATCH_INSTRUCTION_AMOUNT - 1) ? RET_VERSION_STATE : IDLE_STATE;
                                real_time_enable <= 0;
//                                rd_buffer_mcu <= 0;
                                instruction_match_counter <= 0;
                                // Prepare data 
                                data_to_uart_mcu_reg <= VERSION_PACKET_1;
                                TX_use_mcu_reg <= 0;
                                data_counter <= 0;
                            end
                            else if(!buffer_mcu_empty) begin
//                                real_time_enable <= buffer_mcu_empty;
                                if(rd_buffer_mcu) begin // Send data
                                    rd_buffer_mcu <= 0;
                                end
                                else begin              // Sample signal
                                    instruction_match_counter <= (data_from_buffer_mcu == RET_VERSION_DETECT) ? instruction_match_counter + 1 : 0;
                                    rd_buffer_mcu <= 1;
                                end
                            end
                            if(real_time_flag) begin
                                real_time_enable <= 0;
                            end
                            else begin
                                real_time_enable <= buffer_mcu_empty;
                            end
                        end
                        RET_VERSION_STATE: begin
                            if(waiting_finish_transactions) begin
                                if(TX_complete_mcu) begin
                                    waiting_finish_transactions <= 0;
                                    mode_3_state <= IDLE_STATE;
                                end
                                TX_use_mcu_reg <= 0; 
                            end
                            else if(TX_use_mcu_reg) begin
                                case (data_counter)     // load data
                                    1: begin
                                        data_to_uart_mcu_reg <= VERSION_PACKET_2;
                                    end
                                    2: begin
                                        data_to_uart_mcu_reg <= VERSION_PACKET_3;
                                    end
                                    3: begin
                                        data_to_uart_mcu_reg <= VERSION_PACKET_4;
                                    end
                                    4: begin
                                        data_to_uart_mcu_reg <= VERSION_PACKET_4;
                                    end
                                endcase
                                TX_use_mcu_reg <= 0;
                            end
                            else begin                  // send data
                                TX_use_mcu_reg <= 1;
                                if(data_counter == 3) begin
                                    data_counter <= 0;
                                    waiting_finish_transactions <= 1;
                                end
                                else begin
                                    data_counter <= data_counter + 1;
                                end
                            end
                        end
                        RET_CONFIG_STATE: begin
                            if(waiting_finish_transactions) begin
                                if(TX_complete_mcu) begin
                                    waiting_finish_transactions <= 0;
                                    mode_3_state <= IDLE_STATE;
                                end
                                TX_use_mcu_reg <= 0; 
                            end
                            else if(TX_use_mcu_reg) begin
                                case (data_counter)     // load data
                                    1: begin
                                        data_to_uart_mcu_reg <= ADDH;
                                    end
                                    2: begin
                                        data_to_uart_mcu_reg <= ADDL;
                                    end
                                    3: begin
                                        data_to_uart_mcu_reg <= SPED;
                                    end
                                    4: begin
                                        data_to_uart_mcu_reg <= CHAN;
                                    end
                                    5: begin
                                        data_to_uart_mcu_reg <= OPTION;
                                    end
                                endcase
                                TX_use_mcu_reg <= 0;
                            end
                            else begin                  // send data
                                TX_use_mcu_reg <= 1;
                                if(data_counter == 5) begin
                                    data_counter <= 0;
                                    waiting_finish_transactions <= 1;
                                end
                                else begin
                                    data_counter <= data_counter + 1;
                                end
                            end
                        end
                        CONFIGURE_STATE: begin
                            if(real_time_flag) begin
                                mode_3_state <= RET_CONFIG_STATE;
                                rd_buffer_mcu <= 0;
                                real_time_enable <= 0;
                                // Prepare data
                                data_to_uart_mcu_reg <= HEAD;
                                TX_use_mcu_reg <= 0;
                                data_counter <= 0;
                            end
                            else begin
                                real_time_enable <= buffer_mcu_empty;
                                if(!buffer_mcu_empty) begin
                                    if(rd_buffer_mcu) begin
                                        if(data_counter == 6) begin
                                            cur_mode <= ERROR_MODE;
                                        end 
                                        else begin
                                            data_counter <= data_counter + 1;
                                        end
                                        rd_buffer_mcu <= 0;
                                    end
                                    else begin
                                        rd_buffer_mcu <= 1;
                                        case(data_counter) 
                                            1: begin
                                                ADDH <= data_from_buffer_mcu;
                                            end
                                            2: begin
                                                ADDL <= data_from_buffer_mcu;
                                            end
                                            3: begin
                                                SPED <= data_from_buffer_mcu;
                                            end
                                            4: begin
                                                CHAN <= data_from_buffer_mcu;
                                            end
                                            5: begin
                                                OPTION <= data_from_buffer_mcu;
                                            end
                                        endcase
                                    end
                                end
                            end
                        end
                        FAKE_RESET_STATE: begin
                            if(real_time_flag) begin    // Don't implement self-checking
                                mode_3_state <= IDLE_STATE;
                                real_time_enable <= 0;
                            end
                            else begin
                                real_time_enable <= buffer_mcu_empty;
                            end
                        end
                    endcase
                end
                MODE_0: begin   // Normal mode
                    case(mode_0_state) 
                        IDLE_STATE: begin
                            if({M1, M0} != MODE_0) begin
                                cur_mode <= MODE_SWITCH;
                            end
                            else if(!buffer_mcu_empty) begin        // Receive data from MCU
                                mode_0_state <= READY_WTRAN_STATE;
                                real_time_limit_mux <= REAL_TIME_3_TRANSACTION_ENCODE;
                            end
                            else if(RX_flag_node) begin             // Receive wireless-data
                                mode_0_state <= READY_WRECV_STATE;
                                real_time_limit_mux <= REAL_TIME_3_TRANSACTION_ENCODE;
                            end 
                        end
                        READY_WTRAN_STATE: begin
                            if(wireless_tran_cond) begin
                                mode_0_state <= WIRELESS_TRANS_STATE;
                                real_time_enable <= 0;
                                data_to_uart_node_reg <= data_from_buffer_mcu;
                            end
                            else begin
                                real_time_enable <= RX_available_mcu;   // counting when RX_flag (RX_idle) == 1
                            end
                        end
                        READY_WRECV_STATE: begin
                            if(real_time_flag) begin
                                mode_0_state <= WIRELESS_RECV_STATE;
                                RX_use_node_reg <= 0;
                                data_to_uart_mcu_reg <= data_from_uart_node;
                                real_time_enable <= 0;
                            end
                            else begin
                                real_time_enable <= 1;
                            end
                        end
                        WIRELESS_TRANS_STATE: begin
                            if(buffer_mcu_empty) begin
                                if(TX_complete_node) begin      // Wireless-Trans all data
                                    mode_0_state <= IDLE_STATE;
                                    TX_use_node_reg <= 0;
                                    rd_buffer_mcu <= 0;
                                end
                            end
                            else begin
                                if(rd_buffer_mcu) begin   // Falling edge -> send (send detect) data 
                                    TX_use_node_reg <= 0;
                                    rd_buffer_mcu <= 0;
                                end
                                else begin                  // Rising edge -> sample data
                                    data_to_uart_node_reg <= data_from_buffer_mcu;
                                    TX_use_node_reg <= 1;
                                    rd_buffer_mcu <= 1;
                                end
                            end
                        end
                        WIRELESS_RECV_STATE: begin
                            if(waiting_finish_transactions) begin
                                if(TX_complete_mcu) begin
                                    mode_0_state <= IDLE_STATE;
                                    waiting_finish_transactions <= 0;
                                end
                            end 
                            else if(TX_available_mcu & RX_flag_node) begin // Move data from RX_node module to TX_mcu module 
                                real_time_enable <= 0;  // reset counter
                                if(TX_use_mcu_reg) begin
                                    data_to_uart_mcu_reg <= data_from_uart_node;
                                    RX_use_node_reg <= 0;
                                    TX_use_mcu_reg <= 0;
                                end 
                                else begin
                                    RX_use_node_reg <= 1;
                                    TX_use_mcu_reg <= 1;
                                end
                            end
                            else begin
                                if(real_time_flag) begin    // Stop receiving wireless-data
                                    waiting_finish_transactions <= 1;
                                    real_time_enable <= 0;
                                end
                                else begin
                                    real_time_enable <= 1;
                                end 
                            end
                        end
                    endcase 
                end
                default: begin
                
                end
            endcase
        end
    end
endmodule
