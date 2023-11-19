module ram_module
    #(
        parameter DATA_WIDTH    = 8,
        parameter ADDR_DEPTH    = 512,  // <=> 512 bytes
        parameter ADDR_WIDTH    = $clog2(ADDR_DEPTH),
        
        // Deep configuartion
        parameter DEFAULT_ADDR  = 0,
        parameter DEFAULT_DATA  = 0
    )
    (
    input   wire                        clk,
    
    input   wire    [DATA_WIDTH - 1:0]  data_bus_wr,
    output  wire    [DATA_WIDTH - 1:0]  data_bus_rd,
    
    input   wire    [ADDR_WIDTH - 1:0]  addr_rd,
    input   wire    [ADDR_WIDTH - 1:0]  addr_wr,
    
    // State controller
    output  wire                        flag_rd,
    output  wire                        flag_wr,
    
    input   wire                        rd_ins,
    input   wire                        wr_ins,
    
    input   wire                        rst_n
    );
    // Power checking: single register
    // -> Total power is 2.566W
    //  + Signal: 0.194W
    //  + Logic: 0.270W
    //  + IO: 1.938W
    //  + Static: 0.162W
    
//    wire    [ADDR_WIDTH - 1:0]  addr_rd;
//    wire    [ADDR_WIDTH - 1:0]  addr_wr;
//    assign addr_rd = 27;
//    assign addr_wr = 02;
    
    // Set of registers
    reg [DATA_WIDTH - 1:0] registers [0: ADDR_DEPTH - 1];
    
    reg [ADDR_WIDTH - 1:0] addr_rd_buf;
    reg [ADDR_WIDTH - 1:0] addr_wr_buf;
    
    reg [1:0] state_counter_rd;
    reg [1:0] state_counter_wr;
    
    wire rd_ins_sync;
    wire wr_ins_sync;
    
    reg [DATA_WIDTH - 1:0] data_bus_wr_buf;
    
    reg wr_clk;         // Write clock 
    wire [ADDR_DEPTH - 1:0] reg_clk;
    
    // Common state 
    localparam INIT_STATE = 3;
    localparam IDLE_STATE = 0;
    localparam LOAD_ADDR_STATE = 1;
    // Read state
    localparam FLAG_RD_STATE = 2;
    // Write state
    localparam WRITE_STATE = 2;
    
// Read management
    edge_detector rd_sig_management
                            (    
                            .clk(clk),
                            .sig_in(rd_ins),
                            .out(rd_ins_sync),
                            .rst_n(rst_n)
                            );
    
    assign flag_rd = (state_counter_rd == IDLE_STATE);
    
    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            state_counter_rd <= INIT_STATE;
            addr_rd_buf <= DEFAULT_ADDR;
        end
        else begin
            case(state_counter_rd)
                INIT_STATE: begin
                    if(rd_ins_sync) begin
                        state_counter_rd <= LOAD_ADDR_STATE;
                        addr_rd_buf <= addr_rd;
                    end
                end
                IDLE_STATE: begin
                    if(rd_ins_sync) begin
                        state_counter_rd <= LOAD_ADDR_STATE;
                        addr_rd_buf <= addr_rd;
                    end
                end
                LOAD_ADDR_STATE: begin
                    state_counter_rd <= IDLE_STATE;
                end
//                FLAG_RD_STATE: begin
//                    state_counter_rd <= IDLE_STATE;
//                end
                default: state_counter_rd <= IDLE_STATE;
            endcase
        end
    end
    // Multiplexer <ADDR_DEPTH> to 1
    assign data_bus_rd = registers[addr_rd_buf];
    
// Write management 
    edge_detector wr_sig_management
                            (    
                            .clk(clk),
                            .sig_in(wr_ins),
                            .out(wr_ins_sync),
                            .rst_n(rst_n)
                            );
    
    assign flag_wr = (state_counter_wr == IDLE_STATE);               
                            
    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            state_counter_wr <= IDLE_STATE;
            addr_wr_buf <= DEFAULT_ADDR;
            wr_clk <= 0;
        end
        else begin
            case(state_counter_wr) 
                IDLE_STATE: begin
                    if(wr_ins_sync) begin
                        state_counter_wr <= LOAD_ADDR_STATE;
                        addr_wr_buf <= addr_wr;
                        data_bus_wr_buf <= data_bus_wr;
                    end
                    wr_clk <= 0;
                end
                LOAD_ADDR_STATE: begin
                    state_counter_wr <= IDLE_STATE;
                    wr_clk <= 1;
                end
//                WRITE_STATE: begin
//                    state_counter_wr <= IDLE_STATE;
//                    wr_clk <= 0;
//                end
                default: state_counter_wr <= IDLE_STATE;
            endcase 
        end
    end 
    
    genvar i;
    generate
        for(i = 0; i < ADDR_DEPTH; i = i + 1) begin : register_selector_block
            assign reg_clk[i] = (addr_wr_buf == i) ? wr_clk : 1'b0;
            always @(posedge reg_clk[i], negedge rst_n) begin
                if(!rst_n) registers[i] <= DEFAULT_DATA;
                else begin
                    registers[i] <= data_bus_wr_buf;
                end
            end
        end
    endgenerate
    
endmodule
