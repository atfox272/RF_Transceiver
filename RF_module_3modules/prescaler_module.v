// Use least counter to generate multi-prescaler
// User manual: 
//      * Single-prescaler mode: 
//          - HARDCONFIG_DIV (hard config divivder) must be divisible by 2     
//          - Clock out of this mode is clk_out_1
//      * Multi-prescale mode:
//          - HARDCONFIG_DIV (hard config divivder) must be power of 2 (greater than 32)     
//          - Clocks out of this mode consist of clk_1 & clk_2 & clk_3 & clk_4 

module prescaler_module
    #(
        parameter IDLE_CLK          = 0,    // HIGH/LOW
        parameter REVERSE_CLK       = 0,    // True/False
        parameter HARDCONFIG_DIV    = 32,   // Must be divisible by 2
        parameter MULTI_PRESCALER   = 0,    // MULTI_PRES / SINGLE_PRES
        
        
        parameter COUNTER_WIDTH= $clog2(HARDCONFIG_DIV / 2)
    )
    (
        input   wire            clk_in,
        input   wire            prescaler_enable,  
        input   wire            rst_n,
        
        output  wire            clk_1,  // prescaler / 1 (clock use in single-prescaler mode)
        output  wire            clk_2,  // prescaler / 2
        output  wire            clk_3,  // prescaler / 4
        output  wire            clk_4   // prescaler / 8
    );
    localparam MSB_COUNTER_CLK_2 = (COUNTER_WIDTH >= 2) ? 2 : 0;
    localparam MSB_COUNTER_CLK_3 = (COUNTER_WIDTH >= 3) ? 3 : 0;
    localparam MSB_COUNTER_CLK_4 = (COUNTER_WIDTH >= 4) ? 4 : 0;
    
    reg [COUNTER_WIDTH - 1:0] counter;
    
    reg clk_out_1;
    reg clk_out_2;
    reg clk_out_3;
    reg clk_out_4;
    
    always @(posedge clk_in, negedge rst_n) begin
        if(!rst_n) begin
            clk_out_1 <= IDLE_CLK;
            clk_out_2 <= IDLE_CLK;
            clk_out_3 <= IDLE_CLK;
            clk_out_4 <= IDLE_CLK;
            counter <= (HARDCONFIG_DIV / 2) - 1;
        end
        else begin
            if(prescaler_enable) begin
                clk_out_1 <= (counter == (HARDCONFIG_DIV / 2) - 1) ? ~clk_out_1 : clk_out_1;
                if(MULTI_PRESCALER) begin
                    clk_out_2 <= (&counter[COUNTER_WIDTH - MSB_COUNTER_CLK_2:0]) ? ~clk_out_2 : clk_out_2;
                    clk_out_3 <= (&counter[COUNTER_WIDTH - MSB_COUNTER_CLK_3:0]) ? ~clk_out_3 : clk_out_3;
                    clk_out_4 <= (&counter[COUNTER_WIDTH - MSB_COUNTER_CLK_4:0]) ? ~clk_out_4 : clk_out_4;
                end
                else begin
                    clk_out_2 <= clk_out_2;
                    clk_out_3 <= clk_out_3;
                    clk_out_4 <= clk_out_4;
                end
                // Counter management
                counter <= (counter == (HARDCONFIG_DIV / 2) - 1) ? 0 : counter + 1;
                
            end
        end
    end
    
    generate
        if(REVERSE_CLK) begin
            assign clk_1 = ~clk_out_1;       
            assign clk_2 = ~clk_out_2;       
            assign clk_3 = ~clk_out_3;       
            assign clk_4 = ~clk_out_4;       
        end
        else begin
            assign clk_1 = clk_out_1;       
            assign clk_2 = clk_out_2;       
            assign clk_3 = clk_out_3;       
            assign clk_4 = clk_out_4;
        end
    endgenerate
endmodule