////////////////////////////////////  Main module ////////////////////////////////////////////////////////
module main (
	input wire clk 
	);		  
	wire [31:0] instruction_out ,npc,instruction;
	wire [3:0] Rs_add, Rd_add , Rt_add;
	wire WB , memo_w , memo_r , RW, ALU_sor ,enable;
	wire [1:0] ALUop;
	wire [31:0]imm;
	wire [31:0] pc_plus_one ,B_target,J_target ;
	wire [1:0] pc_sel;
	wire [31:0] bus_A,bus_B;
	wire [1:0]IF_reg_in_sel;
	wire [3:0] Rd4_out;
	
	
	reg reset;
	initial begin
		reset =1;
		#20ns 
		
		reset =0;
	end
	
	// fetch stage
	FetchStage f1(pc_sel , B_target , J_target , bus_A , pc_plus_one , // new address for PC 
	clk , reset ,enable ,  
	instruction , npc ); // outputs --> new instruction  ,  new PC value 
	
	
    PCAdder adder (npc , pc_plus_one); // pc = pc + 1 
	
	Branch B1(.imm(imm),.pc(npc),.target(B_target));	// breanch target address
	
	jump j1(.imm(imm),.target(J_target));	// jump target address
	wire enable22;
	// PC control
	pc_control PcControl(
	.opcode(instruction_out[31:26]),.check_load(check_load),
	.Rd_load(Rd2),.Rd_now(instruction_out[25:22]),.Rs_now(instruction_out[21:18]),.Rt_now(instruction_out[17:14]),
	.Rs(bus_A) ,	  // Rs after handl hazard 
	.reset(reset),
	.enable(enable),
	.enable2(enable22),
	.pc_sel(pc_sel),
	.IF_reg_in_sel(IF_reg_in_sel ));
	
	wire [31:0] zero,lw_instruction,sw_instruction,instruction_bus;
	kill_reg k1(.zero(zero));
	Lw l1(.imm(instruction_out[13:0]) ,.Rs(instruction_out[21:18]),.Rd(instruction_out[25:22]),.new_instruction(lw_instruction));
	Sw s1(.imm(instruction_out[13:0]) ,.Rs(instruction_out[21:18]),.Rd(instruction_out[25:22]),.new_instruction(sw_instruction));	
	
	
	
	mux4_1 IFmux( .in0(lw_instruction) , .in1(sw_instruction) , .in2(zero),.in3(instruction)  , // data stage , Registor , ALU result ,data memory stage 
	.sel(IF_reg_in_sel) ,// selector
	.out(instruction_bus));	 //ALU sor 1
	
	
	wire [31:0] npc1;
	// Registor between IF and ID 
	wire [31:0] out_instruction;	
	IF_reg_out IF_r(.clk(clk),
	.instruction(instruction_bus),
	.pc(npc),
	.instruction_out(out_instruction),
	.pc_out(npc1)
	);
	
	instruction_ID r6(.I(out_instruction) ,.enable(enable222),.I_out(instruction_out));
	
	sign_exdend s2(.imm(instruction_out[13:0]),.sign(1'b1),.out(imm));
	
	////////////////////////////////////////////////// Decode stage	 //////////////////////////////////////////	
	wire cll1;
	ID d1(
	.instruction(instruction_out),
	.Rs_add(Rs_add),.Rd_add(Rd_add),.Rt_add(Rt_add),// registor file addresses
	.WB(WB) ,.memo_w(memo_w) ,.memo_r(memo_r),.RW(RW),.ALU_sor(ALU_sor),.cll(cll1), // control signals
	.ALUop(ALUop) // ALU opreation
	); 
	
	wire [1:0] ALU_sor_sel1,ALU_sor_sel2;
	wire [3:0] Rd2;
	wire [3:0] Rd3out;
	
	Hazard_Detect_and_forward H1(
	.Rd2(Rd2),.Rd3(Rd3out),.Rd4(Rd4_out),//input
	.Rs(instruction_out[21:18]) ,.Rt(instruction_out[17:14]),.Rd(instruction_out[25:22]),//input
	.RW1(RW_out1),.RW2(RW_out2),.RW3(RW_out4),
	.ALU_sor_sel1(ALU_sor_sel1),.ALU_sor_sel2(ALU_sor_sel2),.Rd_haz(RD_hazard_sel) //output
	);
	wire [3:0] Rd_address;
	
	 mux2_1fourbit mf1(.A(instruction_out[25:22]), .B(4'b1110), .Sel(cll1), .out(Rd_address));
	
	wire [31:0] Bus1,Bus2,BusRd;
	wire [1:0] RD_hazard_sel;
	wire [31:0] Bus_RD;
	Register_File rf1(  
    .Rs1(instruction_out[21:18]),.Rs2(instruction_out[17:14]),.Rd(instruction_out[25:22]),
    .clk(clk),
	.Rd_WB(Rd4_out), // siganl
    .RegWr(RW_out4), // form WB stage ADDRESS
    .WBus(R_in),	// form WB stage 
    .Bus1(Bus1),.Bus2(Bus2),.BusRd(BusRd) // reg(Rs) , reg(Rt), reg(Rd)
	);

	//Rs//
	mux4_1 ALUs1( .in0(Bus1) , .in1(h1) , .in2(h2),.in3(h3) , // data stage , Registor , ALU result ,data memory stage
	.sel(ALU_sor_sel1) ,// selector
	.out(bus_A));	 //ALU sor 1
	
	//Rt//
	mux4_1 ALUs2( .in0(Bus2) , .in1(h1) , .in2(h2) ,.in3(h3), // data stage , Registor , ALU result ,data memory stage
	.sel(ALU_sor_sel2), // selector
	.out(bus_B));	 // ALU sor 2
	
	mux4_1 Rd_h1( .in0(BusRd) , .in1(h1) , .in2(h2) ,.in3(h3), // data stage , Registor , ALU result ,data memory stage
	.sel(RD_hazard_sel), // selector
	.out(Bus_RD));	 // ALU sor 2
	
	///? ID registor
	wire [31:0] immout, Aout , Bout , Rout;
	
	wire WB_out1 , memo_wout1,memo_rout1,RW_out1 , ALU_sorout1; 
	wire [1:0] ALUopout;
	wire [31:0] npc2;
	wire cll2;
	wire [5:0] check_load;
	wire enable222;
	
	ID_reg_out idr1(
	.clk(clk),
	.enable(enable22),
	.cheack_load(instruction_out[31:26]),
	.imm(imm),.A(bus_A) ,.B(bus_B),.R(Bus_RD),
	.ALUop(ALUop),
	.Rd(Rd_address),
	.WB(WB) ,.memo_w(memo_w) ,.memo_r(memo_r),.RW(RW),.ALU_sor(ALU_sor),
	.pc(npc1),
	.cll(cll1),
	.immout(immout),.Aout(Aout) ,.Bout(Bout),.Rout(Rout),
	.Rdout(Rd2),
	.WBout(WB_out1) ,.memo_wout(memo_wout1), .memo_rout(memo_rout1), .RWout(RW_out1) , .ALU_sorout(ALU_sorout1),
	.ALUopout(ALUopout),
	.pc_out(npc2),
	.cll_out(cll2),
	.cheack_load_out(check_load),
	.enable_out(enable222)
	);
	////////////////////////////////////////////////////////////////////////////////////////////
	wire [31:0] h1,h2,h3;
	/////////////////////////////////  ALU  /////////////////////////////////////////////
	wire [31:0] bus_b_for_alu;
	mux2_1 m3(.A(Bout),.B(immout),.Sel(ALU_sorout1),.out(bus_b_for_alu));
	
	wire [31:0]ALU_result;
	ALU A1(
    .ALUop(ALUopout),
    .Rs(Aout),.Rt(bus_b_for_alu),
    .Rd(ALU_result)
	);
	
	mux2_1 m9(.A(ALU_result),.B(npc2),.Sel(cll2),.out(h1));
	///? ALU Registor 
	wire [31:0] memo_in;
	wire  WB_out2 , memow_out2,memor_out2,RW_out2;
	
	wire [31:0] ALU_result_out;	
	wire [31:0] npc3;
	wire cll3;
	ALU_reg_out aluro1(
	.clk(clk),
	.ALU_result(ALU_result),
	.data_in(Rout), // Rd
	.WB(WB_out1) ,.memo_w(memo_wout1), .memo_r(memo_rout1), .RW(RW_out1) ,
	.Rd(Rd2),
	.pc(npc2),
	.cll(cll2),
	.ALU_result_out(ALU_result_out),
	.data_in_out(memo_in), // Rd
	.WB_out(WB_out2) ,.memo_w_out(memow_out2),.memo_r_out(memor_out2),.RW_out(RW_out2) ,
	.Rd_out(Rd3out),
	.pc_out(npc3),
	.cll_out(cll3)
	
	);
	////////////////////////////////////////////////////////////////////////////////////
	//////////////////////////////////////// Data memory ///////////////////////////////
	wire [31:0] memory_data_out; 
	
	DataMemory dm1(.clk(clk),
	.memRead(memor_out2),.memWrite(memow_out2),
	.address(ALU_result_out[7:0]),
	.writeData(memo_in),
	.readData(memory_data_out));
	wire [31:0] write_back_data;
	
	mux2_1 m4(.A(ALU_result_out),.B(memory_data_out),.Sel(WB_out2),.out(write_back_data));
	
	mux2_1 m10(.A(write_back_data),.B(npc3),.Sel(cll3),.out(h2));
	
	wire [31:0] WriteBackData_out;
	
	wire RW_out4;
	wire cll4;
	wire [31:0] npc4;
	DataMemory_reg dmr1(
	.clk(clk),
	.WriteBackData(write_back_data),
	.Rd4(Rd3out),
	.RW(RW_out2),//signal
	.pc(npc3),
	.cll(cll3),
	.WriteBackData_out(WriteBackData_out),
	.Rd4_out(Rd4_out),
	.RW_out(RW_out4), //signal
	.pc_out(npc4),
	.cll_out(cll4)
	);
	wire [31:0] R_in;
	
	
	mux2_1 m11(.A (WriteBackData_out),.B(npc4), .Sel(cll4), .out (h3));
 mux2_1 m6(.A (WriteBackData_out),.B(npc4), .Sel(cll4), .out (R_in));	
	
	
endmodule 

module instruction_ID (input [31:0] I ,input enable,output reg [31:0] I_out);
	
	
	
	always @(*) begin
	 if (enable)
		 I_out = I;
		
	end
	
	
	endmodule 



// Kill reg:
module kill_reg(output reg [31:0]  zero);
assign zero = 32'd0;
	
endmodule 

// Lw reg:
module Lw (input [13:0] imm , input [3:0] Rs,Rd,output reg [31:0]new_instruction);
	wire [13:0] imm_plus = imm + 1'b1;
	wire [3:0] Rd_plus = Rd +1'b1;
	assign new_instruction = {4'd6,Rd_plus,Rs,4'd0,imm_plus};
	
	endmodule 
	
module Sw (input [13:0] imm , input [3:0] Rs,Rd,output reg  [31:0]new_instruction);
	wire [13:0] imm_plus = imm + 1'b1;
	wire [3:0] Rd_plus = Rd +1'b1;
	assign new_instruction = {4'd7,Rd_plus,Rs,4'd0,imm_plus};
	
endmodule

////////////////////////////////////  Fetch Stage ////////////////////////////////////////////////////////

module FetchStage (
	input [1:0] sel,
	input  [31:0] Branch , Jump , jump_Rs ,pc_plus_one ,
	input  clk,
	input  reset,enable,
	output  [31:0] instruction,
	output  [31:0] pc_next
	);
	
	
	
	
	
	wire [31:0] pc_next_wire;
	wire [31:0]	pc_current;
	assign pc_next = pc_next_wire;
	
    // PC counter reg
    ProgramCounter pc_reg (clk,reset,enable,pc_current,pc_next_wire);
	// pc result breach or jump ...
	mux4_1 pc_mux( .in0(Branch) , .in1(Jump) , .in2(jump_Rs) ,.in3(pc_plus_one) , .sel(sel), .out(pc_current));
    // instruction result 
	InstructionMemory imem (.address(pc_next_wire),.instruction(instruction));
endmodule

 ///////!!!!!!!!!!!!!
module IF_reg_out (
	input clk,
	input [31:0] instruction,
	input [31:0] pc,
	output reg [31:0] instruction_out,
	output reg [31:0] pc_out
	);
	
	reg [31:0] buffer;
	reg [31:0] pc_buffer;
	
	// posedge for read  ......  negedge for write 	 
		
	always @(posedge clk)begin
		instruction_out = buffer;
		 pc_out = pc_buffer;
		end
	
	always @(*) begin
		buffer = instruction;
		pc_buffer = pc;
		
		end
		
endmodule	



module ProgramCounter (input wire clk,input wire reset,input wire enable ,input wire [31:0] pc_in,output reg [31:0] pc_out);
    always @(posedge clk or posedge reset) begin
    if (reset)
        pc_out <= 32'b0;
    else if (enable)
        pc_out <= pc_in;
end

endmodule


//////////////// edit on PC ///////////////////
module PCAdder (input wire [31:0] pc_in,output wire [31:0] pc_out);	  
	
    assign pc_out = pc_in + 1;				 //pc_out = pc_in + 4							

endmodule

module Branch (
 input [31:0] imm, pc,
 output reg [31:0] target
 );
 always @(*)begin
	 	target = imm + pc;
	 end
	
endmodule

module jump (
 input [31:0] imm,
 output reg [31:0] target
 );
 always @(*)begin
	 	target = imm ;
	 end
	
endmodule 
///////////////////////////////////////////////////	
 


/////////////////////////////////// Instruction memory ////////////////////////////////////////
module InstructionMemory (input wire [31:0] address,output wire [31:0] instruction);
  reg [31:0] memory [0:255] ;  

    initial begin
        $readmemh("instructions.mem", memory);  // Load instructions
    end

    assign instruction = (address[9:0] < 256) ? memory[address[9:0]] : 32'd0;  // Word aligned access
endmodule
///////////////////////////////////////////////////////////////////////////////////////////////




////////////////////////////////////  PC control ///////////////////////////////////////////////////
module pc_control (
	input [5:0] opcode, check_load,
	input [31:0] Rs, // !!!! after mux !!!! // 
	input [3:0] Rd_load,Rd_now,Rs_now,Rt_now,
	input reset,
	output reg enable,enable2,
	output reg [1:0] pc_sel,
	output reg [1:0] IF_reg_in_sel
	);
	
	
	always @(*) begin 
		
		if (reset) begin
            enable = 1'b1;
            pc_sel = 2'b11;
            IF_reg_in_sel = 2'b11; 
			enable2 = 1'b1;
			
		end	
		
	else begin
		
		
		
		
		case (opcode)
			
			6'd8 : begin
			enable =1'b0;
			pc_sel = 2'b11;
			IF_reg_in_sel=2'b00;//lw
			enable2 = 1'b1;
			end
			
			
			6'd9: begin 
			enable =1'b0;
			pc_sel = 2'b11;	
			IF_reg_in_sel=2'b01;//sw 
			enable2 = 1'b1;
			end
			
			
			
			6'd10:	begin
			if (Rs == 32'd0)  begin
				pc_sel = 2'b00;
				enable =1'b1;
				IF_reg_in_sel=2'b10;//instruction
				enable2 = 1'b1;
				end
			else   begin
				pc_sel =2'b11;
				enable =1'b1;
				IF_reg_in_sel=2'b11;//instruction 
				enable2 = 1'b1;
			end
			end
			
			
			
			6'd11:	begin
			if (Rs[31] != 1'b1 && Rs != 0)begin
				pc_sel = 2'b00;	
				enable =1'b1;
				IF_reg_in_sel=2'b10;//instruction 
				enable2 = 1'b1;
			end	
			
			else begin
				pc_sel =2'b11;
				enable =1'b1;
				IF_reg_in_sel=2'b11;//instruction
				enable2 = 1'b1;
				
			end
			end
			
				
			6'd12: begin
			if (Rs[31] == 1'b1 && Rs != 0)	begin
				pc_sel = 2'b00;
				enable =1'b1;
				IF_reg_in_sel=2'b10;//instruction
				enable2 = 1'b1;
				end
			else  begin
				pc_sel =2'b11;
				enable =1'b1;
				IF_reg_in_sel=2'b11;//instruction 
				enable2 = 1'b1;
			end
			end
				
			6'd13:	begin
			pc_sel = 2'b10;
			enable =1'b1;
			IF_reg_in_sel=2'b10;//instruction
			enable2 = 1'b1;
			end
			
			6'd14:begin
			pc_sel = 2'b01;
			enable =1'b1;
			IF_reg_in_sel=2'b10;//instruction 
			enable2 = 1'b1;
			end
			
			6'd15: begin
			pc_sel = 2'b01;
			enable =1'b1;
			IF_reg_in_sel=2'b10;//instruction
			enable2 = 1'b1;
			end

			
			default:  begin	
				if (check_load == 6'd6 && Rd_load == Rd_now && (opcode == 6'd7 || opcode == 6'd9)) begin 
					pc_sel = 2'b11;
					enable =1'b0 ;
					IF_reg_in_sel=2'b11;//instruction 
					enable2 = 1'b0;
				end
			else if (check_load == 6'd6 &&( Rd_load == Rs_now ||Rd_load == Rt_now)  && opcode != 6'd6)begin
				  pc_sel = 2'b11;
				enable =1'b0 ;
				IF_reg_in_sel=2'b11;//instruction 
				enable2 = 1'b0;
			end						 
			
			else begin
			pc_sel = 2'b11;
			enable =1'b1 ;
			IF_reg_in_sel=2'b11;//instruction
			enable2 = 1'b1;
			end
			 end
		endcase
		end
		
	
		end
	
endmodule



/////////////////////////////////////////////////// Instruction Decode //////////////////////////////////////////////////////////

module ID (
	input [31:0] instruction,
	output reg [3:0] Rs_add, Rd_add , Rt_add,
	output reg  WB , memo_w , memo_r , RW, ALU_sor, cll,  // write back , memory write , memory read , registor write , ALU source
	output reg [1:0] ALUop
	);
	
	always @(*)begin 

	
	if (instruction == 32'd0) begin 
		
		Rd_add = 4'bxxxx;
		Rs_add = 4'bxxxx;
		Rt_add = 4'bxxxx;
		
			ALUop =2'bxx;
			memo_w = 1'b0;
			memo_r = 1'b0;
			RW = 1'b0;
			ALU_sor=1'b0;
			WB = 1'bx;
			cll =1'b0;
			
	end
	
	else
		begin 
	Rd_add = instruction [25:22];
	Rs_add = instruction [21:18];
	Rt_add = instruction [17:14];
		

		case (instruction [31:26])
			
            6'd0: begin
			ALUop =2'b00;
			memo_w = 1'b0;
			memo_r = 1'b0;
			RW = 1'b1;
			ALU_sor=1'b0;
			WB = 1'b0;
			cll =1'b0;
			end
			
			6'd1:	begin
			ALUop =2'b01;
			memo_w = 1'b0;
			memo_r = 1'b0;
			RW = 1'b1;
			ALU_sor=1'b0;
			WB = 1'b0;
			cll =1'b0;
			end
			
			6'd2: begin
			ALUop =2'b10;
			memo_w = 1'b0;
			memo_r = 1'b0;
			RW = 1'b1;
			ALU_sor=1'b0;
			WB = 1'b0;
			cll =1'b0;
			end
			
			6'd3: begin
			ALUop =2'b11;
			memo_w = 1'b0;
			memo_r = 1'b0;
			RW = 1'b1;
			ALU_sor=1'b0;
			WB = 1'b0;
			cll =1'b0;
			end
			
			6'd4: begin
			ALUop =2'b00;
			memo_w = 1'b0;
			memo_r = 1'b0;
			RW = 1'b1;
			ALU_sor=1'b1;
			WB = 1'b0;
			cll =1'b0;
			end
			
			6'd5:  begin
			ALUop =2'b01;
			memo_w = 1'b0;
			memo_r = 1'b0;
			RW = 1'b1;
			ALU_sor=1'b1;
			WB = 1'b0;
			cll =1'b0;
			end
			
			6'd6:  begin
			ALUop =2'b01;
			memo_w = 1'b0;
			memo_r = 1'b1;
			RW = 1'b1;
			ALU_sor=1'b1;
			WB = 1'b1;
			cll =1'b0;
			end
			
			6'd7: begin
			ALUop =2'b01;
			memo_w = 1'b1;
			memo_r = 1'b0;
			RW = 1'b0;
			ALU_sor=1'b1;
			WB = 1'bx; 
			cll =1'b0;
			end
			
			///////LDW
			6'd8:	begin
			ALUop =2'b01;
			memo_w = 1'b0;
			memo_r = 1'b1;
			RW = 1'b1;
			ALU_sor=1'b1;
			WB = 1'b1;
			cll =1'b0;
			end
			
			////////SDW
			6'd9:  begin
			ALUop =2'b01;
			memo_w = 1'b1;
			memo_r = 1'b0;
			RW = 1'b0;
			ALU_sor=1'b1;
			WB = 1'bx;
			cll =1'b0;
			end
			
			//////// jump and branch
			
			6'd10: begin
			ALUop =2'bxx;
			memo_w = 1'b0;
			memo_r = 1'b0;
			RW = 1'b0;
			ALU_sor=1'bx;
			WB = 1'bx;
			cll =1'b0;
			end
			
			6'd11: begin
			ALUop =2'bxx;
			memo_w = 1'b0;
			memo_r = 1'b0;
			RW = 1'b0;
			ALU_sor=1'bx;
			WB = 1'bx;
			cll =1'b0;
			end
			
			6'd12: begin
			ALUop =2'bxx;
			memo_w = 1'b0;
			memo_r = 1'b0;
			RW = 1'b0;
			ALU_sor=1'bx;
			WB = 1'bx;
			cll =1'b0;
			end
			
			6'd13: begin
			ALUop =2'bxx;
			memo_w = 1'b0;
			memo_r = 1'b0;
			RW = 1'b0;
			ALU_sor=1'bx;
			WB = 1'bx;
			cll =1'b0;
			end
			
			6'd14: begin
			ALUop =2'bxx;
			memo_w = 1'b0;
			memo_r = 1'b0;
			RW = 1'b0;
			ALU_sor=1'bx;
			WB = 1'bx;
			cll =1'b0;
			end
			
			6'd15: begin
			ALUop =2'bxx;
			memo_w = 1'b0;
			memo_r = 1'b0;
			RW = 1'b1;
			ALU_sor=1'bx;
			WB = 1'bx;
			cll =1'b1;
			end
			
        endcase
		end
		
		
			
	end 	
	
	
	
	

endmodule 

module Register_File(  
    input  [3:0]  Rs1, Rs2, Rd,
    input clk,
    input RegWr,
	input [3:0] Rd_WB,
    input  [31:0] WBus,
    output reg [31:0] Bus1, Bus2,BusRd
);
    reg [31:0] rf[15:0]; // 16 registers, 32-bit each
    												 
    initial begin   
        for (int i = 0; i < 16; i = i + 1)
            rf[i] = 0;
			
			
    end
															   
    always @(posedge clk) begin															   
        if (RegWr)
            rf[Rd_WB] = WBus;
    end
    
    always @(*) begin
        Bus1 = rf[Rs1];
        Bus2 = rf[Rs2];
		BusRd = rf[Rd];
    end
																		   
    initial begin
        $monitor("R0=%h R1=%h R2=%h R3=%h R4=%h R5=%h R6=%h R7=%h R8=%h R9=%h R10=%h R11=%h R12=%h R13=%h R14=%h R15=%h", 
                 rf[0], rf[1], rf[2], rf[3], rf[4], rf[5], rf[6], rf[7],
                 rf[8], rf[9], rf[10], rf[11], rf[12], rf[13], rf[14], rf[15]);
    end
endmodule


module Hazard_Detect_and_forward (
	input [3:0] Rd2,Rd3,Rd4,
	input [3:0] Rs , Rt, Rd,
	input RW1,RW2,RW3,
	output reg [1:0] ALU_sor_sel1,ALU_sor_sel2 , Rd_haz
	);
	
	always @(*) begin
		if ( Rd2 == Rs && RW1)
			ALU_sor_sel1 = 2'b01;
		else if ( Rd3 == Rs && RW2)
			ALU_sor_sel1 = 2'b10;
		else if ( Rd4 == Rs && RW3)
			ALU_sor_sel1 = 2'b11;
		else 
			ALU_sor_sel1 = 2'b00;
			
		if ( Rd2 == Rt && RW1)
			ALU_sor_sel2 = 2'b01;
		else if ( Rd3 == Rt && RW2)
			ALU_sor_sel2 = 2'b10;
		else if ( Rd4 == Rt && RW3)
			ALU_sor_sel2 = 2'b11;
		else 
			ALU_sor_sel2 = 2'b00;
		
		if ( Rd2 == Rd && RW1)
			Rd_haz = 2'b01;
		else if ( Rd3 == Rd && RW2)
			Rd_haz = 2'b10;
		else if ( Rd4 == Rd && RW3)
			Rd_haz = 2'b11;
		else 
			Rd_haz = 2'b00;	
			
		end
	
endmodule 
// registor between EX and ID
module ID_reg_out (
	input clk,
	input [5:0] cheack_load,
	input enable,
	input [31:0] imm, A , B, R,	//
	input [1:0] ALUop,
	input [3:0] Rd,
	input WB , memo_w,memo_r,RW , ALU_sor,
	input [31:0] pc,
	input cll,
	output reg [31:0] immout, Aout , Bout ,Rout,//
	output reg [3:0] Rdout,
	output  reg WBout , memo_wout,memo_rout,RWout, ALU_sorout,
	output reg [1:0] ALUopout,
	output reg [31:0] pc_out,
	output reg cll_out, 
	output reg [5:0]  cheack_load_out,
	output reg enable_out
	); 
	reg [31:0] Bimm,BA,BB,BR;
	reg [3:0] BRd;
	reg BWB , Bmemo_w,Bmemo_r,BRW , BALU_sor;
	reg [1:0] BALUopout;
	reg[31:0] Bpc;
	reg Bcll;
	reg [5:0] Bcheack_load;
	reg Benable;
	
	always @(*) begin
		Bimm =imm;
		Benable = enable;
		BA=A;
		BB=B;
		BR=R;
		BRd=Rd;
		BWB =WB;
		Bmemo_w = memo_w;
		Bmemo_r=memo_r;
		BRW=RW;
		BALU_sor =ALU_sor;
		BALUopout =	ALUop;
		Bcll = cll;
		Bpc = pc;
		Bcheack_load=cheack_load;

	end
	always @(posedge clk) begin
		immout =Bimm;
		enable_out = Benable;
		Aout=BA;
		Bout=BB;
		Rout=BR;
		Rdout=BRd;
		WBout =BWB;
		memo_wout = Bmemo_w;
		memo_rout=Bmemo_r;
		RWout=BRW;
		ALU_sorout =BALU_sor;
		ALUopout=BALUopout;
		pc_out = Bpc;
		cll_out = Bcll;
		cheack_load_out= Bcheack_load;
		end

endmodule 
/////////////////////////////////////////////////
	


///////////////////////////////////////////// Execution stage //////////////////////////////////////////////

module ALU (
    input [1:0] ALUop,
    input [31:0] Rs, Rt,
    output reg [31:0] Rd
	);
   always @(*) begin 
	   
	   case (ALUop)
		   // OR operation
            2'b00:  
                Rd = Rs | Rt;
            
		  // ADD operation
            2'b01: 
                Rd = Rs + Rt;
            
		// SUB operation
            2'b10:  
                Rd = Rs - Rt;
           
	 // Comparator
            2'b11: begin 
                if (Rs == Rt)
                    Rd = 32'd0;
                else if (Rs > Rt)
                    Rd = 32'd1;
                else
                    Rd = -32'd1;  
            end
        endcase
    end

endmodule 


module ALU_reg_out(
	input clk,
	input [31:0] ALU_result,
	input [31:0] data_in, // Rd
	input WB , memo_w,memo_r,RW ,
	input [3:0] Rd,
	input [31:0] pc,
	input cll,
	output reg[31:0] ALU_result_out,
	output reg[31:0] data_in_out, // Rd
	output reg WB_out , memo_w_out,memo_r_out,RW_out ,
	output reg [3:0] Rd_out	,
	output reg [31:0]pc_out,
	output reg cll_out
	);
	
	reg [31:0] BALU_result;
	reg [31:0] Bdata_in; // Rd
	reg BWB , Bmemo_w,Bmemo_r,BRW ;
	reg [3:0] BRd;
	reg [31:0] Bpc;
	reg Bcll;
	
	
	always @(*) begin
	BALU_result=ALU_result;
	Bdata_in=data_in; // Rd
	BWB =WB	   ;
	Bmemo_w=  memo_w;
	Bmemo_r	 = memo_r;
	BRW = RW;
	BRd= Rd;
	Bpc=pc;
	Bcll= cll;
		
	end
	
	always @(posedge clk)begin
		
	ALU_result_out=BALU_result;
	data_in_out=Bdata_in;
	WB_out=BWB;
	memo_w_out=Bmemo_w;
	memo_r_out=Bmemo_r;
	RW_out=BRW ;
	Rd_out=BRd;
	pc_out=pc;
	cll_out= Bcll;
		
	end
	
endmodule	
	
	


	

	

//? sign exdender 

module sign_exdend(imm,sign,out); 
	input [13:0] imm; 
	input sign; 
	output [31:0] out; 
	assign 	out = (imm[13] && sign ) ? {18'h3FFFF,imm} :{18'd0,imm} ; 
 
endmodule


  

module DataMemory (input wire clk,input wire memRead,input wire memWrite,input wire [7:0] address,input wire [31:0] writeData,output reg [31:0] readData);

    reg [31:0] memory [255:0] ;
	
	  initial begin   
        $readmemh("data.mem", memory);
    end

    always @(posedge clk) begin
        if (memWrite) begin
            memory[address] = writeData;  // Write operation 
			$display("at address %d , we write %d",address,writeData);
        end
    end

    always @(*) begin
        if (memRead) begin
            readData = memory[address];   // Read operation
        end else begin
            readData = 32'b0;
        end
    end

endmodule

module DataMemory_reg(
	input clk,
	input [31:0] WriteBackData,
	input [3:0] Rd4,
	input RW,
	input [31:0] pc,
	input cll,
	output reg [31:0] WriteBackData_out,
	output reg [3:0] Rd4_out,
	output reg RW_out,
	output reg [31:0] pc_out,
	output reg cll_out
	);
	
	reg [31:0] WriteBackData_reg;
	reg [3:0] Rd4_reg;
	reg RW_reg;
	reg [31:0] Bpc;
	reg Bcll;
	
	always @(*)begin
	 WriteBackData_reg=WriteBackData;
	 Rd4_reg=Rd4;
	 RW_reg=RW;
	 Bpc=pc;
	 Bcll = cll;
	
	end
	always @(posedge clk)begin
	 WriteBackData_out= WriteBackData_reg;
	 Rd4_out=Rd4_reg;
	 RW_out=RW_reg;
	 
	 pc_out=Bpc;
	 cll_out = Bcll;
	 
	end
	
	
	
	
	
endmodule
	
	









//module instruction_memo	(address,data_out);	
	
	//input [5:0] address;
	//output [31:0] data_out;
	//reg [31:0] memo [31:0] = '{};
	//assign data_out=memo[address]
	//endmodule 
	
	
	
	
	
	
	
	
////////////////////////////////////////////

 module register_4bit(input [3:0]Data,input clk,output reg [3:0]out);
	register r1(Data[0],clk,out[0]);
	register r2(Data[1],clk,out[1]); 
	register r3(Data[2],clk,out[2]);
	register r4(Data[3],clk,out[3]);  

endmodule


 module register(input Data,clk,output reg out);
	
	always @(posedge clk)begin
		out=Data;
	end
	
endmodule  
	 





module mux4_1(input [31:0] in0, in1, in2, in3, input [1:0] sel, output reg [31:0] out);
    always @(*) begin
        case(sel)
            2'b00: out = in0;
            2'b01: out = in1;
            2'b10: out = in2;
            2'b11: out = in3;
        endcase
    end
endmodule

module mux2_1(input [31:0] A, B, input Sel, output [31:0] out);
    assign out = Sel ? B : A;
endmodule


module mux2_1fourbit(input [3:0] A, B, input Sel, output [3:0] out);
    assign out = Sel ? B : A;
endmodule
    







