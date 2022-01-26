//
// 2-D systolic array
//
// Soroush Ghodrati
// (soghodra@eng.ucsd.edu)

`timescale 1ns/1ps
`define CONFIGURATION_SELECT_I(select,index) ( (index == 0 ) ? ( 16*(1 << ((select-1)/3))) : (index == 1 ) ? ( 4*(1 << ((select-1) %3))) : 0 )
`define CONFIGURATION_SELECT(select,index) ( (select > 12) ? `CONFIGURATION_SELECT_I(1,index) : `CONFIGURATION_SELECT_I(select,index))
`define WEIGHT_WIDTH(select) ( (select == 13) ? 8 : (select == 14) ? 9 : 7 )

module systolic_array #(
    parameter integer  CONFIG_NO                    = 6,
    parameter integer  ARRAY_N                      = `CONFIGURATION_SELECT(CONFIG_NO,0),
    parameter integer  ARRAY_M                      = `CONFIGURATION_SELECT(CONFIG_NO,0),
    parameter integer  ACT_WIDTH                    = `CONFIGURATION_SELECT(CONFIG_NO,1),
    //parameter integer  WGT_WIDTH                    = `CONFIGURATION_SELECT(CONFIG_NO,1),
    parameter integer  BIAS_WIDTH                   = 32,
    parameter integer  ACC_WIDTH                    = 4*`CONFIGURATION_SELECT(CONFIG_NO,1),
    parameter integer  MULT_OUT_WIDTH               = ACT_WIDTH + WGT_WIDTH,
    parameter integer  PE_OUT_WIDTH                 = MULT_OUT_WIDTH + $clog2(ARRAY_N),
    parameter integer  PE_INTER_WIDTH				= PE_OUT_WIDTH + 1,
    parameter 		   PE_TRUNC_MODE				= "MSB",
    parameter		   ACT_PIPELINE				    = "True",
    parameter          DTYPE                        = "FXP",
    parameter integer  WBUF_REQ_WIDTH 				= $clog2(ARRAY_M) + 1,
    parameter integer  SYSTOLIC_OUT_WIDTH           = ARRAY_M * PE_OUT_WIDTH,
    parameter integer  IBUF_DATA_WIDTH              = ARRAY_N * ACT_WIDTH,
    parameter integer  OUT_WIDTH                    = ARRAY_M * ACC_WIDTH,
    parameter integer  BBUF_DATA_WIDTH              = ARRAY_M * BIAS_WIDTH,
    parameter integer  OBUF_ADDR_WIDTH              = 12,
    parameter integer  BBUF_ADDR_WIDTH              = 5,
    parameter integer  IBUF_ADDR_WIDTH              = 14,
    //parameter integer  WBUF_ADDR_WIDTH				      = `WEIGHT_WIDTH(CONFIG_NO),
    
    parameter	integer  WBUF_DDR_BANDWIDTH					  = 512,
	  parameter integer  WBUF_READ_WIDTH              = 8,
    parameter integer  WBUF_DEPTH                  	= 64,
	  parameter	integer	 WBUF_NUM_BANKS 						  = 64,
    parameter integer  WBUF_READ_LATENCY_B          = 1,
    parameter integer  WBUF_WRITE_WIDTH             = 8,
    parameter integer  WBUF_MEMORY_SIZE             = 256,
    parameter integer  WBUF_WRITE_ADDR_WIDTH        = 8,  
    parameter integer  WBUF_READ_ADDR_WIDTH         = 8,
    parameter integer  WBUF_ADDR_WIDTH				      = WBUF_READ_ADDR_WIDTH,
    parameter integer  WGT_WIDTH                    = WBUF_READ_WIDTH
    
        ) (
    input  wire                                         clk,
    input  wire                                         reset,
    input  wire                                         acc_clear,

    //==============Interface for IBUF========================
    input  wire                                         ibuf_read_req_in,
    input  wire  [ IBUF_ADDR_WIDTH       -1 : 0]        ibuf_read_addr_in,
    output wire  [ ARRAY_N               -1 : 0]        sys_ibuf_read_req,
    output wire  [ ARRAY_N*IBUF_ADDR_WIDTH -1:0]        sys_ibuf_read_addr,
    input  wire	 [ACT_WIDTH*ARRAY_N      -1: 0]		    ibuf_read_data,


    output wire  [ ARRAY_M              -1 : 0]         sys_bias_read_req,
    output wire  [ BBUF_ADDR_WIDTH*ARRAY_M-1 :0]        sys_bias_read_addr,
    input  wire                                         bias_read_req_in,
    input  wire  [ BBUF_ADDR_WIDTH      -1 : 0 ]        bias_read_addr_in,
    input  wire  [ BBUF_DATA_WIDTH      -1 : 0 ]        bbuf_read_data,
    input  wire                                         bias_prev_sw,
    input  wire	 										wbuf_read_req,
    input  wire  [ WBUF_ADDR_WIDTH      -1 : 0 ]		wbuf_read_addr,
 
    input  wire  [ WBUF_REQ_WIDTH*ARRAY_N       -1 : 0 ]		wbuf_write_req,

    input  wire  [ WBUF_ADDR_WIDTH*ARRAY_N      -1 : 0 ]		wbuf_write_addr,
  
    input  wire  [ WGT_WIDTH*ARRAY_N		    -1 : 0 ]		wbuf_write_data,
   
 // TODO: figure out the signals for obuf
    input  wire  [ OUT_WIDTH            -1 : 0 ]        obuf_read_data,
    input  wire  [ OBUF_ADDR_WIDTH      -1 : 0 ]        obuf_read_addr,
    
    input  wire                                         obuf_read_req_in,
    
    output wire  [ ARRAY_M              -1 : 0 ]        sys_obuf_read_req,
    output wire  [ OBUF_ADDR_WIDTH*ARRAY_M-1:0 ]        sys_obuf_read_addr,
    
    input  wire                                         obuf_write_req_in,
    output wire  [ OUT_WIDTH            -1 : 0 ]        obuf_write_data,
    input  wire  [ OBUF_ADDR_WIDTH      -1 : 0 ]        obuf_write_addr_in,
 // TODO: check the obuf_write_req and sys_obuf_write_req. it seems that obuf_write_req is always on but sys_obuf_write_req should be on for when 
 // we just want to write on obuf >>> we may need to add an extra signal
    output wire  [ ARRAY_M              -1 : 0 ]        sys_obuf_write_req,
    output wire  [ OBUF_ADDR_WIDTH*ARRAY_M-1 :0]        sys_obuf_write_addr
);

