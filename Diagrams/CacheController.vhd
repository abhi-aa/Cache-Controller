----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:21:43 09/29/2023 
-- Design Name: 
-- Module Name:    CacheController - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity CacheController is
    Port ( ADD : in  STD_LOGIC_VECTOR (16 downto 0);
           WR_RD : in  STD_LOGIC;
           CS : in  STD_LOGIC;
           Clk : in  STD_LOGIC;
           SDRAM_ADD : out  STD_LOGIC_VECTOR (16 downto 0);
           WEN_SDRAM : out  STD_LOGIC;
           MSTRB : out  STD_LOGIC;
           RDY : out  STD_LOGIC;
           CACHE_ADD : out  STD_LOGIC_VECTOR (8 downto 0);
           WEN_CACHE : out  STD_LOGIC;
           CACHE_DOUT_EN : out  STD_LOGIC;
           CACHE_DIN_EN : out  STD_LOGIC);
end CacheController;

architecture Behavioral of CacheController is
	-- FSM state signal
	type state_type is (s0,s1,s2,s3,s4,s5);
	signal yfsm : state_type;
	-- CPU signals
	signal CPU_DOUT, CPU_DIN : STD_LOGIC_VECTOR(7 DOWNTO 0);
	signal CPU_ADD : STD_LOGIC_VECTOR(15 DOWNTO 0);
	signal CPU_TAG : STD_LOGIC_VECTOR(7 DOWNTO 0);
	signal CPU_INDEX : STD_LOGIC_VECTOR(2 DOWNTO 0);
	signal CPU_OFFSET : STD_LOGIC_VECTOR(4 DOWNTO 0);
	signal CPU_WR_RD, CPU_CS, CPU_RDY : STD_LOGIC;
	signal TAG_INDEX : STD_LOGIC_VECTOR(10 DOWNTO 0);
	-- Cache SRAM signals
	signal DIRTY_BIT : STD_LOGIC_VECTOR(7 DOWNTO 0):="00000000";
	signal VALID_BIT : STD_LOGIC_VECTOR(7 DOWNTO 0):="00000000";
	signal CACHE_ADD, CACHE_DIN, CACHE_DOUT : STD_LOGIC_VECTOR(7 DOWNTO 0);
	signal CACHE_WEN : STD_LOGIC;
	-- SDRAM controller signals
	signal SDRAM_DIN : STD_LOGIC;
	

begin
	process(clk)
	begin
		if(clk'Event AND clk='1') then
			case ysfm is
				-- Processing s0 - Idle
				when s0 =>
					if(CS = '1') then
						yfsm <= s1;
					else
						yfsm <= s0;
					end if;
				-- Processing s1 - Operating
				when s1 =>
					if(Hit/Miss='0' AND WR_RD='1') then
						yfsm <= s2;
					elsif(Hit/Miss='0' AND WR_RD='0') then
						yfsm <= s3;
					elsif(Hit/Miss='1' AND ADD(15)='0') then
						yfsm <= s4;
					elsif(Hit/Miss='1' AND ADD(15)='1') then
						yfsm <= s5;
					end if;
				-- Processing s2 - Cache hit and write
				when s2 =>
					if(RDY='1') then
						yfsm <= s0;
					else
						yfsm <= s2;
					end if;
				-- Processing s3 - Cache hit and read
				when s3 =>
					if(RDY='1') then
						yfsm <= s0;
					else
						yfsm <= s3;
					end if;
				-- Processing s4 - Cache miss and dirty bit=0
				when s4 =>
					if(MSTRB='1' AND WR_RD='0') then
						yfsm <= s3;
					elsif(MSTRB='1' AND WR_RD='1') then
						yfsm <= s2;
					elsif(MSTRB='0') then
						yfsm <= s4;
					end if;
				-- Processing s5 - Cache miss and dirty bit=1
				when s5 =>
				if(MSTRB='1') then
					yfsm <= s4;
				else
					yfsm <= s5;
				end if;
			end case;
		end if;
	end process;
	process(yfsm)
	begin
		case yfsm is
			-- Generating outputs for s0
			when s0 =>
				RDY <= '1';
			-- Generating outputs for s1
			when s1 =>
				RDY <= '0';
			-- Generating outputs for s2
			when s2 =>
				WEN_CACHE <= '1';
				CACHE_DIN_EN <= '0';
				ADD(15) <= '1'; --dirty bit
				ADD(14) <= '1'; --valid bit
				RDY <= '1';
			-- Generating outputs for s3
			when s3 =>
				WEN_CACHE <= '0';
				CACHE_DOUT_EN <= '1';
				RDY <= '1';
			-- Generating outputs for s4
			when s4 =>
				WEN_SDRAM <= '0';
				CACHE_DIN_EN <= '1';
				WEN_CACHE <= '1';
				ADD(14) <= '1'; --valid bit
			-- Generating outputs for s5
			when s5 =>
				WEN_SDRAM <= '1';
				CACHE_DOUT_EN <= '0';
		end case;
	end process;
					


end Behavioral;

