module com_uart_receiver_timer
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
    input clk,                  // 125Mhz (internal clk)
    input [BAUDRATE_SEL_WIDTH - 1:0] baudrate_sel,    // 2 option: 
    input rx_port,              // data_in
    input rst_n,
    output baudrate_clk,
    
    // From rx-controller
    input stop_cond
    // Debug area
//    ,output [6:0] debug_128,
//    output [5:0] debug_40
    );
    // Divider 
//    localparam divider = DEVICE_CLOCK_DIV4800; 
    // Baudrate clock (prescaler)
	 
    wire rst_n_com;
    wire read_en;
    reg read_en_start;
    reg read_en_stop;
    reg [FIRST_COUNTER_WIDTH - 1:0] counter_div41;    // counter 0 -> 40 (to 50Mhz / 50 (clk mod 50)
    reg baudrate_div41;            // Baudrate select
    wire baudrate_div41_clk;
    
    assign baudrate_div41_clk = (read_en) ? baudrate_div41 : clk;
    assign read_en = ~(read_en_start ^ read_en_stop);      
    assign rst_n_com = rst_n & (!stop_cond);
	 
    // Controller of "start_state" and "stop_state"  
    always @(posedge stop_cond, negedge rst_n) begin
        if(!rst_n) read_en_stop <= 1;
        else read_en_stop <= ~read_en_start;
    end 
    always @(negedge rx_port, negedge rst_n) begin
        if(!rst_n) read_en_start <= 0;
        else begin
            read_en_start <= read_en_stop;
        end
    end
    // Controller of Divider
    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            baudrate_div41 <= 0; 
            counter_div41 <= (DEVICE_CLOCK_DIV4800 - 1);    
        end
        else begin 
            if(!read_en) begin
                baudrate_div41 <= 0; 
                counter_div41 <= (DEVICE_CLOCK_DIV4800 - 1); 
            end
            else begin
                if(counter_div41 == (DEVICE_CLOCK_DIV4800 - 1)) begin 
                    baudrate_div41 <= ~baudrate_div41;
                    counter_div41 <= 0;
                end
                else counter_div41 <= counter_div41 + 1;
            end
        end
    end
    reg [6:0] counter_div41_div128;
    reg baudrate_div41_div128;      // Bd 9600
    reg baudrate_div41_div64;       // Bd 19200
    reg baudrate_div41_div32;       // Bd 38400
    reg baudrate_div41_div16;       // Bd 76800
    
    always @(posedge baudrate_div41_clk, negedge rst_n) begin
        // posedge <read_en> for inscresing immediately after read_en is rising
        // posedge <read_en> for converting to ready-state (counter_div41_div128 = 127)
        if(!rst_n) begin
            counter_div41_div128 <= 127;        // Ready for next clk will toggle, It will be toggle immediately, when read_en == 1
            baudrate_div41_div128 <= 0; 
            baudrate_div41_div64 <= 0; 
            baudrate_div41_div32 <= 0; 
            baudrate_div41_div16 <= 0;
        end
        else begin 
            if(!read_en) begin
                counter_div41_div128 <= 127;        // Ready for next clk will toggle, It will be toggle immediately, when read_en == 1
                baudrate_div41_div128 <= 0; 
                baudrate_div41_div64 <= 0; 
                baudrate_div41_div32 <= 0; 
                baudrate_div41_div16 <= 0;
            end
            else begin
                if(counter_div41_div128 == 127) counter_div41_div128 <= 0;
                else counter_div41_div128 <= counter_div41_div128 + 1; 
                
                baudrate_div41_div128 <= (&counter_div41_div128[6:0]) ? ~baudrate_div41_div128: baudrate_div41_div128;
                baudrate_div41_div64 <= (&counter_div41_div128[5:0]) ? ~baudrate_div41_div64 : baudrate_div41_div64;
                baudrate_div41_div32 <= (&counter_div41_div128[4:0]) ? ~baudrate_div41_div32 : baudrate_div41_div32;
                baudrate_div41_div16 <= (&counter_div41_div128[3:0]) ? ~baudrate_div41_div16 : baudrate_div41_div16;
            end
        end
    end
    assign baudrate_clk =   (baudrate_sel == BD9600_ENCODE) ? baudrate_div41_div128 : 
                            (baudrate_sel == BD19200_ENCODE) ? baudrate_div41_div64 : 
                            (baudrate_sel == BD38400_ENCODE) ? baudrate_div41_div32 : baudrate_div41_div16;

//    Debug area /////////////////////////////////
//    assign baudrate_clk = baudrate_div41_div128;    
//    assign debug_128 = counter_div41_div128;
//    assign debug_40 = counter_div41;
endmodule