// TODO: Check if I need these signals!!
  //FSM to see if we can accumulate or not
    reg  [ 2                    -1 : 0 ]        acc_state_d;
    reg  [ 2                    -1 : 0 ]        acc_state_q;


    wire [ OUT_WIDTH            -1 : 0 ]        accumulator_out;
//    wire                                        acc_out_valid;
//    wire [ ARRAY_M              -1 : 0 ]        acc_out_valid_;
//    wire                                        acc_out_valid_all;
    wire [ SYSTOLIC_OUT_WIDTH   -1 : 0 ]        systolic_out;

	// figure out when the input forwarding (left to write) finishes
    wire [ ARRAY_M              -1 : 0 ]        systolic_out_valid;
	// figure out when the output forwarding (up to bottom) finishes
    wire [ ARRAY_N              -1 : 0 ]        _systolic_out_valid;

//    wire [ OBUF_ADDR_WIDTH      -1 : 0 ]        systolic_out_addr;
    wire [ OBUF_ADDR_WIDTH      -1 : 0 ]        _systolic_out_addr;

    wire                                        _addr_eq;
    reg                                         addr_eq;
    wire [ ARRAY_N              -1 : 0 ]        _acc;
    wire [ ARRAY_M              -1 : 0 ]        acc;
    wire [ OBUF_ADDR_WIDTH      -1 : 0 ]        _systolic_in_addr;

    wire [ BBUF_ADDR_WIDTH      -1 : 0 ]        _bias_read_addr;
    wire                                        _bias_read_req;

    wire [ ARRAY_N              -1 : 0 ]        col_bias_sw;
// We will need this part if we want to pipeline the inputs!
    wire [ ARRAY_M              -1 : 0 ]        bias_sel;
    wire                                        _bias_sel;
//    wire [ ARRAY_M              -1 : 0 ]        systolic_acc_clear;
//    wire [ ARRAY_M              -1 : 0 ]        _systolic_acc_clear;
//=========================================
// Systolic Array - Begin
//=========================================

	wire	[ARRAY_N-1:0]								pe_wbuf_read_req[ARRAY_M-1:0];
	wire	[ARRAY_N-1:0]								pe_wbuf_write_req[ARRAY_M-1:0];
	wire	[ARRAY_N-1:0]								pe_wbuf_read_req_frwrd[ARRAY_M-1:0];
	wire	[WBUF_ADDR_WIDTH            -1: 0]			pe_wbuf_read_addr[ARRAY_N-1:0][ARRAY_M-1:0];	
	wire	[WBUF_ADDR_WIDTH            -1: 0]			pe_wbuf_read_addr_frwrd[ARRAY_N-1:0][ARRAY_M-1:0];
	
	wire	[WGT_WIDTH		            -1: 0]			wbuf_write_data_frwrd[ARRAY_N-1:0][ARRAY_M-1:0];
	wire	[WGT_WIDTH		            -1: 0]			wbuf_write_data_in[ARRAY_N-1:0][ARRAY_M-1:0];
	wire	[WGT_WIDTH		            -1: 0]			pe_wbuf_write_data[ARRAY_N-1:0][ARRAY_M-1:0];
	
	wire	[WBUF_ADDR_WIDTH		    -1: 0]			wbuf_write_addr_frwrd[ARRAY_N-1:0][ARRAY_M-1:0];
	wire	[WBUF_ADDR_WIDTH		    -1: 0]			wbuf_write_addr_in[ARRAY_N-1:0][ARRAY_M-1:0];
	wire	[WBUF_ADDR_WIDTH		    -1: 0]			pe_wbuf_write_addr[ARRAY_N-1:0][ARRAY_M-1:0];
	
	wire	[WBUF_REQ_WIDTH		    -1: 0]			wbuf_write_req_en_frwrd[ARRAY_N-1:0][ARRAY_M-1:0];
	wire	[WBUF_REQ_WIDTH		    -1: 0]			wbuf_write_req_en_in[ARRAY_N-1:0][ARRAY_M-1:0];
	wire	[WBUF_REQ_WIDTH		    -1: 0]			pe_wbuf_write_req_en[ARRAY_N-1:0][ARRAY_M-1:0];
	
	wire	[ACT_WIDTH		    	-1: 0]			act_in_row[ARRAY_N-1:0];
	wire	[ACT_WIDTH		    	-1: 0]			pe_act_in[ARRAY_N-1:0][ARRAY_M-1:0];
	wire	[ACT_WIDTH		    	-1: 0]			pe_act_out[ARRAY_N-1:0][ARRAY_M-1:0];
	
	wire	[PE_OUT_WIDTH	    	-1: 0]			part_sum_in[ARRAY_N-1:0][ARRAY_M-1:0];
	wire	[PE_OUT_WIDTH	    	-1: 0]			part_sum_out[ARRAY_N-1:0][ARRAY_M-1:0];
    
    wire [ OBUF_ADDR_WIDTH      -1 : 0 ] obuf_write_addr_q,obuf_write_addr;
    wire obuf_write_req_q,obuf_write_req;
