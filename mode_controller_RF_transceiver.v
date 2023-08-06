module mode_controller_RF_transceiver
    #(
        parameter DEFAULT_MODE = 2'd3,
        parameter END_MODE_SWITCH = 10000
    )
    (
    input   wire    internal_clk,
    input   wire    M0,
    input   wire    M1,
    input   wire    AUX_state_ctrl,
    output  reg     AUX_mode_ctrl,
    
    output  reg     M0_sync,
    output  reg     M1_sync,
    
    input   wire    rst_n
    );
    reg state_counter_mode_ctrl;
    wire end_mode_switch;
    wire [1:0] cur_mode = {M1_sync, M0_sync};
    wire [1:0] new_mode = {M1, M0};
    localparam IDLE_STATE = 0;
    localparam MODE_SWITCH_STATE = 1;
    waiting_module #(
                    .END_COUNTER(END_MODE_SWITCH),
                    .WAITING_TYPE(0),
                    .LEVEL_PULSE(0)
                    )waiting_RX_packet(
                    .clk(internal_clk),
                    .start_counting(AUX_mode_ctrl),
                    .reach_limit(end_mode_switch),
                    .rst_n(rst_n)
                    );
    always @(posedge internal_clk) begin
        if(!rst_n) begin
            M1_sync <= DEFAULT_MODE[1];
            M0_sync <= DEFAULT_MODE[0];
            state_counter_mode_ctrl <= IDLE_STATE;
            AUX_mode_ctrl <= 1;
        end
        else begin
            case(state_counter_mode_ctrl) 
                IDLE_STATE: begin
                    // Mode is switching and Module is free now
                    if(~(new_mode == cur_mode) & AUX_state_ctrl) begin
                        state_counter_mode_ctrl <= MODE_SWITCH_STATE;
                        // AUX controller
                        AUX_mode_ctrl <= 0;
                        M1_sync <= M1;
                        M0_sync <= M0;
                    end
                end
                MODE_SWITCH_STATE: begin
                    if(end_mode_switch) begin
                        state_counter_mode_ctrl <= IDLE_STATE;
                        AUX_mode_ctrl <= 1;
                    end
                end
            endcase
        end
    end
endmodule
