
module nested_loop #(
    parameter NUM_MAX_LOOPS = 7,
    parameter LOG_NUM_MAX_LOOPS = 3,
    parameter BASE_WIDTH = 32,
    parameter STRIDE_WIDTH = BASE_WIDTH,
    parameter ADDRESS_WIDTH = BASE_WIDTH,
    parameter NUM_ITER_WIDTH = 32
)(
    
    input                                       clk,
    input                                       reset,
    
    input                                       in_nested_loop,

    input [BASE_WIDTH-1 : 0]                    base,
    input [STRIDE_WIDTH*NUM_MAX_LOOPS-1 : 0]    stride,
    input [NUM_ITER_WIDTH*NUM_MAX_LOOPS-1 : 0]  num_iter,
    input                                       start_loop,
    
    output [ADDRESS_WIDTH-1:0]                  address_out,
    output reg                                  address_valid,
    output                                      loop_done_out
    );
    
    reg start_loop_d,loop_done;
    wire [STRIDE_WIDTH-1:0] loop_stride[0:NUM_MAX_LOOPS-1];
    wire [NUM_ITER_WIDTH-1:0] max_iter[0:NUM_MAX_LOOPS-1];
    reg [NUM_ITER_WIDTH-1:0] iters[0:NUM_MAX_LOOPS-1];
    reg [ADDRESS_WIDTH-1:0] loop_address[0:NUM_MAX_LOOPS-1];
    reg [ADDRESS_WIDTH-1:0] loop_address_d[0:NUM_MAX_LOOPS-1];
    
    wire [NUM_MAX_LOOPS :0] iter_done;
    reg [NUM_MAX_LOOPS :0] iter_done_d, iter_0_done_speedup;
    assign iter_done[NUM_MAX_LOOPS] = 1'b1;
    
    reg [NUM_ITER_WIDTH-1:0]                  instruction_counter;

    reg [NUM_MAX_LOOPS*ADDRESS_WIDTH-1:0]     total_iter, cur_iter; 


    generate
    for(genvar i=0; i < NUM_MAX_LOOPS; i=i+1) begin
        assign max_iter[i] = ((num_iter[i*NUM_ITER_WIDTH+:NUM_ITER_WIDTH]) == 'b0) ? 0'b0 : (num_iter[i*NUM_ITER_WIDTH+:NUM_ITER_WIDTH]-1);
        assign loop_stride[i] = stride[i*STRIDE_WIDTH+:STRIDE_WIDTH];
    end
    endgenerate
    
    integer i;
    always @(*) begin
        for (i = 0; i < NUM_MAX_LOOPS; i=i+1) begin
            if (i == 0) begin
                total_iter = max_iter[i] + 1;
            end else begin
                total_iter = total_iter * (max_iter[i] + 1);
            end
        end
    end

    always @(posedge clk) begin
        start_loop_d <= start_loop;
        if (reset)
            address_valid <= 1'b0;
        else if (start_loop)
            address_valid <= 1'b1;
        else if (iter_done[0])
            address_valid <= 1'b0;
        else if (loop_done)
            address_valid <= 1'b0;
    end
    
    always @(posedge clk) begin
        if (reset)
            loop_done <= 1'b0;
        else if(start_loop)
            loop_done <= 1'b0;
        else if (iter_done[0])
            loop_done <= 1'b1;
    end
    
    always @(posedge clk) begin
        iter_done_d <= iter_done;
    end

    always @(posedge clk) begin
        if(reset || start_loop || in_nested_loop)
            instruction_counter <= 'b0;
        else 
            instruction_counter <= instruction_counter + 1;
    end


    generate
    for(genvar i =0 ; i < NUM_MAX_LOOPS ; i = i +1) begin
        
        assign iter_done[i] = (iters[i] == max_iter[i]) && iter_done[i+1];
        
        always @( * ) begin
            if(start_loop_d) begin
                loop_address[i] = base;
            end
            else if(iter_done_d[i]) begin
                loop_address[i] = (i == 0) ? 'd0 : loop_address[i-1];
            end
            else if(iter_done_d[i+1] && instruction_counter == 'b0) begin
                loop_address[i] = loop_address_d[i] + loop_stride[i];
            end
            else begin
                loop_address[i] = loop_address_d[i];
            end 
        end
        
        always @(posedge clk) begin
            if ( ~loop_done)
                loop_address_d[i] <= loop_address[i];
        end
        
        always @(posedge clk) begin
            if(reset || start_loop || loop_done) begin
                iters[i] <= 'd0;
            end
            else if(iter_done[i]) begin
                iters[i] <= 'd0;
            end
            else if(iter_done[i+1] && instruction_counter == 'b0) begin
                iters[i] <= iters[i] + 'd1;
            end
        end

        always @(posedge clk) begin
            if(reset || ~in_nested_loop) begin
                cur_iter <= 'd0;
            end else begin
                if (in_nested_loop && (cur_iter < (total_iter+2))) begin
                    cur_iter <= cur_iter + 1;
                end else begin
                    cur_iter <= cur_iter;
                end
            end
        end
        
    end
    endgenerate

    //assign loop_done_out = iter_done[0];
    assign loop_done_out = cur_iter >= (total_iter + 2);
    assign address_out = loop_address[NUM_MAX_LOOPS-1];

endmodule
