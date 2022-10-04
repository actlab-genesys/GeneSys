//
// Instruction Memory

`timescale 1ns/1ps
module instruction_memory
#(
  // Instructions
    parameter integer  NUM_INST_IN                  = 2,
    parameter integer  INST_DATA_WIDTH              = 32,
    parameter integer  INST_ADDR_WIDTH              = 10,
    parameter integer  MULTIPLE_MEMORIES            = 1
    
)
(
  // clk, reset
    input  wire                                         clk,
    input  wire                                         reset,
	
	input  wire											start,
  // Decoder <- imem
    input  wire                                         imem_rd_req,
    input  wire  [ INST_ADDR_WIDTH      -1 : 0 ]        imem_rd_addr,
	input  wire											imem_rd_block_done,
	output wire											imem_block_ready,
		
    output wire  [ INST_DATA_WIDTH      -1 : 0 ]        imem_rd_data,
    output reg  								        imem_rd_valid,
	
	// TO/FROM AXI interface
	output reg											imem_wr_start,
	input  wire											imem_wr_done,
	
	input  wire											imem_wr_data_valid,
	input  wire	 [ NUM_INST_IN*INST_DATA_WIDTH-1 : 0 ]		imem_wr_data
);

//=============================================================
// Localparams
//=============================================================
	localparam integer  STATE_W						 = 2;
  // States
    localparam integer  IMEM_IDLE                    = 0;
    localparam integer  IMEM_WR_WAIT                 = 1;
    localparam integer  IMEM_WR_DATA                 = 2;
    localparam integer  IMEM_WR_DONE                 = 3;
    localparam integer  IMEM_RD_WAIT                 = 1;
    localparam integer  IMEM_RD_DATA                 = 2;
    localparam integer  IMEM_RD_DONE                 = 3;
	
	localparam integer  INST_MEM_ADDR_WIDTH 	     = INST_ADDR_WIDTH + 'd1;
	localparam MEM_MUX_SEL_BIT_WIDTH = $clog2(NUM_INST_IN);
	localparam INST_MEM_IN_ADDR_WIDTH = INST_MEM_ADDR_WIDTH - MEM_MUX_SEL_BIT_WIDTH;
//=============================================================

//=============================================================
// Wires/Regs
//=============================================================
	reg [STATE_W-1:0] imem_wr_state_d, imem_wr_state_q, imem_rd_state_d, imem_rd_state_q;
	wire [INST_MEM_ADDR_WIDTH-1:0] imem_rd_addr_final;
  wire [MEM_MUX_SEL_BIT_WIDTH-1:0] imem_rd_addr_final_delay;
	wire [INST_MEM_ADDR_WIDTH-MEM_MUX_SEL_BIT_WIDTH-1:0] imem_wr_addr_final;
	reg [INST_ADDR_WIDTH-MEM_MUX_SEL_BIT_WIDTH-1:0] imem_wr_addr, imem_wr_addr_max;
	
	reg [1:0] imem_not_empty;
	reg imem_wr_buf, imem_rd_buf, imem_wr_req, imem_rd_start;
	
	//assign imem_block_ready = |imem_not_empty ;
	assign imem_block_ready = ((imem_rd_addr[INST_ADDR_WIDTH-1:MEM_MUX_SEL_BIT_WIDTH] == (imem_wr_addr_max-1)) || (imem_wr_addr_max==0) )?0:1 ;
//=============================================================
// FSM
//=============================================================
  always @(*)
  begin: WRITE_FSM
    imem_wr_state_d = imem_wr_state_q;
    case(imem_wr_state_q)
      IMEM_IDLE: begin
        if (start)
        begin
          imem_wr_state_d = IMEM_WR_WAIT;
        end
      end
	  IMEM_WR_WAIT: begin
        if (imem_wr_req )
        begin
          imem_wr_state_d = IMEM_WR_DATA;
        end
      end
      IMEM_WR_DATA: begin
        if (imem_wr_done)
          imem_wr_state_d = IMEM_WR_DONE;
      end
	  IMEM_WR_DONE: begin
        imem_wr_state_d = IMEM_WR_WAIT;
      end
    endcase
  end

  always @(*)
  begin: READ_FSM
    imem_rd_state_d = imem_rd_state_q;
    case(imem_rd_state_q)
      IMEM_IDLE: begin
        if (start)
        begin
          imem_rd_state_d = IMEM_RD_WAIT;
        end
      end
	  IMEM_RD_WAIT: begin
        if ( imem_rd_start )
        begin
          imem_rd_state_d = IMEM_RD_DATA;
        end
      end
      IMEM_RD_DATA: begin
        if (imem_rd_block_done)
          imem_rd_state_d = IMEM_RD_DONE;
      end
	  IMEM_RD_DONE: begin
        imem_rd_state_d = IMEM_RD_WAIT;
      end
    endcase
  end
  
  always @(posedge clk)
  begin
    if (reset) begin
      imem_not_empty <= 2'b00;
	  imem_wr_buf <= 1'b0;
	  imem_rd_buf <= 1'b0;
	  imem_wr_req <= 1'b0;
	  imem_rd_start <= 1'b0;
    end
	else begin
		if ( ~imem_wr_buf && imem_wr_state_q == IMEM_WR_DONE)
		  imem_not_empty[0] <= 1'b1;
		else if( ~imem_rd_buf && imem_rd_state_q == IMEM_RD_DONE)
		  imem_not_empty[0] <= 1'b0;
		
		if ( imem_wr_buf && imem_wr_state_q == IMEM_WR_DONE)
		  imem_not_empty[1] <= 1'b1;
		else if( imem_rd_buf && imem_rd_state_q == IMEM_RD_DONE)
		  imem_not_empty[1] <= 1'b0;
		
		if( imem_wr_state_q == IMEM_WR_DONE) begin
		  imem_wr_buf <= ~imem_wr_buf;
		  imem_wr_req <= ~imem_not_empty[~imem_wr_buf];
		end 
		else begin
		  imem_wr_buf <= imem_wr_buf;
		  imem_wr_req <= ~imem_not_empty[imem_wr_buf];
		end 
		
		if( imem_rd_state_q == IMEM_RD_DONE) begin
		//  imem_rd_buf <= ~imem_rd_buf;
		//  imem_rd_start <= imem_not_empty[~imem_rd_buf];
		    imem_rd_start <= imem_block_ready;
		end 
		else begin
		  imem_rd_buf <= imem_rd_buf;
		  imem_rd_start <= imem_not_empty[imem_rd_buf];
		end 
	end
  end
  	
  
  always @(posedge clk)
  begin
    if (reset) begin
      imem_rd_state_q <= IMEM_IDLE;
      imem_wr_state_q <= IMEM_IDLE;
    end
	else begin
      imem_rd_state_q <= imem_rd_state_d;
      imem_wr_state_q <= imem_wr_state_d;
	end
  end

  always @(posedge clk)
  begin
    if (reset)
      imem_rd_valid <= 0;
    else
      imem_rd_valid <= imem_rd_req && (imem_rd_state_q == IMEM_RD_DATA);
  end

  always @(posedge clk)
  begin
    if (reset)
      imem_wr_start <= 0;
    else
      imem_wr_start <= (imem_wr_state_q != IMEM_WR_DATA) && (imem_wr_state_d == IMEM_WR_DATA);
  end

  always @(posedge clk)
  begin
    if (reset) begin
      imem_wr_addr <= 0;
      imem_wr_addr_max <= 0;
    end
    else if( imem_wr_state_q == IMEM_WR_DONE) begin
	  imem_wr_addr <= 0;
	  imem_wr_addr_max <= imem_wr_addr ;
	end
	else if( imem_wr_data_valid) begin
      imem_wr_addr <= imem_wr_addr + 'd1;
     // imem_wr_addr_max <= imem_wr_addr  + 'd1 ;
    end
  end


//=============================================================
assign  imem_rd_addr_final = {imem_rd_buf,imem_rd_addr};
assign  imem_wr_addr_final = {imem_wr_buf,imem_wr_addr};


generate
if ( MULTIPLE_MEMORIES == 0 ) begin
    ram_asymmetric
        #(
          .DATA_WIDTH(INST_DATA_WIDTH),
          .ADDR_WIDTH_IN(INST_MEM_IN_ADDR_WIDTH ),
          .ADDR_WIDTH_OUT(INST_MEM_ADDR_WIDTH ),
		  .BITWIDTH_RATIO(NUM_INST_IN)
        ) instruction_memory
        (
          .clk		   (    clk                 ),
          .reset       (	reset               ),
    
          .read_req    (    imem_rd_req	        ),
          .read_addr   (	imem_rd_addr_final  ),
          .read_data   (	imem_rd_data        ),
    
          .write_req   (	imem_wr_data_valid  ),
          .write_addr  (	imem_wr_addr_final  ),
          .write_data  (	imem_wr_data        )
        );
end
else begin
    wire [INST_DATA_WIDTH-1:0] imem_rd_data_w[0:NUM_INST_IN-1];
    
    for (genvar i = 0 ; i < NUM_INST_IN ; i=i+1) begin
        ram
            #(
              .DATA_WIDTH(INST_DATA_WIDTH),
              .ADDR_WIDTH(INST_MEM_IN_ADDR_WIDTH )
            ) instruction_memory
            (
              .clk		   (    clk                 ),
              .reset       (	reset               ),
        
              .read_req    (    imem_rd_req	        ),
              .read_addr   (	imem_rd_addr_final[INST_MEM_ADDR_WIDTH-1:MEM_MUX_SEL_BIT_WIDTH]  ),
              .read_data   (	imem_rd_data_w[i]        ),
        
              .write_req   (	imem_wr_data_valid  ),
              .write_addr  (	imem_wr_addr_final  ),
              .write_data  (	imem_wr_data[INST_DATA_WIDTH*i+:INST_DATA_WIDTH]        )
            );
     end
     
     register_sync #(MEM_MUX_SEL_BIT_WIDTH) imem_rd_addr_final_reg (clk, reset, imem_rd_addr_final[MEM_MUX_SEL_BIT_WIDTH-1:0], imem_rd_addr_final_delay);
     assign imem_rd_data = imem_rd_data_w[imem_rd_addr_final_delay];
end
endgenerate

//=============================================================
endmodule
