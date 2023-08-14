// File name   : cpu.v
// Description : implementation of single cycle CPU
// Author      : Vivek Surwase (EE20B153)

module cpu (clk,reset,iaddr,idata,daddr,drdata,dwdata,dwe);

  //defining input-output ports
  input clk;
  input reset;
  output [31:0] iaddr;
  input [31:0] idata;
  output [31:0] daddr;
  input [31:0] drdata;
  output [31:0] dwdata;
  output [3:0] dwe;


  reg [31:0] iaddr, daddr, dwdata;
  reg [3:0]  dwe;

  // Wire declaration for instantiation
  wire [5:0] op, alu_op;
  wire [4:0] rs1, rs2, rd;
  wire [31:0] rv1, rv2, rv2_rf, rvout, r_wdata, daddr_w, dwdata_w;
  wire rwe;
  
  // Wires required in control logic
  wire [31:0] imm, pc_next, pc_curr;
  wire [3:0]  dwe_w;

  always @(posedge clk) 
    begin
        if (reset) 
          begin                // resets all the values
              iaddr <= 0;
          end 
        else 
          begin
              iaddr <= pc_next; // pc_next is determined by Control module
          end
    end

  // Instantiate alu
  alu alu1 (
    .op(alu_op),  //in
    .in1(rv1),    //in
    .in2(rv2),    //in
    .out(rvout)   //out
  );

  // Instantiate decoder
  decoder dec1 (
    .idata(idata),      //in
    .rv2_rf(rv2_rf),    //in
    .op(op),            //out
    .rs1(rs1),          //out
    .rs2(rs2),          //out
    .rd(rd),            //out
    .rv2(rv2),          //out
    .imm(imm)           //out
  );

  // Instantiate regfile
  regfile reg1(
    .rs1(rs1),          //in
    .rs2(rs2),          //in
    .rd(rd),            //in
    .we(rwe),           //in(from control)
    .wdata(r_wdata),    //in
    .rv1(rv1),          //out
    .rv2(rv2_rf),       //out
    .clk(clk),
    .reset(reset)
  );

  // Instantiate control logic block
  control ls1(
    .op(op),              //in
    .rv2_rf(rv2_rf),      //in(store operations)
    .drdata(drdata),      //in
    .rvout(rvout),        //in
    .imm(imm),            //in
    .pc_curr(iaddr),      //in
    .alu_op(alu_op),      //out
    .rwe(rwe),            //out
    .daddr(daddr_w),      //out
    .dwdata(dwdata_w),    //out
    .wdata_r(r_wdata),    //out
    .dwe(dwe_w),          //out
    .pc_next(pc_next)     //out
  );

  //Load DMEM write enable, address and write data from output wires of control module
  always @(daddr_w or dwdata_w or dwe_w) 
    begin
      daddr = daddr_w;
      dwdata = dwdata_w;
      dwe = dwe_w;
    end

endmodule
