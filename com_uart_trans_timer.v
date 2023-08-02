module com_uart_trans_timer
    #(
        parameter DEVICE_CLOCK_DIV4800 = 21,  // Internal clock / 9600
        parameter BD4800_ENCODE = 0,
        parameter BD9600_ENCODE = 1,
        parameter BD19200_ENCODE = 2,
        parameter BD38400_ENCODE = 3,
        
        parameter BAUDRATE_SEL_WIDTH = $clog2(BD38400_ENCODE),  // Max encode value
        localparam FIRST_COUNTER_WIDTH = $clog2(DEVICE_CLOCK_DIV4800)
    )
    (
    input clk,
    input [BAUDRATE_SEL_WIDTH - 1:0] baudrate_sel,
    input rst_n,
    output baudrate_clk,
//    output [5:0] debug_40,
//    output [6:0] debug_128
    input FIFO_empty,
    input ctrl_idle_state,
    input ctrl_stop_state
    
    // Debug 
//    , output wire TX_disable_wire
//    , output wire debug
//    , output [FIRST_COUNTER_WIDTH - 1:0] debug_1
    );
    // Divider 
    localparam divider = DEVICE_CLOCK_DIV4800; 
    // Baudrate clock (prescaler)
//    localparam Bd9600 = 3'b000;
//    localparam Bd19200 = 3'b001;
//    localparam Bd38400 = 3'b010;
//    localparam Bd76800 = 3'b011;
    
    wire TX_disable = (FIFO_empty & ctrl_idle_state);
    
    reg [FIRST_COUNTER_WIDTH - 1:0] counter_div40;
    reg baudrate_div40;
    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            counter_div40 <= (divider - 1);
            baudrate_div40 <= 0; 
        end
        else begin
            if(TX_disable) begin
                counter_div40 <= (divider - 1);
                baudrate_div40 <= 0;
            end
            else begin
                if(counter_div40 == (divider - 1)) begin
                    counter_div40 <= 0;
                    baudrate_div40 <= ~baudrate_div40;
                end
                else counter_div40 <= counter_div40 + 1;
            end
        end
    end
    
    
    reg [6:0] counter_bd9600;
    reg baudrate_div40_div128;      // Bd 9600
    reg baudrate_div40_div64;       // Bd 19200
    reg baudrate_div40_div32;       // Bd 38400
    reg baudrate_div40_div16;       // Bd 76800
//    always @(posedge baudrate_div40, negedge rst_n, reg_en) begin
    always @(posedge baudrate_div40, negedge rst_n) begin
        if(!rst_n) begin
            counter_bd9600 <= 127;
            baudrate_div40_div128 <= 0;      
            baudrate_div40_div64 <= 0;       
            baudrate_div40_div32 <= 0;       
            baudrate_div40_div16 <= 0;
        end
        else begin
            if(TX_disable) begin
                counter_bd9600 <= 127;
                baudrate_div40_div128 <= 0;      
                baudrate_div40_div64 <= 0;       
                baudrate_div40_div32 <= 0;       
                baudrate_div40_div16 <= 0;
            end
            else begin
                case (baudrate_sel)
                    BD4800_ENCODE: begin
                    
                    end
                    BD9600_ENCODE: begin
                        if(&counter_bd9600[6:0]) begin
                            counter_bd9600 <= ((baudrate_div40_div128 == 0) & (ctrl_stop_state)) ? counter_bd9600 : 0;
                            baudrate_div40_div128 <= ~baudrate_div40_div128;
                        end
                        else counter_bd9600 <= counter_bd9600 + 1;
                    end
                    BD19200_ENCODE: begin
                        if(&counter_bd9600[5:0]) begin
                            counter_bd9600 <= ((baudrate_div40_div128 == 0) & (ctrl_stop_state)) ? counter_bd9600 : 0;
                            baudrate_div40_div64 <= ~baudrate_div40_div64;
                        end
                        else counter_bd9600 <= counter_bd9600 + 1;
                    end
                    BD38400_ENCODE: begin
                        if(counter_bd9600 == 31) begin
                            counter_bd9600 <= ((baudrate_div40_div128 == 0) & (ctrl_stop_state)) ? counter_bd9600 : 0;
                            baudrate_div40_div32 <= ~baudrate_div40_div32;
                        end
                        else counter_bd9600 <= counter_bd9600 + 1;
                    end
                    default: begin
                    
                    end
                endcase 
//                if(counter_bd9600 == 127 & baudrate_sel == BD9600_ENCODE) begin
//                    counter_bd9600 <= ((baudrate_div40_div128 == 0) & (ctrl_stop_state)) ? counter_bd9600 : 0;
//                    baudrate_div40_div128 <= ~baudrate_div40_div128;
//                end
//                else counter_bd9600 <= counter_bd9600 + 1;
//                if(counter_bd9600 == 63 & baudrate_sel == BD19200_ENCODE) begin
//                    counter_bd9600 <= ((baudrate_div40_div128 == 0) & (ctrl_stop_state)) ? counter_bd9600 : 0;
//                end
//                else 
//                baudrate_div40_div16 <= (&counter_bd9600[3:0]) ? ~baudrate_div40_div16 : baudrate_div40_div16;
            end
        end
    end 
    
    assign baudrate_clk =   (baudrate_sel == BD9600_ENCODE) ? baudrate_div40_div128 : 
                            (baudrate_sel == BD19200_ENCODE) ? baudrate_div40_div64 : 
                            (baudrate_sel == BD38400_ENCODE) ? baudrate_div40_div32 : baudrate_div40_div16;
                            
//  //Debug area ///////////////////////////////
//    assign debug_128 = counter_bd9600;
//    assign debug_40 = counter_div40;
//    assign debug = baudrate_div40;
//    assign debug_1 = counter_div40;
//    assign TX_disable_wire = TX_disable;
endmodule