//    
    register_sync #(1) obuf_write_req_reg (clk, reset, obuf_write_req_in, obuf_write_req_q);
//    register_sync #(1) obuf_write_req_reg2 (clk, reset, obuf_write_req_q, obuf_write_req);
    assign obuf_write_req = obuf_write_req_q;
    
    
    register_sync #(OBUF_ADDR_WIDTH) obuf_write_addr_reg (clk, reset, obuf_write_addr_in, obuf_write_addr_q);
//    register_sync #(OBUF_ADDR_WIDTH) obuf_write_addr_reg2 (clk, reset, obuf_write_addr_q, obuf_write_addr);
    assign obuf_write_addr = obuf_write_addr_q;





//    wire [ OBUF_ADDR_WIDTH      -1 : 0 ] obuf_read_addr_q,obuf_read_addr_qq;
//    wire obuf_read_req_q,obuf_read_req;
//
//
//    register_sync #(1) obuf_write_req_reg (clk, reset, obuf_read_req_in, obuf_read_req_q);
//    register_sync #(1) obuf_write_req_reg2 (clk, reset, obuf_read_req_q, obuf_read_req);
//    assign obuf_write_req = obuf_write_req_in;
//    
//    
//    register_sync #(OBUF_ADDR_WIDTH) obuf_write_addr_reg (clk, reset, obuf_read_addr, obuf_read_addr_q);
//    register_sync #(OBUF_ADDR_WIDTH) obuf_write_addr_reg2 (clk, reset, obuf_read_addr_q, obuf_read_addr_qq);
//    assign obuf_write_addr = obuf_write_addr_in;

    
    
    
    
    
    
    wire [ BBUF_ADDR_WIDTH      -1 : 0 ] bias_read_addr_q,bias_read_addr;
    wire bias_read_req_q,bias_read_req;
    
    register_sync #(1) bias_read_req_reg (clk, reset, bias_read_req_in, bias_read_req_q);
//    register_sync #(1) bias_read_req_reg2 (clk, reset, bias_read_req_q, bias_read_req);
    assign bias_read_req = bias_read_req_q;
    
    
    register_sync #(BBUF_ADDR_WIDTH) bias_read_addr_reg (clk, reset, bias_read_addr_in, bias_read_addr_q);
//    register_sync #(BBUF_ADDR_WIDTH) bias_read_addr_reg2 (clk, reset, bias_read_addr_q, bias_read_addr);
    assign bias_read_addr = bias_read_addr_q;
   
    wire [ IBUF_ADDR_WIDTH         -1 : 0] ibuf_read_addr_q;
    wire                                   ibuf_read_req_q;
//    register_sync #(1) ibuf_read_req_reg (clk, reset, ibuf_read_req_in, ibuf_read_req_q); 
    assign ibuf_read_req_q = ibuf_read_req_in;
//    register_sync #(IBUF_ADDR_WIDTH) ibuf_read_addr_reg (clk, reset, ibuf_read_addr_in, ibuf_read_addr_q);  
    assign  ibuf_read_addr_q = ibuf_read_addr_in;
    
    
    

//	assign 						pe_wbuf_read_req[0][0]             =        wbuf_read_req;
//	assign                      pe_wbuf_read_addr[0][0]            =        wbuf_read_addr;
	genvar m,n;
	generate
		for(n = 0; n < ARRAY_N; n = n+1) begin
			for(m = 0; m < ARRAY_M; m = m+1) begin
				if( n == 0) begin
					if( m == 0) begin
