`timescale 1ns / 1ps

module execute_control_pipelines #(
    parameter OPCODE_BITS 			=	4,
	parameter FUNCTION_BITS 		=	4,
    parameter NS_ID_BITS 			=	3,
	parameter NS_INDEX_ID_BITS 		=	5,
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
    reg [4:0] pipe_stages; 
    // wire [BASE_STRIDE_WIDTH + NS_INDEX_ID_BITS: 0] pipe_in1,pipe_in2, pipe_in3, pipe_in4, pipe_in6, pipe_in12;
    // wire [BASE_STRIDE_WIDTH + NS_INDEX_ID_BITS: 0] pipe_out1, pipe_out2, pipe_out3, pipe_out4, pipe_out6, pipe_out12;
    
    // wire [5:0]                       buf_wr_req_out1, buf_wr_req_out2, buf_wr_req_out3, buf_wr_req_out4, buf_wr_req_out6, buf_wr_req_out12;
    // wire [BASE_STRIDE_WIDTH-1:0]     buf_wr_addr_out1, buf_wr_addr_out2, buf_wr_addr_out3, buf_wr_addr_out4, buf_wr_addr_out6, buf_wr_addr_out12;
    // wire [OPCODE_BITS-1:0]           opcode_out1, opcode_out2, opcode_out3, opcode_out4, opcode_out6, opcode_out12;
    // wire [FUNCTION_BITS-1:0]         fn_out1, fn_out2, fn_out3, fn_out4, fn_out6, fn_out12;
    
    wire [5:0]                       buf_wr_req_out8;
    wire [BASE_STRIDE_WIDTH-1:0]     buf_wr_addr_out8;
    wire [BASE_STRIDE_WIDTH + NS_INDEX_ID_BITS: 0] pipe_in8, pipe_out8;
    wire [OPCODE_BITS-1:0] opcode_out8;
    wire [FUNCTION_BITS-1:0] fn_out8;

    reg   [OPCODE_BITS+FUNCTION_BITS-1:0] prev_inst;
    wire  [OPCODE_BITS+FUNCTION_BITS-1:0] cur_inst;
    assign cur_inst = {opcode, fn};
    
    reg  in_loop;
    wire out_valid;
    reg [4:0] stage_count; 
    assign out_valid = (cur_inst == 8'b00001111) ? (in_loop || (stage_count == pipe_stages)) : 1'b1;

    always @(posedge clk) begin
        if (reset) begin
            in_loop <= 1'b0;
        end else if (in_loop_in) begin
            in_loop <= 1'b1;
        end else if (in_loop && stage_count == (pipe_stages)) begin
            in_loop <= 1'b0;
        end
    end

    always @(posedge clk) begin
        if (cur_inst == 8'b00001111) begin
            stage_count <= stage_count + 1;
        end else begin
            stage_count <= 0;
        end
    end

    always @(*) begin
        if (cur_inst == 8'b00001111) begin
            opcode_out = prev_inst[OPCODE_BITS+FUNCTION_BITS-1:FUNCTION_BITS];
            fn_out     = prev_inst[FUNCTION_BITS-1:0];
        end else begin
            opcode_out = opcode;
            fn_out = fn;
        end
    end

    always @(posedge clk) begin
        if (cur_inst == 8'b00001111) begin
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
                    //4'b0100 : pipe_stages = 6;  // Div is not implemented
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
                    4'b1000: begin
                        pipe_stages = 8;
                    end
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

    assign pipe_in8 = {buf_wr_req_in, buf_wr_addr_in};
    pipeline #( 
        .NUM_BITS	( BASE_STRIDE_WIDTH + NS_INDEX_ID_BITS + 1 ), 
        .NUM_STAGES	( 8	), 
        .EN_RESET   ( 0 )
    ) i_1regs (
        .clk		(	clk		    ), 
        .rst		(	reset		), 
        .data_in	(	pipe_in8	), 
        .data_out	(	pipe_out8    ) 
    );

    assign {buf_wr_req_out8, buf_wr_addr_out8} = pipe_out8;

    /*
    pipeline #( 
        .NUM_BITS	( BASE_STRIDE_WIDTH + NS_INDEX_ID_BITS + 1 ), 
        .NUM_STAGES	( 1	), 
        .EN_RESET   ( 0 ) ) 
    i_1regs (
        .clk		(	clk		    ), 
        .rst		(	reset		), 
        .data_in	(	pipe_in1	), 
        .data_out	(	pipe_out1    ) );

    assign pipe_in2 = pipe_out1;
    assign {buf_wr_req_out1, buf_wr_addr_out1} = pipe_out1;

    pipeline #( 
        .NUM_BITS	( BASE_STRIDE_WIDTH + NS_INDEX_ID_BITS + 1 ), 
        .NUM_STAGES	( 1	), 
        .EN_RESET   ( 0 ) ) 
    i_2regs (
        .clk		(	clk		    ), 
        .rst		(	reset		), 
        .data_in	(	pipe_in2 	), 
        .data_out	(	pipe_out2    ) );
    
    assign pipe_in3 = pipe_out2;
    assign {buf_wr_req_out2, buf_wr_addr_out2} = pipe_out2;

    pipeline #( 
        .NUM_BITS	( BASE_STRIDE_WIDTH + NS_INDEX_ID_BITS + 1 ), 
        .NUM_STAGES	( 1	), 
        .EN_RESET   ( 0 ) ) 
    i_3regs (
        .clk		(	clk		    ), 
        .rst		(	reset		), 
        .data_in	(	pipe_in3 	), 
        .data_out	(	pipe_out3    ) );

    assign pipe_in6 = pipe_out3;
    assign {buf_wr_req_out3, buf_wr_addr_out3} = pipe_out3;

    pipeline #( 
        .NUM_BITS	( BASE_STRIDE_WIDTH + NS_INDEX_ID_BITS + 1 ), 
        .NUM_STAGES	( 1	), 
        .EN_RESET   ( 0 ) ) 
    i_4regs (
        .clk		(	clk		    ), 
        .rst		(	reset		), 
        .data_in	(	pipe_in4 	), 
        .data_out	(	pipe_out4    ) );

    assign pipe_in4 = pipe_out3;
    assign {buf_wr_req_out4, buf_wr_addr_out4} = pipe_out4;

    pipeline #( 
        .NUM_BITS	( BASE_STRIDE_WIDTH + NS_INDEX_ID_BITS + 1 ), 
        .NUM_STAGES	( 3	), 
        .EN_RESET   ( 0 ) ) 
    i_6regs (
        .clk		(	clk		    ), 
        .rst		(	reset		), 
        .data_in	(	pipe_in6 	), 
        .data_out	(	pipe_out6    ) );
    
    assign pipe_in12 = pipe_out6;
    assign {buf_wr_req_out6, buf_wr_addr_out6} = pipe_out6;

    pipeline #( 
        .NUM_BITS	( BASE_STRIDE_WIDTH + NS_INDEX_ID_BITS + 1 ), 
        .NUM_STAGES	( 6	), 
        .EN_RESET   ( 0 ) ) 
    i_12regs (
        .clk		(	clk		    ), 
        .rst		(	reset		), 
        .data_in	(	pipe_in12 	), 
        .data_out	(	pipe_out12    ) );
    
    assign {buf_wr_req_out12, buf_wr_addr_out12} = pipe_out12;
    */

    always @(*) begin
        if (out_valid) begin
            case (pipe_stages)
                /*
                5'b00001: begin
                    buf_wr_req_out    =   buf_wr_req_out1;
                    buf_wr_addr_out   =   buf_wr_addr_out1;
                end
                5'b00010: begin
                    buf_wr_req_out    =   buf_wr_req_out2;
                    buf_wr_addr_out   =   buf_wr_addr_out2;
                end
                5'b00011: begin
                    buf_wr_req_out    =   buf_wr_req_out3;
                    buf_wr_addr_out   =   buf_wr_addr_out3;
                end
                5'b00100: begin
                    buf_wr_req_out    =   buf_wr_req_out4;
                    buf_wr_addr_out   =   buf_wr_addr_out4;
                end
                5'b00110: begin
                    buf_wr_req_out    =   buf_wr_req_out6;
                    buf_wr_addr_out   =   buf_wr_addr_out6;
                end
                5'b01100: begin
                    buf_wr_req_out    =   buf_wr_req_out12;
                    buf_wr_addr_out   =   buf_wr_addr_out12;
                end
                */

                5'b01000: begin
                    buf_wr_req_out    =   buf_wr_req_out8;
                    buf_wr_addr_out   =   buf_wr_addr_out8;
                end
                
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