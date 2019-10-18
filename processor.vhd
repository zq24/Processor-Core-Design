LIBRARY ieee;
USE ieee.std_logic_1164.all;

-- The core of the Duke 550 processor
-- Author: <Zhaoming Qin, Zihao Wu>

ENTITY processor IS
    PORT (	clock, reset	: IN STD_LOGIC;
			keyboard_in	: IN STD_LOGIC_VECTOR(31 downto 0);
			keyboard_ack, lcd_write	: OUT STD_LOGIC;
			lcd_data	: OUT STD_LOGIC_VECTOR(31 downto 0) );
END processor;

ARCHITECTURE Structure OF processor IS
	COMPONENT imem IS
		PORT (	address	: IN STD_LOGIC_VECTOR (11 DOWNTO 0);
				clken	: IN STD_LOGIC ;
				clock	: IN STD_LOGIC ;
				q	: OUT STD_LOGIC_VECTOR (31 DOWNTO 0) );
	END COMPONENT;
	COMPONENT dmem IS
		PORT (	address	: IN STD_LOGIC_VECTOR (11 DOWNTO 0);
				clock	: IN STD_LOGIC ;
				data	: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
				wren	: IN STD_LOGIC ;
				q	: OUT STD_LOGIC_VECTOR (31 DOWNTO 0) );
	END COMPONENT;
	COMPONENT regfile IS
		PORT (	clock, wren, clear	: IN STD_LOGIC;
				regD, regA, regB	: IN STD_LOGIC_VECTOR(4 DOWNTO 0);
				valD	: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
				valA, valB	: OUT STD_LOGIC_VECTOR(31 DOWNTO 0) );
	END COMPONENT;
	COMPONENT alu IS
		PORT (	A, B	: IN STD_LOGIC_VECTOR(31 DOWNTO 0);	-- 32bit inputs
				op	: IN STD_LOGIC_VECTOR(2 DOWNTO 0);	-- 3bit ALU opcode
				R	: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);	-- 32bit output
				isEqual : OUT STD_LOGIC; -- true if A=B
				isLessThan	: OUT STD_LOGIC ); -- true if A<B
	END COMPONENT;
	COMPONENT control IS
	PORT (	op	: IN STD_LOGIC_VECTOR(4 DOWNTO 0);	-- instruction opcode
				output_sel : OUT STD_LOGIC;
				reg_dst                      : OUT STD_LOGIC;
				reg_read                     : OUT STD_LOGIC;
				alu_sel                      : OUT STD_LOGIC;
				alu_op 							  : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
				data_write_enable_in_memory  : OUT STD_LOGIC;
				branch_equal 					  : OUT STD_LOGIC;
				branch_larger_than 			  : OUT STD_LOGIC;
				jump_sel 						  : OUT STD_LOGIC;
				jump_jr_sel                  : OUT STD_LOGIC;
				mem_to_reg_sel               : OUT STD_LOGIC;
				mem_to_reg_jal_sel           : OUT STD_LOGIC;
				input_sel                    : OUT STD_LOGIC;
				write_enable                 : OUT STD_LOGIC			
			);
	END COMPONENT;
	
	-- TODO: Likely need other components here (register/adder for PC?, muxes for the data path?, etc.)
	
	-- The block below is the PC
	COMPONENT reg IS
	GENERIC ( n : integer := 32 );
	PORT (	D	: IN STD_LOGIC_VECTOR(n-1 DOWNTO 0);
			clock, clear, enable	: IN STD_LOGIC;
			Q	: OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0) );
	END COMPONENT;	
	
	COMPONENT mux IS
	GENERIC(n: integer:=16);
	PORT (	A, B	: IN STD_LOGIC_VECTOR(n-1 DOWNTO 0);
			s	: IN STD_LOGIC;	-- select (NOT A / B)
			F	: OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0) );
	END COMPONENT;
	
	COMPONENT adder_cs IS
	GENERIC(n: integer:=8);
	PORT (	
		A, B : IN STD_LOGIC_VECTOR(n-1 DOWNTO 0);
		cin  : IN STD_LOGIC;
		cout : OUT STD_LOGIC;
		sum  : OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0);
		signed_overflow : OUT STD_LOGIC	);
	END COMPONENT;
	
	COMPONENT signextended IS
	GENERIC(
	input_width : NATURAL := 17
	);
	PORT (
		immediate : IN STD_LOGIC_VECTOR(input_width - 1 DOWNTO 0);
		ext_immediate : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
	);
	END COMPONENT;

	-- TODO: Also likely need a bunch of signals...
	
	SIGNAL new_pc             : STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL current_pc         : STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL instruction        : STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL data_to_write      : STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL data_one           : STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL data_two           : STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL register_thirtyone : STD_LOGIC_VECTOR(4 DOWNTO 0);
	SIGNAL final_write_register: STD_LOGIC_VECTOR(4 DOWNTO 0);
	SIGNAL final_read_register: STD_LOGIC_VECTOR(4 DOWNTO 0);
	SIGNAL extended_immed : STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL final_data_two : STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL alu_result : STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL is_equal : STD_LOGIC;
	SIGNAL is_less_than : STD_LOGIC;
	SIGNAL pc_carry_out : STD_LOGIC;
	SIGNAL branch_carry_out : STD_LOGIC;
	SIGNAL next_pc :STD_LOGIC_VECTOR(31 DOWNTO 0);
	--SIGNAL branch_shift_result : STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL branch_add_result : STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL branch_sel : STD_LOGIC;
	SIGNAL branch_result : STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL jump_address : STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL jump_result : STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL mem_to_reg_sel_result : STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL mem_to_reg_jal_sel_result : STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL resetadder : STD_LOGIC_VECTOR(31 DOWNTO 0);
	
	SIGNAL reverse_clock : STD_LOGIC;
	
	--control signals
	SIGNAL output_sel : STD_LOGIC;
	SIGNAL reg_dst                     : STD_LOGIC;
	SIGNAL reg_read                    : STD_LOGIC;
	SIGNAL alu_sel                     : STD_LOGIC;
	SIGNAL alu_op 							  : STD_LOGIC_VECTOR(2 DOWNTO 0);
	SIGNAL data_write_enable_in_memory : STD_LOGIC;
	SIGNAL memory_out 					  : STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL branch_equal 					  : STD_LOGIC;
	SIGNAL branch_larger_than 			  : STD_LOGIC;
	SIGNAL jump_sel 						  : STD_LOGIC;
	SIGNAL jump_jr_sel                 : STD_LOGIC;
	SIGNAL mem_to_reg_sel              : STD_LOGIC;
	SIGNAL mem_to_reg_jal_sel          : STD_LOGIC;
	SIGNAL input_sel                   : STD_LOGIC;
	SIGNAL write_enable                : STD_LOGIC;
	
	
