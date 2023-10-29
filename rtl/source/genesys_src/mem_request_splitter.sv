module mem_request_splitter #(parameter integer ADDR_WIDTH = 64,
                              parameter integer REQ_SIZE_WIDTH = 16
    )
    (
        input   wire                                    clk,
        input   wire                                    reset,
        input   wire  [ADDR_WIDTH-1 : 0]                addr_in,
        input   wire                                    addr_in_valid,
        input   wire  [REQ_SIZE_WIDTH-1 : 0]            input_req_size_bytes,
        input   wire                                    pop_request,
        input   wire                                    axi_wr_ready,
        output  wire  [ADDR_WIDTH-1 : 0]                addr_out,
        output  wire                                    addr_out_valid,
        output  wire  [REQ_SIZE_WIDTH-1 : 0]            output_req_size_bytes,
        output  wire                                    split_sm_running, 
        output  wire                                    split_sm_complete,
        output  wire                                    request_valid,
        output wire                                     split_first_sent
    );
    
    localparam integer  SPLIT_REQ_IDLE            = 0;
    localparam integer  SPLIT_REQ                 = 1;
    localparam integer  SPLIT_REQ_A_WAIT          = 2;
    localparam integer  SPLIT_REQ_A               = 3;
    localparam integer  SPLIT_REQ_B_WAIT          = 4;
    localparam integer  SPLIT_REQ_B_WAIT_WRREADY  = 5;
    localparam integer  SPLIT_REQ_B               = 6;
    localparam integer  SPLIT_DONE                = 7; 

    logic                                       req_valid;
    logic                                       req_valid_same;
    logic                                       request_valid_w;
    logic                                       addr_in_valid_d;
    logic                                       SPLIT_req_v;
    logic                                       SPLIT_req_pulse;
    wire    [ ADDR_WIDTH      -1 : 0 ]          prev_4k_aligned_addr;
    wire    [ ADDR_WIDTH      -1 : 0 ]          next_4k_aligned_addr;       
    reg     [ ADDR_WIDTH      -1 : 0 ]          split_a_req_addr; 
    reg     [ ADDR_WIDTH      -1 : 0 ]          split_b_req_addr; 
    reg     [ REQ_SIZE_WIDTH  -1 : 0 ]          split_a_req_size;
    reg     [ REQ_SIZE_WIDTH  -1 : 0 ]          split_b_req_size;  
    reg     [ 3               -1 : 0 ]          stmem_split_state_d;
    reg     [ 3               -1 : 0 ]          stmem_split_state_q;    
    reg     [ 3               -1 : 0 ]          stmem_split_state_qq; 


    // logic to identify if we need to split the request, currently assuming that each split is at 64B * n
    assign prev_4k_aligned_addr = {addr_in[ADDR_WIDTH-1:12], 12'b0};
    assign next_4k_aligned_addr = prev_4k_aligned_addr + {1,12'b0};
    //assign SPLIT_req_v = ((input_req_size_bytes + addr_in) > next_4k_aligned_addr) && addr_in_valid;
    // rohan: if request size is greater than 4k but the request is starting at 4k address, then it is fine. 
    assign st_addr_eq_4kalign = addr_in[11:0] == 12'b0; // this means address is alogned 
    // if address is not aligned and req_size cross 4k boundary then assert SPLIT_req_v
    // if address is aligned and req_size crosses 4k boundary, do not asset SPLIT_req_v
    assign SPLIT_req_pulse = ((input_req_size_bytes + addr_in) > next_4k_aligned_addr) && addr_in_valid && ~st_addr_eq_4kalign;
    register_sync #(1) SPLIT_req_reg (clk, reset, SPLIT_req_pulse, SPLIT_req_v);

    //always @(posedge clk) begin
    //  if (reset || stmem_split_state_d == )
    //    SPLIT_req_v <= 1'b0;
    //  else if (addr_in_valid)
    //    SPLIT_req_v = ((input_req_size_bytes + addr_in) > next_4k_aligned_addr) && ~st_addr_eq_4kalign;
    //end

    always @(posedge clk) begin
      if (reset) begin
         split_a_req_addr <= 0;
         split_b_req_addr <= 0;
         split_a_req_size <= 0;
         split_b_req_size <= 0;
      end
      else if (SPLIT_req_pulse) begin
         split_a_req_addr <= addr_in;
         split_b_req_addr <= next_4k_aligned_addr;
         split_a_req_size <= (next_4k_aligned_addr - addr_in);
         split_b_req_size <= (input_req_size_bytes - (next_4k_aligned_addr - addr_in));
      end
    end

  //wire split_sm_busy;
  // todo: rohan -> as an optimization, may also destall when the stmem_split_state_d is at SPLIT_DONE
  //assign split_sm_busy = (stmem_split_state_d != SPLIT_REQ_IDLE) && (stmem_split_state_q != SPLIT_REQ_IDLE);

  always @(*)
  begin
    req_valid = 1'b0;
    req_valid_same = 1'b0;
    request_valid_w = 1'b0;
    stmem_split_state_d = stmem_split_state_q;
    case(stmem_split_state_q)
      SPLIT_REQ_IDLE: begin
        if (addr_in_valid) begin
          if (~SPLIT_req_pulse)
            request_valid_w = 1'b1;
          
          stmem_split_state_d = SPLIT_REQ;
        end
      end
      SPLIT_REQ: begin
        if (SPLIT_req_v) begin
          stmem_split_state_d = SPLIT_REQ_A_WAIT;
        end
        else begin
          stmem_split_state_d = SPLIT_DONE;
          req_valid_same = 1'b1;
        end
      end
      SPLIT_REQ_A_WAIT: begin
        if (axi_wr_ready) begin
            stmem_split_state_d = SPLIT_REQ_A;
            req_valid = 1'b1;
        end
      end
      SPLIT_REQ_A: begin
          stmem_split_state_d = SPLIT_REQ_B_WAIT; 
      end
      
      SPLIT_REQ_B_WAIT: begin
        if (pop_request)
            stmem_split_state_d = SPLIT_REQ_B_WAIT_WRREADY;
      end
      SPLIT_REQ_B_WAIT_WRREADY: begin
        if (axi_wr_ready)
          stmem_split_state_d = SPLIT_REQ_B;
      end
      
      SPLIT_REQ_B: begin
          stmem_split_state_d = SPLIT_DONE;
      end
      SPLIT_DONE: begin
        stmem_split_state_d = SPLIT_REQ_IDLE;
      end
    endcase
  end

  always @(posedge clk)
  begin
    if (reset)
      stmem_split_state_q <= SPLIT_REQ_IDLE;
    else
      stmem_split_state_q <= stmem_split_state_d;
  end

  assign request_valid = request_valid_w ? 1'b1 : (stmem_split_state_d == SPLIT_REQ_A) || (stmem_split_state_d == SPLIT_REQ_B);
  assign addr_out_valid = req_valid_same || (stmem_split_state_q == SPLIT_REQ_A) || (stmem_split_state_q == SPLIT_REQ_B);
  assign output_req_size_bytes = req_valid_same ? (input_req_size_bytes): (stmem_split_state_q == SPLIT_REQ_A) ? split_a_req_size : split_b_req_size;
  assign addr_out = req_valid_same ? addr_in : (stmem_split_state_q == SPLIT_REQ_A) ? split_a_req_addr : split_b_req_addr;

  //assign split_sm_running = stmem_split_state_q == SPLIT_REQ_B_WAIT;
  assign split_sm_running = stmem_split_state_q == SPLIT_REQ_B_WAIT || stmem_split_state_q == SPLIT_REQ_A_WAIT || stmem_split_state_q == SPLIT_REQ_A;
  
  assign split_sm_complete = stmem_split_state_q == SPLIT_DONE || stmem_split_state_q == SPLIT_REQ_IDLE;
  
  assign split_first_sent = stmem_split_state_q == SPLIT_REQ_A || stmem_split_state_q == SPLIT_REQ_B_WAIT ||  stmem_split_state_q == SPLIT_REQ_B;
endmodule