module single_port_xpm #(
    parameter integer DATA_WIDTH                   = 8,
    parameter integer BUFFER_DEPTH                  = 128,
    parameter integer READ_LATENCY_A                = 1,
    parameter integer MEMORY_SIZE                   = 1024,
    parameter integer ADDR_WIDTH              = 8 

) (
      input                                         clk,
      input                                         rst,
      input [ADDR_WIDTH - 1 : 0]                    addr,
      input [DATA_WIDTH - 1 : 0]                    din,
      input                                         en,
      input                                         regcea,
      input                                         we,
      output                                        dbiterr,
      output [DATA_WIDTH - 1 : 0]                   dout,
      output                                        sbiterr
);

    wire                                            injectdbiterr;
    wire                                            injectsbiterr;
    wire                                            sleep;
    
    assign injectdbiterr   = 1'b0;
    assign injectsbiterr   = 1'b0;
    assign sleep            = 1'b0;

   xpm_memory_spram #(
      .ADDR_WIDTH_A(ADDR_WIDTH),              // DECIMAL
      .AUTO_SLEEP_TIME(0),           // DECIMAL
      .BYTE_WRITE_WIDTH_A(DATA_WIDTH),       // DECIMAL
      .CASCADE_HEIGHT(0),            // DECIMAL
      .ECC_MODE("no_ecc"),           // String
      .MEMORY_INIT_FILE("none"),     // String
      .MEMORY_INIT_PARAM("0"),       // String
      .MEMORY_OPTIMIZATION("true"),  // String
      .MEMORY_PRIMITIVE("block"),     // String
      .MEMORY_SIZE(MEMORY_SIZE),            // DECIMAL
      .MESSAGE_CONTROL(0),           // DECIMAL
      .READ_DATA_WIDTH_A(DATA_WIDTH),        // DECIMAL
      .READ_LATENCY_A(READ_LATENCY_A),            // DECIMAL
      .READ_RESET_VALUE_A("0"),      // String
      .RST_MODE_A("SYNC"),           // String
      .SIM_ASSERT_CHK(0),            // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
      .USE_MEM_INIT(1),              // DECIMAL
      .WAKEUP_TIME("disable_sleep"), // String
      .WRITE_DATA_WIDTH_A(DATA_WIDTH),       // DECIMAL
      .WRITE_MODE_A("read_first")    // String
   )
   xpm_memory_spram_inst (
      .dbiterra(dbiterr),             // 1-bit output: Status signal to indicate double bit error occurrence
                                       // on the data output of port A.

      .douta(dout),                   // READ_DATA_WIDTH_A-bit output: Data output for port A read operations.
      .sbiterra(sbiterr),             // 1-bit output: Status signal to indicate single bit error occurrence
                                       // on the data output of port A.

      .addra(addr),                   // ADDR_WIDTH_A-bit input: Address for port A write and read operations.
      .clka(clk),                     // 1-bit input: Clock signal for port A.
      .dina(din),                     // WRITE_DATA_WIDTH_A-bit input: Data input for port A write operations.
      .ena(en),                       // 1-bit input: Memory enable signal for port A. Must be high on clock
                                       // cycles when read or write operations are initiated. Pipelined
                                       // internally.

      .injectdbiterra(injectdbiterr), // 1-bit input: Controls double bit error injection on input data when
                                       // ECC enabled (Error injection capability is not available in
                                       // "decode_only" mode).

      .injectsbiterra(injectsbiterr), // 1-bit input: Controls single bit error injection on input data when
                                       // ECC enabled (Error injection capability is not available in
                                       // "decode_only" mode).

      .regcea(regcea),                 // 1-bit input: Clock Enable for the last register stage on the output
                                       // data path.

      .rsta(rst),                     // 1-bit input: Reset signal for the final port A output register stage.
                                       // Synchronously resets output port douta to the value specified by
                                       // parameter READ_RESET_VALUE_A.

      .sleep(sleep),                   // 1-bit input: sleep signal to enable the dynamic power saving feature.
      .wea(we)                        // WRITE_DATA_WIDTH_A/BYTE_WRITE_WIDTH_A-bit input: Write enable vector
                                       // for port A input data port dina. 1 bit wide when word-wide writes are
                                       // used. In byte-wide write configurations, each bit controls the
                                       // writing one byte of dina to address addra. For example, to
                                       // synchronously write only bits [15-8] of dina when WRITE_DATA_WIDTH_A
                                       // is 32, wea would be 4'b0010.

   );
				
endmodule