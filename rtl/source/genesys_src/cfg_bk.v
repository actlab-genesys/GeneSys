///////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps
module controller_fsm_group #(
  parameter integer  LOOP_ID_W                    = 5,
  parameter integer  GROUP_ID_W                    = 2,
  parameter integer  LOOP_ITER_W                  = 16,
  // Internal Parameters
  parameter integer  STATE_W                      = 3,
  parameter integer  GROUP_ENABLED                = 1,
  parameter integer  LOOP_STATE_W                 = LOOP_ID_W,
  parameter integer  NUM_MAX_LOOPS                = (1 << LOOP_ID_W),
  parameter integer  NUM_MAX_GROUPS                = (1 << GROUP_ID_W)
) (
  input  wire                                         clk,
  input  wire                                         reset,

  // Start and Done handshake signals
  input  wire                                         start,
  input  wire                                         block_done,
  
  output wire                                         done,
  input  wire                                         stall,

  // Loop instruction valid
  input  wire                                         cfg_loop_iter_v,
  input  wire  [ LOOP_ITER_W          -1 : 0 ]        cfg_loop_iter,
  input  wire  [ LOOP_ID_W            -1 : 0 ]        cfg_loop_iter_loop_id,
  
  input  wire  [ GROUP_ID_W           -1 : 0 ]        cfg_loop_group_id,
  
  input  wire  [ GROUP_ID_W           -1 : 0 ]        loop_group_id,

  output reg   [ NUM_MAX_LOOPS           : 0 ]        iter_done,
  output wire  [ LOOP_ITER_W*NUM_MAX_LOOPS-1:0]       current_iters
);

    localparam MAX_GROUPS = (GROUP_ENABLED == 1) ? NUM_MAX_GROUPS : 1 ;
	
	reg start_d,loop_done;	
    reg [LOOP_ITER_W-1:0] iters[0:NUM_MAX_LOOPS-1];
    reg [LOOP_ITER_W-1:0] iters_w[0:NUM_MAX_LOOPS-1];
	wire  [ NUM_MAX_LOOPS           : 0 ]        iter_done_w;
	
	wire [LOOP_ITER_W-1 : 0]    max_iter[0:NUM_MAX_LOOPS-1];
    reg [LOOP_ITER_W-1 : 0]    max_iter_d[0:NUM_MAX_LOOPS-1];
	reg [NUM_MAX_LOOPS-1:0] group_loop_max_iter_valid[0:MAX_GROUPS-1];
	reg [LOOP_ITER_W-1 : 0 ] group_loop_max_iter[0:MAX_GROUPS-1][0:NUM_MAX_LOOPS-1];
	reg [LOOP_ITER_W-1 : 0 ] group_iters[0:MAX_GROUPS-1][0:NUM_MAX_LOOPS-1];
	
	reg [LOOP_ID_W-1 : 0]    counter[0:MAX_GROUPS-1];
	reg [ GROUP_ID_W           -1 : 0 ]        prev_group_id;
//	wire [LOOP_ITER_W-1 : 0]    counter_w;
	reg iter_done_d;
	wire load_new_group;
	
	wire  [ GROUP_ID_W           -1 : 0 ]        cfg_loop_group_id_in;
  
  wire  [ GROUP_ID_W           -1 : 0 ]        loop_group_id_in;
  
      generate
      if(GROUP_ENABLED == 1) begin
            assign cfg_loop_group_id_in = cfg_loop_group_id;
            assign loop_group_id_in = loop_group_id;
      end
      else begin
            assign cfg_loop_group_id_in = 'b0;
            assign loop_group_id_in = 'b0;
      end
      endgenerate
  
	always @(posedge clk) begin
	   start_d <= start;
	   prev_group_id <= loop_group_id_in;
	end
	assign load_new_group = loop_group_id_in != prev_group_id;
	
	always @(posedge clk) 
        if (reset) 
            iter_done_d <= 1'b0;            // Rohan added reset condition
        else
	        iter_done_d <= iter_done[0];
