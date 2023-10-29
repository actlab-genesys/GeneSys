`timescale 1ns / 1ps

module iterator_memories #(
	parameter NS_ID_BITS 			=	3,
	parameter NS_INDEX_ID_BITS 		=	5,
	parameter OPCODE_BITS 			=	4,
	parameter FUNCTION_BITS 		=	4,
	
    parameter NUM_ELEM              =   4,
	parameter BASE_STRIDE_WIDTH     =   4*(NS_INDEX_ID_BITS + NS_ID_BITS),
	parameter IMMEDIATE_WIDTH       =   32,
	
	parameter NUM_MAX_LOOPS = 8,
    parameter LOG_NUM_MAX_LOOPS = 3,
    parameter BASE_WIDTH = BASE_STRIDE_WIDTH,
    parameter STRIDE_WIDTH = BASE_STRIDE_WIDTH,
    parameter ADDRESS_WIDTH = BASE_STRIDE_WIDTH,
    parameter NUM_ITER_WIDTH = 32
	
)(
    input                               clk,
    input                               reset,
    
    input [OPCODE_BITS-1:0]             opcode,  
    input [FUNCTION_BITS-1:0]           fn,

    input	[NS_ID_BITS-1:0]			dest_ns_id,
	input	[NS_INDEX_ID_BITS-1:0]		dest_ns_index_id,
	
	input	[NS_ID_BITS-1:0]			src1_ns_id,
	input	[NS_INDEX_ID_BITS-1:0]		src1_ns_index_id,
	
	input	[NS_ID_BITS-1:0]			src2_ns_id,
	input	[NS_INDEX_ID_BITS-1:0]		src2_ns_index_id,
    
    input [IMMEDIATE_WIDTH-1:0]         immediate,
    input [NS_ID_BITS-1:0]              loop_id,  
    //////////////////////////////////
    input [5:0]						iterator_read_req,
	input [5:0]						iterator_write_req_base,
	input [5:0]						iterator_write_req_stride,
	
	input [5:0]						mem_bypass,
	
    input                           in_nested_loop,
    input                           in_single_loop,
    input [(3*NS_ID_BITS + 3*NS_INDEX_ID_BITS)-1:0] current_iterations,
    
	//////////////////////////////////
	input [NS_INDEX_ID_BITS-1 :0] 		iterator_read_addr_in_0,
	
	input [NS_INDEX_ID_BITS-1 :0] 		iterator_write_addr_base_in_0,
	input [BASE_STRIDE_WIDTH-1 : 0]		iterator_data_in_base_in_0,
	
	input [NS_INDEX_ID_BITS-1 :0] 		iterator_write_addr_stride_in_0,
	input [BASE_STRIDE_WIDTH-1 : 0]		iterator_data_in_stride_in_0,
	
	input [BASE_STRIDE_WIDTH-1 : 0]		base_plus_stride_in_0,
	
	//////////////////////////////////
	input [NS_INDEX_ID_BITS-1 :0] 		iterator_read_addr_in_1,
	
	input [NS_INDEX_ID_BITS-1 :0] 		iterator_write_addr_base_in_1,
	input [BASE_STRIDE_WIDTH-1 : 0]		iterator_data_in_base_in_1,
	
	input [NS_INDEX_ID_BITS-1 :0] 		iterator_write_addr_stride_in_1,
	input [BASE_STRIDE_WIDTH-1 : 0]		iterator_data_in_stride_in_1,
	
	input [BASE_STRIDE_WIDTH-1 : 0]		base_plus_stride_in_1,

	//////////////////////////////////
	input [NS_INDEX_ID_BITS-1 :0] 		iterator_read_addr_in_2,
	
	input [NS_INDEX_ID_BITS-1 :0] 		iterator_write_addr_base_in_2,
	input [BASE_STRIDE_WIDTH-1 : 0]		iterator_data_in_base_in_2,
	
	input [NS_INDEX_ID_BITS-1 :0] 		iterator_write_addr_stride_in_2,
	input [BASE_STRIDE_WIDTH-1 : 0]		iterator_data_in_stride_in_2,
	
	input [BASE_STRIDE_WIDTH-1 : 0]		base_plus_stride_in_2,

	//////////////////////////////////
	input [NS_INDEX_ID_BITS-1 :0] 		iterator_read_addr_in_3,
	
	input [NS_INDEX_ID_BITS-1 :0] 		iterator_write_addr_base_in_3,
	input [BASE_STRIDE_WIDTH-1 : 0]		iterator_data_in_base_in_3,
	
	input [NS_INDEX_ID_BITS-1 :0] 		iterator_write_addr_stride_in_3,
	input [BASE_STRIDE_WIDTH-1 : 0]		iterator_data_in_stride_in_3,
	
	input [BASE_STRIDE_WIDTH-1 : 0]		base_plus_stride_in_3,

	//////////////////////////////////
	input [NS_INDEX_ID_BITS-1 :0] 		iterator_read_addr_in_4,
	
	input [NS_INDEX_ID_BITS-1 :0] 		iterator_write_addr_base_in_4,
	input [BASE_STRIDE_WIDTH-1 : 0]		iterator_data_in_base_in_4,
	
	input [NS_INDEX_ID_BITS-1 :0] 		iterator_write_addr_stride_in_4,
	input [BASE_STRIDE_WIDTH-1 : 0]		iterator_data_in_stride_in_4,
	
	input [BASE_STRIDE_WIDTH-1 : 0]		base_plus_stride_in_4,

    //////////////////////////////////
	input [NS_INDEX_ID_BITS-1 :0] 		iterator_read_addr_in_5,
	
	input [NS_INDEX_ID_BITS-1 :0] 		iterator_write_addr_base_in_5,
	input [BASE_STRIDE_WIDTH-1 : 0]		iterator_data_in_base_in_5,
	
	input [NS_INDEX_ID_BITS-1 :0] 		iterator_write_addr_stride_in_5,
	input [BASE_STRIDE_WIDTH-1 : 0]		iterator_data_in_stride_in_5,
	
	input [BASE_STRIDE_WIDTH-1 : 0]		base_plus_stride_in_5,
	
	//////////////////////////////////
	output [BASE_STRIDE_WIDTH-1 : 0]	    iterator_stride_0,
	output [BASE_STRIDE_WIDTH-1 : 0]	    buffer_address_0,
    
    output [BASE_STRIDE_WIDTH-1 : 0]	    iterator_stride_1,
	output [BASE_STRIDE_WIDTH-1 : 0]	    buffer_address_1,
	
	output [BASE_STRIDE_WIDTH-1 : 0]	    iterator_stride_2,
	output [BASE_STRIDE_WIDTH-1 : 0]	    buffer_address_2,
	
	output [BASE_STRIDE_WIDTH-1 : 0]	    iterator_stride_3,
	output [BASE_STRIDE_WIDTH-1 : 0]	    buffer_address_3,
	
	output [BASE_STRIDE_WIDTH-1 : 0]	    iterator_stride_4,
	output [BASE_STRIDE_WIDTH-1 : 0]	    buffer_address_4,
	
	output [BASE_STRIDE_WIDTH-1 : 0]	    iterator_stride_5,
	output [BASE_STRIDE_WIDTH-1 : 0]	    buffer_address_5,
    output                                  loop_done_out,
	output                                  loop_done_final
    );
    
    wire [NS_INDEX_ID_BITS-1 :0] iterator_read_addr[0:5];
    wire [NS_INDEX_ID_BITS-1 :0] iterator_write_addr_base[0:5];
    wire [BASE_STRIDE_WIDTH-1 : 0] iterator_data_in_base[0:5];
    wire [NS_INDEX_ID_BITS-1 :0] iterator_write_addr_stride[0:5];
    wire [BASE_STRIDE_WIDTH-1 : 0] iterator_data_in_stride[0:5];
    
    wire [BASE_STRIDE_WIDTH-1 : 0] base_plus_stride[0:5];   
    
    wire [BASE_STRIDE_WIDTH-1 : 0]	    buffer_address[0:5];      
    wire [BASE_STRIDE_WIDTH-1 : 0]	    iterator_stride[0:5]; 
    
    wire start_loop;
    wire [5:0] loop_done;
    reg start_loop_d;
    reg [7:0] loop_delay_counter; 
    reg loop_done_out_d;
    reg [NS_ID_BITS-1:0]        loop_id_d;
    reg [OPCODE_BITS-1:0]       opcode_d;      
    reg [FUNCTION_BITS-1:0]     fn_d;
    reg in_single_loop_d, in_single_loop_d2, in_single_loop_d3;
    
    always @(posedge clk) begin
        fn_d <= fn;
        in_single_loop_d <= in_single_loop;
        in_single_loop_d2 <= in_single_loop_d;
        in_single_loop_d3 <= in_single_loop_d2;
    end

    assign loop_done_out = |loop_done;
    always @(posedge clk) begin
        opcode_d <= opcode;
        loop_done_out_d <= loop_done_out;
    end

    always @(posedge clk) begin
        if (loop_done_out_d == 1'b0 && loop_done_out) begin
            loop_delay_counter <= 0;
        end else if (loop_done_out) begin
            loop_delay_counter <= loop_delay_counter + 1;
        end
    end

    assign loop_done_final = (loop_delay_counter == NUM_ELEM) ? 1 : 0; // DEBUG 

    assign start_loop = (opcode == 4'b0111) && (fn[2:0] == 3'b010); //&& loop_id[0];
    always @(posedge clk) begin
        start_loop_d <= start_loop;
    end 

    always @(posedge clk) begin
        if(reset)
            loop_id_d <= 'd0;
        else if( (opcode == 4'b0111) && (fn[2:0] == 3'b001))
            loop_id_d <= loop_id;
    end

    generate
    for (genvar gv = 0 ; gv < 6 ; gv = gv + 1) begin
        wire [BASE_STRIDE_WIDTH-1 : 0] mem_data_out_base, mem_data_out_stride;
        
        reg [BASE_WIDTH-1 : 0]                      base;
        reg [STRIDE_WIDTH-1 : 0]                    stride_nested [0:NUM_MAX_LOOPS-1];
        wire [STRIDE_WIDTH*NUM_MAX_LOOPS-1 : 0]     stride_in;
        reg [NUM_ITER_WIDTH-1 : 0]                  num_iter_nested [0:NUM_MAX_LOOPS-1];
        wire [NUM_ITER_WIDTH*NUM_MAX_LOOPS-1 : 0]   num_iter_in;
    
        wire [ADDRESS_WIDTH-1:0]                    address_out_single;
        wire [ADDRESS_WIDTH-1:0]                    address_out_nested;
        reg [ADDRESS_WIDTH-1:0]                     address_out;

        reg                                         address_valid;
        wire                                        address_valid_nested;
        wire                                        address_valid_single;

        always @(*) begin
            if (in_nested_loop) begin
                address_out = address_out_nested;
                address_valid = address_valid_nested;
            end else if ((in_single_loop || in_single_loop_d3)) begin
                address_out = address_out_single;
                address_valid = address_valid_single;
            end else begin
                address_out = 'b0;
                address_valid = 1'b0;
            end
        end

        ram #(
          .DATA_WIDTH(BASE_STRIDE_WIDTH),
          .ADDR_WIDTH(NS_INDEX_ID_BITS )
        ) iterator_base_memory (
          .clk		   (    clk                 ),
          .reset       (	reset               ),
        
          .read_req    (    iterator_read_req[gv]            ),
          .read_addr   (	iterator_read_addr[gv]           ),
          .read_data   (	mem_data_out_base        ),
        
          .write_req   (	iterator_write_req_base[gv]              ),
          .write_addr  (	iterator_write_addr_base[gv]            ),
          .write_data  (	iterator_data_in_base[gv]                 )
        );
        
        ram #(
          .DATA_WIDTH(BASE_STRIDE_WIDTH),
          .ADDR_WIDTH(NS_INDEX_ID_BITS )
        ) iterator_stride_memory (
          .clk		   (    clk                 ),
          .reset       (	reset               ),
        
          .read_req    (    iterator_read_req[gv]     ),
          .read_addr   (	iterator_read_addr[gv]     ),
          .read_data   (	mem_data_out_stride     ),
        
          .write_req   (	iterator_write_req_stride[gv]             ),
          .write_addr  (	iterator_write_addr_stride[gv]              ),
          .write_data  (	iterator_data_in_stride[gv]                   )
        );
        
        assign buffer_address[gv] = address_valid ? address_out : 
                                    (mem_bypass[gv] ? base_plus_stride[gv] : mem_data_out_base);
        assign iterator_stride[gv] =  mem_data_out_stride;
        
        always @(posedge clk) begin
            if(reset || loop_done[gv]) begin
                base <= 'b0;
            end else begin
                if(in_nested_loop && opcode == 4'b0111) begin
                    if(loop_id_d == 'd0)
                        base <= mem_data_out_base;
                end
            end
        end
        
        for (genvar l = 0 ; l< NUM_MAX_LOOPS; l=l+1) begin
            always @(posedge clk) begin
                if (reset || loop_done[gv]) begin
                    stride_nested[l] <= 'd0;
                    num_iter_nested[l] <= 'd0;
                end else begin
                    if (opcode == 4'b0111) begin
                        if(l == loop_id && fn == 4'b0001) begin
                            num_iter_nested[l] <= immediate[15:0];
                        end 
                    end

                    if (opcode_d == 4'b0111) begin
                        if(l == loop_id_d && fn_d == 4'b0000) begin
                            stride_nested[l] <= mem_data_out_stride;
                        end
                    end
                end
            end
        end

        for (genvar l = 0 ; l< NUM_MAX_LOOPS; l=l+1) begin
            assign stride_in[l*STRIDE_WIDTH+:STRIDE_WIDTH] = stride_nested[l];
            assign num_iter_in[l*NUM_ITER_WIDTH+:NUM_ITER_WIDTH] = num_iter_nested[l];
        end
        
        nested_loop #(
            .NUM_MAX_LOOPS          (   NUM_MAX_LOOPS     ),
            .LOG_NUM_MAX_LOOPS      (   LOG_NUM_MAX_LOOPS ),
            .BASE_WIDTH             (   BASE_WIDTH        ),
            .STRIDE_WIDTH           (   STRIDE_WIDTH      ),
            .ADDRESS_WIDTH          (   ADDRESS_WIDTH     ),
            .NUM_ITER_WIDTH         (   NUM_ITER_WIDTH    )
        ) nested_loop_inst (
            .clk                (   clk             ),      
            .reset              (   reset           ),
            
            .in_nested_loop     ( in_nested_loop ),

            .base               (   base            ),
            .stride             (   stride_in       ),
            .num_iter           (   num_iter_in     ),
            .start_loop         (   start_loop_d      ),
                       
            .address_out        (   address_out_nested     ),
            .address_valid      (   address_valid_nested   ),
            .loop_done_out      (   loop_done[gv]   )
        );

        single_loop #(
            .IMMEDIATE_WIDTH    (   IMMEDIATE_WIDTH     ),
	        .NS_ID_BITS 		(   NS_ID_BITS          ),
	        .NS_INDEX_ID_BITS 	(   NS_INDEX_ID_BITS    ),
            .OPCODE_BITS 		(   OPCODE_BITS         ),
	        .FUNCTION_BITS 		(   FUNCTION_BITS       ),
            .BASE_WIDTH         (   BASE_WIDTH          ),
            .STRIDE_WIDTH       (   STRIDE_WIDTH        ),
            .ADDRESS_WIDTH      (   ADDRESS_WIDTH       ),
            .NUM_ITER_WIDTH     (   NUM_ITER_WIDTH      )
        ) single_loop_inst (
            .clk                (   clk     ),      
            .reset              (   reset   ),

            .opcode             (   opcode      ),
            .fn                 (   fn          ),
            .immediate          (   immediate   ),

            .ns_in              (   gv      ),
            .dest_ns_id         (	dest_ns_id      	),
	        .dest_ns_index_id   (	dest_ns_index_id	),
	        .src1_ns_id         (	src1_ns_id      	),
	        .src1_ns_index_id   (	src1_ns_index_id	),
	        .src2_ns_id         (	src2_ns_id      	),
	        .src2_ns_index_id   (	src2_ns_index_id	),

            .in_single_loop     (   in_single_loop || in_single_loop_d3 ),

            .base               (   mem_data_out_base   ),
            .stride             (   mem_data_out_stride ),
            .start_loop         (   start_loop_d        ),
            .current_iterations (current_iterations     ),

            .address_out        (   address_out_single  ),
            .address_valid      (   address_valid_single)
        );
        
    end 
    endgenerate 
    
    
    assign	iterator_read_addr[0]			=	iterator_read_addr_in_0;

    assign	iterator_write_addr_base[0]		=	iterator_write_addr_base_in_0;
    assign	iterator_data_in_base[0]		=	iterator_data_in_base_in_0;
    
    assign	iterator_write_addr_stride[0]	=	iterator_write_addr_stride_in_0;
    assign	iterator_data_in_stride[0]		=	iterator_data_in_stride_in_0;
    
    assign	base_plus_stride[0]				=	base_plus_stride_in_0;
    
    //////////////////////////////////////////
    assign	iterator_read_addr[1]			=	iterator_read_addr_in_1;
    
    assign	iterator_write_addr_base[1]		=	iterator_write_addr_base_in_1;
    assign	iterator_data_in_base[1]		=	iterator_data_in_base_in_1;
    
    assign	iterator_write_addr_stride[1]	=	iterator_write_addr_stride_in_1;
    assign	iterator_data_in_stride[1]		=	iterator_data_in_stride_in_1;
    
    assign	base_plus_stride[1]				=	base_plus_stride_in_1;
    
    //////////////////////////////////////////
	assign	iterator_read_addr[2]			=	iterator_read_addr_in_2;

	assign	iterator_write_addr_base[2]		=	iterator_write_addr_base_in_2;
	assign	iterator_data_in_base[2]		=	iterator_data_in_base_in_2;

	assign	iterator_write_addr_stride[2]	=	iterator_write_addr_stride_in_2;
	assign	iterator_data_in_stride[2]		=	iterator_data_in_stride_in_2;

	assign	base_plus_stride[2]				=	base_plus_stride_in_2;
	
	//////////////////////////////////////////
	assign	iterator_read_addr[3]			=	iterator_read_addr_in_3;

	assign	iterator_write_addr_base[3]		=	iterator_write_addr_base_in_3;
	assign	iterator_data_in_base[3]		=	iterator_data_in_base_in_3;

	assign	iterator_write_addr_stride[3]	=	iterator_write_addr_stride_in_3;
	assign	iterator_data_in_stride[3]		=	iterator_data_in_stride_in_3;

	assign	base_plus_stride[3]				=	base_plus_stride_in_3;
	
	//////////////////////////////////////////
	assign	iterator_read_addr[4]			=	iterator_read_addr_in_4;

	assign	iterator_write_addr_base[4]		=	iterator_write_addr_base_in_4;
	assign	iterator_data_in_base[4]		=	iterator_data_in_base_in_4;

	assign	iterator_write_addr_stride[4]	=	iterator_write_addr_stride_in_4;
	assign	iterator_data_in_stride[4]		=	iterator_data_in_stride_in_4;

	assign	base_plus_stride[4]				=	base_plus_stride_in_4;
	
	//////////////////////////////////////////
	
	assign	iterator_read_addr[5]			=	iterator_read_addr_in_5;

	assign	iterator_write_addr_base[5]		=	iterator_write_addr_base_in_5;
	assign	iterator_data_in_base[5]		=	iterator_data_in_base_in_5;

	assign	iterator_write_addr_stride[5]	=	iterator_write_addr_stride_in_5;
	assign	iterator_data_in_stride[5]		=	iterator_data_in_stride_in_5;

	assign	base_plus_stride[5]				=	base_plus_stride_in_5;
	
	//////////////////////////////////////////
	assign  buffer_address_0                    =   buffer_address[0];
	assign  buffer_address_1                    =   buffer_address[1];
	assign  buffer_address_2                    =   buffer_address[2];
	assign  buffer_address_3                    =   buffer_address[3];
	assign  buffer_address_4                    =   buffer_address[4];
	assign  buffer_address_5                    =   buffer_address[5];
	
	assign  iterator_stride_0                  =   iterator_stride[0];
	assign  iterator_stride_1                  =   iterator_stride[1];
	assign  iterator_stride_2                  =   iterator_stride[2];
	assign  iterator_stride_3                  =   iterator_stride[3];
	assign  iterator_stride_4                  =   iterator_stride[4];
	assign  iterator_stride_5                  =   iterator_stride[5];
endmodule
