//File name   : regfile.v
//Description : implementation of register file
//Author      : Vivek Surwase(EE20B153)

module regfile(rs1,rs2,rd,we,wdata,rv1,rv2,clk,reset);

    //defining input-output ports

    input [4:0] rs1;     // address of source register 1
    input [4:0] rs2;     // address of source register 2
    input [4:0] rd;      // address of destination register
    input we;            // write enable signal
    input [31:0] wdata;  // value to be written (din bus)
    output [31:0] rv1;   // value of source register 1
    output [31:0] rv2;   // value of source register 2
    input clk;           // clk signal for flip-flops
    input reset;         // reset



    reg [31:0] x [0:31];   //register file
    integer i;
    
    //setting all the values of register file to 0 initially
    initial 
      begin
        for (i=0; i<32; i=i+1)
          x[i] <= {32'b0};
      end 
    
    
    //Synchronous write to register file
    always @(posedge clk) 
      begin
        if (reset) 
          begin
            for (i=0; i<32; i=i+1) 
              x[i] <= {32'b0};
          end

        else if(we)
          begin
            if(rd != 5'b0)   //x[0] = 0 always
              begin
                x[rd] <= wdata;  
              end               
          end
      end

    //Asynchronous read
    assign rv1 = x[rs1];
    assign rv2 = x[rs2];
    
endmodule
