`timescale 1ns / 1ps

module execute_control_pipelines #(
    parameter OPCODE_BITS 			=	4,
	parameter FUNCTION_BITS 		=	4,
    parameter NS_ID_BITS 			=	3,
	parameter NS_INDEX_ID_BITS 		=	5,
    parameter PIPE_STAGE_WIDTH      =   6,
    parameter BASE_STRIDE_WIDTH     =   4*(NS_INDEX_ID_BITS + NS_ID_BITS)
) (
    input                               clk,
    input                               reset,
    input  [FUNCTION_BITS-1:0]          fn,
    input  [OPCODE_BITS-1:0]            opcode,                              
    input  [5:0]                        buf_wr_req_in,
    input  [BASE_STRIDE_WIDTH-1:0]      buf_wr_addr_in,
    input                               in_loop_in,
    output reg [FUNCTION_BITS-1:0]          fn_out,
    output reg [OPCODE_BITS-1:0]            opcode_out, 
    output reg [5:0]                        buf_wr_req_out,
    output reg [BASE_STRIDE_WIDTH-1:0]      buf_wr_addr_out
);
    reg [PIPE_STAGE_WIDTH-1:0] pipe_stages; 
    
    // wire [5:0]                       buf_wr_req_out8;
    // wire [BASE_STRIDE_WIDTH-1:0]     buf_wr_addr_out8;
    // wire [BASE_STRIDE_WIDTH + NS_INDEX_ID_BITS: 0] pipe_in8, pipe_out8;

    // wire [5:0]                       buf_wr_req_out_div; // ------------------- 51 cycle delay ---------------------------// 
    // wire [BASE_STRIDE_WIDTH-1:0]     buf_wr_addr_out_div;
    // wire [BASE_STRIDE_WIDTH + NS_INDEX_ID_BITS: 0] pipe_in_div, pipe_out_div;

    reg   [OPCODE_BITS+FUNCTION_BITS-1:0] prev_inst;
    wire  [OPCODE_BITS+FUNCTION_BITS-1:0] cur_inst;
    assign cur_inst = {opcode, fn};
    
    wire out_valid;
    reg [PIPE_STAGE_WIDTH-1:0] stage_count; 
    
    assign out_valid = (state_q == IN_LOOP || state_q == POST_LOOP);

    localparam integer  IDLE            = 0;
	localparam integer  IN_LOOP         = 1;
	localparam integer  POST_LOOP       = 2;
    reg [1:0] state_q, state_d;
    
    always @(*) begin
		case (state_q)
		IDLE: begin
			if (in_loop_in) begin
				state_d = IN_LOOP;
		    end else begin
		        state_d = state_q;
		    end
		end 

        IN_LOOP: begin
			if (!in_loop_in) begin
				state_d = POST_LOOP;
            end else begin
		        state_d = state_q;
		    end
        end

        POST_LOOP: begin
			if (stage_count >= pipe_stages) begin
				state_d = IDLE;
            end else begin
		        state_d = state_q;
		    end
        end
        
        default: begin
			state_d = IDLE;
		end
		endcase
    end

    always @(posedge clk ) begin
	   if (reset) begin
            state_q <= IDLE;
	   end else begin
            state_q <= state_d;
	   end
	end
    
    always @(posedge clk) begin
        if (state_q == POST_LOOP) begin
            stage_count <= stage_count + 1;
        end else begin
            stage_count <= 0;
        end
    end

    always @(*) begin
        if (state_q == POST_LOOP) begin
            opcode_out = prev_inst[OPCODE_BITS+FUNCTION_BITS-1:FUNCTION_BITS];
            fn_out     = prev_inst[FUNCTION_BITS-1:0];
        end else begin
            opcode_out = opcode;
            fn_out = fn;
        end
    end

    always @(posedge clk) begin
        if (state_q == POST_LOOP) begin
            prev_inst <= prev_inst;
        end else begin
            prev_inst <= cur_inst;
        end
    end
   
    always @(*) begin
        pipe_stages = 0;
        case(opcode_out)
            4'b0000 : begin
                case(fn_out)
                    4'b0000, 4'b0001,4'b0010,4'b0011,4'b0101,4'b0110 : begin
                        pipe_stages = 0;
                    end
                    // 4'b0100 : pipe_stages = 51;  // Div is not implemented
                    default : pipe_stages = 0;     
                endcase
            end
            4'b0001 : begin
                case(fn_out)
                    /*
                    4'b0010, 4'b0011: begin
                        pipe_stages = 3;
                    end
                    
                    4'b0111: begin
                        pipe_stages = 4;
                    end

                    4'b0100, 4'b0101, 4'b1000: begin
                        pipe_stages = 6;
                    end
                    */
                    // 4'b1000: begin
                    //     pipe_stages = 8;
                    // end
                    default : pipe_stages = 0;     
                endcase
            end
            4'b0010 : begin
                pipe_stages = 0; 
            end
            4'b1010 : begin
                pipe_stages = 0;
            end
            default :  pipe_stages = 0;
        endcase
    end

    // assign pipe_in8 = {buf_wr_req_in, buf_wr_addr_in};
    // pipeline #( 
    //     .NUM_BITS	( BASE_STRIDE_WIDTH + NS_INDEX_ID_BITS + 1 ), 
    //     .NUM_STAGES	( 8	), 
    //     .EN_RESET   ( 0 )
    // ) reg_8 (
    //     .clk		(	clk		    ), 
    //     .rst		(	reset		), 
    //     .data_in	(	pipe_in8	), 
    //     .data_out	(	pipe_out8    ) 
    // );

    // assign {buf_wr_req_out_div, buf_wr_addr_out_div} = pipe_out_div;

    // assign pipe_in_div = {buf_wr_req_in, buf_wr_addr_in};
    // pipeline #( 
    //     .NUM_BITS	( BASE_STRIDE_WIDTH + NS_INDEX_ID_BITS + 1 ), 
    //     .NUM_STAGES	( 51 ), 
    //     .EN_RESET   ( 0 )
    // ) reg_51 (
    //     .clk		(	clk		    ), 
    //     .rst		(	reset		), 
    //     .data_in	(	pipe_in_div	), 
    //     .data_out	(	pipe_out_div    ) 
    // );

    // assign {buf_wr_req_out_div, buf_wr_addr_out_div} = pipe_out_div;

    always @(*) begin
        if (out_valid) begin
            case (pipe_stages)
                // 6'b110011: begin
                //     buf_wr_req_out    =   buf_wr_req_out_div;
                //     buf_wr_addr_out   =   buf_wr_addr_out_div;
                // end
            
                // 6'b001000: begin
                //     buf_wr_req_out    =   buf_wr_req_out8;
                //     buf_wr_addr_out   =   buf_wr_addr_out8;
                // end
                
                default: begin
                    buf_wr_req_out    =   buf_wr_req_in;
                    buf_wr_addr_out   =   buf_wr_addr_in;
                end 
            endcase       
        end else begin
            buf_wr_req_out = 'b0;
            buf_wr_addr_out = 'b0;
        end
    end

endmodule