//					  register_sync #(1) wbuf_read_req00 (clk, reset, wbuf_read_req, pe_wbuf_read_req[0][0]);
//					  register_sync #(WBUF_ADDR_WIDTH) wbuf_read_addr00 (clk, reset, wbuf_read_addr, pe_wbuf_read_addr[0][0]);
						assign 						pe_wbuf_read_req[n][m]             =        wbuf_read_req;
						assign                      pe_wbuf_read_addr[n][m]            =        wbuf_read_addr;
					end
					else begin
						assign				pe_wbuf_read_req[n][m]        =   		pe_wbuf_read_req_frwrd[n][m-1];
						assign				pe_wbuf_read_addr[n][m]        =   		pe_wbuf_read_addr_frwrd[n][m-1];
					end
				end
				else begin
					assign				pe_wbuf_read_req[n][m]        =   		pe_wbuf_read_req_frwrd[n-1][m];
					assign				pe_wbuf_read_addr[n][m]        =   		pe_wbuf_read_addr_frwrd[n-1][m];
				end
				
				assign				pe_wbuf_write_data[n][m]        =   		wbuf_write_data_frwrd[n][m];
				
				if( m == 0) 
					assign				wbuf_write_data_in[n][m]        =   		wbuf_write_data[(n+1)*WGT_WIDTH-1: n*WGT_WIDTH];
				else
					assign				wbuf_write_data_in[n][m]        =   		wbuf_write_data_frwrd[n][m-1];
				
				register_sync #(WGT_WIDTH) wbuf_write_data_reg (clk, reset, wbuf_write_data_in[n][m], wbuf_write_data_frwrd[n][m]);

				assign				pe_wbuf_write_addr[n][m]        =   		wbuf_write_addr_frwrd[n][m];
				
				if( m == 0) 
					assign				wbuf_write_addr_in[n][m]        =   		wbuf_write_addr[(n+1)*WBUF_ADDR_WIDTH-1:n*WBUF_ADDR_WIDTH];
				else
					assign				wbuf_write_addr_in[n][m]        =   		wbuf_write_addr_frwrd[n][m-1];
					
				register_sync #(WBUF_ADDR_WIDTH) wbuf_write_addr_reg (clk, reset, wbuf_write_addr_in[n][m], wbuf_write_addr_frwrd[n][m]);

				
				assign				pe_wbuf_write_req_en[n][m]        =   		wbuf_write_req_en_frwrd[n][m];
				
				if( m == 0) 
					assign				wbuf_write_req_en_in[n][m]        =   		wbuf_write_req[(n+1)*WBUF_REQ_WIDTH-1:n*WBUF_REQ_WIDTH];
				else
					assign				wbuf_write_req_en_in[n][m]        =   		wbuf_write_req_en_frwrd[n][m-1];
					
				register_sync #(WBUF_REQ_WIDTH) wbuf_write_req_reg (clk, reset, wbuf_write_req_en_in[n][m], wbuf_write_req_en_frwrd[n][m]);
				

				assign						pe_wbuf_write_req[n][m] =  pe_wbuf_write_req_en[n][m] == m + 1 ? 1 : 0;

				if( m == 0) 
					assign				pe_act_in[n][m]        =   		act_in_row[n];
				else
					assign				pe_act_in[n][m]        =   		pe_act_out[n][m-1];
				
				
				if( n == 0) 
					assign				part_sum_in[n][m]        =   		0;
				else
					assign				part_sum_in[n][m]        =   		part_sum_out[n-1][m];
				if( n == 0)
				    assign						systolic_out[(m+1)*PE_OUT_WIDTH-1:m*PE_OUT_WIDTH] 	= part_sum_out[ARRAY_N-1][m];
			
				pe #(
					.WMEM_ADDR_BITWIDTH													(WBUF_ADDR_WIDTH),
					.ACT_BITWIDTH														    (ACT_WIDTH),
					.WGT_BITWIDTH 														  (WGT_WIDTH),
					.SUM_IN_BITWIDTH 													  (PE_OUT_WIDTH),
					.INTER_BITWIDTH														  (PE_INTER_WIDTH),
					.TRUNCATION_MODE 													  (PE_TRUNC_MODE),
					.ACT_PIPELINE 														  (ACT_PIPELINE),
					.PE_M                                       (m),
					.PE_N                                       (n),
          .WBUF_DDR_BANDWIDTH			                    (WBUF_DDR_BANDWIDTH),
          .WBUF_READ_WIDTH                            (WBUF_READ_WIDTH),
          .WBUF_DEPTH                                 (WBUF_DEPTH),
          .WBUF_NUM_BANKS 			                      (WBUF_NUM_BANKS),
          .WBUF_READ_LATENCY_B                        (WBUF_READ_LATENCY_B),
          .WBUF_WRITE_WIDTH                           (WBUF_WRITE_WIDTH),
          .WBUF_MEMORY_SIZE                           (WBUF_MEMORY_SIZE),
          .WBUF_WRITE_ADDR_WIDTH                      (WBUF_WRITE_ADDR_WIDTH),
          .WBUF_READ_ADDR_WIDTH                       (WBUF_READ_ADDR_WIDTH)
				) pe_inst (
					.clk																(clk),
					.reset																(reset),
					.act_in 															(pe_act_in[n][m]),
					.sum_in																(part_sum_in[n][m]),
					.read_req_w_mem 													(pe_wbuf_read_req[n][m]),
					.r_addr_w_mem 														(pe_wbuf_read_addr[n][m]),
					.write_req_w_mem 													(pe_wbuf_write_req[n][m]),
					.w_addr_w_mem 														(pe_wbuf_write_addr[n][m]),
					.w_data_w_mem 														(pe_wbuf_write_data[n][m]),
					.read_req_w_mem_frwrd 												(pe_wbuf_read_req_frwrd[n][m]),
					.r_addr_w_mem_frwrd 												(pe_wbuf_read_addr_frwrd[n][m]),
					.act_out 															(pe_act_out[n][m]),
					.sum_out															(part_sum_out[n][m])
				);
				
				
			end	
			
			assign						act_in_row[n] 					=   ibuf_read_data[(n+1)*ACT_WIDTH-1:(n)*ACT_WIDTH];
		end
	endgenerate


