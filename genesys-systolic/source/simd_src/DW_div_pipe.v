////////////////////////////////////////////////////////////////////////////////
//
//       This confidential and proprietary software may be used only
//     as authorized by a licensing agreement from Synopsys Inc.
//     In the event of publication, the following notice is applicable:
//
//                    (C) COPYRIGHT 2000 - 2018 SYNOPSYS INC.
//                           ALL RIGHTS RESERVED
//
//       The entire notice above must be reproduced on all authorized
//     copies.
//
// AUTHOR:    Rajeev Huralikoppi         Feb 15, 2002
//
// VERSION:   Verilog Simulation Architecture
//
// DesignWare_version: 638d0c5c
// DesignWare_release: N-2017.09-DWBB_201709.5
//
////////////////////////////////////////////////////////////////////////////////
//-----------------------------------------------------------------------------
// ABSTRACT:   An n stage pipelined Divider Simulation model
//
//      Parameters      Valid Values    Description
//      ==========      =========       ===========
//      a_width         >= 1            default: none
//                                      Word length of a
//
//      b_width         >= 1            default: none
//                                      Word length of b
//
//      tc_mode         0 or 1          default: 0
//                                      Two's complement control:
//                                        0 => inputs/outputs unsigned
//                                        1 => inputs/outputs two's complement
//
//      rem_mode        0 or 1          default: 1
//                                      Remainder output control:
//                                        0 => remainder output is VHDL modulus
//                                        1 => remainder output is remainder
//
//      num_stages      >= 2            default: 2
//                                      Number of pipelined stages
//
//      stall_mode      0 or 1          default: 1
//                                      Stall mode
//                                        0 => non-stallable
//                                        1 => stallable
//
//      rst_mode        0 to 2          default: 1
//                                      Reset mode
//                                        0 => no reset
//                                        1 => asynchronous reset
//                                        2 => synchronous reset
//
//      op_iso_mode     0 to 4         default: 0
//                                     Type of operand isolation
//                                       If 'stall_mode' is '0', this parameter is ignored and no isolation is applied
//                                       0 => Follow intent defined by Power Compiler user setting
//                                       1 => no operand isolation
//                                       2 => 'and' gate operand isolaton
//                                       3 => 'or' gate operand isolation
//                                       4 => preferred isolation style: 'or'
//
//
//      Input Ports     Size            Description
//      ===========     ====            ============
//      clk             1               Clock
//      rst_n           1               Reset, active low
//      en              1               Register enable, active high
//      a               a_width         Divisor
//      b               b_width         Dividend
//
//      Output Ports    Size            Description
//      ============    ====            ============
//      quotient        a_width         quotient (a/b)
//      remainder       b_width         remainder
//      divide_by_0     1               divide by zero flag
//
//
// MODIFIED:
//              RJK  05/14/15   Updated model to work with less propagated 'X's
//                              so as to be more friendly with VCS-NLP
//
//              RJK  05/28/13   Updated documentation in comments to properly
//                              describe the "en" input (STAR 9000627580)
//
//              DLL  01/28/08   Enhanced abstract and added "op_iso_mode" parameter
//                              and related code.
//
//              DLL  11/10/05   Changed legality checking of 'num_stages'
//                              parameter along with its abstract "Valid Values"
//
//		RJK  2/5/03	Fixed port size mismatches for output
//				ports, quotient & divisor (STAR 159440)
//           
//-----------------------------------------------------------------------------

module DW_div_pipe (clk,rst_n,en,a,b,quotient,remainder,divide_by_0);
   
   parameter a_width = 8;
   parameter b_width = 8;
   parameter tc_mode = 0;
   parameter rem_mode = 1;
   parameter num_stages = 2;
   parameter stall_mode = 1;
   parameter rst_mode = 1;
   parameter op_iso_mode = 0;

   
   input clk;
   input rst_n;
   input [a_width-1 : 0] a;
   input [b_width-1 : 0] b;
   input en;
   
   output [a_width-1 : 0] quotient;
   output [b_width-1 : 0] remainder;
   output 		divide_by_0;
   
   reg [a_width-1 : 0]  a_reg [0 : num_stages-2];
   reg [b_width-1 : 0]  b_reg [0 : num_stages-2];

  // synopsys translate_off
  //---------------------------------------------------------------------------
  // Behavioral model
  //---------------------------------------------------------------------------   
   
