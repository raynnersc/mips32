library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity main_decoder is
  generic (
        OPCODE_WIDTH  : natural;
        FUNCT_WIDTH   : natural
    );

	port(
    --Instruction Memory
    --Opcode	            : in std_logic_vector(OPCODE_WIDTH - 1 downto 0);
    --Funct	              : in std_logic_vector(FUNCT_WIDTH - 1 downto 0);
	 
	 Opcode	            : in std_logic_vector(5 downto 0);
    Funct	              : in std_logic_vector(5 downto 0);
	 
    MoveC0Direction     : in std_logic;
    --Datapath Inputs
    less_than_0         :in  std_logic;                        --IT VERIFATES THE MSB BIT FROM RD OUTPUT
    zero                :in  std_logic;                        --ALU RESULT IS ZERO
    --Datapath Outputs
    srl_sll_sel         :out std_logic;                          --SELECT "SRL" OR "SLL" OPERATION
    ext_type            :out std_logic;                        --EXTENSION TYPE (ZERO OR SIGN EXTENSION)
    sel_mult_div			  :out std_logic;                        --SELECT "MULT" OR "DIV" OPERATION
    alusrc					    :out std_logic;                        --SELECT THE SOURCE OF 2ND INPUT ALU
    we_hi_lo				    :out std_logic;                        --ENABLE WRITING ON HI AND LO REGISTERS
    wregsrc					    :out std_logic_vector(1 downto 0);     --SELECT THE MUX ADDRESS INPUT TO SELECT THE REGISTER
    pcsrc               :out std_logic_vector(2 downto 0);     --SELECT FROM WHERE TO GET THE ADRESS OF THE NEXT INSTRUCTION
    wregdata            :out std_logic_vector(2 downto 0);     --SELECT THE MUX DATA INPUT TO WRITE ON REGISTER FILE
    we_pc					      :out std_logic;                        --ENABLE WRITING ON PC
    reg_write           :out std_logic;                        --ENABLE WRITING ON THE REGISTER FILE
    --Memory outputs
    data_mem_we         :out std_logic;                        --ENABLE WRITING ON THE DATA MEMORY
	 data_mem_re         :out std_logic;                        --ENABLE READING ON THE DATA MEMORY
    --Alu
    ALUOp	              :out std_logic_vector(1 downto 0);     --SELECT THE DESIRED ALU OPERATION (FOR INSTRUCTIONS THAT NEEDS ALU OPERATION BUT ARE NOT R TYPE)
    --Coprocessor 0
    interrupt_request   :in std_logic;                         --IT INDICATES AN INTERRUPT REQUEST FROM COPROCESSOR 0
    cop0_we             :out std_logic;                        --ENABLE WRITING ON COPROCESSOR 0
    syscall             :out std_logic;                        --REQUEST A SYSCALL FOR COPROCESSOR 0
    bad_instr           :out std_logic                         --IT INDICATES AN UNKNOWN INSTRUCTION 
	);
end;

