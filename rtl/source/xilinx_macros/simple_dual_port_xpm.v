module simple_dual_port_xpm #(
    parameter integer WRITE_WIDTH                   = 8,
    parameter integer READ_WIDTH                    = 8,
    parameter integer BUFFER_DEPTH                  = 128,
    parameter integer READ_LATENCY_B                = 1,
    parameter integer MEMORY_SIZE                   = 1024,
    parameter integer WRITE_ADDR_WIDTH              = 8,  
    parameter integer READ_ADDR_WIDTH               = 8
) (
      input                                         clka,
      input                                         rstb,
      input [WRITE_ADDR_WIDTH - 1 : 0]              addra,
      input [READ_ADDR_WIDTH - 1 : 0]               addrb,
      input [WRITE_WIDTH - 1 : 0]                   dina,
      input                                         ena,
      input                                         enb,
      input                                         regceb,
      input                                         wea,
      output                                        dbiterrb,
      output [READ_WIDTH - 1 : 0]                   doutb,
      output                                        sbiterrb
);

    wire                                            clkb;
    wire                                            injectdbiterra;
    wire                                            injectsbiterra;
    wire                                            sleep;
    
    assign clkb             = 1'b0;
    assign injectdbiterra   = 1'b0;
    assign injectsbiterra   = 1'b0;
    assign sleep            = 1'b0;
    
    xpm_memory_sdpram #(
      .ADDR_WIDTH_A(WRITE_ADDR_WIDTH),               // DECIMAL
      .ADDR_WIDTH_B(READ_ADDR_WIDTH),               // DECIMAL
      .AUTO_SLEEP_TIME(0),            // DECIMAL
      .BYTE_WRITE_WIDTH_A(WRITE_WIDTH),        // DECIMAL
      .CASCADE_HEIGHT(0),             // DECIMAL
      .CLOCKING_MODE("common_clock"), // String
      .ECC_MODE("no_ecc"),            // String
      .MEMORY_INIT_FILE("none"),      // String
      .MEMORY_INIT_PARAM("0"),        // String
      .MEMORY_OPTIMIZATION("true"),   // String
      .MEMORY_PRIMITIVE("block"),      // String
      .MEMORY_SIZE(MEMORY_SIZE),             // DECIMAL
      .MESSAGE_CONTROL(0),            // DECIMAL
      .READ_DATA_WIDTH_B(READ_WIDTH),         // DECIMAL
      .READ_LATENCY_B(READ_LATENCY_B),             // DECIMAL
      .READ_RESET_VALUE_B("0"),       // String
      .RST_MODE_A("SYNC"),            // String
      .RST_MODE_B("SYNC"),            // String
      .SIM_ASSERT_CHK(0),             // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
      .USE_EMBEDDED_CONSTRAINT(0),    // DECIMAL
      .USE_MEM_INIT(1),               // DECIMAL
      .WAKEUP_TIME("disable_sleep"),  // String
      .WRITE_DATA_WIDTH_A(WRITE_WIDTH),        // DECIMAL
      .WRITE_MODE_B("read_first")      // String
   )
   xpm_memory_sdpram_inst (
      .dbiterrb(dbiterrb),             // 1-bit output: Status signal to indicate double bit error occurrence
                                       // on the data output of port B.

      .doutb(doutb),                   // READ_DATA_WIDTH_B-bit output: Data output for port B read operations.
      .sbiterrb(sbiterrb),             // 1-bit output: Status signal to indicate single bit error occurrence
                                       // on the data output of port B.

      .addra(addra),                   // ADDR_WIDTH_A-bit input: Address for port A write operations.
      .addrb(addrb),                   // ADDR_WIDTH_B-bit input: Address for port B read operations.
      .clka(clka),                     // 1-bit input: Clock signal for port A. Also clocks port B when
                                       // parameter CLOCKING_MODE is "common_clock".

      .clkb(clkb),                     // 1-bit input: Clock signal for port B when parameter CLOCKING_MODE is
                                       // "independent_clock". Unused when parameter CLOCKING_MODE is
                                       // "common_clock".

      .dina(dina),                     // WRITE_DATA_WIDTH_A-bit input: Data input for port A write operations.
      .ena(ena),                       // 1-bit input: Memory enable signal for port A. Must be high on clock
                                       // cycles when write operations are initiated. Pipelined internally.

      .enb(enb),                       // 1-bit input: Memory enable signal for port B. Must be high on clock
                                       // cycles when read operations are initiated. Pipelined internally.

      .injectdbiterra(injectdbiterra), // 1-bit input: Controls double bit error injection on input data when
                                       // ECC enabled (Error injection capability is not available in
                                       // "decode_only" mode).

      .injectsbiterra(injectsbiterra), // 1-bit input: Controls single bit error injection on input data when
                                       // ECC enabled (Error injection capability is not available in
                                       // "decode_only" mode).

      .regceb(regceb),                 // 1-bit input: Clock Enable for the last register stage on the output
                                       // data path.

      .rstb(rstb),                     // 1-bit input: Reset signal for the final port B output register stage.
                                       // Synchronously resets output port doutb to the value specified by
                                       // parameter READ_RESET_VALUE_B.

      .sleep(sleep),                   // 1-bit input: sleep signal to enable the dynamic power saving feature.
      .wea(wea)                        // WRITE_DATA_WIDTH_A/BYTE_WRITE_WIDTH_A-bit input: Write enable vector
                                       // for port A input data port dina. 1 bit wide when word-wide writes are
                                       // used. In byte-wide write configurations, each bit controls the
                                       // writing one byte of dina to address addra. For example, to
                                       // synchronously write only bits [15-8] of dina when WRITE_DATA_WIDTH_A
                                       // is 32, wea would be 4'b0010.

   );

endmodule

   // End of xpm_memory_sdpram_inst instantiation
				
				