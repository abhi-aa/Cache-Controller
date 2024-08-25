----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:18:33 10/04/2023 
-- Design Name: 
-- Module Name:    SDRAMController - Behavioral 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity SDRAMController is
    Port ( ADD : in  STD_LOGIC_VECTOR (15 downto 0);
           WR_RD : in  STD_LOGIC;
           MSTRB : in  STD_LOGIC;
           Clk : in  STD_LOGIC;
           DIN : in  STD_LOGIC_VECTOR (7 downto 0);
           DOUT : out  STD_LOGIC_VECTOR (7 downto 0));
end SDRAMController;

architecture Behavioral of SDRAMController is
	-- Array of 2048 blocks of Cache Memory
	type rammemory is array (7 downto 0,31 DOWNTO 0) of STD_LOGIC_VECTOR(7 downto 0);
	signal ram_signal: rammemory;
	-- Counter signal - need to read 32 words one at a time
	signal counter : integer := 0;
begin
	process(clk)
	begin
		if(clk'Event AND clk='1') then
			if(counter = 0) then
				for i in 0 to 7 loop
					for j in 0 to 31 loop
						ram_signal(i,j) <= "11110000";
					end loop;
				end loop;
			end if;
			if(MSTRB = '1') then
				if(WR_RD = '1') then
					ram_signal(to_integer(unsigned(ADD(7 DOWNTO 5))),to_integer(unsigned(ADD(4 DOWNTO 0)))) <= DIN;
				else
					DOUT <= ram_signal(to_integer(unsigned(ADD(7 DOWNTO 5))),to_integer(unsigned(ADD(4 DOWNTO 0))));
				end if;
			end if;
		end if;
	end process;
				


end Behavioral;

