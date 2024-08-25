----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:29:41 10/21/2023 
-- Design Name: 
-- Module Name:    sram - Behavioral 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity sram is
    Port ( WEN : in  STD_LOGIC;
           ADD : in  STD_LOGIC_VECTOR (7 downto 0);
           Din : in  STD_LOGIC;
           Dout : out  STD_LOGIC);
end sram;

architecture Behavioral of sram is

begin


end Behavioral;

