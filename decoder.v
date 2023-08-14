//File name   : decoder.v
//Description : implementation of decoder
//Author      : Vivek Surwase (EE20B153)

module decoder(idata,op,rs1,rs2,rd,rv2_rf,rv2,imm);

  //defining input-output ports 

  input [31:0] idata;      //Instruction fetched from IMEM
  output [5:0] op;     // Opcode (operation encoding)
  output [4:0] rs1;    // Address of first register source
  output [4:0] rs2;    // Address of second register source
  output [4:0] rd;     // Address of destination register
  input  [31:0] rv2_rf;    //From Register File
  output [31:0] rv2;   // To ALU
  output [31:0] imm;   // Immediate used as relative address in Branching and as upper imm in LUI


  reg [31:0] rv2;
  reg [5:0] op;
  reg [4:0] rs1, rs2, rd;
  reg [6:0] idata_op;
  reg [2:0] funct3;
  reg [6:0] funct7;
  reg [31:0] imm;

  //Decode instructions for ALU, Load/Store, Branch and Upper Immediate instructions
  always @(idata)
  begin
      rs1 = idata[19:15];
      rs2 = idata[24:20];
      rd  = idata[11:7];

      idata_op = idata[6:0];
      funct3 = idata[14:12];
      funct7 = idata[31:25];

      if (idata == 32'b0) 
        begin
          op = 6'b0;   // idata == 0 means no instruction is executed,all values are retained.
        end

      else if ({idata_op[4], idata_op[2]} == 2'b10) //ALU Type instruction
        begin 

          op[3] = 1;
          op[5] = idata_op[5];
          op[2:0] = funct3;

          // op[5] is alu_src control signal
          if (op[5] == 1'b1) 
            begin
              rv2   = rv2_rf;         // value returned by regfile
              op[4] = funct7[5];      // encoding add,sub, srl,sra
            end

          else if (op[1:0] == 2'b01) 
            begin                                     //shift immediate operation
              rv2 = {{27{idata[24]}}, idata[24:20]};  //sign extend shift;

              //alu considers only lower 5 bits of imm for shift
              op[4] = funct7[5];                      // srli/srai
            end

          else
            begin
              rv2 = {{20{idata[31]}}, idata[31:20]};  //sign extended immediate
              op[4] = 1'b0;
            end
      
      end


      else                              // Load/Store or Branch type instruction
        begin 

          op[3] = 0;
          op[4] = ({idata_op[6], idata_op[4]} == 2'b00);

          if (op[4]) 
            begin                   // Load-store instructions
              op[5] = idata_op[5];  // 0: LOAD, 1: STORE 
              op[2:0] = funct3;

              if (op[5] == 0) 
                begin
                  rv2 = {{20{idata[31]}}, idata[31:20]};               // LOAD
                end
              else 
                begin
                  rv2 = {{20{idata[31]}}, idata[31:25], idata[11:7]};  // STORE
                end
            end 
          
          else              // Branch instructions
            begin
              op[5] = ({idata_op[6:5], idata_op[2]} == 3'b110);
              
              if (op[5])    // Conditional Branch instructions
                begin
                  op[2:0] = funct3; 
                  rv2 = rv2_rf;     // alu computes val(rs1)-val(rs2)
                  imm = {{19{idata[31]}}, idata[31], idata[7], idata[30:25], idata[11:8], 1'b0}; // sign_ext(imm[12], imm[11], imm[10:5], imm[4:1], 0)
                end 
              
              else 
                begin         // JALR, JAL, LUI, AUIPC
                  op[2:0] = idata_op[5:3];
                  case(op[2:0])
                    3'b100 :  rv2 = {{20{idata[31]}}, idata[31:20]};  // JALR
                    3'b101 :  imm = {{11{idata[31]}}, idata[31], idata[19:12], idata[20], idata[30:21], 1'b0}; // JAL
                    3'b010 :  imm = {idata[31:12], 12'b0};            // AUIPC
                    3'b110 :  imm = {idata[31:12], 12'b0};            // LUI
                  endcase
                end
            end

      end
  end
  
endmodule