//=========================================
// Systolic Array - End
//=========================================
//=========================================
// Accumulate logic
//=========================================

  genvar i;

  reg  [ OBUF_ADDR_WIDTH      -1 : 0 ]        prev_obuf_write_addr;

  always @(posedge clk)
  begin
    if (reset)
      prev_obuf_write_addr <= 0;
    else if (obuf_write_req)
      prev_obuf_write_addr <= obuf_write_addr;
  end

    localparam integer  ACC_INVALID                  = 0;
    localparam integer  ACC_VALID                    = 1;

  // If the current read address and the previous write address are the same, accumulate
    assign _addr_eq = (obuf_write_addr == prev_obuf_write_addr) && (obuf_write_req) && (acc_state_q != ACC_INVALID);
    wire acc_clear_dly1;
  register_sync #(1) acc_clear_dlyreg (clk, reset, acc_clear, acc_clear_dly1);
  always @(posedge clk)
  begin
    if (reset)
      addr_eq <= 1'b0;
    else
      addr_eq <= _addr_eq;
  end

  always @(*)
  begin
    acc_state_d = acc_state_q;
    case (acc_state_q)
      ACC_INVALID: begin
        if (obuf_write_req)
          acc_state_d = ACC_VALID;
      end
      ACC_VALID: begin
        if (acc_clear_dly1)
          acc_state_d = ACC_INVALID;
      end
    endcase
  end

  always @(posedge clk)
  begin
    if (reset)
      acc_state_q <= ACC_INVALID;
    else
      acc_state_q <= acc_state_d;
  end
//=========================================
// TODO: make the below implementations compatible with the generator.
// TODO: make sure the below part works.
  register_sync #(1) out_valid_delay (clk, reset, obuf_write_req, _systolic_out_valid[0]);
  
//  register_sync #(1) out_acc_delay (clk, reset, addr_eq && _systolic_out_valid, _acc[0]);
// Expecting this signal activates after 1 cycle
  assign 	_acc[0] = addr_eq && _systolic_out_valid;
// _acc needs to be delayed *N* cycles!
//  register_sync #(1) out_acc_delay (clk, reset, addr_eq, _acc[0]);
  generate
    for (i=1; i<ARRAY_N; i=i+1)
    begin: COL_ACC
      register_sync #(1) out_valid_delay (clk, reset, _acc[i-1], _acc[i]);
    end
    for (i=1; i<ARRAY_M; i=i+1)
    begin: ROW_ACC
       register_sync #(1) out_valid_delay (clk, reset, acc[i-1], acc[i]);
//    assign acc[i] = acc[i-1];
    end
  endgenerate
  assign acc[0] = _acc[ARRAY_N-1];
//  register_sync #(1) acc_delay (clk, reset, _acc[ARRAY_N-1], acc[0]);


  generate
    for (i=1; i<ARRAY_N; i=i+1)
    begin: COL_VALID_OUT
	  //
      register_sync #(1) out_valid_delay (clk, reset, _systolic_out_valid[i-1], _systolic_out_valid[i]);
    end
    for (i=1; i<ARRAY_M; i=i+1)
    begin: ROW_VALID_OUT
	    // when systolic_out_valid[M-1] gets 1, it shows that the output of last coloumn is ready
      register_sync #(1) out_valid_delay (clk, reset, systolic_out_valid[i-1], systolic_out_valid[i]);
    end
  endgenerate

    //when _systolic_out_valid[ARRAY_N-1]  gets 1, shows that the column pipeline
     // is done for the first coloumn and the first output is ready
    assign systolic_out_valid[0] = _systolic_out_valid[ARRAY_N-1];


  register_sync #(OBUF_ADDR_WIDTH) out_addr_delay (clk, reset, obuf_write_addr, _systolic_out_addr);
  register_sync #(OBUF_ADDR_WIDTH) in_addr_delay (clk, reset, obuf_read_addr, _systolic_in_addr);