BEGIN
	-- TODO: Connect stuff up to make a processor
	
	register_thirtyone <= "11111";
	
	branch_sel <= (is_equal AND branch_equal) OR ((is_less_than) AND branch_larger_than);
	
	reverse_clock <= NOT clock;
	
	RegDstMux : mux GENERIC MAP(5) PORT MAP(instruction(26 DOWNTO 22), register_thirtyone, reg_dst, final_write_register);
	RegReadMux : mux GENERIC MAP(5) PORT MAP(instruction(16 DOWNTO 12),instruction(26 DOWNTO 22), reg_read, final_read_register);
	ALUSRCMUX : mux GENERIC MAP(32) PORT MAP(data_two, extended_immed, alu_sel, final_data_two);
	BranchMux : mux GENERIC MAP(32) PORT MAP(next_pc, branch_add_result, branch_sel, branch_result);
	JumpMux : mux GENERIC MAP(32) PORT MAP(branch_result, jump_address, jump_sel, jump_result);
	JumpMuxJr : mux GENERIC MAP(32) PORT MAP(jump_result, data_two, jump_jr_sel, new_pc);
	MemToRegMux : mux GENERIC MAP(32) PORT MAP(alu_result, memory_out, mem_to_reg_sel, mem_to_reg_sel_result);
	MemToRegJalMux : mux GENERIC MAP(32) PORT MAP(mem_to_reg_sel_result, next_pc, mem_to_reg_jal_sel, mem_to_reg_jal_sel_result);
	MemToRegInputMux : mux GENERIC MAP(32) PORT MAP(mem_to_reg_jal_sel_result, keyboard_in, input_sel, data_to_write);
	
	PC: reg PORT MAP(resetadder, clock, reset, '1', current_pc);
	addPC : adder_cs GENERIC MAP(32) PORT MAP(current_pc, x"00000001", '0', pc_carry_out, next_pc);
	--BranchShift : shifter PORT MAP(extended_immed, '0', "00010", branch_shift_result);
	addBranch : adder_cs GENERIC MAP(32) PORT MAP(next_pc, extended_immed, '0', branch_carry_out, branch_add_result);
	IMEMORY: imem PORT MAP(resetadder(11 DOWNTO 0), '1', clock, instruction);
	REGFILES : regfile PORT MAP(clock, write_enable, reset, final_write_register,instruction(21 DOWNTO 17),final_read_register,data_to_write,data_one,data_two);
	signEx : signextended PORT MAP(instruction(16 DOWNTO 0), extended_immed);
	signExJump : signextended GENERIC MAP(27) PORT MAP(instruction(26 DOWNTO 0), jump_address);
 	ALUunit : alu PORT MAP(data_one, final_data_two, alu_op, alu_result, is_equal, is_less_than);
	DMEMORY : dmem PORT MAP(alu_result(11 DOWNTO 0), reverse_clock, data_two, data_write_enable_in_memory, memory_out);
	ControlUnit : control PORT MAP(instruction(31 DOWNTO 27), output_sel, reg_dst, reg_read, alu_sel, alu_op, data_write_enable_in_memory, branch_equal, branch_larger_than, jump_sel, jump_jr_sel, mem_to_reg_sel, mem_to_reg_jal_sel, input_sel,write_enable);
	
	
	
	
	keyboard_ack <= '1' WHEN input_sel='1' ELSE
	             '0';
	lcd_write <= '1' WHEN output_sel='1' ELSE
	             '0';
	lcd_data <= data_two WHEN output_sel='1' ELSE
	             x"00000000";
	
	
	
	--keyboard_ack <= '1' WHEN instruction(31 DOWNTO 27)="01110" ELSE
	--             '0';
	--lcd_write <= '1' WHEN instruction(31 DOWNTO 27)="01111" ELSE
	--             '0';
	--lcd_data <= data_two WHEN instruction(31 DOWNTO 27)="01111" ELSE
	--             x"00000000";
	
	--output_sel='1' ELSE
	--				data_two;
	
	resetadder <= x"00000000" WHEN reset='1' ELSE
				 new_pc;
	
	--PROCESS(clock, reset, resetadder)
	--BEGIN
	--	IF reset='1' THEN resetadder<=x"00000000";
	--	ELSIF RISING_EDGE(clock) THEN
	--		resetadder <= new_pc;
	--	END IF;
	--END PROCESS;
		
	
	---- FETCH Stage
	
	---- DECODE Stage
	
	---- EXECUTE Stage
	
	---- MEMORY WRITE Stage
	
	---- WRITEBACK Stage
	
	
	
		
END Structure;