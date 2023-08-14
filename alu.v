//File name   : alu.v
//Description : implementation of ALU block
//Author      : Vivek Surwase (EE20B153)

module alu(op,in1,in2,out);

  //defining input-output ports
  input [5:0] op;       // 6-bit alu op code
  input [31:0] in1;     // First operand
  input [31:0] in2;     // Second operand
  output [31:0] out;    // Output value

  reg [31:0] out_r;

  assign out = out_r;

  always @(*)
    begin
      case (op[4:0])
        5'b01000 : out_r = in1 + in2;           // ADD, ADDI
        5'b11000 : out_r = in1 - in2;           // SUB
        5'b01001 : out_r = {in1 << {in2[4:0]}}; // SLL, SLLI
        5'b01010 : out_r = {{31{1'b0}}, ($signed(in1) < $signed(in2))}; // SLT, SLTI
        5'b01011 : out_r = {31'b0, (in1<in2)};  // SLTU, SLTIU
        5'b01100 : out_r = in1 ^ in2;           // XOR, XORI
        5'b01101 : out_r = {in1 >> {in2[4:0]}}; // SRL, SRLI
        5'b11101 : out_r = {in1 >>> {in2[4:0]}};// SRA, SRAI
        5'b01110 : out_r = in1 | in2;           // OR, ORI
        5'b01111 : out_r = in1 & in2;           // AND, ANDI
        default : out_r = 32'bx;                // invalid opcode -> O/P to unknown state
      endcase
    end
endmodule