//Done
// delaying the obuf_write_addr for *N* more cycles (1 cycle has been done above)
  generate
    for (i=0; i<ARRAY_N; i=i+1)
    begin: COL_ADDR_OUT
    wire [ OBUF_ADDR_WIDTH      -1 : 0 ]        prev_addr;
    wire [ OBUF_ADDR_WIDTH      -1 : 0 ]        next_addr;
      if (i==0)
    assign prev_addr = _systolic_out_addr;
      else
    assign prev_addr = COL_ADDR_OUT[i-1].next_addr;
      register_sync #(OBUF_ADDR_WIDTH) out_addr (clk, reset, prev_addr, next_addr);
    end
  endgenerate

  	// the obuf_write_addr is received as input, will be delayed *N+1* cycels and then it will be the output
    assign sys_obuf_write_addr[OBUF_ADDR_WIDTH -1 :0] = COL_ADDR_OUT[ARRAY_N-1].next_addr;
	
	generate
    for (i=1; i<ARRAY_M; i=i+1) begin
		register_sync #(OBUF_ADDR_WIDTH) obuf_write_addr (clk, reset,
	  									sys_obuf_write_addr[(i)*OBUF_ADDR_WIDTH-1:(i-1)*OBUF_ADDR_WIDTH],
	  									sys_obuf_write_addr[(i+1)*OBUF_ADDR_WIDTH-1:(i)*OBUF_ADDR_WIDTH]);
	end
	endgenerate

//Done
 // delaying the obuf_read_addr *N-1* more cycles (1 cycle has been done above)
 //TODO: make sure that it takes ONLY 1 cycle to read from obuf (>> check the obuf_wrapper)
  generate
    for (i=1; i<ARRAY_N ; i=i+1)
    begin: COL_ADDR_IN
    wire [ OBUF_ADDR_WIDTH      -1 : 0 ]        prev_addr;
    wire [ OBUF_ADDR_WIDTH      -1 : 0 ]        next_addr;
      if (i==1)
    assign prev_addr = _systolic_in_addr;
      else
    assign prev_addr = COL_ADDR_IN[i-1].next_addr;
      register_sync #(OBUF_ADDR_WIDTH) out_addr (clk, reset, prev_addr, next_addr);
      if(i == ARRAY_N-1)
        assign sys_obuf_read_addr[OBUF_ADDR_WIDTH -1 :0] = COL_ADDR_IN[ARRAY_N-1].next_addr;
    end
  endgenerate
  	// the obuf_read_addr is received as input, will be delayed *N-1* cycles and then it will be the output
    

	generate
    for (i=1; i<ARRAY_M; i=i+1) begin
		register_sync #(OBUF_ADDR_WIDTH) obuf_read_addr (clk, reset,
	  									sys_obuf_read_addr[(i)*OBUF_ADDR_WIDTH-1:(i-1)*OBUF_ADDR_WIDTH],
	  									sys_obuf_read_addr[(i+1)*OBUF_ADDR_WIDTH-1:(i)*OBUF_ADDR_WIDTH]);
	end
	endgenerate


  // the below part is also for delaying the bias_read_addr/req for *N-1* cycles (they are the input signals, then after N cycles
  // will be the output signals for bias read_addr/req)
  // Delay logic for bias reads
  // Done
