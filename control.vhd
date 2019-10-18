LIBRARY ieee;
USE ieee.std_logic_1164.all;

-- Control logic for the Duke 550 processor
-- Author: <Zhaoming Qin>

ENTITY control IS
	PORT (	op	: IN STD_LOGIC_VECTOR(4 DOWNTO 0);	-- instruction opcode
			--TODO: Figure out what control signals you need here
				--Branch   : OUT STD_LOGIC;
				--Jump     : OUT STD_LOGIC;
				--MemWrite : OUT STD_LOGIC;
				--MemtoReg : OUT STD_LOGIC;
				--ALUOp    : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
				--ALUinB   : OUT STD_LOGIC;
				--RegWrite : OUT STD_LOGIC;
				--Regdst   : OUT STD_LOGIC
				
				--add an output control signal
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
END control;

ARCHITECTURE Behavior OF control IS
SIGNAL add_sig    : STD_LOGIC;
SIGNAL sub_sig    : STD_LOGIC;
SIGNAL and_sig    : STD_LOGIC;
SIGNAL or_sig     : STD_LOGIC;
SIGNAL sll_sig    : STD_LOGIC;
SIGNAL srl_sig    : STD_LOGIC;
SIGNAL addi_sig   : STD_LOGIC;
SIGNAL lw_sig     : STD_LOGIC;
SIGNAL sw_sig     : STD_LOGIC;
SIGNAL beq_sig    : STD_LOGIC;
SIGNAL bgt_sig    : STD_LOGIC;
SIGNAL jr_sig     : STD_LOGIC;
SIGNAL j_sig      : STD_LOGIC;
SIGNAL jal_sig    : STD_LOGIC;
SIGNAL input_sig  : STD_LOGIC;
SIGNAL output_sig : STD_LOGIC;

BEGIN
	-- TODO: implement behavior of control unit
	-- NOTE: Behavioral WHEN... ELSE statements may be used
	
add_sig <= '1' WHEN op="00000" ELSE
			  '0';
sub_sig <= '1' WHEN op="00001" ELSE
			  '0';
and_sig <= '1' WHEN op="00010" ELSE
			  '0';
or_sig <= '1' WHEN op="00011" ELSE
			  '0';
sll_sig <= '1' WHEN op="00100" ELSE
			  '0';
srl_sig <= '1' WHEN op="00101" ELSE
			  '0';
addi_sig <= '1' WHEN op="00110" ELSE
			  '0';
lw_sig <= '1' WHEN op="00111" ELSE
			  '0';
sw_sig <= '1' WHEN op="01000" ELSE
			  '0';
beq_sig <= '1' WHEN op="01001" ELSE
			  '0';
bgt_sig <= '1' WHEN op="01010" ELSE
			  '0';
jr_sig <= '1' WHEN op="01011" ELSE
			  '0';
j_sig <= '1' WHEN op="01100" ELSE
			  '0';
jal_sig <= '1' WHEN op="01101" ELSE
			  '0';
input_sig <= '1' WHEN op="01110" ELSE
			  '0';
output_sig <= '1' WHEN op="01111" ELSE
			  '0';

------------------------------------------
output_sel <= output_sig;

reg_read <= sw_sig OR beq_sig or bgt_sig or jr_sig or output_sig; 

reg_dst <= jal_sig;

alu_sel <= addi_sig or lw_sig or sw_sig;

mem_to_reg_sel <= lw_sig;

mem_to_reg_jal_sel <= jal_sig;

write_enable <= add_sig or sub_sig or and_sig or or_sig or sll_sig or srl_sig or addi_sig or lw_sig or jal_sig or input_sig;

data_write_enable_in_memory <= sw_sig;

branch_equal <= beq_sig;

branch_larger_than <= bgt_sig;

alu_op(2) <= sll_sig or srl_sig;

alu_op(1) <= and_sig or or_sig;

alu_op(0) <= sub_sig or or_sig or srl_sig or bgt_sig;

jump_sel <= j_sig or jal_sig;

jump_jr_sel <= jr_sig;

input_sel <= input_sig;

END Behavior;