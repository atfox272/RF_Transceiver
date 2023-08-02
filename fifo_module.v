// Requirement: DEPTH of FIFO must be a power of 2
//              Or you can use limit-fifo option (set parameter LIMIT_FIFO_FLAG = 1 and load limit value to limit_fifo),
//              Notice: Limit value must be less than Depth of FIFO
module fifo_module
    #(
        parameter DEPTH             = 32,
        parameter WIDTH             = 8,
        localparam COUNTER_WIDTH    = $clog2(DEPTH + 1),
        localparam DEPTH_ALIGN      = DEPTH + 1
     )(
    // Data
    input [WIDTH - 1:0]         data_bus_in,
    output [WIDTH - 1:0]        data_bus_out,
    // Instruction
    input               write_ins,
    input               read_ins,
    // State 
    output              full,
    output              empty,
    // Option feature
    output  [COUNTER_WIDTH - 1: 0] counter_elem,
    // Reset 
    input               rst_n
    );
    
    localparam init_buffer = 8'h00;
    localparam init_index_front = 0;
    localparam init_index_rear = 0;
    
    reg [COUNTER_WIDTH - 1:0] front_queue;
    reg [COUNTER_WIDTH - 1:0] rear_queue;
    reg [WIDTH - 1:0] queue [0: DEPTH_ALIGN - 1];
    
    //Data 
    assign data_bus_out = queue[front_queue];
    // State 
    assign full = (counter_elem == DEPTH);
    assign empty = (rear_queue == front_queue);
    assign counter_elem = rear_queue - front_queue;
    // Write instruction
    always @(posedge write_ins, negedge rst_n) begin
        if(!rst_n) begin
            rear_queue <= init_index_rear;
//            for(i = 0; i < capacity; i = i + 1) begin
//                queue[i] <= init_buffer;
//            end
//            queue[capacity - 1:0] <= 0;
        end
        else begin
            if(!full) begin
                queue[rear_queue] <= data_bus_in;
                rear_queue <= rear_queue + 1;
            end
        end
    end 
    // Read instruction
    always @(posedge read_ins, negedge rst_n) begin
        if(!rst_n) begin
            front_queue <= init_index_front;
        end
        else begin
            if(!empty) begin
                front_queue <= front_queue + 1;
            end
        end
    end
    
endmodule