//	assign counter_w = 
	
	generate
	for (genvar g = 0 ; g< MAX_GROUPS; g=g+1) begin
        always @(posedge clk) begin
           if(reset) begin
               counter[g] <= 'd0;
           end
           else begin
               counter[g] <=  block_done ? 'd0 : (( cfg_loop_iter_v &&  g == cfg_loop_group_id_in )? counter[g] +'d1 : counter[g]) ;
           end
        end
	end
	endgenerate
	
	generate
	for (genvar g = 0 ; g< MAX_GROUPS; g=g+1) begin
        for (genvar l = 0 ; l< NUM_MAX_LOOPS; l=l+1) begin
            always @(posedge clk) begin
                if(reset) begin
                    group_loop_max_iter_valid[g][l] <= 1'b0;
                    group_loop_max_iter[g][l] <= 'b0;
                end
                else begin
                    if(  cfg_loop_iter_v ) begin
                        // Rohan: why test l == counter[g] ? 
                        group_loop_max_iter[g][l] <= (l == counter[g] && g == cfg_loop_group_id_in ) ? cfg_loop_iter : group_loop_max_iter[g][l];
                        group_loop_max_iter_valid[g][l] <= (l == counter[g] && g == cfg_loop_group_id_in ) ? 1'b1 : group_loop_max_iter_valid[g][l];
                    end
                    else if( block_done) begin
                        group_loop_max_iter_valid[g][l] <= 1'b0;
                    end
                end
            end
        end
	end
	endgenerate
	
	
	generate
	for (genvar l = 0 ; l< NUM_MAX_LOOPS; l=l+1) begin
        assign current_iters[LOOP_ITER_W*l+:LOOP_ITER_W] = iters[l];
		
        assign max_iter[l] = ((start && ~start_d) || load_new_group) ? ( (group_loop_max_iter_valid[loop_group_id_in][l] == 1'b1)? group_loop_max_iter[loop_group_id_in][l] : 'b0) : max_iter_d[l];
        
        always @(posedge clk)
            if(reset)
                max_iter_d[l] <= 'b0;
            else
                max_iter_d[l] <= max_iter[l];
        
        // always @(*) begin
        //        // rohan
        //     //    if (reset)
        //     //     max_iter[l] <= 'b0;
        //     //else begin 
        //     if((start && ~start_d) || load_new_group) begin
        //         if( group_loop_max_iter_valid[loop_group_id_in][l] == 1'b1) begin
        //             max_iter[l] = group_loop_max_iter[loop_group_id_in][l];
        //         end
        //         else begin
        //             max_iter[l] = 'b0;
        //         end
        //     end
        //     //end
        // end 
    end
	endgenerate
	
    assign iter_done_w[NUM_MAX_LOOPS] = 1'b1;
    assign done = iter_done[0] && ~iter_done_d;
    //assign done = iter_done[0]; // && ~iter_done_d; // rohan added
    

    always @(posedge clk) begin
        if(reset)
            loop_done <= 1'b0;
        else if(start)
            loop_done <= 1'b0;
        else if(iter_done[0])
            loop_done <= 1'b1;
    end
    
	
    generate
    for(genvar i =0 ; i < NUM_MAX_LOOPS ; i = i +1) begin
        
        assign iter_done_w[i] = (iters_w[i] == max_iter[i]) && iter_done_w[i+1];
        
        always @(*) begin
            // rohan
			if(start || reset) begin
				iters_w[i] = 'd0;
			end
			else if( load_new_group) begin
				iters_w[i] = group_iters[loop_group_id_in][i];
			end
			else if(~stall) begin
				if(iter_done_w[i] || loop_done) begin
					iters_w[i] = 'd0;
				end
				else if(iter_done_w[i+1]) begin
					iters_w[i] = iters[i] + 'd1;
				end
			end
			else begin
				iters_w[i] = iters[i];
			end
            
        end
		
		always @(posedge clk) begin
            // rohan
            if (reset) begin
                iters[i] <= 'd0;
                iter_done[i] <= 'd0;
            end
			else begin
				iters[i] <= iters_w[i];
				iter_done[i] <= iter_done_w[i];
            end
        end
    end
    endgenerate
    
	generate
    for(genvar l =0 ; l < NUM_MAX_LOOPS ; l = l +1) begin
        for(genvar g = 0 ; g < MAX_GROUPS ; g = g+1) begin
            always @(posedge clk) begin
                if(reset) begin
                    group_iters[g][l] <= 'd0;
                end
                else if(load_new_group || done) begin
                    group_iters[g][l] <= (g == prev_group_id) ? iters[l] : group_iters[g][l];
                end
            end
        end
    end
    endgenerate
endmodule

