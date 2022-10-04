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
// AUTHOR:    Reto Zimmermann		April 12, 2000
//
// VERSION:   Verilog Simulation Architecture
//
// DesignWare_version: 7434024d
// DesignWare_release: N-2017.09-DWBB_201709.5
//
////////////////////////////////////////////////////////////////////////////////
//
// ABSTRACT:  Verilog Simulation Models for Combinational Divider
//            - Uses modeling functions from DW_div_function.inc.
//
// MODIFIED:
//           05/14/15  RJK
//           Updated to eliminate === comparison to 1'bx for better
//           compatibility with verification tools and 2-state simulation.
//
//           08/03/05  Doug Lee
//           Modified the parameter checking for a_width and b_width
//
//-----------------------------------------------------------------------------

module DW_div (a, b, quotient, remainder, divide_by_0);

  parameter a_width  = 8;
  parameter b_width  = 8;
  parameter tc_mode  = 0;
  parameter rem_mode = 1;

  input  [a_width-1 : 0] a;
  input  [b_width-1 : 0] b;
  output [a_width-1 : 0] quotient;
  output [b_width-1 : 0] remainder;
  output 		 divide_by_0;
  
  wire [a_width-1 : 0] a;
  wire [b_width-1 : 0] b;
  reg  [a_width-1 : 0] quotient;
  reg  [b_width-1 : 0] remainder;
  reg		       divide_by_0;
  reg 		       b_x;

  // include modeling functions
