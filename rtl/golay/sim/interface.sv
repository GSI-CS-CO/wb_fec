`timescale 1ns/1ns

interface intf(input logic clk,reset);
   
  //declaring the signals
  logic         stb;
  logic [11:0]  payload;
  logic [11:0]  codeword;
  logic [23:0]  codepay;
  logic         stb_dec;
  logic         decoded;
  logic         failed;
  logic [11:0]  payload_rec;
 
  clocking driver_cb @(posedge clk);
    //default input #1 output #1;
    input   codeword;
    output  payload;
    output  stb;
    output  codepay;
    output  stb_dec;
    input   decoded;
    input   failed;
    input   payload_rec;
  endclocking
  
  modport DRIVER(clocking driver_cb, input codeword);
endinterface
