`timescale 1ns / 1ps

module iterator_address_gen_new #(
	parameter NS_ID_BITS 			=	3,
	parameter NS_INDEX_ID_BITS 		=	5,
	parameter OPCODE_BITS 			=	4,
	parameter FUNCTION_BITS 		=	4,
	
	parameter BASE_STRIDE_WIDTH     = 4*(NS_INDEX_ID_BITS + NS_ID_BITS),
	parameter IMMEDIATE_WIDTH       =   32
	
)(
    input                               clk,
    input                               reset,
    
    input	[OPCODE_BITS-1:0]			opcode,
	input	[FUNCTION_BITS-1:0]			fn,
	
	input	[NS_ID_BITS-1:0]			dest_ns_id,
	input	[NS_INDEX_ID_BITS-1:0]		dest_ns_index_id,
	
	input	[NS_ID_BITS-1:0]			src1_ns_id,
	input	[NS_INDEX_ID_BITS-1:0]		src1_ns_index_id,
	
	input	[NS_ID_BITS-1:0]			src2_ns_id,
	input	[NS_INDEX_ID_BITS-1:0]		src2_ns_index_id,
	
    input                               in_single_loop,
	
	input [BASE_STRIDE_WIDTH-1 : 0]	    iterator_stride_0,
	input [BASE_STRIDE_WIDTH-1 : 0]	    iterator_base_0,
    
    input [BASE_STRIDE_WIDTH-1 : 0]	    iterator_stride_1,
	input [BASE_STRIDE_WIDTH-1 : 0]	    iterator_base_1,
	
	input [BASE_STRIDE_WIDTH-1 : 0]	    iterator_stride_2,
	input [BASE_STRIDE_WIDTH-1 : 0]	    iterator_base_2,
	
	input [BASE_STRIDE_WIDTH-1 : 0]	    iterator_stride_3,
	input [BASE_STRIDE_WIDTH-1 : 0]	    iterator_base_3,
	
	input [BASE_STRIDE_WIDTH-1 : 0]	    iterator_stride_4,
	input [BASE_STRIDE_WIDTH-1 : 0]	    iterator_base_4,
	
	input [BASE_STRIDE_WIDTH-1 : 0]	    iterator_stride_5,
	input [BASE_STRIDE_WIDTH-1 : 0]	    iterator_base_5,
	
    //////////////////////////////////
    output reg [5:0]					iterator_read_req_out,
	output reg [5:0]					iterator_write_req_base_out,
	output reg [5:0]					iterator_write_req_stride_out,
	
	output reg [5:0]					buffer_write_req,
	output reg [5:0]					buffer_read_req,
	//output reg [5:0]					mem_bypass,
	
    output reg [NS_INDEX_ID_BITS-1 :0] iterator_read_addr_out_src0,
    output reg [NS_INDEX_ID_BITS-1 :0] iterator_read_addr_out_src1,
    output reg [NS_INDEX_ID_BITS-1 :0] iterator_read_addr_out_dest,
	
    //////////////////////////////////
	output [NS_INDEX_ID_BITS-1 :0] 		iterator_write_addr_base_out_0,
	output [BASE_STRIDE_WIDTH-1 : 0]	iterator_data_in_base_out_0,
	
	output [NS_INDEX_ID_BITS-1 :0] 		iterator_write_addr_stride_out_0,
	output [BASE_STRIDE_WIDTH-1 : 0]	iterator_data_in_stride_out_0,
	
	output [BASE_STRIDE_WIDTH-1 : 0]	base_plus_stride_out_0,
	
	//////////////////////////////////
	output [NS_INDEX_ID_BITS-1 :0] 		iterator_write_addr_base_out_1,
	output [BASE_STRIDE_WIDTH-1 : 0]	iterator_data_in_base_out_1,
	
	output [NS_INDEX_ID_BITS-1 :0] 		iterator_write_addr_stride_out_1,
	output [BASE_STRIDE_WIDTH-1 : 0]	iterator_data_in_stride_out_1,
	
	output [BASE_STRIDE_WIDTH-1 : 0]	base_plus_stride_out_1,

	//////////////////////////////////
	output [NS_INDEX_ID_BITS-1 :0] 		iterator_write_addr_base_out_2,
	output [BASE_STRIDE_WIDTH-1 : 0]	iterator_data_in_base_out_2,
	
	output [NS_INDEX_ID_BITS-1 :0] 		iterator_write_addr_stride_out_2,
	output [BASE_STRIDE_WIDTH-1 : 0]	iterator_data_in_stride_out_2,
	
	output [BASE_STRIDE_WIDTH-1 : 0]	base_plus_stride_out_2,

	//////////////////////////////////
	output [NS_INDEX_ID_BITS-1 :0] 		iterator_write_addr_base_out_3,
	output [BASE_STRIDE_WIDTH-1 : 0]	iterator_data_in_base_out_3,
	
	output [NS_INDEX_ID_BITS-1 :0] 		iterator_write_addr_stride_out_3,
	output [BASE_STRIDE_WIDTH-1 : 0]	iterator_data_in_stride_out_3,
	
	output [BASE_STRIDE_WIDTH-1 : 0]	base_plus_stride_out_3,

	//////////////////////////////////
	output [NS_INDEX_ID_BITS-1 :0] 		iterator_write_addr_base_out_4,
	output [BASE_STRIDE_WIDTH-1 : 0]	iterator_data_in_base_out_4,
	
	output [NS_INDEX_ID_BITS-1 :0] 		iterator_write_addr_stride_out_4,
	output [BASE_STRIDE_WIDTH-1 : 0]	iterator_data_in_stride_out_4,
	
	output [BASE_STRIDE_WIDTH-1 : 0]	base_plus_stride_out_4,

    //////////////////////////////////
	output [NS_INDEX_ID_BITS-1 :0] 		iterator_write_addr_base_out_5,
	output [BASE_STRIDE_WIDTH-1 : 0]	iterator_data_in_base_out_5,
	
	output [NS_INDEX_ID_BITS-1 :0] 		iterator_write_addr_stride_out_5,
	output [BASE_STRIDE_WIDTH-1 : 0]	iterator_data_in_stride_out_5,
	
	output [BASE_STRIDE_WIDTH-1 : 0]	base_plus_stride_out_5,

    //////////////////////////////////
	output reg [IMMEDIATE_WIDTH-1:0]    immediate_out
    );
    
    /******************************** write to memory *********************************/
    wire iterator_inst, base_config,stride_config;
    reg [BASE_STRIDE_WIDTH/2-1 : 0] low_data;
    wire [15 : 0] immediate;
    reg [IMMEDIATE_WIDTH-1 : 0] immediate_reg;
    wire [BASE_STRIDE_WIDTH-1 : 0] iterator_data_in;
    
    reg in_loop_d,in_loop_d2,in_loop_d3;
    reg was_in_nested_loop;
    /*
    always @(posedge) begin
        
    end
    */
    
    assign immediate = { src1_ns_id , src1_ns_index_id , src2_ns_id , src2_ns_index_id};
    
    always @(*) begin
        case(fn)
            4'b1000: immediate_reg = {immediate_out[31:16],immediate};
            4'b1001: immediate_reg = {immediate,immediate_out[15:0]};
            default: immediate_reg = {{16{immediate[15]}},immediate[15:0]};
        endcase
    end
    always @(posedge clk)
        immediate_out <= immediate_reg;
    
    assign iterator_inst = (opcode == 4'b0110) && ~fn[3];
    
    assign base_config = ~fn[2] && iterator_inst;
    assign stride_config = fn[2] && iterator_inst;
    
    always @(posedge clk) begin
        if(iterator_inst)
            low_data <= immediate;
        in_loop_d <= in_single_loop;
        in_loop_d2 <= in_loop_d;
        in_loop_d3 <= in_loop_d2;
    end
    //compiler restriction - _HIGH -> _LOW always
    assign iterator_data_in[BASE_STRIDE_WIDTH/2-1 : 0] = immediate;
    assign iterator_data_in[BASE_STRIDE_WIDTH-1 : BASE_STRIDE_WIDTH/2] = (fn[1:0] == 2'b11) ? {BASE_STRIDE_WIDTH/2{1'b0}} : 
                                                                    (fn[1:0] == 2'b00) ? {BASE_STRIDE_WIDTH/2{immediate[BASE_STRIDE_WIDTH/2-1]}} 
                                                                     :  low_data;
    
    /******************************** read from memory *********************************/
    reg src1_valid,src2_valid,dest_valid;
    
    always @(*) begin
        case(opcode)
            4'b0000: begin
                src1_valid = (fn != 4'b1111);
                src2_valid = (fn != 4'b1111);
                dest_valid = (fn != 4'b1111);
            end
            4'b0010,4'b0011,4'b0111: begin
                src1_valid = 1'b1;
                src2_valid = 1'b1;
                dest_valid = 1'b1;
            end
            4'b0001: begin
                src1_valid = 1'b1;
                src2_valid = (fn == 4'b0001) || (fn == 4'b0010) || (fn == 4'b0011);
                dest_valid = 1'b1;
            end
            4'b0110: begin
                src1_valid = 1'b0;
                src2_valid = 1'b0;
                dest_valid = (fn == 4'b1001) || (fn == 4'b1010) || (fn == 4'b1000);
            end

            default: begin
                src1_valid = 1'b0;
                src2_valid = 1'b0;
                dest_valid = 1'b0;
            end           
        endcase
    end
    
    wire [BASE_STRIDE_WIDTH-1 : 0] iterator_base[0:5];
    wire [BASE_STRIDE_WIDTH-1 : 0] iterator_stride[0:5];
    
    //reg [NS_INDEX_ID_BITS-1 :0] iterator_read_addr_out[0:2];
    reg [NS_INDEX_ID_BITS-1 :0] iterator_write_addr_base_out[0:5];
    reg [BASE_STRIDE_WIDTH-1 : 0] iterator_data_in_base_out[0:5];
    reg [NS_INDEX_ID_BITS-1 :0] iterator_write_addr_stride_out[0:5];
    reg [BASE_STRIDE_WIDTH-1 : 0] iterator_data_in_stride_out[0:5];
    
    reg [BASE_STRIDE_WIDTH-1 : 0] base_plus_stride_out[0:5];

    generate
    for ( genvar gv = 0 ; gv <  6 ; gv = gv + 1) begin 
        wire write_req_base;
        wire write_req_stride;
        reg read_req,read_req_d,read_req_d2;
        reg buf_read_req,buf_read_req_d;
        reg buf_write_req,buf_write_req_d;
        reg [NS_INDEX_ID_BITS-1:0] read_addr,read_addr_d,read_addr_d2;
        wire [NS_INDEX_ID_BITS-1:0] write_addr_base,write_addr_stride;
        
        wire [BASE_STRIDE_WIDTH-1 : 0] mem_data_in_base,mem_data_in_stride;
        wire [BASE_STRIDE_WIDTH-1 : 0] base_plus_stride;
        
        wire [BASE_STRIDE_WIDTH-1 : 0] wr_addr;
        wire wr_req;
        assign base_plus_stride = iterator_base[gv] + iterator_stride[gv];
        always @(posedge clk) begin
            base_plus_stride_out[gv] <= ~in_loop_d3 ? iterator_base[gv] : base_plus_stride;
            read_req_d <= read_req;
            read_req_d2 <= read_req_d;
        end
        assign write_req_base = ((dest_ns_id == gv) && base_config); //|| (in_loop_d2 && read_req_d2);
        assign write_req_stride = (dest_ns_id == gv) && stride_config;
        
        assign mem_data_in_base = in_loop_d2 ? base_plus_stride : iterator_data_in;
        assign mem_data_in_stride = iterator_data_in;
        
        assign write_addr_base = in_loop_d2 ? read_addr_d2 : dest_ns_index_id;
        assign write_addr_stride = dest_ns_index_id;
        
        always @(*) begin
            if (src1_ns_id == gv && src1_valid) begin
                read_req = 1'b1;
                read_addr = src1_ns_index_id;
                buf_read_req = (opcode != 4'b0111);
                buf_write_req = dest_ns_id == gv && dest_valid && (opcode != 4'b0111);
            end else if (src2_ns_id == gv && src2_valid) begin
                read_req = 1'b1;
                read_addr = src2_ns_index_id;
                buf_read_req = (opcode != 4'b0111);
                buf_write_req = dest_ns_id == gv && dest_valid && (opcode != 4'b0111);
            end else if (dest_ns_id == gv && dest_valid) begin
                read_req = 1'b1;
                read_addr = dest_ns_index_id;
                buf_read_req = ((src1_ns_id == gv && src1_valid) || (src2_ns_id == gv && src2_valid)) && (opcode != 4'b0111);
                buf_write_req = (opcode != 4'b0111);
            end else begin
                read_req = 1'b0;
                read_addr = 'b0;
                buf_read_req = 1'b0;
                buf_write_req = 1'b0;
            end
        end
        
        always @(*) begin
            buffer_read_req[gv] = buf_read_req;
            buffer_write_req[gv] = buf_write_req;
        end

        
        always @(posedge clk) begin
            read_addr_d <= read_addr;
            read_addr_d2 <= read_addr_d;
        end
        
        always @(posedge clk) begin
            iterator_read_req_out[gv] <= read_req;
            //iterator_read_addr_out[gv] <= read_addr;
            iterator_write_req_base_out[gv] <= write_req_base;
            iterator_write_addr_base_out[gv] <= write_addr_base;
            iterator_data_in_base_out[gv] <= mem_data_in_base;
            iterator_write_req_stride_out[gv] <= write_req_stride;
            iterator_write_addr_stride_out[gv] <= write_addr_stride;
            iterator_data_in_stride_out[gv] <= mem_data_in_stride;
        end


    end
    endgenerate

    // read address base on operand
        always @(posedge clk) begin
            if (src1_ns_id >=0 && src1_ns_id < 6 && src1_valid) begin
                iterator_read_addr_out_src0 <= src1_ns_index_id;
            end 
            
            if (src2_ns_id >=0 && src2_ns_id < 6 && src2_valid) begin
                iterator_read_addr_out_src1 <= src2_ns_index_id;
            end 
            
            if (dest_ns_id >= 0 && dest_ns_id < 6  && dest_valid) begin
                iterator_read_addr_out_dest <= dest_ns_index_id;
            end 
        end

 
    
    //////////////////////////////////////////
    assign	iterator_write_addr_base_out_0		=	iterator_write_addr_base_out[0];
    assign	iterator_data_in_base_out_0			=	iterator_data_in_base_out[0];
    
    assign	iterator_write_addr_stride_out_0	=	iterator_write_addr_stride_out[0];
    assign	iterator_data_in_stride_out_0		=	iterator_data_in_stride_out[0];
    
    assign	base_plus_stride_out_0				=	base_plus_stride_out[0];
    
    //////////////////////////////////////////
    assign	iterator_write_addr_base_out_1		=	iterator_write_addr_base_out[1];
    assign	iterator_data_in_base_out_1			=	iterator_data_in_base_out[1];
    
    assign	iterator_write_addr_stride_out_1	=	iterator_write_addr_stride_out[1];
    assign	iterator_data_in_stride_out_1		=	iterator_data_in_stride_out[1];
    
    assign	base_plus_stride_out_1				=	base_plus_stride_out[1];
    
    //////////////////////////////////////////
	assign	iterator_write_addr_base_out_2		=	iterator_write_addr_base_out[2];
	assign	iterator_data_in_base_out_2			=	iterator_data_in_base_out[2];

	assign	iterator_write_addr_stride_out_2	=	iterator_write_addr_stride_out[2];
	assign	iterator_data_in_stride_out_2		=	iterator_data_in_stride_out[2];

	assign	base_plus_stride_out_2				=	base_plus_stride_out[2];
	
	//////////////////////////////////////////
	assign	iterator_write_addr_base_out_3		=	iterator_write_addr_base_out[3];
	assign	iterator_data_in_base_out_3			=	iterator_data_in_base_out[3];

	assign	iterator_write_addr_stride_out_3	=	iterator_write_addr_stride_out[3];
	assign	iterator_data_in_stride_out_3		=	iterator_data_in_stride_out[3];

	assign	base_plus_stride_out_3				=	base_plus_stride_out[3];
	
	//////////////////////////////////////////
	assign	iterator_write_addr_base_out_4		=	iterator_write_addr_base_out[4];
	assign	iterator_data_in_base_out_4			=	iterator_data_in_base_out[4];

	assign	iterator_write_addr_stride_out_4	=	iterator_write_addr_stride_out[4];
	assign	iterator_data_in_stride_out_4		=	iterator_data_in_stride_out[4];

	assign	base_plus_stride_out_4				=	base_plus_stride_out[4];
	
	//////////////////////////////////////////
	assign	iterator_write_addr_base_out_5		=	iterator_write_addr_base_out[5];
	assign	iterator_data_in_base_out_5			=	iterator_data_in_base_out[5];

	assign	iterator_write_addr_stride_out_5	=	iterator_write_addr_stride_out[5];
	assign	iterator_data_in_stride_out_5		=	iterator_data_in_stride_out[5];

	assign	base_plus_stride_out_5				=	base_plus_stride_out[5];
	
	//////////////////////////////////////////
	assign  iterator_base[0]                    =   iterator_base_0;
	assign  iterator_base[1]                    =   iterator_base_1;
	assign  iterator_base[2]                    =   iterator_base_2;
	assign  iterator_base[3]                    =   iterator_base_3;
	assign  iterator_base[4]                    =   iterator_base_4;
	assign  iterator_base[5]                    =   iterator_base_5;
	
	assign  iterator_stride[0]                    =   iterator_stride_0;
	assign  iterator_stride[1]                    =   iterator_stride_1;
	assign  iterator_stride[2]                    =   iterator_stride_2;
	assign  iterator_stride[3]                    =   iterator_stride_3;
	assign  iterator_stride[4]                    =   iterator_stride_4;
	assign  iterator_stride[5]                    =   iterator_stride_5;
endmodule
