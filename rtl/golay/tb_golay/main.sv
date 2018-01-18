`include "interface.sv"
`include "test.sv"
`timescale 1ns/1ns

module main;
   
  //clock and reset signal declaration
  bit clk;
  bit reset;
  bit[11 : 0] codeword;
  
  //clock generation
  always #4 clk = ~clk;
   
  //reset Generation
  initial begin
    reset = 0;
    #8 reset =1;
  end
  
  //creatinng instance of interface, inorder to connect DUT and testcase
  intf i_intf(clk,reset);
   
  //Testcase instance, interface handle is passed to test as an argument
  test t1(i_intf);
  
   golay_encoder ENC (
    .clk_i(i_intf.clk),
    .rst_n_i(i_intf.reset),
    .stb_i(i_intf.stb),
    .payload_i(i_intf.payload),
    .code_word_o(i_intf.codeword));

   golay_decoder DEC ( 
    .clk_i(i_intf.clk),
    .rst_n_i(i_intf.reset),
    .stb_i(i_intf.stb_dec),
    .paycode_i(i_intf.codepay),
    .decoded_o(i_intf.decoded),
    .failed_o(i_intf.failed),
    .payload_o(i_intf.payload_rec));
  
  //enabling the wave dump
  initial begin
    $dumpfile("dump.vcd"); $dumpvars;
  end
endmodule
