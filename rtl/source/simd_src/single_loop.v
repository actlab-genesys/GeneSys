module single_loop #(
    parameter IMMEDIATE_WIDTH       =   32,
    parameter NS_ID_BITS 			=	3,
	parameter NS_INDEX_ID_BITS 		=	5,
    parameter OPCODE_BITS 			=	4,
	parameter FUNCTION_BITS 		=	4,
    parameter NS_INDEX_SIZE = 2 << (NS_INDEX_ID_BITS+1),
    parameter BASE_WIDTH = 32,
    parameter STRIDE_WIDTH = BASE_WIDTH,
    parameter ADDRESS_WIDTH = BASE_WIDTH,
    parameter NUM_ITER_WIDTH = 32 
)(    
    input                                       clk,
    input                                       reset,

    input	[OPCODE_BITS-1:0]			        opcode,
	input	[FUNCTION_BITS-1:0]			        fn,
    input   [IMMEDIATE_WIDTH-1:0]               immediate,

    input   [2:0]                               ns_in,
    input	[NS_ID_BITS-1:0]			        dest_ns_id,
	input	[NS_INDEX_ID_BITS-1:0]		        dest_ns_index_id,
	
	input	[NS_ID_BITS-1:0]			        src1_ns_id,
	input	[NS_INDEX_ID_BITS-1:0]		        src1_ns_index_id,
	
	input	[NS_ID_BITS-1:0]			        src2_ns_id,
	input	[NS_INDEX_ID_BITS-1:0]		        src2_ns_index_id,

    input                                       in_single_loop,

    input [BASE_WIDTH-1 : 0]                    base,
    input [STRIDE_WIDTH-1 : 0]                  stride,
    input                                       start_loop,
    input [(3*NS_ID_BITS + 3*NS_INDEX_ID_BITS)-1:0] current_iterations,
    
    output [ADDRESS_WIDTH-1:0]                  address_out,
    output                                      address_valid
);

    // Address tracker for each ns, and each index in each ns
    reg [NUM_ITER_WIDTH-1:0]                num_instructions, first_cycle_counter;
    reg loop_started, first_cycle_d;
    wire first_cycle;
    reg ns_valid;              
    reg [NS_ID_BITS-1:0]			        ns_id;
	reg [NS_INDEX_ID_BITS-1:0]		        index_id;
    //reg [NUM_ITER_WIDTH-1:0] current_buffer_addr [0:(NS_INDEX_SIZE-1)];

    reg	[NS_ID_BITS-1:0]			        dest_ns_id_d, src1_ns_id_d, src2_ns_id_d;
	reg	[NS_INDEX_ID_BITS-1:0]		        dest_ns_index_id_d, src1_ns_index_id_d, src2_ns_index_id_d;
    reg [(3*NS_ID_BITS + 3*NS_INDEX_ID_BITS)-1:0] current_iterations_d, current_iterations_d2, current_iterations_d3;
    
    assign first_cycle = first_cycle_counter < num_instructions;

    always @(posedge clk) begin
        if (reset) begin
            ns_id <= ns_in; 
        end
    end

    always @(posedge clk) begin
        first_cycle_d <= first_cycle;
        dest_ns_id_d <= dest_ns_id;
        src1_ns_id_d <= src1_ns_id;
        src2_ns_id_d <= src2_ns_id;
        dest_ns_index_id_d <= dest_ns_index_id;
        src1_ns_index_id_d <= src1_ns_index_id;
        src2_ns_index_id_d <= src2_ns_index_id;

        current_iterations_d <= (current_iterations-1);
        current_iterations_d2 <= current_iterations_d;
        current_iterations_d3 <= current_iterations_d2;
    end

    always @(posedge clk) begin
        if (reset) begin
            num_instructions <= 'b0;
        end else if (opcode == 4'b0111 && fn == 4'b0010) begin
            num_instructions <= immediate;
        end 
    end
    
    always @(posedge clk) begin
        if (reset) begin
            loop_started <= 1'b0;
        end else if (start_loop) begin
            loop_started <= 1'b1;
        end 
    end

    always @(posedge clk) begin
        if (reset) begin
            first_cycle_counter <= 'b0;
        end else if (loop_started) begin
            first_cycle_counter <= first_cycle_counter + 1;
        end 
    end

    always @(posedge clk) begin
        if (reset)
            ns_id <= ns_in;
    end

    always @(*) begin
        if (ns_id == dest_ns_id_d) begin
            index_id = dest_ns_index_id_d;
            ns_valid = 1'b1;
        end else if (ns_id == src1_ns_id_d) begin 
            index_id = src1_ns_index_id_d;
            ns_valid = 1'b1;
        end else if (ns_id == src2_ns_id_d) begin 
            index_id = src2_ns_index_id_d;
            ns_valid = 1'b1;
        end else begin
            ns_valid = 1'b0;
        end
    end

    /*
    always @(posedge clk) begin
        if (first_cycle) begin
            current_buffer_addr[index_id] <= base + stride;
        end else if (in_single_loop && ns_valid) begin
            current_buffer_addr[index_id] <= current_buffer_addr[index_id] + stride;
        end
    end 
    */

    assign address_valid = ns_valid && loop_started;
    assign address_out = base + stride * current_iterations_d3; //first_cycle ? base : current_buffer_addr[index_id];

endmodule