//`include "DW_div_function.inc"
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
// AUTHOR:    Reto Zimmermann		April 12, 2000
//
// VERSION:   Verilog Simulation Functions
//
// DesignWare_version: b764c750
// DesignWare_release: N-2017.09-DWBB_201709.5
//
////////////////////////////////////////////////////////////////////////////////
//
// ABSTRACT: Verilog Function Descriptions for Combinational Divider
//
//           Function descriptions for division quotient and modulus
//           used for synthesis inference of function calls
//           and for behavioral Verilog simulation.
//
//           The following functions are declared:
//
//           DWF_div_uns (a, b)
//           DWF_div_tc (a, b)
//           DWF_rem_uns (a, b)
//           DWF_rem_tc (a, b)
//           DWF_mod_uns (a, b)
//           DWF_mod_tc (a, b)
//
// MODIFIED: 
//           09/04/13 Alex Tenca - Star 9000663666
//           Fixes bug for the case when b_width >= 2*a_width, tc mode is used
//           and b=0. Sign extension on the remainder is not properly
//           done in this case by functions DWF_rem_tc and DWF_mod_tc. 
//
//           08/03/12 Doug Lee
//           Added `DW_SUPPRESS_WARN directive support to conditionally print
//           "divide by 0" warning messages. This addresses STAR#9000546904.
//
//           08/03/05 Doug Lee
//           Fixed a couple of bugs on DWF_rem_tc and DWF_mod_tc along with
//           incorporating a couple fixes to handle b_width > a_width conditions.
//
//-----------------------------------------------------------------------------

  function [a_width-1 : 0] DWF_div_uns;
    // Function to compute the unsigned quotient
    
    // synopsys map_to_operator DIV_UNS_OP
    // synopsys return_port_name QUOTIENT

    input [a_width-1 : 0] A;
    input [b_width-1 : 0] B;

    reg [a_width-1 : 0] QUOTIENT_v;
    reg                 A_x, B_x;


    begin
      // synopsys translate_off
      A_x = ^A;
      B_x = ^B;
      if ((A_x === 1'bx) || (B_x === 1'bx)) begin
	QUOTIENT_v = {a_width{1'bx}};
      end
      else begin
	if (B == 0) begin
	  QUOTIENT_v = {a_width{1'b1}};
`ifdef DW_SUPPRESS_WARN `else
	  $write ("WARNING: %m: Division by zero\n");
`endif
	end
	else begin
	  QUOTIENT_v = A / B;
	end
      end
      DWF_div_uns = QUOTIENT_v;
      // synopsys translate_on
    end
  endfunction

  
  function [a_width-1 : 0] DWF_div_tc;
    // Function to compute the signed quotient
    
    // synopsys map_to_operator DIV_TC_OP
    // synopsys return_port_name QUOTIENT

    input [a_width-1 : 0] A;
    input [b_width-1 : 0] B;

    reg [a_width-1 : 0] A_v;
    reg [b_width-1 : 0] B_v;
    reg [a_width-1 : 0] QUOTIENT_v;
    reg A_x, B_x;


    begin
      // synopsys translate_off
      A_x = ^A;
      B_x = ^B;
      if ((A_x === 1'bx) || (B_x === 1'bx)) begin
	QUOTIENT_v = {a_width{1'bx}};
      end
      else begin
	if (B == 0) begin
	  if (A[a_width-1] == 1'b0)
	    QUOTIENT_v = {1'b0, {a_width{1'b1}}} >> 1;
	  else
	    QUOTIENT_v = {1'b1, {a_width{1'b0}}} >> 1;
`ifdef DW_SUPPRESS_WARN `else
	  $write ("WARNING: %m: Division by zero\n");
`endif
	end
	else begin
	  if (A[a_width-1] == 1'b1) A_v = ~A + 1'b1;
	  else A_v = A;
	  if (B[b_width-1] == 1'b1) B_v = ~B + 1'b1;
	  else B_v = B;
	  QUOTIENT_v = A_v / B_v;
	  if (A[a_width-1] != B[b_width-1])
	    QUOTIENT_v = ~QUOTIENT_v + 1'b1;
	end
      end
      DWF_div_tc = QUOTIENT_v;
      // synopsys translate_on
    end
  endfunction

  
  function [b_width-1 : 0] DWF_rem_uns;
    // Function to compute the unsigned remainder
    
    // synopsys map_to_operator REM_UNS_OP
    // synopsys return_port_name REMAINDER

    input [a_width-1 : 0] A;
    input [b_width-1 : 0] B;

    reg [b_width-1 : 0] REMAINDER_v;
    reg A_x, B_x;

    begin
      // synopsys translate_off
      A_x = ^A;
      B_x = ^B;
      if ((A_x === 1'bx) || (B_x === 1'bx)) begin
	REMAINDER_v = {b_width{1'bx}};
      end
      else begin
	if (B == 0) begin
	  REMAINDER_v = A;
`ifdef DW_SUPPRESS_WARN `else
	  $write ("WARNING: %m: Division by zero\n");
`endif
	end
	else begin
	  REMAINDER_v = A % B;
	end
      end
      DWF_rem_uns = REMAINDER_v;
      // synopsys translate_on
    end
  endfunction

  
  function [b_width-1 : 0] DWF_rem_tc;
    // Function to compute the signed remainder
    
    // synopsys map_to_operator REM_TC_OP
    // synopsys return_port_name REMAINDER

    input [a_width-1 : 0] A;
    input [b_width-1 : 0] B;

    reg [a_width-1 : 0] A_v;
    reg [b_width-1 : 0] B_v;
    reg [b_width-1 : 0] REMAINDER_v;
    reg A_x, B_x;
    reg [a_width+b_width-1:0] A_extended;

    begin
      // synopsys translate_off
      A_x = ^A;
      B_x = ^B;
      if ((A_x === 1'bx) || (B_x === 1'bx)) begin
	REMAINDER_v = {b_width{1'bx}};
      end
      else begin
	if (B == 0) begin
	  A_extended = {{b_width{A[a_width-1]}},A};
	  REMAINDER_v = A_extended[b_width-1:0];
`ifdef DW_SUPPRESS_WARN `else
	  $write ("WARNING: %m: Division by zero\n");
`endif
	end
	else begin
	  if (A[a_width-1] == 1'b1) A_v = ~A + 1'b1;
	  else A_v = A;
	  if (B[b_width-1] == 1'b1) B_v = ~B + 1'b1;
	  else B_v = B;
	  REMAINDER_v = A_v % B_v;
	  if (A[a_width-1] == 1'b1)
	    REMAINDER_v = ~REMAINDER_v + 1'b1;
	end
      end
      DWF_rem_tc = REMAINDER_v;
      // synopsys translate_on
    end
  endfunction

  
  function [b_width-1 : 0] DWF_mod_uns;
    // Function to compute the unsigned modulus
    
    // synopsys map_to_operator MOD_UNS_OP
    // synopsys return_port_name REMAINDER

    input [a_width-1 : 0] A;
    input [b_width-1 : 0] B;

    reg [b_width-1 : 0] MODULUS_v;
    reg A_x, B_x;

    begin
      // synopsys translate_off
      A_x = ^A;
      B_x = ^B;
      if ((A_x === 1'bx) || (B_x === 1'bx)) begin
	MODULUS_v = {a_width{1'bx}};
      end
      else begin
	if (B == 0) begin
	  MODULUS_v = A;
`ifdef DW_SUPPRESS_WARN `else
	  $write ("WARNING: %m: Division by zero\n");
`endif
	end
	else begin
	  MODULUS_v = A % B;
	end
      end
      DWF_mod_uns = MODULUS_v;
      // synopsys translate_on
    end
  endfunction

  
  function [b_width-1 : 0] DWF_mod_tc;
    // Function to compute the signed modulus
    
    // synopsys map_to_operator MOD_TC_OP
    // synopsys return_port_name REMAINDER

    input [a_width-1 : 0] A;
    input [b_width-1 : 0] B;

    reg [a_width-1 : 0] A_v;
    reg [b_width-1 : 0] B_v;
    reg [b_width-1 : 0] REMAINDER_v;
    reg [b_width-1 : 0] MODULUS_v;
    reg A_x, B_x;
    reg [a_width+b_width-1:0] A_extended;

    begin
      // synopsys translate_off
      A_x = ^A;
      B_x = ^B;
      if ((A_x === 1'bx) || (B_x === 1'bx)) begin
	MODULUS_v = {a_width{1'bx}};
      end
      else begin
	if (B == 0) begin
	  A_extended = {{b_width{A[a_width-1]}},A};
	  MODULUS_v = A_extended[b_width-1:0];
`ifdef DW_SUPPRESS_WARN `else
	  $write ("WARNING: %m: Division by zero\n");
`endif
	end
	else begin
	  if (A[a_width-1] == 1'b1) A_v = ~A + 1'b1;
	  else A_v = A;
	  if (B[b_width-1] == 1'b1) B_v = ~B + 1'b1;
	  else B_v = B;
	  REMAINDER_v = A_v % B_v;
	  if (REMAINDER_v == {b_width{1'b0}})
	    MODULUS_v = REMAINDER_v;
	  else begin
	    if (A[a_width-1] == 1'b0)
	      MODULUS_v = REMAINDER_v;
	    else
	      MODULUS_v = ~REMAINDER_v + 1'b1;
	    if (A[a_width-1] != B[b_width-1])
	      MODULUS_v = B + MODULUS_v;
	  end
	end
      end
      DWF_mod_tc = MODULUS_v;
      // synopsys translate_on
    end
  endfunction

//-----------------------------------------------------------------------------


  
 
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
  
    if ( param_err_flg == 1) begin
      $display(
        "%m :\n  Simulation aborted due to invalid parameter value(s)");
      $finish;
    end

  end // parameter_check 



  always @(a or b)
  begin
    if (tc_mode == 0) begin
      quotient = DWF_div_uns (a, b);
      if (rem_mode == 1)
	remainder = DWF_rem_uns (a, b);
      else
	remainder = DWF_mod_uns (a, b);
    end
    else begin
      quotient = DWF_div_tc (a, b);
      if (rem_mode == 1)
	remainder = DWF_rem_tc (a, b);
      else
	remainder = DWF_mod_tc (a, b);
    end
    if (b == {b_width{1'b0}})
      divide_by_0 = 1'b1;
    else
      divide_by_0 = 1'b0;
  end 

endmodule

//-----------------------------------------------------------------------------