architecture behavior of main_decoder is

	begin

    process (Opcode,Funct,MoveC0Direction,less_than_0,zero,interrupt_request) is	 
	 
      begin
		
		--DEFAULT OUTPUTS VALUES
	  --Memory outputs
		 data_mem_we <= '0';
		 data_mem_re <= '0';
	  --Datapath Outputs
		 srl_sll_sel <= '0';
		 ext_type <= '0';
		 sel_mult_div <= '0';
		 alusrc <= '0';
		 we_hi_lo <= '0';
		 wregsrc <= "00";
		 pcsrc <= "000";
		 wregdata <= "000";
		 we_pc <= '1';
		 reg_write <= '0';
		 --Alu
		 ALUOp <= "00";
		 --Coprocessor 0
		 cop0_we <= '0';
		 syscall <= '0';
		 bad_instr <= '0';

      if (interrupt_request = '0') then --THERE IS NO INTERRUPT

        case Opcode is

          when "000000" => --INSTRUCTIONS TYPE R AND OTHERS

            case Funct is

              when "011010" =>                         --DIV
                we_hi_lo <= '1';                         --REGISTER HI AND REGISTER LO ENABLE
                sel_mult_div <= '0';                     --SELECT THE OPERATION "DIV"

              when "011000" =>                         --MULT
                we_hi_lo <= '1';                         --REGISTER HI AND REGISTER LO ENABLE
                sel_mult_div <= '1';                     --SELECT THE OPERATION "MULT"

              when "010001" =>                         --MFHI
                reg_write <= '1';                        --REGISTER FILE WRITE ENABLE
                wregdata <= "010";                       --SELECT DATA FROM REGISTER HI
                wregsrc <= "01";                         --SELECT REGISTER RD (15:11)

              when "010010" =>                         --MFLO
                reg_write <= '1';                        --REGISTER FILE WRITE ENABLE
                wregdata <= "011";                       --SELECT DATA FROM REGISTER LO
                wregsrc <= "01";                         --SELECT REGISTER RD (15:11)

              when "001000" =>                         --JR
                pcsrc <= "011";                          --PC = [REGISTER]
                

              when "001100" =>                         --SYSCALL
                we_pc <= '0';                            --DISABLE THE PROGRAM COUNTER
                syscall <= '1';                          --IT INDICATES THE STATUS "SYSCALL"

              when "000000" =>                         --SLL
                reg_write <= '1';                        --REGISTER FILE WRITE ENABLE
                wregdata <= "111";                       --SELECT DATA FROM SHIFTER
                wregsrc <= "01";                         --SELECT REGISTER RD (15:11)
                srl_sll_sel <= '1';                      --SELECT THE OPERATION "SLL"
                  
              when "000010" =>                         --SRL
                reg_write <= '1';                        --REGISTER FILE WRITE ENABLE
                wregdata <= "111";                       --SELECT DATA FROM SHIFTER
                wregsrc <= "01";                         --SELECT REGISTER RD (15:11)
                srl_sll_sel <= '0';                      --SELECT THE OPERATION "SRL"

              --ALU OPERATIONS (TYPE R)
              when "100000" | "100010" | "100100" | "100101" |"100110" | "100111" | "101010" => 
                ALUOp <= "10";                   --IT INDICATES DO ALU DECODER TO VERIFY THE "FUNCT"
                reg_write <= '1';                --REGISTER FILE WRITE ENABLE
                wregsrc <= "01";                         --SELECT REGISTER RD (15:11)

              when others =>                     --BAD INSTRUCTION
                we_pc <= '0';                       --STOP THE PROGRAM COUNTER
                bad_instr <= '1';                   --IT INDICATES THE STATUS "BAD INSTRUCTION"

            end case;

          when "001000" =>                 --ADDI
            alusrc <= '1';                   --SELECT THE MUX'S INPUT BEFORE ALU
            reg_write <= '1';                --REGISTER FILE WRITE ENABLE
            ext_type <= '1';                 --SELECT SIGN EXTEND
          
          when "001101" =>                 --ORI
            alusrc <= '1';                   --SELECT THE MUX'S INPUT BEFORE ALU
            ALUOp <= "11";                   --SELECT THE ALU'S OPERATION "OR"
            reg_write <= '1';                --REGISTER FILE WRITE ENABLE
        
          when "001111" =>                 --LUI
            reg_write <= '1';                --REGISTER FILE WRITE ENABLE
            wregdata <= "110";               --SELECT THE SHIFTER'S OUTPUT TO SAVE IN REGISTER FILE

          when "000100" =>                 --BEQ
            ALUOp <= "01";                   --SELECT THE ALU'S OPERATION "SUB"
            if (zero = '1') then
              pcsrc <= "001";                --DO BRANCH 
            else                           
              pcsrc <= "000";                --PC = PC + 4
            end if;

          when "000111" =>                             --BGTZ
              ALUOp <= "01";                             --SELECT THE ALU'S OPERATION "SUB"
              if (zero = '0' and less_than_0 = '0') then      --DO BRANCH
                pcsrc <= "001";                            --PC = BTA
              else
                pcsrc <= "000";                            --PC = PC + 4
              end if;
                
          when "000010" =>                   --J
            pcsrc <= "010";                    --PC = JTA
                
          when "000011" =>                   --JAL
            pcsrc <= "010";                    --PC = JTA
            reg_write <= '1';                  --REGISTER FILE WRITE ENABLE
            wregdata <= "101";                  --SELECT DATA TO WRITE IN THE REGISTER FILE
            wregsrc <= "10";                    --SELECT REGISTER 31
              
          when "010000" =>                   --MTC0 MFC0

            if (MoveC0Direction = '0') then   --MFC0
              reg_write <= '1';                 --REGISTER FILE WRITE ENABLE
              wregdata <= "100";                --SELECT DATA FROM C0 TO WRITE IN THE REGISTER FILE
              wregsrc <= "01";                   --SELECT REGISTER RD (15:11)
            else                              --MTC0
              cop0_we <= '1';                   --C0 WRITE ENABLE
            end if;

          when "100011" =>                    --LW
            alusrc <= '1';                      --SELECT EXTENDED IMMEDIATE AS SECOND OPERAND OF ALU 
            reg_write <= '1';                   --REGISTER FILE WRITE ENABLE
            wregdata <= "001";                  --SELECT DATA FROM MEMORY TO WRITE IN THE REGISTER FILE
            ext_type <= '1';                    --SELECT SIGN EXTEND
				data_mem_re <= '1';                 --DATA MEMORY READ ENABLE

          when "101011" =>                    --SW
            alusrc <= '1';                      --SELECT EXTENDED IMMEDIATE AS SECOND OPERAND OF ALU 
            ext_type <= '1';                    --SELECT SIGN EXTEND
            data_mem_we <= '1';                 --DATA MEMORY WRITE ENABLE

          when others =>                      --BAD INSTRUCTION
            we_pc <= '0';                       --STOP THE PROGRAM COUNTER
            bad_instr <= '1';                   --IT INDICATES THE STATUS "BAD INSTRUCTION"

        end case;
        
      else                                    --INTERRUPT REQUEST
        pcsrc <= "100";                         --ADDRESS OF INTERRUPT'S HANDLING ROUTINE
        
      end if; 
        
    end process;
    
end behavior;