//  register_sync #(BBUF_ADDR_WIDTH) bias_addr_delay (clk, reset, bias_read_addr, _bias_read_addr);
//  register_sync #(1) bias_req_delay (clk, reset, bias_read_req, _bias_read_req);


  	assign _bias_read_addr = bias_read_addr;
  	assign _bias_read_req = bias_read_req;
  generate
    for (i=1; i<ARRAY_N; i=i+1)
    begin: BBUF_COL_ADDR_IN
    wire [ BBUF_ADDR_WIDTH      -1 : 0 ]        prev_addr;
    wire [ BBUF_ADDR_WIDTH      -1 : 0 ]        next_addr;
    wire                                        prev_req;
    wire                                        next_req;
      if (i==1) begin
    assign prev_addr = _bias_read_addr;
    assign prev_req = _bias_read_req;
      end
      else begin
    assign prev_addr = BBUF_COL_ADDR_IN[i-1].next_addr;
    assign prev_req = BBUF_COL_ADDR_IN[i-1].next_req;
      end
      register_sync #(BBUF_ADDR_WIDTH) out_addr (clk, reset, prev_addr, next_addr);
      register_sync #(1) out_req (clk, reset, prev_req, next_req);
    end
  endgenerate
    assign sys_bias_read_addr[BBUF_ADDR_WIDTH-1:0] = BBUF_COL_ADDR_IN[ARRAY_N-1].next_addr;
    assign sys_bias_read_req[0] = BBUF_COL_ADDR_IN[ARRAY_N-1].next_req;
 
	generate
    for (i=1; i<ARRAY_M; i=i+1) begin
		register_sync #(1) bias_req (clk, reset, sys_bias_read_req[i-1], sys_bias_read_req[i]);

		register_sync #(BBUF_ADDR_WIDTH) bias_addr (clk, reset,
	  									sys_bias_read_addr[i*BBUF_ADDR_WIDTH-1:(i-1)*BBUF_ADDR_WIDTH],
	  									sys_bias_read_addr[(i+1)*BBUF_ADDR_WIDTH-1:(i)*BBUF_ADDR_WIDTH]);
	end
	endgenerate




  
  wire  [ ARRAY_N           -1: 0]              _sys_ibuf_read_req_out;
  wire  [ ARRAY_N*IBUF_ADDR_WIDTH -1: 0]        _sys_ibuf_read_addr_out;
  
  assign sys_ibuf_read_addr = _sys_ibuf_read_addr_out;
  assign sys_ibuf_read_req = _sys_ibuf_read_req_out;
  
  assign _sys_ibuf_read_req_out[0] = ibuf_read_req_q;
  assign _sys_ibuf_read_addr_out[IBUF_ADDR_WIDTH -1:0] = ibuf_read_addr_q;
  
  
  generate
      for (i=0; i<ARRAY_N-1; i=i+1) begin
        register_sync #(IBUF_ADDR_WIDTH) out_addr_ibuf (clk, reset, _sys_ibuf_read_addr_out[(i+1)*IBUF_ADDR_WIDTH-1:i*IBUF_ADDR_WIDTH],
                                                                    _sys_ibuf_read_addr_out[(i+2)*IBUF_ADDR_WIDTH-1:(i+1)*IBUF_ADDR_WIDTH]);
        register_sync #(1) out_req_ibuf (clk, reset, _sys_ibuf_read_req_out[i], _sys_ibuf_read_req_out[i+1]);           
      end
  endgenerate
  


  //=========================================


    assign obuf_write_data = accumulator_out;

// TODO: Fix this part with the proper signal; probably bias_prev_sw! 

 ////////////////////////////////////////////////////////////

//
//  register_sync #(1) acc_out_vld (clk, reset, systolic_out_valid[0], acc_out_valid);
//    wire                                        _sys_obuf_write_req;
//  register_sync #(1) sys_obuf_write_req_delay (clk, reset, acc_out_valid, _sys_obuf_write_req);

  // after N+1 cycles we can write to obuf!

	generate
    for (i=0; i<ARRAY_M; i=i+1) begin
		register_sync #(1) sys_obuf_write_req_delay (clk, reset, systolic_out_valid[i], sys_obuf_write_req[i]);

	end
	endgenerate


  // assign sys_obuf_write_req = acc_out_valid;


// TODO: Figure out this part
//    assign acc_out_valid_[0] = acc_out_valid && ~addr_eq;
//    assign acc_out_valid_all = |acc_out_valid_;


// We will need this part if we want to pipeline the inputs!
// cycle by cycle the output of other coloumns accumulators will be vaild
//generate
//for (i=1; i<ARRAY_M; i=i+1)
//begin: OBUF_VALID_OUT
//      register_sync #(1) obuf_output_delay (clk, reset, acc_out_valid_[i-1], acc_out_valid_[i]);
//end
//endgenerate
// the read_req needs to be activated after (N-1) cycles, bias_prev_sw = 1, acc = 0,
// I am using the mentioned signals at the cycle (N).
// Changed systolic_out_valid[0] ==>>>  
//    assign sys_obuf_read_req[0] = _systolic_out_valid[ARRAY_N-2] && col_bias_sw[ARRAY_N-1] && !_acc[ARRAY_N-2];
    wire                            _sys_obuf_read_req_en;
    // rohan: The || condition below is needed because otherwise the partial sum for the last OC is not getting added, as we are reading OBUF only for N-1 times otherwise.
    //assign sys_obuf_read_req[0] = _systolic_out_valid[ARRAY_N-2] && col_bias_sw[ARRAY_N-2] && !_acc[ARRAY_N-2] || _systolic_out_valid[ARRAY_N-1] && col_bias_sw[ARRAY_N-1] && !_acc[ARRAY_N-1];
    assign sys_obuf_read_req[0] = _systolic_out_valid[ARRAY_N-2] && col_bias_sw[ARRAY_N-1] && !_acc[ARRAY_N-2];
    // 1 cycle delay due to latching the addr and addr_v of the compute_addr_gen. The obuf_read_req needs to be also delayed for 1 cycle
//    register_sync #(1) sys_obuf_read_req_en_delay (clk, reset, _sys_obuf_read_req_en, sys_obuf_read_req[0]);
    
	generate
    for (i=1; i<ARRAY_M; i=i+1) begin
		register_sync #(1) sys_obuf_read_req_delay (clk, reset, sys_obuf_read_req[i-1], sys_obuf_read_req[i]);
	end
	endgenerate

   
   wire                         _bias_prev_sw_s;              
   register_sync #(1) bias_prev_sw_delay (clk, reset, bias_prev_sw, _bias_prev_sw_s);
   
   // adding one more delay cycle due to latching the wlaker address and add_v
   wire                                 _bias_prev_sw_s_delay;
   register_sync #(1) bias_prev_sw_delay_additional (clk, reset, _bias_prev_sw_s, _bias_prev_sw_s_delay);
   assign col_bias_sw[0] = _bias_prev_sw_s_delay;
