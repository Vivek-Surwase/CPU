// File Name   : control.v
// Description : implementation of control logic
// Author      : Vivek Surwase (EE20B153)

module control(op,rv2_rf,drdata,rvout,imm,pc_curr,rwe,dwdata,wdata_r,daddr,dwe,alu_op,pc_next);

  //defining input_output ports

  input [5:0] op;             // 6-bit op code from decoder
  input [31:0] rv2_rf;        // value at rs2 register in regfile (used in case of store instructions)
  input [31:0] drdata;        // Data from DMEM
  input [31:0] rvout;         // ALU output (used for daddr calculation in Load and Store and iaddr calc in branch)
  input [31:0] imm;           // immediate value = used for PC increment (conditional branch & JAL), and for AUIPC, LUI
  input [31:0] pc_curr;       // current PC value

  output rwe;                 // regfile write enable
  output [31:0] dwdata;       // Data to be written to DMEM (during Store)
  output [31:0] wdata_r;      // Data to be written to regfile (during Load)
  output [31:0] daddr;        // address of DMEM location (to read/write)
  output [3:0] dwe;           // DMEM Write enable
  output [5:0] alu_op;        // 6-bit alu op code
  output [31:0] pc_next;      // next iaddr
  

  reg [31:0] dwdata, wdata_r, daddr, pc_next;
  reg [3:0] dwe;
  reg [5:0] alu_op;
  reg rwe;


  always @(*) 
    begin
      pc_next = pc_curr + 4;   // default: Increment PC by 4, write disabled
      dwe = 4'b0;
      rwe = 0;

      // ALU operation
      //alu_op = op if instr is ALU type
      if(op[3] == 1'b1) 
        begin
          alu_op = op;
          wdata_r = rvout;
          rwe = 1;
        end

      //Load/Store Instructions
      else if (op[4:3] == 2'b10) 
        begin                          // if load or store instr

          //alu_op = op if instr is ALU type = op(addi) if instr is load/store (+ JALR)
          alu_op = 6'b001000;   // op(addi)
          daddr = rvout;

          //Load Instructions
          case(op)

            6'b010000: 
              begin  //LB
                rwe = 1;
                // daddr[1:0] :- last two bits of address indicate the byte to be addressed
                case(daddr[1:0])    
                  2'b00:  wdata_r = {{24{drdata[7]}}, drdata[7:0]};   //Byte 0
                  2'b01:  wdata_r = {{24{drdata[15]}}, drdata[15:8]}; //Byte 1
                  2'b10:  wdata_r = {{24{drdata[23]}}, drdata[23:16]};//Byte 2
                  2'b11:  wdata_r = {{24{drdata[31]}}, drdata[31:24]};//Byte 3
                endcase
              end               //LB

            6'b010001: 
              begin  //LH
                rwe = 1;
                case(daddr[1:0])
                  2'b00:  wdata_r = {{16{drdata[15]}}, drdata[15:0]}; //HW 0
                  2'b10:  wdata_r = {{16{drdata[31]}}, drdata[31:16]};//HW 1
                endcase
              end               //LH

            6'b010010: 
              begin  //LW
                rwe = 1;
                case(daddr[1:0])
                  2'b00:  wdata_r = drdata;
                endcase
              end               //LW

            6'b010100: 
              begin  //LBU
                rwe = 1;
                case(daddr[1:0])
                  2'b00:  wdata_r = {24'b0, drdata[7:0]};   //Byte 0
                  2'b01:  wdata_r = {24'b0, drdata[15:8]};  //Byte 1
                  2'b10:  wdata_r = {24'b0, drdata[23:16]}; //Byte 2
                  2'b11:  wdata_r = {24'b0, drdata[31:24]}; //Byte 3
                endcase
              end               //LBU

            6'b010101: 
              begin  //LHU
                rwe = 1;
                case(daddr[1:0])    // last two bits of address indicate the byte to be addressed
                  2'b00:  wdata_r = {16'b0, drdata[15:0]}; //HW 0
                  2'b10:  wdata_r = {16'b0, drdata[31:16]};//HW 1
                endcase
              end               //LHU

            //Store Instructions
            6'b110000: 
            begin  //SB

              case(daddr[1:0])
                2'b00: begin 
                  dwe = 4'b0001;
                  dwdata = rv2_rf; 
                end
                2'b01: begin
                  dwe = 4'b0010;
                  dwdata = {rv2_rf<<8}; 
                end
                2'b10: begin 
                  dwe = 4'b0100;
                  dwdata = {rv2_rf<<16}; 
                end
                2'b11:  begin 
                  dwe = 4'b1000;
                  dwdata = {rv2_rf<<24}; 
                end
              endcase
            end               //SB

            6'b110001: 
            begin  //SH

              case(daddr[1:0])

                2'b00:  begin 
                  dwe = 4'b0011;
                  dwdata = rv2_rf; 
                end

                2'b10:  begin
                  dwe = 4'b1100;
                  dwdata = {rv2_rf<<16}; 
                end

              endcase
            end                 //SH

            6'b110010: 
            begin    //SW
              case(daddr[1:0])
                2'b00:  begin 
                  dwe = 4'b1111;
                  dwdata = rv2_rf; 
                end
              endcase
            end                 //SW

          endcase
        end // end Load/Store else


        // Conditional Branch
        else if (op[5:3] == 3'b100) 
          begin
          
          case (op[2:0])

            //alu_op = = op(sub)  (BEQ and BNE)
            3'b000 : 
            begin  //BEQ
              alu_op = 6'b111000; //op(SUB)
              if (rvout == 0) pc_next = pc_curr + imm;
            end             //BEQ

            3'b001 : 
            begin  //BNE
              alu_op = 6'b111000; //op(SUB)
              if (rvout != 0) pc_next = pc_curr + imm;
            end             //BNE

            3'b100 : 
            begin  //BLT
              alu_op = 6'b101010; //op(SLT)
              if (rvout[0])  pc_next = pc_curr + imm;
            end             //BLT

            3'b101 :
            begin  //BGE
              alu_op = 6'b101010; //op(SLT)
              if (!rvout[0]) pc_next = pc_curr + imm;
            end             //BGE

            3'b110 :
            begin  //BLTU
              alu_op = 6'b101011; //op(SLTU)
              if (rvout[0])  pc_next = pc_curr + imm;
            end             //BLTU

            3'b111 : 
            begin  //BGEU
              alu_op = 6'b101011; //op(SLTU)
              if (!rvout[0]) pc_next = pc_curr + imm;
            end             //BGEU

          endcase
        end
        
        else if (op[5:3] == 3'b0) 
        begin
          rwe = 1;

          //alu_op = = Dont care (JAL, AUIPC, LUI)
          //alu_op = = op(addi) if instr is JALR
          case(op[2:0])   
          3'b100: 
          begin   //JALR
            alu_op = 6'b001000;             // op(addi)
            wdata_r = pc_curr + 4;
            pc_next = {rvout[31:1], 1'b0};  //ALU input rv1 through control
          end             //JALR

          3'b101: 
          begin   //JAL
            wdata_r = pc_curr + 4;
            pc_next = pc_curr + imm;
          end             //JAL

          3'b010 :  wdata_r = pc_curr + imm;  //AUIPC

          3'b110 :  wdata_r = imm;            //LUI

          endcase
        end // end Branching else

    end // end always block

endmodule
