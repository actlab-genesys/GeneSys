`timescale 1ns / 1ps

module iterators #(
	parameter NS_ID_BITS 			=	3,
	parameter NS_INDEX_ID_BITS 		=	5,
	parameter OPCODE_BITS 			=	4,
	parameter FUNCTION_BITS 		=	4,
	
	parameter BASE_STRIDE_WIDTH     = 4*(NS_INDEX_ID_BITS + NS_ID_BITS)
	
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
	
	input                               in_loop,
	
	output  [BASE_STRIDE_WIDTH-1:0]     rd_addr0,
	output  [BASE_STRIDE_WIDTH-1:0]     rd_addr1,
	output  [BASE_STRIDE_WIDTH-1:0]     rd_addr2,
	output  [BASE_STRIDE_WIDTH-1:0]     rd_addr3,
	output  [BASE_STRIDE_WIDTH-1:0]     rd_addr4,
	
	output                              rd_rq0,
	output                              rd_rq1,
	output                              rd_rq2,
	output                              rd_rq3,
	output                              rd_rq4,
	
	output  [BASE_STRIDE_WIDTH-1:0]     wr_addr0,
	output  [BASE_STRIDE_WIDTH-1:0]     wr_addr1,
	output  [BASE_STRIDE_WIDTH-1:0]     wr_addr2,
	output  [BASE_STRIDE_WIDTH-1:0]     wr_addr3,
	output  [BASE_STRIDE_WIDTH-1:0]     wr_addr4,
	
	output                              wr_rq0,
	output                              wr_rq1,
	output                              wr_rq2,
	output                              wr_rq3,
	output                              wr_rq4,
	
	output   [15:0]                     wr_data3,
	
	output  [NS_ID_BITS-1:0]            src0_sel,
	output  [NS_ID_BITS-1:0]            src1_sel
	
    );
    
    /******************************** write to memory *********************************/
    wire iterator_inst, base_config,stride_config;
    reg [BASE_STRIDE_WIDTH/2-1 : 0] low_data;
    wire [BASE_STRIDE_WIDTH/2-1 : 0] immediate;
    wire [BASE_STRIDE_WIDTH-1 : 0] iterator_data_in;
    
    reg in_loop_d;
    
    assign immediate = { src1_ns_id , src1_ns_index_id , src2_ns_id , src2_ns_index_id};
    
    assign iterator_inst = (opcode == 4'b0110) && ~fn[3];
    
    assign base_config = ~fn[2] && iterator_inst;
    assign stride_config = fn[2] && iterator_inst;
    
    always @(posedge clk) begin
        if(iterator_inst)
            low_data <= immediate;
        in_loop_d <= in_loop;
    end
    //compiler restriction - _HIGH followed by _LOW always
    assign iterator_data_in[BASE_STRIDE_WIDTH/2-1 : 0] = immediate;
    assign iterator_data_in[BASE_STRIDE_WIDTH-1 : BASE_STRIDE_WIDTH/2] = (fn[1:0] == 2'b00) ? {BASE_STRIDE_WIDTH/2{1'b0}} : 
                                                                    (fn[1:0] == 2'b11) ? {BASE_STRIDE_WIDTH/2{immediate[BASE_STRIDE_WIDTH/2-1]}} 
                                                                     :  low_data;
    
    /******************************** read from memory *********************************/
    reg src1_valid,src2_valid,dest_valid;
    
    always @(*) begin
        case(opcode)
            4'b0000,4'b0010,4'b0011: begin
                src1_valid = 1'b1;
                src2_valid = 1'b1;
                dest_valid = 1'b1;
            end
            4'b0001: begin
                src1_valid = 1'b1;
                src2_valid = 1'b0;
                dest_valid = 1'b1;
            end
            4'b0100: begin
                src1_valid = 1'b0;
                src2_valid = 1'b1;
                dest_valid = 1'b0;
            end
            4'b0110: begin
                src1_valid = 1'b0;
                src2_valid = 1'b0;
                dest_valid = (fn == 4'b1000);
            end
            default: begin
                src1_valid = 1'b0;
                src2_valid = 1'b0;
                dest_valid = 1'b0;
            end           
        endcase
    end
    
    /********************************  memories *********************************/
    wire [BASE_STRIDE_WIDTH-1 : 0]  buf_read_address[0:4];
    wire [BASE_STRIDE_WIDTH-1 : 0]  buf_write_address[0:4];
    wire [4 : 0]  buf_read_rq;
    wire [4 : 0]  buf_write_rq;
    
    assign rd_addr0 = buf_read_address[0];
    assign rd_addr1 = buf_read_address[1];
    assign rd_addr2 = buf_read_address[2];
    assign rd_addr3 = buf_read_address[3];
    assign rd_addr4 = buf_read_address[4];
    
    assign rd_rq0 = buf_read_rq[0];
    assign rd_rq1 = buf_read_rq[1];
    assign rd_rq2 = buf_read_rq[2];
    assign rd_rq3 = buf_read_rq[3];
    assign rd_rq4 = buf_read_rq[4];
    
    assign wr_addr0 = buf_write_address[0];
    assign wr_addr1 = buf_write_address[1];
    assign wr_addr2 = buf_write_address[2];
    assign wr_addr3 = buf_write_address[3];
    assign wr_addr4 = buf_write_address[4];
    
    assign wr_rq0 = buf_write_rq[0];
    assign wr_rq1 = buf_write_rq[1];
    assign wr_rq2 = buf_write_rq[2];
    assign wr_rq3 = buf_write_rq[3];
    assign wr_rq4 = buf_write_rq[4];
    
    // immediate delay - 1 for iterator memory, 1 for buffer meaory read, 1 for computation
    pipeline #(
        .NUM_BITS	( 16	),
        .NUM_STAGES	( 3	),
        .EN_RESET   ( 0 )
    ) immediate_delay(
    
        .clk		(	clk		    ),
        .rst		(	reset		),
        
        .data_in	(	immediate	),
        .data_out	(	wr_data3    )
    
    );
    
    // src sel delay - 1 for iterator memory, 1 for buffer meaory read,
    pipeline #(
        .NUM_BITS	( 16	),
        .NUM_STAGES	( 2	),
        .EN_RESET   ( 0 )
    ) src0_sel_delay(
    
        .clk		(	clk		    ),
        .rst		(	reset		),
        
        .data_in	(	src1_ns_id	),
        .data_out	(	src0_sel    )
    
    );
    pipeline #(
        .NUM_BITS	( 16	),
        .NUM_STAGES	( 2	),
        .EN_RESET   ( 0 )
    ) src1_sel_delay(
    
        .clk		(	clk		    ),
        .rst		(	reset		),
        
        .data_in	(	src2_ns_id	),
        .data_out	(	src1_sel    )
    
    );
        
    generate
    for ( genvar gv = 0 ; gv < 5 ; gv = gv + 1) begin
        
        wire write_req_base;
        wire write_req_stride;
        reg read_req,read_req_d;
        reg buf_read_req,buf_read_req_d;
        reg buf_write_req,buf_write_req_d;
        reg [NS_INDEX_ID_BITS-1:0] read_addr,read_addr_d;
        wire [NS_INDEX_ID_BITS-1:0] write_addr_base,write_addr_stride;
        reg mem_bypass;
        wire [BASE_STRIDE_WIDTH-1 : 0] mem_data_in_base,mem_data_in_stride;
        wire [BASE_STRIDE_WIDTH-1 : 0] mem_data_out_base,mem_data_out_stride;
        wire [BASE_STRIDE_WIDTH-1 : 0] read_data_base,read_data_stride;
        wire [BASE_STRIDE_WIDTH-1 : 0] base_plus_stride;
        reg [BASE_STRIDE_WIDTH-1 : 0] base_plus_stride_d;
        wire [BASE_STRIDE_WIDTH-1 : 0] wr_addr;
        wire wr_req;
        assign base_plus_stride = read_data_base + read_data_stride;
        always @(posedge clk) begin
            base_plus_stride_d <= base_plus_stride;
            read_req_d <= read_req;
        end
        assign write_req_base = ((dest_ns_id == gv) && base_config) || (in_loop_d && read_req_d);
        assign write_req_stride = (dest_ns_id == gv) && stride_config;
        
        assign mem_data_in_base = in_loop_d ? base_plus_stride : iterator_data_in;
        assign mem_data_in_stride = iterator_data_in;
        
        assign write_addr_base = in_loop_d ? read_addr_d : dest_ns_index_id;
        assign write_addr_stride = dest_ns_index_id;
        
        always @(*) begin
            if(src1_ns_id == gv && src1_valid) begin
                read_req = 1'b1;
                read_addr = src1_ns_index_id;
                buf_read_req = 1'b1;
                buf_write_req = 1'b0;
            end
            else if(src2_ns_id == gv && src2_valid) begin
                read_req = 1'b1;
                read_addr = src2_ns_index_id;
                buf_read_req = 1'b1;
                buf_write_req = 1'b0;
            end
            else if(dest_ns_id == gv && dest_valid) begin
                read_req = 1'b1;
                read_addr = dest_ns_index_id;
                buf_read_req = 1'b0;
                buf_write_req = 1'b1;
            end
            else begin
                read_req = 1'b0;
                read_addr = 'b0;
                buf_read_req = 1'b0;
                buf_write_req = 1'b0;
            end
        end
        
        always @(posedge clk) begin
            read_addr_d <= read_addr;
            buf_read_req_d <= buf_read_req;
            buf_write_req_d <= buf_write_req;
            if( read_addr == read_addr_d && in_loop )
                mem_bypass <= 1'b1;
            else
                mem_bypass <= 1'b0;
        end
        
        assign read_data_base = mem_bypass ? base_plus_stride_d : mem_data_out_base;
        assign read_data_stride =  mem_data_out_stride;
        
        ram
        #(
          .DATA_WIDTH(BASE_STRIDE_WIDTH),
          .ADDR_WIDTH(NS_INDEX_ID_BITS )
        ) iterator_base_memory
        (
          .clk		   (    clk                 ),
          .reset       (	reset               ),
        
          .read_req    (    read_req            ),
          .read_addr   (	read_addr           ),
          .read_data   (	mem_data_out_base        ),
        
          .write_req   (	write_req_base              ),
          .write_addr  (	write_addr_base            ),
          .write_data  (	mem_data_in_base                 )
        );
        
        ram
        #(
          .DATA_WIDTH(BASE_STRIDE_WIDTH),
          .ADDR_WIDTH(NS_INDEX_ID_BITS )
        ) iterator_stride_memory
        (
          .clk		   (    clk                 ),
          .reset       (	reset               ),
        
          .read_req    (    read_req     ),
          .read_addr   (	read_addr     ),
          .read_data   (	mem_data_out_stride     ),
        
          .write_req   (	write_req_stride              ),
          .write_addr  (	write_addr_stride              ),
          .write_data  (	mem_data_in_stride                   )
        );
        
        pipeline #(
            .NUM_BITS	( BASE_STRIDE_WIDTH+1	),
            .NUM_STAGES	( 2	),
            .EN_RESET   ( 0 )
        ) wr_signals_delay(
        
            .clk		(	clk		   ),
            .rst		(	reset		),
            
            .data_in	(	{read_data_base,buf_write_req_d}	),
            .data_out	(	{wr_addr,wr_req} )
        
        );
        assign buf_read_address[gv] = read_data_base;
        assign buf_read_rq[gv] = buf_read_req_d;
        
        assign buf_write_address[gv] = wr_addr;
        assign buf_write_rq[gv] = wr_req;
    end
    endgenerate 
    
endmodule