//  register_sync #(1) row_bias_sel_delay (clk, reset, bias_prev_sw, col_bias_sw[0]);
  // 1 cycle delay
  // rohan: this leads to setting _bias_sel one cycle before it should be for one of the tiles, which is weird.
  // revert back after testing.

  // Rohan 14.10
  //register_sync #(1) col_bias_sel_delay (clk, reset, col_bias_sw[ARRAY_N-2] || col_bias_sw[ARRAY_N-1], _bias_sel);
  register_sync #(1) col_bias_sel_delay (clk, reset, col_bias_sw[ARRAY_N-1], _bias_sel);
  //register_sync #(1) col_bias_sel_delay (clk, reset, col_bias_sw[ARRAY_N-2], _bias_sel);
//  register_sync #(1) _bias_sel_delay (clk, reset, _bias_sel, bias_sel[0]);
  	assign bias_sel[0] = _bias_sel;
// delaying for N-1 cycles (N cycles in total)
  generate
    for (i=1; i<ARRAY_N; i=i+1)
    begin: ADD_SRC_SEL_COL
      register_sync #(1) col_bias_sel_delay (clk, reset, col_bias_sw[i-1], col_bias_sw[i]);
    end
// We will need this part if we want to pipeline the inputs
    for (i=1; i<ARRAY_M; i=i+1)
    begin: ADD_SRC_SEL
      register_sync #(1) bias_sel_delay (clk, reset, bias_sel[i-1], bias_sel[i]);
//    assign bias_sel[i] = bias_sel[i-1];
    end
  endgenerate

    wire [ ARRAY_M              -1 : 0 ]        acc_enable;
  
//    assign acc_enable[0] = _sys_obuf_write_req;
    
//    wire                    acc_enable_delay;
//    register_sync #(1) acc_enable_deleay_reg (clk, reset, systolic_out_valid[0], acc_enable_delay);
    assign acc_enable[0] = systolic_out_valid[0];
  
generate
for (i=1; i<ARRAY_M; i=i+1)
begin: ACC_ENABLE
      register_sync #(1) acc_enable_delay (clk, reset, acc_enable[i-1], acc_enable[i]);
//    assign acc_enable[i] = acc_enable[i-1];
end
endgenerate

//=========================================



//=========================================
// Accumulator
//=========================================
generate
for (i=0; i<ARRAY_M; i=i+1)
begin: ACCUMULATOR

    wire [ ACC_WIDTH            -1 : 0 ]        obuf_in;
    wire [ PE_OUT_WIDTH         -1 : 0 ]        sys_col_out;
    wire [ ACC_WIDTH            -1 : 0 ]        acc_out_q;

    wire                                        local_acc;
    wire                                        local_bias_sel;
    wire                                        local_acc_enable;

    assign local_acc_enable = acc_enable[i];
    assign local_acc = acc[i];
    assign local_bias_sel = bias_sel[i];

    wire [ ACC_WIDTH            -1 : 0 ]        local_bias_data;
    wire [ ACC_WIDTH            -1 : 0 ]        local_obuf_data;

    assign local_bias_data = $signed(bbuf_read_data[BIAS_WIDTH*i+:BIAS_WIDTH]);
    assign local_obuf_data = obuf_read_data[ACC_WIDTH*i+:ACC_WIDTH];

    assign obuf_in = ~local_bias_sel ? local_bias_data : local_obuf_data;
    assign accumulator_out[ACC_WIDTH*i+:ACC_WIDTH] = acc_out_q;
    assign sys_col_out = systolic_out[PE_OUT_WIDTH*i+:PE_OUT_WIDTH];

  wire signed [ ACC_WIDTH    -1 : 0 ]        add_in;
    assign add_in = local_acc ? acc_out_q : obuf_in;
	

    signed_adder #(
    .DTYPE                          ( DTYPE                          ),
    .REGISTER_OUTPUT                ( "TRUE"                         ),
    .IN1_WIDTH                      ( PE_OUT_WIDTH                   ),
    .IN2_WIDTH                      ( ACC_WIDTH                      ),
    .OUT_WIDTH                      ( ACC_WIDTH                      )
    ) adder_inst (
    .clk                            ( clk                            ),  // input
    .reset                          ( reset                          ),  // input
    .enable                         ( local_acc_enable               ),
    .a                              ( sys_col_out                    ),
    .b                              ( add_in                         ),
    .out                            ( acc_out_q                      )
      );
end
endgenerate
//=========================================

`ifdef COCOTB_SIM
  initial begin
    $dumpfile("systolic_array.vcd");
    $dumpvars(0, systolic_array);
  end
`endif

endmodule




































