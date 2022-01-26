//
// Processing Element, the input pipelining can be activated for both inputs and weights
//
// Soroush Ghodrati
// (soghodra@eng.ucsd.edu)

`timescale 1ns/1ps

module pe #(
	parameter					WMEM_ADDR_BITWIDTH				= 8,
	parameter					ACT_BITWIDTH					= 8,
	parameter					WGT_BITWIDTH					= 8,
	parameter					SUM_IN_BITWIDTH					= 16,
	parameter					INTER_BITWIDTH					= 17,
	parameter					TRUNCATION_MODE					= "MSB",
	parameter					ACT_PIPELINE					= "True",
	parameter                   PE_M                            = 0,
	parameter                   PE_N                            = 0,
	parameter					SUM_OUT_BITWIDTH				= SUM_IN_BITWIDTH,
	parameter					WBUF_DDR_BANDWIDTH		    	= 512,
	parameter integer 			WBUF_READ_WIDTH                 = 8,
    parameter integer 			WBUF_DEPTH                  	= 64,
	parameter					WBUF_NUM_BANKS 					= 64,
    parameter integer 			WBUF_READ_LATENCY_B             = 1,
    parameter integer 			WBUF_WRITE_WIDTH                = 8,
    parameter integer 			WBUF_MEMORY_SIZE                = 256,
    parameter integer 			WBUF_WRITE_ADDR_WIDTH           = 8,  
    parameter integer 			WBUF_READ_ADDR_WIDTH            = 8

)(
	input														clk,
	input														reset,
	input						[ACT_BITWIDTH      -1: 0]		act_in,
	input						[SUM_IN_BITWIDTH   -1: 0]		sum_in,
	input														read_req_w_mem,
	input						[WBUF_READ_ADDR_WIDTH-1: 0]		r_addr_w_mem,
	input														write_req_w_mem,
	input						[WBUF_WRITE_ADDR_WIDTH-1: 0]	w_addr_w_mem,
	input						[WBUF_WRITE_WIDTH      -1: 0]	w_data_w_mem,
	output														read_req_w_mem_frwrd,
	output						[WBUF_READ_ADDR_WIDTH-1: 0]		r_addr_w_mem_frwrd,
	output						[ACT_BITWIDTH	   -1: 0]		act_out,
	output						[SUM_OUT_BITWIDTH  -1: 0]		sum_out
);
	
	wire						[WBUF_READ_WIDTH	  -1: 0]	wgt_read;
	

    weight_buffer #(
        .DDR_BANDWIDTH              (WBUF_DDR_BANDWIDTH),
        .NUM_BANKS                  (WBUF_NUM_BANKS),
        .DATA_WIDTH                 (WGT_BITWIDTH),
        .READ_WIDTH                 (WBUF_READ_WIDTH),
        .BUFFER_DEPTH               (WBUF_DEPTH),
		.READ_LATENCY_B  			(WBUF_READ_LATENCY_B),
		.WRITE_WIDTH     			(WBUF_WRITE_WIDTH),
		.MEMORY_SIZE     			(WBUF_MEMORY_SIZE),
		.WRITE_ADDR_WIDTH			(WBUF_WRITE_ADDR_WIDTH),
		.READ_ADDR_WIDTH 			(WBUF_READ_ADDR_WIDTH)


	) wbuf_bank (
        .clk                        ( clk                           ),
        .reset                      ( reset                         ),

        .bs_read_req                ( read_req_w_mem             ),
        .bs_read_addr               ( r_addr_w_mem               ),
        .bs_read_data               ( wgt_read                   ),

        .bs_write_req               ( write_req_w_mem            ),
        .bs_write_addr              ( w_addr_w_mem               ),
        .bs_write_data              ( w_data_w_mem               )
    );

//	
// weight-stationary logic	

//	wire						[WGT_BITWIDTH	  -1: 0]		_wgt_read_reg;
//	reg						    [WGT_BITWIDTH	  -1: 0]		_wgt_read;
//	
//	register #(
//		.BIT_WIDTH										(WGT_BITWIDTH)
//	) register_ws(
//		.clk											(clk),
//		.reset											(reset_ws_reg),
//		.wrt_en											(ws_en),
//		.data_in										(_wgt_read_),
//		.data_out 										(_wgt_read_reg)	
//		);
//	always @ (*) begin	
//		if (ws_en == 0) begin
//			_wgt_read	=	_wgt_read_;
//		end
//		// if ws, at the first cycle the data directs to the macc logic,
//		//but for the rest cycles will be read from the register
//
//		if (ws_en == 1 && ws_mux == 1) begin			
//			_wgt_read	=	_wgt_read_;
//		end
//		
//		if (ws_en == 1 && ws_mux == 0) begin
//			_wgt_read	=	_wgt_read_reg;
//		end 
//	end
//	
//	
	
	
	wire						[INTER_BITWIDTH   -1: 0]		_macc_out;
	
	macc #(
		.ACT_BITWIDTH											(ACT_BITWIDTH),
		.WGT_BITWIDTH											(WGT_BITWIDTH),
		.SUM_IN_BITWIDTH										(SUM_IN_BITWIDTH),
		.INTER_BITWIDTH											(INTER_BITWIDTH)
	) macc_inst (
		.a_in													(act_in),
		.w_in													(wgt_read),
		.sum_in													(sum_in),
		.out													(_macc_out)
	);
		
	wire						[SUM_OUT_BITWIDTH -1: 0]		_truncator_out;
	
	truncator #(
		.TRUNCATION_MODE										(TRUNCATION_MODE),
		.DATA_IN_BITWIDTH										(INTER_BITWIDTH),
		.DATA_OUT_BITWIDTH										(SUM_OUT_BITWIDTH)
	) truncator_inst (
		.data_in												(_macc_out),
		.data_out												(_truncator_out)
	);
	


	if (ACT_PIPELINE == "True")
	begin	
	register_sync #(
		.WIDTH 													(ACT_BITWIDTH)
	) register_act_out(
		.clk													(clk),
		.reset 													(reset),
		.in 													(act_in),
		.out 													(act_out)
		);
		
	register_sync #(
		.WIDTH 													(1)
	) register_wmem_rd_req_frwrd(
		.clk													(clk),
		.reset 													(reset),
		.in 													(read_req_w_mem),
		.out 													(read_req_w_mem_frwrd)
		);
	
	register_sync #(
		.WIDTH 													(WBUF_READ_ADDR_WIDTH)
	) register_wmem_rd_addr_frwrd(
		.clk													(clk),
		.reset 													(reset),
		.in 													(r_addr_w_mem),
		.out 													(r_addr_w_mem_frwrd)
		);	
			
	end
	else //if (ACT_PIPELINE == "False")
	begin
		assign act_out = act_in;
		
		if(PE_M == 0) begin
		    register_sync #(
                .WIDTH 													(1)
            ) register_wmem_rd_req_frwrd(
                .clk													(clk),
                .reset 													(reset),
                .in 													(read_req_w_mem),
                .out 													(read_req_w_mem_frwrd)
                );
            
            register_sync #(
                .WIDTH 													(WBUF_READ_ADDR_WIDTH)
            ) register_wmem_rd_addr_frwrd(
                .clk													(clk),
                .reset 													(reset),
                .in 													(r_addr_w_mem),
                .out 													(r_addr_w_mem_frwrd)
                );	
		end
		else begin
            assign read_req_w_mem_frwrd = read_req_w_mem;
            assign r_addr_w_mem_frwrd = r_addr_w_mem;
        end
	end
	register_sync #(
		.WIDTH													(SUM_OUT_BITWIDTH)
	) register_out(
		.clk													(clk),
		.reset													(reset),
		.in														(_truncator_out),
		.out													(sum_out)	
	);

	
endmodule