generate
  if (rst_mode == 0) begin : GEN_RSM_EQ_0

    if (stall_mode == 0) begin : GEN_RM0_SM0
      always @(posedge clk) begin: rm0_sm0_pipe_reg_PROC
	integer i;

	for(i= 0; i < num_stages-1; i=i+1) begin 
	   if (i == 0) begin
	      a_reg[0]  <= a;
	      b_reg[0]  <= b;
	   end else begin
	      a_reg[i]  <= a_reg[i-1];
	      b_reg[i]  <= b_reg[i-1];
	   end
	end	  // for (i= 0; i < num_stages-1; i++)
      end // block: rm0_pipe_reg_PROC
    end else begin : GEN_RM0_SM1
      always @(posedge clk) begin: rm0_sm1_pipe_reg_PROC
	integer i;

	for(i= 0; i < num_stages-1; i=i+1) begin 
	   if (i == 0) begin
	      a_reg[0]  <= (en == 1'b0)? a_reg[0] : ((en == 1'b1)? a : {a_width{1'bx}});
	      b_reg[0]  <= (en == 1'b0)? b_reg[0] : ((en == 1'b1)? b : {b_width{1'bx}});
	   end else begin
	      a_reg[i]  <= (en == 1'b0)? a_reg[i] : ((en == 1'b1)? a_reg[i-1] : {a_width{1'bx}});
	      b_reg[i]  <= (en == 1'b0)? b_reg[i] : ((en == 1'b1)? b_reg[i-1] : {b_width{1'bx}});
	   end
        end
      end
    end

  end else if (rst_mode == 1) begin : GEN_RM_EQ_1

    if (stall_mode == 0) begin : GEN_RM1_SM0
      always @(posedge clk or negedge rst_n) begin: rm1_pipe_reg_PROC
	integer i;
	 
	if (rst_n == 1'b0) begin
	  for (i= 0; i < num_stages-1; i=i+1) begin
	    a_reg[i] <= {a_width{1'b0}};
	    b_reg[i] <= {b_width{1'b0}};
	  end // for (i= 0; i < num_stages-1; i++)
	end else if  (rst_n == 1'b1) begin
	  for(i= 0; i < num_stages-1; i=i+1) begin 
	     if (i == 0) begin
		a_reg[0]  <= a;
		b_reg[0]  <= b;
	     end else begin
		a_reg[i]  <= a_reg[i-1];
		b_reg[i]  <= b_reg[i-1];
	     end
	  end	  // for (i= 0; i < num_stages-1; i++)
	end else begin // rst_n not 1'b0 and not 1'b1
	  for (i= 0; i < num_stages-1; i=i+1) begin
	    a_reg[i] <= {a_width{1'bx}};
	    b_reg[i] <= {b_width{1'bx}};
	  end // for (i= 0; i < num_stages-1; i++)
	end
      end // block: rm1_pipe_reg_PROC
    end else begin : GEN_RM1_SM1
      always @(posedge clk or negedge rst_n) begin: rm1_pipe_reg_PROC
	integer i;
	 
	if (rst_n == 1'b0) begin
	  for (i= 0; i < num_stages-1; i=i+1) begin
	    a_reg[i] <= {a_width{1'b0}};
	    b_reg[i] <= {b_width{1'b0}};
	  end // for (i= 0; i < num_stages-1; i++)
	end else if  (rst_n == 1'b1) begin
	  for(i= 0; i < num_stages-1; i=i+1) begin 
	    if (i == 0) begin
	      a_reg[0]  <= (en == 1'b0)? a_reg[0] : ((en == 1'b1)? a : {a_width{1'bx}});
	      b_reg[0]  <= (en == 1'b0)? b_reg[0] : ((en == 1'b1)? b : {b_width{1'bx}});
	    end else begin
	      a_reg[i]  <= (en == 1'b0)? a_reg[i] : ((en == 1'b1)? a_reg[i-1] : {a_width{1'bx}});
	      b_reg[i]  <= (en == 1'b0)? b_reg[i] : ((en == 1'b1)? b_reg[i-1] : {b_width{1'bx}});
	    end
	  end	  // for (i= 0; i < num_stages-1; i++)
	end else begin // rst_n not 1'b0 and not 1'b1
	  for (i= 0; i < num_stages-1; i=i+1) begin
	    a_reg[i] <= {a_width{1'bx}};
	    b_reg[i] <= {b_width{1'bx}};
	  end // for (i= 0; i < num_stages-1; i++)
	end
      end // block: rm1_pipe_reg_PROC
    end

  end else begin : GEN_RM_GT_1

    if (stall_mode == 0) begin : GEN_RM2_SM0
      always @(posedge clk) begin: rm2_pipe_reg_PROC
	integer i;
	 
	if (rst_n == 1'b0) begin
	  for (i= 0; i < num_stages-1; i=i+1) begin
	    a_reg[i] <= {a_width{1'b0}};
	    b_reg[i] <= {b_width{1'b0}};
	  end // for (i= 0; i < num_stages-1; i++)
	end else if  (rst_n == 1'b1) begin
	  for(i= 0; i < num_stages-1; i=i+1) begin 
	     if (i == 0) begin
		a_reg[0]  <= a;
		b_reg[0]  <= b;
	     end else begin
		a_reg[i]  <= a_reg[i-1];
		b_reg[i]  <= b_reg[i-1];
	     end
	  end	  // for (i= 0; i < num_stages-1; i++)
	end else begin // rst_n not 1'b0 and not 1'b1
	  for (i= 0; i < num_stages-1; i=i+1) begin
	    a_reg[i] <= {a_width{1'bx}};
	    b_reg[i] <= {b_width{1'bx}};
	  end // for (i= 0; i < num_stages-1; i++)
	end
      end // block: rm2_pipe_reg_PROC
    end else begin : GEN_RM2_SM1
      always @(posedge clk) begin: rm2_pipe_reg_PROC
	integer i;
	 
	if (rst_n == 1'b0) begin
	  for (i= 0; i < num_stages-1; i=i+1) begin
	    a_reg[i] <= {a_width{1'b0}};
	    b_reg[i] <= {b_width{1'b0}};
	  end // for (i= 0; i < num_stages-1; i++)
	end else if  (rst_n == 1'b1) begin
	  for(i= 0; i < num_stages-1; i=i+1) begin 
	    if (i == 0) begin
	      a_reg[0]  <= (en == 1'b0)? a_reg[0] : ((en == 1'b1)? a : {a_width{1'bx}});
	      b_reg[0]  <= (en == 1'b0)? b_reg[0] : ((en == 1'b1)? b : {b_width{1'bx}});
	    end else begin
	      a_reg[i]  <= (en == 1'b0)? a_reg[i] : ((en == 1'b1)? a_reg[i-1] : {a_width{1'bx}});
	      b_reg[i]  <= (en == 1'b0)? b_reg[i] : ((en == 1'b1)? b_reg[i-1] : {b_width{1'bx}});
	    end
	  end	  // for (i= 0; i < num_stages-1; i++)
	end else begin // rst_n not 1'b0 and not 1'b1
	  for (i= 0; i < num_stages-1; i=i+1) begin
	    a_reg[i] <= {a_width{1'bx}};
	    b_reg[i] <= {b_width{1'bx}};
	  end // for (i= 0; i < num_stages-1; i++)
	end
      end // block: rm2_pipe_reg_PROC
    end

  end
endgenerate
   
   DW_div #(a_width, b_width, tc_mode, rem_mode)
      U1 (.a(a_reg[num_stages-2]),
	  .b(b_reg[num_stages-2]),
	  .quotient(quotient),
	  .remainder(remainder),
	  .divide_by_0(divide_by_0));
 //---------------------------------------------------------------------------
  // Parameter legality check and initializations
  //---------------------------------------------------------------------------
  
 
  initial begin : parameter_check
    integer param_err_flg;

    param_err_flg = 0;
    
    
    if (a_width < 1) begin
      param_err_flg = 1;
      $display(
	"ERROR: %m :\n  Invalid value (%d) for parameter a_width (lower bound: 1)",
	a_width );
    end
    
    if (b_width < 1) begin
      param_err_flg = 1;
      $display(
	"ERROR: %m :\n  Invalid value (%d) for parameter b_width (lower bound: 1)",
	b_width );
    end
    
    if ( (tc_mode < 0) || (tc_mode > 1) ) begin
      param_err_flg = 1;
      $display(
	"ERROR: %m :\n  Invalid value (%d) for parameter tc_mode (legal range: 0 to 1)",
	tc_mode );
    end
    
    if ( (rem_mode < 0) || (rem_mode > 1) ) begin
      param_err_flg = 1;
      $display(
	"ERROR: %m :\n  Invalid value (%d) for parameter rem_mode (legal range: 0 to 1)",
	rem_mode );
    end            
    
    if (num_stages < 2) begin
      param_err_flg = 1;
      $display(
	"ERROR: %m :\n  Invalid value (%d) for parameter num_stages (lower bound: 2)",
	num_stages );
    end   
    
    if ( (stall_mode < 0) || (stall_mode > 1) ) begin
      param_err_flg = 1;
      $display(
	"ERROR: %m :\n  Invalid value (%d) for parameter stall_mode (legal range: 0 to 1)",
	stall_mode );
    end   
    
    if ( (rst_mode < 0) || (rst_mode > 2) ) begin
      param_err_flg = 1;
      $display(
	"ERROR: %m :\n  Invalid value (%d) for parameter rst_mode (legal range: 0 to 2)",
	rst_mode );
    end
    
    if ( (op_iso_mode < 0) || (op_iso_mode > 4) ) begin
      param_err_flg = 1;
      $display(
	"ERROR: %m :\n  Invalid value (%d) for parameter op_iso_mode (legal range: 0 to 4)",
	op_iso_mode );
    end
  
    if ( param_err_flg == 1) begin
      $display(
        "%m :\n  Simulation aborted due to invalid parameter value(s)");
      $finish;
    end

  end // parameter_check 

 
  //---------------------------------------------------------------------------
  // Report unknown clock inputs
  //---------------------------------------------------------------------------
  
  always @ (clk) begin : clk_monitor 
    if ( (clk !== 1'b0) && (clk !== 1'b1) && ($time > 0) )
      $display( "WARNING: %m :\n  at time = %t, detected unknown value, %b, on clk input.",
                $time, clk );
    end // clk_monitor 
    
  // synopsys translate_on   
endmodule //

module div_tb();
    parameter CLK_PERIOD = 10;  // 10 ns == 100 MHz
    parameter WIDTH = 8;
    parameter FBITS = 4;
    parameter SF = 2.0**-4.0;  // Q4.4 scaling factor is 2^-4

    reg clk;
    reg reset;
    reg start;            // start signal
    reg busy;             // calculation in progress
    reg valid;            // quotient and remainder are valid
    wire dbz;              // divide by zero flag
    reg ovf;              // overflow flag (fixed-point only)
    reg [WIDTH-1:0] x;    // dividend
    reg [WIDTH-1:0] y;    // divisor
    wire [WIDTH-1:0] q;    // quotient
    wire [WIDTH-1:0] r;    // remainder
    
    DW_div_pipe dut (.clk(clk), .rst_n(reset), .en(1), .a(x), .b(y), .quotient(q), .remainder(r),.divide_by_0(dbz));
    //div #(.WIDTH(WIDTH), .FBITS(FBITS)) DW_div_pipe (.*);

    always #(CLK_PERIOD / 2) clk = ~clk;

    initial begin
        $monitor("\t%d:\t%f / %f = %b (%f) (r = %b) (V=%b) (DBZ=%b) (OVF=%b)",
            $time, x*SF, y*SF, q, q*SF, r, valid, dbz, ovf);
    end

    initial begin
                clk = 1;
        reset = 0; @(posedge clk);
        reset = 1; @(posedge clk);
       
        x = 8'b0011_0000;  y = 8'b0010_0000; @(posedge clk);

        x = 8'b0010_0000;  y = 8'b0001_0110; @(posedge clk); // 1.375 (the largest number that's ≤√2 in Q4.4)

        /*
        #120    x = 8'b0010_0000;  // 2.0
                y = 8'b0000_0000;  // 0.0
                start = 1;
        #10     start = 0;

        #120    x = 8'b0000_0000;  // 0.0
                y = 8'b0010_0000;  // 2.0
                start = 1;
        #10     start = 0;

        #120    x = 8'b0000_0010;  // 0.125
                y = 8'b0010_0000;  // 2.0
                start = 1;
        #10     start = 0;

        #120    x = 8'b1000_0000;  // 8.0
                y = 8'b0000_0100;  // 0.25
                start = 1;
        #10     start = 0;

        #120    x = 8'b1111_1110;  // 15.875
                y = 8'b0010_0000;  // 2.0
                start = 1;
        #10     start = 0;

        #120    x = 8'b1000_0000;  // 8.0
                y = 8'b1001_0000;  // 9.0
                start = 1;
        #10     start = 0;
        */
    end
endmodule