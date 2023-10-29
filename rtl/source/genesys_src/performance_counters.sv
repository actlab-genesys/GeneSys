// Performance Counter

`timescale 1ns/1ps
module performance_counters #(
    parameter integer  PC_DATA_WIDTH                = 64,
    parameter integer  AXI_DATA_WIDTH               = 512,
    parameter integer  AXI_ADDR_WIDTH               = 64
) (
    input  wire                                         clk,
    input  wire                                         reset,
    // controller
    input wire                                          pc_start,
    input wire [PC_DATA_WIDTH - 1 : 0]                  pc_decode,
    input wire [PC_DATA_WIDTH - 1 : 0]                  pc_end2end,
    input wire [PC_DATA_WIDTH - 1 : 0]                  pc_sys_tot_compute,
    input wire [PC_DATA_WIDTH - 1 : 0]                  pc_simd_tot_compute,
    input wire [PC_DATA_WIDTH - 1 : 0]                  pc_num_tiles,
    
    // ibuf
    input wire [PC_DATA_WIDTH - 1 : 0]                 pc_ibuf_num_tiles,
    input wire [PC_DATA_WIDTH - 1 : 0]                 pc_ibuf_tot_cycles, 
    input wire [PC_DATA_WIDTH - 1 : 0]                 pc_ibuf_tot_requests,
    input wire [PC_DATA_WIDTH - 1 : 0]                 pc_ibuf_size_per_requests, 
    
    // obuf
    input wire [PC_DATA_WIDTH - 1 : 0]                 pc_obuf_ld_num_tiles,
    input wire [PC_DATA_WIDTH - 1 : 0]                 pc_obuf_ld_tot_cycles, 
    input wire [PC_DATA_WIDTH - 1 : 0]                 pc_obuf_ld_tot_requests,
    input wire [PC_DATA_WIDTH - 1 : 0]                 pc_obuf_ld_size_per_requests,
    input wire [PC_DATA_WIDTH - 1 : 0]                 pc_obuf_st_num_tiles,
    input wire [PC_DATA_WIDTH - 1 : 0]                 pc_obuf_st_tot_cycles, 
    input wire [PC_DATA_WIDTH - 1 : 0]                 pc_obuf_st_tot_requests,
    input wire [PC_DATA_WIDTH - 1 : 0]                 pc_obuf_st_size_per_requests,    
    
    // parambuf
    input wire [PC_DATA_WIDTH - 1 : 0]                 pc_wbuf_num_tiles,
    input wire [PC_DATA_WIDTH - 1 : 0]                 pc_wbuf_tot_cycles, 
    input wire [PC_DATA_WIDTH - 1 : 0]                 pc_wbuf_tot_requests,
    input wire [PC_DATA_WIDTH - 1 : 0]                 pc_wbuf_size_per_requests, 
    input wire [PC_DATA_WIDTH - 1 : 0]                 pc_bbuf_num_tiles,
    input wire [PC_DATA_WIDTH - 1 : 0]                 pc_bbuf_tot_cycles, 
    input wire [PC_DATA_WIDTH - 1 : 0]                 pc_bbuf_tot_requests,
    input wire [PC_DATA_WIDTH - 1 : 0]                 pc_bbuf_size_per_requests,
    
    // vmem1
    input wire [PC_DATA_WIDTH - 1 : 0]                 pc_vmem1_ld_num_tiles,
    input wire [PC_DATA_WIDTH - 1 : 0]                 pc_vmem1_ld_tot_cycles, 
    input wire [PC_DATA_WIDTH - 1 : 0]                 pc_vmem1_ld_tot_requests,
    input wire [PC_DATA_WIDTH - 1 : 0]                 pc_vmem1_ld_size_per_requests,
    input wire [PC_DATA_WIDTH - 1 : 0]                 pc_vmem1_st_num_tiles,
    input wire [PC_DATA_WIDTH - 1 : 0]                 pc_vmem1_st_tot_cycles, 
    input wire [PC_DATA_WIDTH - 1 : 0]                 pc_vmem1_st_tot_requests,
    input wire [PC_DATA_WIDTH - 1 : 0]                 pc_vmem1_st_size_per_requests, 

    // vmem1
    input wire [PC_DATA_WIDTH - 1 : 0]                 pc_vmem2_ld_num_tiles,
    input wire [PC_DATA_WIDTH - 1 : 0]                 pc_vmem2_ld_tot_cycles, 
    input wire [PC_DATA_WIDTH - 1 : 0]                 pc_vmem2_ld_tot_requests,
    input wire [PC_DATA_WIDTH - 1 : 0]                 pc_vmem2_ld_size_per_requests,
    input wire [PC_DATA_WIDTH - 1 : 0]                 pc_vmem2_st_num_tiles,
    input wire [PC_DATA_WIDTH - 1 : 0]                 pc_vmem2_st_tot_cycles, 
    input wire [PC_DATA_WIDTH - 1 : 0]                 pc_vmem2_st_tot_requests,
    input wire [PC_DATA_WIDTH - 1 : 0]                 pc_vmem2_st_size_per_requests, 

    // AXI
    input wire [AXI_ADDR_WIDTH - 1 : 0]                axi_addr,
    input wire                                         axi_awready,
    input wire                                         axi_wready,
    input wire                                         axi_done,
    output wire                                        pc_done,
    output reg [AXI_ADDR_WIDTH - 1 : 0]                axi_st_addr,
    output wire                                        axi_st_addr_v,
    output wire [AXI_DATA_WIDTH-1 : 0]                 axi_st_size,
    
    output reg [AXI_DATA_WIDTH - 1 : 0]                axi_st_data,
    output reg [AXI_DATA_WIDTH - 1 : 0]                axi_st_data_v,
    input wire                                         imem_bvalid

);

  enum bit [3:0] {
        IDLE                    = 0,
        PC_AXI_REQ          = 1,
        PC_WRITE_DDR_CONTROLLER = 2,
        PC_WRITE_DDR_IBUF       = 3,
        PC_WRITE_DDR_OBUF       = 4,
        PC_WRITE_DDR_PARAMBUF   = 5,
        PC_WRITE_DDR_VMEM1      = 6,
        PC_WRITE_DDR_VMEM2      = 7,
        PC_DONE_WAIT            = 8,
        PC_DONE                 = 9
  } pc_state_d, pc_state_q;


    wire [AXI_DATA_WIDTH-1 : 0] pc_controller;
    wire [AXI_DATA_WIDTH-1 : 0] pc_ibuf;
    wire [AXI_DATA_WIDTH-1 : 0] pc_obuf;
    wire [AXI_DATA_WIDTH-1 : 0] pc_parambuf;
    wire [AXI_DATA_WIDTH-1 : 0] pc_vmem1;
    wire [AXI_DATA_WIDTH-1 : 0] pc_vmem2;
    reg                         axi_req_en;
    reg                         axi_wdata_v;
     
    reg 			counter ;
    always @ (posedge clk) begin 
	if (reset) begin
	    counter <= 0 ;
	end
        else if (pc_state_d == IDLE && pc_state_q == PC_DONE) begin
	    counter = counter + 1;
	end
    end

    always @ (posedge clk) begin
        if (reset)
            axi_st_addr <= 0;
        else
            axi_st_addr <= axi_addr + (counter * 64'd384) ;
    end
    assign axi_st_addr_v = pc_state_q == PC_WRITE_DDR_VMEM2 && pc_state_d == PC_AXI_REQ; 

    assign pc_controller = {pc_decode, pc_end2end, pc_sys_tot_compute, pc_simd_tot_compute, pc_num_tiles};

    assign pc_ibuf = {pc_ibuf_num_tiles, pc_ibuf_tot_cycles, pc_ibuf_tot_requests, pc_ibuf_size_per_requests};
    
    assign pc_obuf = { pc_obuf_ld_num_tiles, pc_obuf_ld_tot_cycles,  pc_obuf_ld_tot_requests, 
                      pc_obuf_ld_size_per_requests, pc_obuf_st_num_tiles, pc_obuf_st_tot_cycles,  
                      pc_obuf_st_tot_requests, pc_obuf_st_size_per_requests};
    
    assign pc_parambuf = { pc_wbuf_num_tiles,pc_wbuf_tot_cycles, pc_wbuf_tot_requests,pc_wbuf_size_per_requests, 
                           pc_bbuf_num_tiles,pc_bbuf_tot_cycles, pc_bbuf_tot_requests,pc_bbuf_size_per_requests};
    
    assign pc_vmem1 = { pc_vmem1_ld_num_tiles,pc_vmem1_ld_tot_cycles, pc_vmem1_ld_tot_requests,
                        pc_vmem1_ld_size_per_requests,pc_vmem1_st_num_tiles,pc_vmem1_st_tot_cycles, 
                        pc_vmem1_st_tot_requests,pc_vmem1_st_size_per_requests};
    
    assign pc_vmem2 = { pc_vmem2_ld_num_tiles,pc_vmem2_ld_tot_cycles, pc_vmem2_ld_tot_requests,
                        pc_vmem2_ld_size_per_requests,pc_vmem2_st_num_tiles,pc_vmem2_st_tot_cycles, 
                        pc_vmem2_st_tot_requests,pc_vmem2_st_size_per_requests};

    assign pc_done = pc_state_d == PC_DONE && pc_state_q == PC_DONE_WAIT;

    assign axi_st_size = 384; // 64 * 6 packets
    assign axi_st_data_v = axi_wdata_v;

  
    always @(*)
  begin
    pc_state_d = pc_state_q;
    axi_req_en = 0;
    axi_wdata_v = 0;
    axi_st_data = 0;
    case(pc_state_q)
      IDLE: begin
        if (pc_start)
            pc_state_d = PC_WRITE_DDR_CONTROLLER;
      end
      PC_WRITE_DDR_CONTROLLER: begin
          // valid and data always high since if wready is low, protocol requires these to be high
          // if wready is high, we change state and send next data
            axi_wdata_v = 1;
            axi_st_data = pc_controller;
         // if (axi_wready) begin
            pc_state_d = PC_WRITE_DDR_IBUF;
//            pc_state_d = PC_DONE_WAIT;
         // end
      end
      PC_WRITE_DDR_IBUF: begin
            axi_wdata_v = 1;
            axi_st_data = pc_ibuf;
        //  if (axi_wready) begin
//            pc_state_d = PC_WRITE_DDR_OBUF;
            pc_state_d = PC_WRITE_DDR_OBUF ;
        //  end
      end
      PC_WRITE_DDR_OBUF: begin
            axi_wdata_v = 1;
            axi_st_data = pc_obuf;
       //   if (axi_wready) begin
           pc_state_d = PC_WRITE_DDR_PARAMBUF;
      //    end
      end
      PC_WRITE_DDR_PARAMBUF: begin
            axi_wdata_v = 1;
            axi_st_data = pc_parambuf;
      //    if (axi_wready) begin
//            pc_state_d = PC_WRITE_DDR_VMEM1;
            pc_state_d = PC_WRITE_DDR_VMEM1;
      //    end
      end
      PC_WRITE_DDR_VMEM1: begin
            axi_wdata_v = 1;
            axi_st_data = pc_vmem1;
       //   if (axi_wready) begin
            pc_state_d = PC_WRITE_DDR_VMEM2;
      //    end
      end
      PC_WRITE_DDR_VMEM2: begin
            axi_wdata_v = 1;
            axi_st_data = pc_vmem2;
       //    if (axi_wready) begin
            pc_state_d = PC_AXI_REQ;
       //   end
      end
      PC_AXI_REQ: begin
          axi_req_en = 1;
          if (axi_awready )
            pc_state_d = PC_DONE_WAIT;
      end

      PC_DONE_WAIT: begin
        if (imem_bvalid)
            pc_state_d = PC_DONE;
      end
      PC_DONE: begin
        pc_state_d = IDLE;
      end
    endcase
  end
  
  always @(posedge clk)
  begin
    if (reset)
      pc_state_q <= IDLE;
    else
      pc_state_q <= pc_state_d;
  end
  
  endmodule
