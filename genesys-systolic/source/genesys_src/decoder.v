//
// GeneSys controller - decoder
//
// Soroush Ghodrati
// (soghodra@eng.ucsd.edu)

`timescale 1ns/1ps
module decoder #(
    parameter integer  IMEM_ADDR_W                  = 10,
    parameter integer  DDR_ADDR_W                   = 42,
  // Internal
    parameter integer  INST_W                       = 32,
    // Systolic Array Buffers: IBUF, WBUF, OBUF, BBUF
    parameter integer  BUF_TYPE_W                   = 2,
    parameter integer  IMM_WIDTH                    = 16,
    parameter integer  OP_CODE_W                    = 4,
    parameter integer  OP_SPEC_W                    = 6,
    parameter integer  LOOP_ID_W                    = 6,
    parameter integer  INST_GROUP_ID_W              = 4,
    parameter integer  LOOP_ITER_W                  = IMM_WIDTH,
    parameter integer  ADDR_STRIDE_W                = 2*IMM_WIDTH,
    parameter integer  MEM_REQ_SIZE_W               = IMM_WIDTH,
    parameter integer  STATE_W                      = 3,
	parameter integer  WAIT_CYCLES  				= 128,
	parameter integer  WAIT_SIGNALS_WIDTH			= $clog2(WAIT_CYCLES)
) (
    input  wire                                         clk,
    input  wire                                         reset,
  // Instruction memory
    input  wire  [ INST_W               -1 : 0 ]        imem_read_data,
    input  wire											imem_read_valid,
    output wire  [ IMEM_ADDR_W          -1 : 0 ]        imem_read_addr,
    output wire                                         imem_read_req,
    output wire											imem_base_addr_valid,
  // Handshake
  // initiate decoder for the first time, when the first block is written
    input  wire                                         start,
    // finishing the decode (after last block)
    output wire                                         done,
    output wire                                         loop_ctrl_start,
    // following seems unusable
//    input  wire                                         loop_ctrl_done,
    input  wire                                         block_done,
    output wire                                         last_block,
    
    
    input wire											next_block_ready,

    output wire											imem_rd_block_done,
    
  // Loop strides
    output wire                                         cfg_loop_iter_v,
    output wire  [ LOOP_ITER_W          -1 : 0 ]        cfg_loop_iter,
    output wire  [ LOOP_ID_W            -1 : 0 ]        cfg_loop_iter_loop_id,
    output wire                                         cfg_set_specific_loop_v,
    output wire  [ LOOP_ID_W            -1 : 0 ]        cfg_set_specific_loop_loop_id,
    output wire  [ 2                       : 0 ]        cfg_set_specific_loop_loop_param,
//    output wire  [ LOOP_ID_W            -1 : 0 ]		cfg_loop_iter_level,
  // Loop strides
    output wire                                         cfg_loop_stride_v,
    output wire  [ 2                    -1 : 0 ]        cfg_loop_stride_type,
    output wire  [ ADDR_STRIDE_W        -1 : 0 ]        cfg_loop_stride,
    output wire  [ LOOP_ID_W            -1 : 0 ]        cfg_loop_stride_loop_id,
    output wire  [ BUF_TYPE_W           -1 : 0 ]        cfg_loop_stride_id,
//    output wire											cfg_loop_stride_segment,
  // Mem access
    output wire                                         cfg_mem_req_v,
    output wire  [ MEM_REQ_SIZE_W       -1 : 0 ]        cfg_mem_req_size,
    output wire  [ 2                    -1 : 0 ]        cfg_mem_req_type, // 0: LD, 1:ST
    output wire  [ LOOP_ID_W            -1 : 0 ]        cfg_mem_req_loop_id, // specify which Loop
    output wire  [ BUF_TYPE_W           -1 : 0 ]        cfg_mem_req_id, // specify which scratchpad
    
    output wire											imem_ld_req_valid,
    output wire	 [ IMM_WIDTH			-1 : 0 ]		imem_ld_req_size,
  // DDR Address
    output wire  [ DDR_ADDR_W           -1 : 0 ]        ibuf_base_addr,
    output wire  [ DDR_ADDR_W           -1 : 0 ]        wbuf_base_addr,
    output wire  [ DDR_ADDR_W           -1 : 0 ]        obuf_base_addr,
    output wire  [ DDR_ADDR_W           -1 : 0 ]        bias_base_addr,
    output wire	 [ DDR_ADDR_W			-1 : 0 ]              imem_base_addr,
  // Buf access: seems unsuable
//    output wire                                         cfg_buf_req_v,
//    output wire  [ MEM_REQ_SIZE_W       -1 : 0 ]        cfg_buf_req_size,
//    output wire                                         cfg_buf_req_type, // 0: RD, 1: WR
//    output wire  [ BUF_TYPE_W           -1 : 0 ]        cfg_buf_req_loop_id, // specify which scratchpad

    output wire	 [ INST_GROUP_ID_W       -1 : 0 ]		inst_group_id,
    output wire											inst_group_type,
    output wire  										inst_group_s_e,
    output wire											inst_group_v,
//    output wire	 [ LOOP_ID_W			 -1 : 0 ]		inst_group_sa_loop_id,
    output wire											inst_group_last,

  // SIMD
    output wire  [ INST_W               -1 : 0 ]        cfg_simd_inst, // instructions for SIMD
    output wire                                         cfg_simd_inst_v  // instructions for SIMD    
    
);

//=============================================================
// Localparams
//=============================================================
    localparam integer  FSM_IDLE                     = 0; // IDLE
    localparam integer  FSM_DECODE                   = 1; // Decode and Configure Block
    localparam integer  FSM_SIMD_GROUP               = 2; // Wait for dispatching the SIMD array instructions
    localparam integer  FSM_EXECUTE                  = 3; // Wait for execution of inst block
    localparam integer  FSM_NEXT_BLOCK               = 4; // Check for next block
    localparam integer  FSM_DONE_WAIT                = 5; // Wait to ensure no RAW hazard
    localparam integer  FSM_DONE                     = 6; // Done
    
    localparam integer	OP_SA_LOOP					        = 9;
	localparam integer  OP_INST_GROUP                 = 10;
	localparam integer  OP_BLOCK_END 				          = 11;
	localparam integer  OP_GENADDR					          = 12;
	localparam integer  OP_BASE_ADDR                  = 13;
	localparam integer  OP_LD_ST     				          = 14;
 
    localparam integer  MEM_LOAD                     = 0;
    localparam integer  MEM_STORE                    = 1;
    localparam integer  BUF_READ                     = 2;
    localparam integer  BUF_WRITE                    = 3;
	
	// LD, ST, RD, WR
	localparam integer  MEM_ACCESS_TYPE_W			 = 2;
	
	localparam integer  INST_GROUP_SA                = 0;
	localparam integer  INST_GROUP_SIMD              = 1;
	localparam integer  INST_GROUP_START 			 = 0;
	localparam integer  INST_GROUP_END				 = 1;
	

//=============================================================

//=============================================================
// Wires/Regs
//=============================================================
    reg  [ WAIT_SIGNALS_WIDTH   -1   : 0 ]      done_wait_d;
    reg  [ WAIT_SIGNALS_WIDTH   -1   : 0 ]      done_wait_q;
    reg  [ IMM_WIDTH            -1 : 0 ]        loop_stride_hi;
	reg	 [ IMM_WIDTH			-1 : 0 ]        loop_stride_low;


    wire                                        simd_inst_group_end;

    wire [ IMM_WIDTH            -1 : 0 ]        simd_num_instructions;
    wire                                        simd_inst_group_start;
    

    reg  [ STATE_W              -1 : 0 ]        state_q;
    reg  [ STATE_W              -1 : 0 ]        state_d;
    wire [ STATE_W              -1 : 0 ]        state;

    wire [ OP_CODE_W            -1 : 0 ]        op_code;
    wire [ OP_SPEC_W            -1 : 0 ]        op_spec;
    wire [ LOOP_ID_W            -1 : 0 ]        loop_id;
    wire [ IMM_WIDTH            -1 : 0 ]        immediate;

    wire [ BUF_TYPE_W           -1 : 0 ]        buf_id;
	wire [ MEM_ACCESS_TYPE_W      -1 : 0 ]		gen_addr_mem_access_type;
	wire                                        loop_stride_segment;
	wire                                        loop_stride_v;
	wire                                        cfg_loop_stride_v_d;
    wire                                        cfg_loop_stride_v_q;
    
    reg   [LOOP_ID_W            -1 : 0 ]        loop_id_q;
    reg   [MEM_ACCESS_TYPE_W      -1 : 0 ]      gen_addr_mem_access_type_q;
    reg   [ BUF_TYPE_W           -1 : 0 ]       buf_id_q;
    wire                                        inst_valid;
    reg                                         _inst_valid;
    wire                                        block_end;


    reg  [ IMM_WIDTH            -1 : 0 ]        simd_inst_counter_d;
    reg  [ IMM_WIDTH            -1 : 0 ]        simd_inst_counter_q;

    reg  [ IMEM_ADDR_W          -1 : 0 ]        addr_d;
    reg  [ IMEM_ADDR_W          -1 : 0 ]        addr_q;

    wire                                        _last_block;

    wire                                        sa_group_end;


    wire                                        base_addr_v;
    wire [ BUF_TYPE_W           -1 : 0 ]        base_addr_id;
    wire 								        base_addr_part;
	wire [ IMM_WIDTH 	            -1 : 0 ]        base_addr;
	
	wire 										base_addr_imem_v;
	wire										base_addr_imem_part;
	wire [ IMM_WIDTH				-1 : 0 ]	base_addr_imem;
	
	
	
	
	
	
//=============================================================

//=============================================================
// Logic
//=============================================================
  // Ops
    assign loop_ctrl_start = block_end;

    assign imem_read_req = state == FSM_DECODE || state == FSM_SIMD_GROUP;
    assign imem_read_addr = addr_q;
	
  always @(posedge clk)
  begin
    if (reset)
      addr_q <= {IMEM_ADDR_W{1'b0}};
    else
      addr_q <= addr_d;
  end

//=================================================
  // Decode instructions
//=================================================
    assign {op_code, op_spec, loop_id, immediate} = imem_read_data;
  	
  	assign buf_id = op_spec[1:0];

  
// Decoding Block End Instruction  
    assign block_end = op_code == OP_BLOCK_END && _inst_valid && state == FSM_DECODE;
  	assign imem_rd_block_done = block_end;
 
  	assign _last_block = immediate[0];
  
 // Decoding LOOP Insstrucion
    assign cfg_loop_iter_v = (op_code == OP_SA_LOOP) && inst_valid && ~op_spec[5];
    assign cfg_loop_iter = immediate;
    assign cfg_loop_iter_loop_id = loop_id;
  	assign cfg_set_specific_loop_v = (op_code == OP_SA_LOOP) && inst_valid && op_spec[5];
  	assign cfg_set_specific_loop_loop_id = loop_id;
  	assign cfg_set_specific_loop_loop_param = immediate[2:0]; 
  	
  	
// Decoding GENADDR Instructions
  	assign gen_addr_mem_access_type = op_spec[3:2];  
  
    assign loop_stride_v = (op_code == OP_GENADDR) && inst_valid;
  	assign loop_stride_segment = op_spec[5];

  	//TODO: make sure about block_done
  	always @(posedge clk)
	begin 
		if (reset) begin
			loop_stride_hi <= 0;
			loop_stride_low <= 0;
	    end
		else begin
			if (loop_stride_v && loop_stride_segment)
				loop_stride_hi <= immediate;
			else if (loop_stride_v && ~loop_stride_segment)
				loop_stride_low <= immediate;
		end
	end
//	
    assign cfg_loop_stride_v_d = loop_stride_v && loop_stride_segment;	
    register_sync #(1) cfg_loop_stride_delay_reg (clk, reset, cfg_loop_stride_v_d, cfg_loop_stride_v_q);   
    always @(posedge clk) begin
        if (reset || block_done) begin
           buf_id_q <= 0;
           gen_addr_mem_access_type_q <= 0;
           loop_id_q <= 0;
        end
        else if (cfg_loop_stride_v_d) begin
           buf_id_q <= buf_id;
           gen_addr_mem_access_type_q <= gen_addr_mem_access_type;
           loop_id_q <= loop_id;
        end
    end   
    
    assign cfg_loop_stride_v = cfg_loop_stride_v_q;
    assign cfg_loop_stride = {loop_stride_hi, loop_stride_low};
    assign cfg_loop_stride_id = buf_id_q;
    assign cfg_loop_stride_type = gen_addr_mem_access_type_q;
    assign cfg_loop_stride_loop_id = loop_id_q;
 
// Decoding LD/ST Instructions
	// W/I/O/B
    assign cfg_mem_req_v = (op_code == OP_LD_ST) && inst_valid && ~op_spec[4];
    assign cfg_mem_req_size = immediate;
    assign cfg_mem_req_type = op_spec[5] == 0 ? MEM_LOAD : MEM_STORE;
    assign cfg_mem_req_loop_id = loop_id;
    assign cfg_mem_req_id = buf_id;
	// IMEM
	assign imem_ld_req_valid = (op_code == OP_LD_ST) && inst_valid && op_spec[4];
	assign imem_ld_req_size  = immediate;

	
// Decoding INST GROUP Instructions
	assign inst_group_v = (op_code == OP_INST_GROUP) && inst_valid;
	assign inst_group_type = op_spec[5]; 
	assign inst_group_s_e  = op_spec[4];
	assign inst_group_id = op_spec[3:0];
//	assign inst_group_sa_loop_id = loop_id;
    assign inst_group_last = immediate[0];
	// SIMD 
    assign simd_num_instructions = immediate;
	assign simd_inst_group_start = inst_valid && (op_code == OP_INST_GROUP) && inst_group_type && ~inst_group_s_e;
	assign simd_inst_group_end = state == FSM_SIMD_GROUP && simd_inst_counter_q == 0;
	// Dispatching the SIMD INST GP Start/End to SIMD array to 
	assign cfg_simd_inst_v = (state == FSM_SIMD_GROUP) || (inst_valid && (op_code == OP_INST_GROUP) && inst_group_type && state == FSM_DECODE);
    assign cfg_simd_inst = imem_read_data;
    
    assign sa_group_end = inst_group_v && ~inst_group_type && inst_group_s_e;
			
// Decoding BASEADDR Instructions
// SG: Currently assuming that there is no specific base addr for each loop id.
// The base addr is just associated with the INST GROUP (a register in the controller holds the current group)
	// W/I/O/B Buffers
	assign base_addr_v = (op_code == OP_BASE_ADDR) && inst_valid && ~op_spec[4];
	assign base_addr = immediate;
	assign base_addr_id = buf_id;
    assign base_addr_part = op_spec[5];
	// IMEM
	assign base_addr_imem_v = (op_code == OP_BASE_ADDR) && inst_valid && op_spec[4];
	assign base_addr_imem = immediate;
	assign base_addr_imem_part = op_spec[5];
			
//=============================================================

//=============================================================
// FSM
//=============================================================
    reg                                         last_block_d;
    reg                                         last_block_q;
    assign last_block = last_block_q;
always @(posedge clk)
begin
  if (reset)
    last_block_q <= 0;
  else
    last_block_q <= last_block_d;
end

always @(posedge clk)
begin
  if (reset)
    done_wait_q <= 0;
  else
    done_wait_q <= done_wait_d;
end


  always @(*)
  begin: FSM
    state_d = state_q;
    addr_d = addr_q;
    simd_inst_counter_d = simd_inst_counter_q;
    last_block_d = last_block_q;  
    done_wait_d = done_wait_q;
    case(state_q)
      FSM_IDLE: begin               // 0
        if (start) begin
          state_d = FSM_DECODE;
          addr_d = 0;
        end
      end
      FSM_DECODE: begin             // 1
        if (loop_ctrl_start) begin
          state_d = FSM_EXECUTE;
          last_block_d = _last_block;     // for some reason this is not getting set.
        end
        else if (simd_inst_group_start) begin
          state_d = FSM_SIMD_GROUP;
          addr_d = addr_q + 1;
          simd_inst_counter_d = simd_num_instructions -1;
        end
        else          
          addr_d = addr_q + 1;
      end
      FSM_SIMD_GROUP: begin         // 2
        addr_d = addr_q + 1;
        if (simd_inst_group_end) begin
          state_d = FSM_DECODE;
        end
        else begin
          simd_inst_counter_d = simd_inst_counter_q - 1;
        end
      end
      FSM_EXECUTE: begin            // 3
        if (block_done) begin
          state_d = FSM_NEXT_BLOCK;
        end
      end
      FSM_NEXT_BLOCK: begin
        if (last_block_q) begin
          done_wait_d = WAIT_CYCLES;
          state_d = FSM_DONE_WAIT;
        end
        else if (next_block_ready) begin
          state_d = FSM_DECODE;
        end
      end
      FSM_DONE_WAIT: begin
        if (done_wait_d == 0) begin
          state_d = FSM_DONE;
        end
        else
          done_wait_d = done_wait_d - 1;
      end
      FSM_DONE: begin
        state_d = FSM_IDLE;
      end
    endcase
  end

    assign done = state_q == FSM_DONE;

  always @(posedge clk)
  begin
    if (reset)
      _inst_valid <= 0;
    else
      _inst_valid <= imem_read_req;
  end
  	// TODO: Brahmendra: Make sure the imem_rd_valid is used in the right place!
    assign inst_valid = _inst_valid && ~block_end && state == FSM_DECODE && imem_read_valid;

  always @(posedge clk)
  begin
    if (reset)
      simd_inst_counter_q <= 0;
    else
      simd_inst_counter_q <= simd_inst_counter_d;
  end

  always @(posedge clk)
  begin
    if (reset)
      state_q <= FSM_IDLE;
    else
      state_q <= state_d;
  end

    assign state = state_q;
//=============================================================


//=============================================================
// Base Address
//=============================================================
    reg  [ 2*IMM_WIDTH            -1 : 0 ]        _obuf_base_addr;
    reg  [ 2*IMM_WIDTH            -1 : 0 ]        _bias_base_addr;
    reg  [ 2*IMM_WIDTH            -1 : 0 ]        _ibuf_base_addr;
    reg  [ 2*IMM_WIDTH            -1 : 0 ]        _wbuf_base_addr;
	  reg  [ 2*IMM_WIDTH            -1 : 0 ]        _imem_base_addr; 
	      
  
  reg											_imem_base_addr_valid;
  genvar i;
  generate
    for (i=0; i<2; i=i+1) begin: BASE_ADDR_CFG 
    
    /* 
    if( DDR_ADDR_W > 2*IMM_WIDTH) begin
			assign obuf_base_addr[DDR_ADDR_W-1: 2*IMM_WIDTH] = {(DDR_ADDR_W- (2*IMM_WIDTH + DDR_4K_ALIGNMENT_OFFSET)){1'b0}};
			assign bias_base_addr[DDR_ADDR_W-1: 2*IMM_WIDTH] = {(DDR_ADDR_W- (2*IMM_WIDTH + DDR_4K_ALIGNMENT_OFFSET)){1'b0}};
			assign ibuf_base_addr[DDR_ADDR_W-1: 2*IMM_WIDTH] = {(DDR_ADDR_W- (2*IMM_WIDTH + DDR_4K_ALIGNMENT_OFFSET)){1'b0}};
			assign wbuf_base_addr[DDR_ADDR_W-1: 2*IMM_WIDTH] = {(DDR_ADDR_W- (2*IMM_WIDTH + DDR_4K_ALIGNMENT_OFFSET)){1'b0}};
			assign imem_base_addr[DDR_ADDR_W-1: 2*IMM_WIDTH] = {(DDR_ADDR_W- (2*IMM_WIDTH + DDR_4K_ALIGNMENT_OFFSET)){1'b0}}; 
	  end
    */
    if( DDR_ADDR_W > 2*IMM_WIDTH) begin
			assign obuf_base_addr[DDR_ADDR_W-1: 2*IMM_WIDTH] = {DDR_ADDR_W- 2*IMM_WIDTH{1'b0}};
			assign bias_base_addr[DDR_ADDR_W-1: 2*IMM_WIDTH] = {DDR_ADDR_W- 2*IMM_WIDTH{1'b0}};
			assign ibuf_base_addr[DDR_ADDR_W-1: 2*IMM_WIDTH] = {DDR_ADDR_W- 2*IMM_WIDTH{1'b0}};
			assign wbuf_base_addr[DDR_ADDR_W-1: 2*IMM_WIDTH] = {DDR_ADDR_W- 2*IMM_WIDTH{1'b0}};
			assign imem_base_addr[DDR_ADDR_W-1: 2*IMM_WIDTH] = {DDR_ADDR_W- 2*IMM_WIDTH{1'b0}};
	  end

      always @(posedge clk) begin
        if (reset)
          _ibuf_base_addr[i*IMM_WIDTH+:IMM_WIDTH] <= 0;
        else if (base_addr_v && base_addr_id == 1 && base_addr_part == i)
          _ibuf_base_addr[i*IMM_WIDTH+:IMM_WIDTH] <= base_addr;
        else if (sa_group_end)
          _ibuf_base_addr[i*IMM_WIDTH+:IMM_WIDTH] <= 0;
      end

      always @(posedge clk) begin
        if (reset)
          _wbuf_base_addr[i*IMM_WIDTH+:IMM_WIDTH] <= 0;
        else if (base_addr_v && base_addr_id == 0 && base_addr_part == i)
          _wbuf_base_addr[i*IMM_WIDTH+:IMM_WIDTH] <= base_addr;
        else if (sa_group_end)
          _wbuf_base_addr[i*IMM_WIDTH+:IMM_WIDTH] <= 0;
      end

      always @(posedge clk) begin
        if (reset)
          _obuf_base_addr[i*IMM_WIDTH+:IMM_WIDTH] <= 0;
        else if (base_addr_v && base_addr_id == 2 && base_addr_part == i)
          _obuf_base_addr[i*IMM_WIDTH+:IMM_WIDTH] <= base_addr;
        else if (sa_group_end)
          _obuf_base_addr[i*IMM_WIDTH+:IMM_WIDTH] <= 0;
      end
      
      always @(posedge clk) begin
        if (reset)
          _bias_base_addr[i*IMM_WIDTH+:IMM_WIDTH] <= 0;
        else if (base_addr_v && base_addr_id == 3 && base_addr_part == i)
          _bias_base_addr[i*IMM_WIDTH+:IMM_WIDTH] <= base_addr;
        else if (sa_group_end)
          _bias_base_addr[i*IMM_WIDTH+:IMM_WIDTH] <= 0;
      end

      always @(posedge clk) begin
        if (reset) begin
          _imem_base_addr[i*IMM_WIDTH+:IMM_WIDTH] <= 0;
	    end
        else if (base_addr_imem_v && base_addr_imem_part == i) begin
          _imem_base_addr[i*IMM_WIDTH+:IMM_WIDTH] <= base_addr_imem;
	    end
        else if (block_done)
          _imem_base_addr[i*IMM_WIDTH+:IMM_WIDTH] <= 0;
      end

    end
  endgenerate
	
	always @(posedge clk) begin
		if (reset) begin
		  _imem_base_addr_valid <= 0;
		end
		else if (base_addr_imem_v && base_addr_imem_part == 1'b1) begin
		  _imem_base_addr_valid <= 1;
		end
		else
		   _imem_base_addr_valid <= 0;
	  end
	  
 	assign imem_base_addr_valid 				  = _imem_base_addr_valid;

    /*
    // rohan: added changes to make the DDR address 4K aligned
    localparam integer  DDR_4K_ALIGNMENT_OFFSET   = 12;
    wire  [ DDR_ADDR_W           -1 : 0 ]        ibuf_base_addr_4kAlign ;
    wire  [ DDR_ADDR_W           -1 : 0 ]        wbuf_base_addr_4kAlign ;
    wire  [ DDR_ADDR_W           -1 : 0 ]        obuf_base_addr_4kAlign ;
    wire  [ DDR_ADDR_W           -1 : 0 ]        bias_base_addr_4kAlign ;
    wire	[ DDR_ADDR_W			     -1 : 0 ]        imem_base_addr_4kAlign ;
    assign ibuf_base_addr_4kAlign     =  _ibuf_base_addr;
    assign wbuf_base_addr_4kAlign     =  _wbuf_base_addr;
    assign obuf_base_addr_4kAlign     =  _obuf_base_addr;
    assign bias_base_addr_4kAlign     =  _bias_base_addr;
    assign imem_base_addr_4kAlign     =  _imem_base_addr;
    assign ibuf_base_addr             = ibuf_base_addr_4kAlign  << DDR_4K_ALIGNMENT_OFFSET;
    assign wbuf_base_addr             = wbuf_base_addr_4kAlign  << DDR_4K_ALIGNMENT_OFFSET;
    assign obuf_base_addr             = obuf_base_addr_4kAlign  << DDR_4K_ALIGNMENT_OFFSET;
    assign bias_base_addr             = bias_base_addr_4kAlign  << DDR_4K_ALIGNMENT_OFFSET;
	  assign imem_base_addr             = imem_base_addr_4kAlign  << DDR_4K_ALIGNMENT_OFFSET;
    */
    
    assign ibuf_base_addr             = _ibuf_base_addr;
    assign wbuf_base_addr             = _wbuf_base_addr;
    assign obuf_base_addr             = _obuf_base_addr;
    assign bias_base_addr             = _bias_base_addr;
	  assign imem_base_addr             = _imem_base_addr;


//=============================================================

//=============================================================
// VCD
//=============================================================
//  `ifdef COCOTB_TOPLEVEL_decoder
//    initial begin
//    $dumpfile("decoder.vcd");
//    $dumpvars(0, decoder);
//    end
//  `endif
//=============================================================

endmodule
