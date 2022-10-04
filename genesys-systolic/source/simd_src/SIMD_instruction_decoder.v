`timescale 1ns / 1ps

module SIMD_instruction_decoder 
#(
	parameter NS_ID_BITS 			=	3,
	parameter NS_INDEX_ID_BITS 		=	5,
	parameter OPCODE_BITS 			=	4,
	parameter FUNCTION_BITS 		=	4,
	parameter INSTRUCTION_WIDTH 	= 	OPCODE_BITS + FUNCTION_BITS + 3*(NS_ID_BITS + NS_INDEX_ID_BITS),
	parameter GROUP_ID_W            =   4,
	parameter MAX_NUM_GROUPS        =   (1<<GROUP_ID_W),

	parameter IMEM_ADDR_WIDTH			= 10,
	parameter PC_DATA_WIDTH             = 64
	
)(
	input 								clk,
	input 								reset,
			
	input 								start,
	input 								in_fusion,
	input   [GROUP_ID_W-1:0]            group_id_s,
	
	input 	[INSTRUCTION_WIDTH-1:0]	    instruction_in,
	input 								instruction_in_v,
	
	input                               nested_loop_done,
	input								nested_loop_done_final,

	input   [IMEM_ADDR_WIDTH-1:0]       group_buf_rd_data,
	input                               group_buf_rd_v,

    output                              group_buf_rd_req,
    output  [GROUP_ID_W-1:0]            group_buf_rd_addr,
	
	// Ports for LD/ST
	input								mws_ld_base_vmem1_has_start,
    input								mws_ld_base_vmem2_has_start,
	input                               ld_mem_simd_done,
	input                               st_mem_simd_done,
	
	// Port for Multi Tile
	input								simd_tiles_done,
	
	// Ports for Data Shuffling
	input                               data_shuffle_done,

	output                              in_ld_st,
	output								in_shuffle,

	output                              ready,
	
	output  [MAX_NUM_GROUPS-1:0]        ld_config_done,
	output  [MAX_NUM_GROUPS-1:0]        st_config_done,
	output  [GROUP_ID_W    -1:0]        ld_st_group_id,
	
	output                              stall,	
	
	output 	[IMEM_ADDR_WIDTH-1:0]		imem_rd_address,
	output 								imem_rd_req,
	
	output	reg [OPCODE_BITS-1:0]		opcode,
	output	reg [FUNCTION_BITS-1:0]		fn,
	
	output	reg [NS_ID_BITS-1:0]		dest_ns_id,
	output	reg [NS_INDEX_ID_BITS-1:0]	dest_ns_index_id,
	
	output	reg [NS_ID_BITS-1:0]		src1_ns_id,
	output	reg [NS_INDEX_ID_BITS-1:0]	src1_ns_index_id,
	
	output	reg [NS_ID_BITS-1:0]		src2_ns_id,
	output	reg [NS_INDEX_ID_BITS-1:0]	src2_ns_index_id,
	
	output  reg  [7:0]                 	dest_integer_bits,
	output  reg  [7:0]                 	src1_integer_bits,
	output  reg  [7:0]                 	src2_integer_bits,
	
	output                              in_nested_loop,
	output                              in_single_loop,
	output  reg                         buf_done,
	output  reg                         done,
	output  reg  [GROUP_ID_W-1:0]       group_id,

	output  [(3*NS_ID_BITS + 3*NS_INDEX_ID_BITS)-1:0] current_iterations,
	output wire [PC_DATA_WIDTH - 1 : 0]                 pc_simd_tot_compute
);

    localparam integer  OP_LD_ST                    = 5;    
    localparam integer  OP_LOOP                     = 7;
	localparam integer  OP_PERMUTATION              = 8;
    localparam integer  OP_INST_GROUP               = 10;

    localparam integer  FN_PERMUTATION_START        = 3;
    localparam integer  FN_LD_START                 = 5;
    localparam integer  FN_ST_START                 = 13;
    
    localparam integer  INST_GROUP_SIMD             = 1;
    localparam integer  INST_GROUP_START            = 0;
    
	reg loop_ns_recorded;
	reg	[NS_ID_BITS-1:0]			dest_ns_id_loop;
	reg	[NS_INDEX_ID_BITS-1:0]		dest_ns_index_id_loop;
	reg	[NS_ID_BITS-1:0]			src1_ns_id_loop;
	reg	[NS_INDEX_ID_BITS-1:0]		src1_ns_index_id_loop;
	reg	[NS_ID_BITS-1:0]			src2_ns_id_loop;
	reg	[NS_INDEX_ID_BITS-1:0]		src2_ns_index_id_loop;
	reg	[OPCODE_BITS-1:0]			opcode_loop;
	reg [FUNCTION_BITS-1:0]			fn_loop;
 
	wire loop_inst,loop_start;
	reg  [(3*NS_ID_BITS + 3*NS_INDEX_ID_BITS)-1:0] loop_iterations;
	reg  [(3*NS_ID_BITS + 3*NS_INDEX_ID_BITS)-1:0] loop_instructions;
	wire [(3*NS_ID_BITS + 3*NS_INDEX_ID_BITS)-1:0] loop_instructions_w;
	
	reg [2:0] state_d;
	reg [2:0] state_q;
	
	reg [GROUP_ID_W-1:0] _group_id; 
	reg                  _group_buf_rd_req;

	
	reg [IMEM_ADDR_WIDTH-1:0] addr_d;
	reg  [IMEM_ADDR_WIDTH-1:0] addr_q,addr_q2,addr_loop_start,addr_loop_end;
	
	reg [(3*NS_ID_BITS + 3*NS_INDEX_ID_BITS)-1:0] num_iterations_d;
	reg  [(3*NS_ID_BITS + 3*NS_INDEX_ID_BITS)-1:0] num_iterations_q;
	assign current_iterations = num_iterations_q;

	reg imem_rd_v,imem_rd_v_q;
	wire inst_group_ex_end, inst_group_buf_end;
	
	reg [MAX_NUM_GROUPS-1:0] _ld_config_done_d;
	reg [MAX_NUM_GROUPS-1:0] _st_config_done_d;              
    reg [MAX_NUM_GROUPS-1:0] _ld_config_done_q;
    reg [MAX_NUM_GROUPS-1:0] _st_config_done_q; 
    
    reg [GROUP_ID_W-1:0] curr_group_id, prev_group_id;
    wire               inst_group_s_v;
    
    wire               inst_ld_start_v;
    wire               inst_st_start_v;
	wire 			   inst_noop_start_v;
    
    reg                _stall_d;
    reg                _stall_q;

	reg				   in_fusion_reg;
	always @(posedge clk) begin
		if (reset || done) begin // DEBUG for FUSED LAYER
			in_fusion_reg <= 1'b0;
		end else begin
			in_fusion_reg <= in_fusion;
		end
	end
	
	localparam integer  IDLE                         = 0;
	localparam integer  GET_GROUP_START_ADDR         = 1;
	localparam integer  INST_READ                    = 2;
	localparam integer  IN_LOOP                   	 = 3;
	localparam integer  IN_NESTED_LOOP             	 = 4;
	localparam integer  LD                           = 5;
	localparam integer  ST                           = 6;
	localparam integer  PERMUTATION                  = 7;

	/**************** Instructions fields extarction ***************************/
	always @(*) begin
		if (loop_ns_recorded) begin
			opcode 				= opcode_loop;
			fn 					= fn_loop;
			dest_ns_id 			= dest_ns_id_loop;
			dest_ns_index_id 	= dest_ns_index_id_loop;
			src1_ns_id 			= src1_ns_id_loop;
			src1_ns_index_id 	= src1_ns_index_id_loop;
			src2_ns_id 			= src2_ns_id_loop;
			src2_ns_index_id 	= src2_ns_index_id_loop;
		end else begin
			fn 					= instruction_in[3*NS_ID_BITS + 3*NS_INDEX_ID_BITS + FUNCTION_BITS-1:3*NS_ID_BITS + 3*NS_INDEX_ID_BITS];
			opcode				= instruction_in[3*NS_ID_BITS + 3*NS_INDEX_ID_BITS + FUNCTION_BITS + OPCODE_BITS-1:3*NS_ID_BITS + 3*NS_INDEX_ID_BITS + FUNCTION_BITS];
			src2_ns_index_id 	= instruction_in[NS_INDEX_ID_BITS-1:0];
			src2_ns_id 			= instruction_in[NS_ID_BITS + NS_INDEX_ID_BITS-1:NS_INDEX_ID_BITS];
			src1_ns_index_id 	= instruction_in[NS_ID_BITS + 2*NS_INDEX_ID_BITS-1:NS_ID_BITS + NS_INDEX_ID_BITS];
			src1_ns_id 			= instruction_in[2*NS_ID_BITS + 2*NS_INDEX_ID_BITS-1:NS_ID_BITS + 2*NS_INDEX_ID_BITS];
			dest_ns_index_id 	= instruction_in[2*NS_ID_BITS + 3*NS_INDEX_ID_BITS-1:2*NS_ID_BITS + 2*NS_INDEX_ID_BITS];
			dest_ns_id 			= instruction_in[3*NS_ID_BITS + 3*NS_INDEX_ID_BITS-1:2*NS_ID_BITS + 3*NS_INDEX_ID_BITS];
		end
	end
	
	// ns output need to continue when in loop and no instruction	
	always @(posedge clk) begin
		if ((state_d == IN_NESTED_LOOP) && opcode != 3'b0111) begin
			opcode_loop <= opcode;
			fn_loop <= fn;
			loop_ns_recorded <= 1'b1;
			dest_ns_id_loop <= dest_ns_id;
			dest_ns_index_id_loop <= dest_ns_index_id;
			src1_ns_id_loop <= src1_ns_id;
			src1_ns_index_id_loop <= src1_ns_index_id;
			src2_ns_id_loop <= src2_ns_id;
			src2_ns_index_id_loop <= src2_ns_index_id;
		end else begin
			loop_ns_recorded <= 1'b0;
			opcode_loop <= 'b0;
			fn_loop <= 'b0;
			dest_ns_id_loop <= 'b0;
			dest_ns_index_id_loop <= 'b0;
			src1_ns_id_loop <= 'b0;
			src1_ns_index_id_loop <= 'b0;
			src2_ns_id_loop <= 'b0;
			src2_ns_index_id_loop <= 'b0;
		end
    end

	/**************** loop control signals ***************************/
	assign loop_inst = (opcode == OP_LOOP);
	assign loop_start = loop_inst && (fn[1] == 1'b1);
	assign nested_loop = loop_inst && (fn == 4'b0010) && dest_ns_id[0];
	assign in_nested_loop = state_d == IN_NESTED_LOOP;
	assign in_single_loop = state_d == IN_LOOP;
	assign loop_instructions_w = instruction_in[(3*NS_ID_BITS + 3*NS_INDEX_ID_BITS)-1:0];
	assign inst_group_buf_end = (opcode == 4'b1010) && (fn[3:1] == 3'b111) ; // Sync Instruction
    assign inst_group_ex_end = (opcode == 4'b1010) && (fn[3:1] == 3'b110) ; // DEBUG Sync Instruction
    
    always @(posedge clk) begin
        if( inst_group_buf_end ) begin
            group_id <= src1_ns_id;
        end
    end

    always @(posedge clk) begin
		buf_done <= inst_group_buf_end;
	    done <= inst_group_ex_end; 
	end 

    always @(posedge clk) begin
		if(opcode == 4'b0100) begin
            dest_integer_bits <= instruction_in[23:16];
			src1_integer_bits <= instruction_in[15:8];
			src2_integer_bits <= instruction_in[7:0];
        end
    end
    
    // Set loop iteration for single loop
	always @(posedge clk) begin
		if(reset)
			loop_iterations <= 'b0;
		else if(loop_inst && fn == 4'b0001) begin
			loop_iterations[(3*NS_ID_BITS + 3*NS_INDEX_ID_BITS)/2-1:0] <= instruction_in[(3*NS_ID_BITS + 3*NS_INDEX_ID_BITS)/2-1:0];
			loop_iterations[(3*NS_ID_BITS + 3*NS_INDEX_ID_BITS)-1:(3*NS_ID_BITS + 3*NS_INDEX_ID_BITS)/2] <= (fn[1] == 1'b0) ? 'b0 : instruction_in[(3*NS_ID_BITS + 3*NS_INDEX_ID_BITS)-1:(3*NS_ID_BITS + 3*NS_INDEX_ID_BITS)/2];
		end
	end
			
	always @(posedge clk) begin
		if (loop_start) begin
			addr_loop_start <= addr_q;
			addr_loop_end <= addr_q+loop_instructions_w-1; // addr_q+loop_instructions_w
		end
	end
		
    always @(posedge clk) begin
       if (reset) begin
           _group_buf_rd_req <= 0;
           _group_id = 0;
       end
       else begin
           _group_buf_rd_req <= start;
           _group_id <= group_id_s;
       end 
    end

    assign group_buf_rd_req = _group_buf_rd_req;
    assign group_buf_rd_addr = _group_id;
 
    
    // Logic to store the current group_id
    assign inst_group_s_v = (opcode == OP_INST_GROUP) && (fn[3] == INST_GROUP_SIMD) && (fn[2] == INST_GROUP_START);
    always @(posedge clk) begin
        if (reset)
            curr_group_id <= 0;
        else if (inst_group_s_v)
            curr_group_id <= {fn[1:0],dest_ns_id[2:1]};
			prev_group_id <= curr_group_id;
    end
    
    // Sending the current group_id to the LD_ST SIMD interface
    assign ld_st_group_id = curr_group_id;
    
	// Make sure both one ld and two ld has only one config iteration
	reg ld_two_operand, ld_config_start_delay;
	wire ld_config_iteration_done;
	always @(posedge clk) begin
		if (reset || simd_tiles_done) begin
			ld_two_operand <= 0;
		end else if ((opcode == 4'b0000 || opcode == 4'b0001 || opcode == 4'b0010 || opcode == 4'b0011 || opcode == 4'b0100 || opcode == 4'b1000) && (!ld_two_operand)) begin
			ld_two_operand <= 1'b1;
		end
	end

	always @(posedge clk) begin
		if (reset || simd_tiles_done) begin
			ld_config_start_delay <= 1'b0;
		end else if (mws_ld_base_vmem1_has_start || mws_ld_base_vmem2_has_start) begin
			ld_config_start_delay <= 1'b1;
		end
	end

	assign ld_config_iteration_done = ld_config_start_delay ? (ld_two_operand ? mws_ld_base_vmem1_has_start && mws_ld_base_vmem2_has_start : mws_ld_base_vmem1_has_start || mws_ld_base_vmem2_has_start) : 1'b0; // DEBUG

    // Logic for done configuration of the LD/ST
    genvar i;
    generate
        for (i=0; i<MAX_NUM_GROUPS; i=i+1) begin
			always @(*) begin
				if (_ld_config_done_q[i] == 0 && ld_config_iteration_done) // DBEUG
					_ld_config_done_d[i] = 1'b1;
				else
					_ld_config_done_d[i] = _ld_config_done_q[i];
			end
           
           	always @(posedge clk) begin
        		if (reset || simd_tiles_done)
					_ld_config_done_q[i] <= 1'b0;
				else
					_ld_config_done_q[i] <= _ld_config_done_d[i];
			end          
        end
    endgenerate
    assign ld_config_done = _ld_config_done_q;
	
    generate
        for (i=0; i<MAX_NUM_GROUPS; i=i+1) begin
           always @(*) begin
               if (_st_config_done_q[i] == 0 && opcode == OP_LD_ST && fn == FN_ST_START && curr_group_id == i)
                   _st_config_done_d[i] = 1'b1;
               else
                   _st_config_done_d[i] = _st_config_done_q[i];
           end
           
           always @(posedge clk) begin
              if (reset)
                  _st_config_done_q[i] <= 1'b0;
             else
                  _st_config_done_q[i] <= _st_config_done_d[i];
           end          
        end
    endgenerate  
	assign st_config_done = _st_config_done_q;

    // Decoding the LD_ST START Instruction
    assign inst_ld_start_v = (opcode == OP_LD_ST) && (fn == FN_LD_START);
    assign inst_st_start_v = (opcode == OP_LD_ST) && (fn == FN_ST_START);
    assign inst_noop_start_v = (opcode == 4'b0000) && (fn == 4'b1111);
	assign inst_data_shuffle_start_v = (opcode == OP_PERMUTATION) && (fn == FN_PERMUTATION_START);

    assign ready = state_q == IDLE;
    
    assign in_ld_st = state_q == LD || state_q == ST;
	assign in_shuffle = state_q == PERMUTATION;
    assign in_data_shuffle = state_q == PERMUTATION;
    
    
    reg st_mem_simd_done_d ;
    always @(posedge clk) begin
        st_mem_simd_done_d <= st_mem_simd_done ;
    end

	/**************** FSM ***************************/
	always @(*) begin
		case (state_q)
		IDLE: begin
			addr_d = addr_q;
			if (start) begin
				state_d = GET_GROUP_START_ADDR;
				imem_rd_v = 1'b0;
		    end else begin
		        state_d = state_q;
		        imem_rd_v = 1'b0;
		    end
			num_iterations_d = 'b1;			
		end

		GET_GROUP_START_ADDR: begin
		    if (group_buf_rd_v) begin
		        state_d = INST_READ;
		        imem_rd_v = 1'b1;
		        addr_d = group_buf_rd_data; 
		    end else begin
		        state_d = state_q;
		        imem_rd_v = 1'b0;
		        addr_d = addr_q;
		    end
		end	

		INST_READ: begin		
			if(inst_group_ex_end) begin
			     state_d = IDLE;
			     num_iterations_d = 'b1;
			     if (simd_tiles_done) begin
			         addr_d = addr_q + 'b1;
			     end
			     else
			         addr_d = 0;
			     imem_rd_v = 1'b1;
			end else if (loop_start) begin
				state_d = nested_loop ? IN_NESTED_LOOP : IN_LOOP;
				addr_d = addr_q; // nested_loop ? addr_q : addr_q + 1;
                imem_rd_v = 1'b1;
			end else if (inst_ld_start_v) begin
		        state_d = LD;
		        imem_rd_v = 1'b0;
		        addr_d = addr_q;
		        _stall_d = 1'b1;
		    end else if (inst_st_start_v) begin
                state_d = ST;
                imem_rd_v = 1'b0;
                addr_d = addr_q;
                _stall_d = 1'b1;		        
		    end else if (inst_data_shuffle_start_v) begin
                state_d = PERMUTATION;
                imem_rd_v = 1'b0;
                addr_d = addr_q;
                _stall_d = 1'b1;	
            end else if (st_mem_simd_done_d) begin
                state_d = state_q;
//		        num_iterations_d = 'b1;
		        addr_d = addr_q ;
		        imem_rd_v = 1'b1; 	    
		    end else begin
		        state_d = state_q;
		        num_iterations_d = 'b1;
		        addr_d = addr_q + 'b1;
		        imem_rd_v = 1'b1;
		    end
		end

		LD: begin
		   if (ld_mem_simd_done) begin
		       state_d = INST_READ;
		       imem_rd_v = 1'b1;
		       _stall_d = 1'b0;
		       addr_d = addr_q + 1;
		   end else begin
               state_d = state_q;	    
		       imem_rd_v = 1'b0;
		       _stall_d = 1'b1;
		       addr_d = addr_q;
		   end
		end

		ST: begin
		    if (st_mem_simd_done) begin
		    
//				if (in_fusion_reg) begin // NEED CORRECTLY IDENTIFY FUSION
//					state_d = IDLE;
//					imem_rd_v = 1'b1;
//					_stall_d = 1'b0;
					
//					// Multi Tile Support
//					if (simd_tiles_done)
//						addr_d = addr_q + 1;
//					else 
//						addr_d = 0;

//				end else begin
                     
				    if (simd_tiles_done || in_fusion_reg) begin
						addr_d = addr_q + 1;
					end else begin
						addr_d = 0;
					end 
					state_d = INST_READ;
					imem_rd_v = 1'b1;
					_stall_d = 1'b0;			
		   end else begin
		       state_d = state_q;
		       imem_rd_v = 1'b0;
		       _stall_d = 1'b1;
		       addr_d = addr_q; 
		   end		
		end

		IN_LOOP: begin
			if (addr_q == addr_loop_end) begin	// || addr_q2 == addr_loop_end) begin						
				num_iterations_d = num_iterations_q + 'b1;
				if( num_iterations_q == loop_iterations) begin
					state_d = INST_READ;
					addr_d = addr_q +'b1;
				end else begin
					state_d = state_q;
					addr_d = addr_loop_start;
				end
			end else begin
				addr_d = addr_q + 'b1; // addr_d should not be increasing
				num_iterations_d = num_iterations_q;
				state_d = state_q;
			end
			imem_rd_v = 1'b1;
		end

		IN_NESTED_LOOP: begin
            if (nested_loop_done_final) begin
                state_d = INST_READ;
            end else begin
                addr_d = addr_q;
            end
		end

        PERMUTATION: begin
            if (data_shuffle_done) begin
               state_d = INST_READ;
               imem_rd_v = 1'b1;
               _stall_d = 1'b0;
               addr_d = addr_q + 1;
           end else begin
               state_d = state_q;
               imem_rd_v = 1'b0;
               _stall_d = 1'b1;
               addr_d = addr_q; 
           end      
        end

		default: begin
			state_d = IDLE;
			num_iterations_d = 'b1;
			imem_rd_v = 1'b0;
		end
		endcase
	end
    

	always @(posedge clk ) begin
	   if(reset)begin
            addr_q <= 'd0;
            addr_q2 <= 'd0;
            imem_rd_v_q <= 'd0;
            state_q <= 'd0;
            num_iterations_q <= 'd1;
            _stall_q <= 1'b0;
	   end else begin
            addr_q <= addr_d;
            addr_q2 <= addr_q;
            imem_rd_v_q <= imem_rd_v;
            state_q <= state_d;
            num_iterations_q <= num_iterations_d;
            _stall_q <= _stall_d;
	   end
	end
	
	assign imem_rd_address = addr_q;
	assign imem_rd_req = imem_rd_v_q;
	assign stall = _stall_q;
	
wire pc_simd_tot_compute_en ;
assign pc_simd_tot_compute_en = (state_q == 4)?1:0 ;	
	// Number of compute cycles
perf_counter #(
    .DATA_WIDTH (PC_DATA_WIDTH)
) pc_num_compute_cycles (
    .clk (clk),
    .en (pc_simd_tot_compute_en),
    .rst (reset),
    .out (pc_simd_tot_compute)
);

//ila_1 simd_ila_2 (
//  .clk(clk),
//  // 4 bit width
//  .probe0(state_q[2:0])
  
//  );
 
  
  
  
endmodule
