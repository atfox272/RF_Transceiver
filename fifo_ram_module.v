module fifo_ram_module
    #(
        parameter DEPTH             = 512,
        parameter WIDTH             = 8,
        parameter SLEEP_MODE        = 1,
        parameter LIMIT_COUNTER     = 58,
        // Do not configuration below parameter 
        parameter COUNTER_WIDTH     = $clog2(DEPTH + 1)
     )(
    // Clock for synchronous fifo
    input clk,
    // Data
    input   wire    [WIDTH - 1:0]   data_bus_in,
    output  wire    [WIDTH - 1:0]   data_bus_out,
    // Instruction
    input   wire                    write_ins,
    input   wire                    read_ins,
    // State 
    output  wire                    full,
    output  wire                    empty,
    // Option feature
    output  wire                    reach_limit,
    // Enable pin
    input   wire                    enable,
    // Reset 
    input   wire                    rst_n
    
    // debug
//    ,output [COUNTER_WIDTH - 1:0] front_addr_wire
//    ,output [COUNTER_WIDTH - 1:0] rear_addr_wire
    );
    
    wire clk_en;
    wire read_ins_en;
    wire write_ins_en;
    
    wire flag_rd;
    wire flag_wr;
    
    reg [COUNTER_WIDTH - 1:0] front_addr;
    reg [COUNTER_WIDTH - 1:0] rear_addr;
    
    generate 
        if(SLEEP_MODE) begin
            assign clk_en = (!enable) ? 1'b0 : clk;
            assign read_ins_en = (empty | !enable) ? 1'b0 : read_ins;
            assign write_ins_en = (full | !enable) ? 1'b0 : write_ins;
        end
        else begin
            assign clk_en = clk;
            assign read_ins_en = (empty) ? 1'b0 : read_ins;
            assign write_ins_en = (full) ? 1'b0 : write_ins;
        end
    endgenerate
    
    ram_module #(
                .DATA_WIDTH(WIDTH),
                .ADDR_DEPTH(DEPTH)
                )ram_core(
                .clk(clk_en),
                .data_bus_wr(data_bus_in),
                .data_bus_rd(data_bus_out),
                .rd_ins(read_ins_en),
                .wr_ins(write_ins_en),
                .addr_rd(front_addr),
                .addr_wr(rear_addr),
                .flag_rd(flag_rd),
                .flag_wr(flag_wr),
                .rst_n(rst_n)
                );
            
    assign empty = (front_addr == (rear_addr + 1));     
    assign full = (rear_addr - front_addr) == (DEPTH - 1);   
    
    generate
        if(LIMIT_COUNTER == DEPTH) begin
            assign reach_limit = full;
        end          
        else begin
            assign reach_limit = (rear_addr - front_addr) == (LIMIT_COUNTER - 1);
        end
    endgenerate
    
    // Address management        
    always @(posedge flag_rd, negedge rst_n) begin
        if(!rst_n) begin
            front_addr <= 1;
        end
        else begin
            front_addr <= front_addr + 1;
        end
    end
    always @(posedge flag_wr, negedge rst_n) begin
        if(!rst_n) begin
            rear_addr <= 0;
        end
        else begin
            rear_addr <= rear_addr + 1;
        end
    end
    
    // Debug
//    assign front_addr_wire = front_addr;
//    assign rear_addr_wire = rear_addr;
endmodule
