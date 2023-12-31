module mode_controller_RF_transceiver
    #(
        parameter DEFAULT_MODE      = 2'd3,
        parameter END_MODE_SWITCH   = 10000,
        parameter END_POWER_ON_CHECK= 750000,   // Asume: 500ms
        parameter AUX_POWER_ON      = 1'b0      // State of AUX in power-on state (In Real module, Its HIGH)
    )
    (
    input   wire    internal_clk,
    input   wire    M0,
    input   wire    M1,
    input   wire    AUX_state_ctrl,
    output  reg     AUX_mode_ctrl,
    output  reg     AUX_power_on_ctrl,
    input   wire    AUX_uart_ctrl,
    input   wire    UART_mcu_complete,
    
    output  reg     M0_sync,
    output  reg     M1_sync,
    
    input   wire    rst_n
    );
    reg [1:0] state_counter_mode_ctrl;
    wire stop_waiting_mode_switching_signal;
    wire stop_waiting_power_on_signal;
    wire [1:0] cur_mode = {M1_sync, M0_sync};
    wire [1:0] new_mode = {M1, M0};
    // FSM Encoder
    localparam IDLE_STATE = 0;
    localparam INIT_STATE = 2;
    localparam MODE_SWITCH_STATE = 1;
    // Mode Encoder
    localparam MODE_0 = 0;
    localparam MODE_1 = 1;
    localparam MODE_2 = 2;
    localparam MODE_3 = 3;
    
    waiting_module #(
                    .END_COUNTER(END_MODE_SWITCH),
                    .WAITING_TYPE(0),
                    .LEVEL_PULSE(0)
                    )waiting_mode_switching(
                    .clk(internal_clk),
                    .start_counting(AUX_mode_ctrl),
                    .reach_limit(stop_waiting_mode_switching_signal),
                    .rst_n(rst_n)
                    );
                        
                 
    waiting_module #(
                    .END_COUNTER(END_POWER_ON_CHECK),
                    .WAITING_TYPE(0),
                    .LEVEL_PULSE(0)
                    )waiting_power_on(
                    .clk(internal_clk),
                    .start_counting(AUX_power_on_ctrl),
                    .reach_limit(stop_waiting_power_on_signal),
                    .rst_n(rst_n)
                    );
    always @(posedge internal_clk, negedge rst_n) begin
        if(!rst_n) begin
            M1_sync <= DEFAULT_MODE[1];
            M0_sync <= DEFAULT_MODE[0];
            state_counter_mode_ctrl <= INIT_STATE;
            // Repair for self-checking when module is reset
            AUX_mode_ctrl <= 1'b1;
            AUX_power_on_ctrl <= AUX_POWER_ON;
        end
        else begin
            case(state_counter_mode_ctrl) 
                INIT_STATE: begin
                     // AUX controller
                     AUX_power_on_ctrl <= AUX_POWER_ON;
                     if(stop_waiting_power_on_signal) begin
                        state_counter_mode_ctrl <= IDLE_STATE;
                        AUX_power_on_ctrl <= 1;
                    end
                end
                IDLE_STATE: begin
                    // Mode is switching and Module is free now
                    if(AUX_state_ctrl & AUX_uart_ctrl & AUX_power_on_ctrl) begin
                        // Recommand: "e mode changes from stand-by mode to others, the module will reset its parameters, during which the AUX keeps low level and then outputs high level after reset completed"
                        if((cur_mode == MODE_3) & (new_mode != MODE_3)) begin
                            state_counter_mode_ctrl <= MODE_SWITCH_STATE;
                            // AUX controller
                            AUX_mode_ctrl <= 0;
                            M1_sync <= M1;
                            M0_sync <= M0;
                        end
//                        // Mode swithcing when
                        else if(~(new_mode == cur_mode)) begin
                            M1_sync <= M1;
                            M0_sync <= M0;    
                        end
//                        if(~(new_mode == cur_mode)) begin
//                            M1_sync <= M1;
//                            M0_sync <= M0;    
//                        end
                    end
                end
                MODE_SWITCH_STATE: begin        // Switching from Stand-by mode (Mode 3) to others mode
                    if(stop_waiting_mode_switching_signal) begin
                        state_counter_mode_ctrl <= IDLE_STATE;
                        AUX_mode_ctrl <= 1;
                    end
                end
            endcase
        end
    end
endmodule
