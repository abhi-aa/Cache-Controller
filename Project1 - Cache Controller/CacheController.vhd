-- Company: 
-- Engineer: 
-- 
-- Create Date:    04:49:31 10/22/2023 
-- Design Name: 
-- Module Name:    CacheController - Behavioral 
-- Project Name: 	 Project 1
-- Target Devices: 
-- Tool versions: 
-- Description:    Implement a basic cache controller
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

--Set cache controller entity and initialize input/output ports
entity CacheController is
    Port ( clk 	      					: in  STD_LOGIC; --system clk signal
			setup_hold							: in STD_LOGIC := '1'; --used to delay the system to allow all processes to sync
			ADDR 	 								: out  STD_LOGIC_VECTOR(15 downto 0); --input address from CPU
			DOUT 	  								: out  STD_LOGIC_VECTOR(7 downto 0); --ouput address from CPU to SRAM
			SRAM_ADD    						: out  STD_LOGIC_VECTOR(7 downto 0); --address for SRAM
			SRAM_DIN    						: out  STD_LOGIC_VECTOR(7 downto 0); --data in for SRAM
			SRAM_DOUT   	 					: out  STD_LOGIC_VECTOR(7 downto 0); --data out for SRAM
			SDRAMADD  							: out  STD_LOGIC_VECTOR(15 downto 0); --address for SDRAM
			SD_RAM_DIN   						: out  STD_LOGIC_VECTOR(7 downto 0); --data in for SDRAM
			SD_RAM_DOUT  						: out  STD_LOGIC_VECTOR(7 downto 0); --data out for SDRAM
         WR_RD									: out  STD_LOGIC; --read and write strobe for SDRAM
			MEMSTRB								: out  STD_LOGIC; --memstrb for SDRAM
			RDY									: out  STD_LOGIC; --ready strobe to initialize when the cache is ready for another CPU request
			CS										: out  STD_LOGIC); --CPU clock
end CacheController;

architecture Behavioral of CacheController is
	--CPU SIGNALS AND VARIABLES
	signal CPU_Dout							: STD_LOGIC_VECTOR(7 downto 0); --port mapped to CPU dout
	signal CPU_Din								: STD_LOGIC_VECTOR(7 downto 0); --port mapped to CPU din
	signal CPU_ADD 							: STD_LOGIC_VECTOR (15 downto 0); --port mapped to CPU address, this holds the core information for the cache controller
	signal CPU_W_R								: STD_LOGIC; --port mapped to CPU read and write
	signal CPU_CS 								: STD_LOGIC := '1'; --port mapped to CPU CS
	signal CPU_RDY								: STD_LOGIC := '0'; --port mapped to CPU ready signal
	signal cpu_tag				      		: STD_LOGIC_VECTOR(7 downto 0); --port mapped to the CPU Tag(bits 15 - 8) of the CPU address sent to the cache controller
	signal index				      		: STD_LOGIC_VECTOR(2 downto 0); --port mapped to the CPU Index(bits 7 - 5) of the CPU address sent to the cache controller
	signal offset		            		: STD_LOGIC_VECTOR(4 downto 0); --port mapped to the CPU Offset(bits 4 - 0) of the CPU address sent to the cache controller
	
	--SRAM SIGNALS AND VARIABLES
	signal DIRTY_BIT							: STD_LOGIC_VECTOR(7 downto 0):= "00000000"; --port mapped to store the dirty value
	signal VALID_BIT							: STD_LOGIC_VECTOR(7 downto 0):= "00000000"; --port mapped to store the valid bit value
	signal SRAMADD								: STD_LOGIC_VECTOR(7 downto 0); --port mapped to SRAM address
	signal SRAMDin 							: STD_LOGIC_VECTOR(7 downto 0); --port mapped to SRAM data in
	signal SRAMDout 							: STD_LOGIC_VECTOR(7 downto 0); --port mapped to SRAM data out
	signal SRAMWen								: STD_LOGIC_VECTOR(0 DOWNTO 0); --port mapped to SRAM strobe write enabled when recieving data out from SDRAM
	signal TAGWen								: STD_LOGIC := '0'; --port mapped to SRAM strobe write enabled for the TAG when a hit case happens
	
	--SDRAM Signals
	signal SDRAM_Din							: STD_LOGIC_VECTOR(7 downto 0); --port mapped to SDRAM data in
	signal SDRAM_Dout							: STD_LOGIC_VECTOR(7 downto 0); --port mapped to SDRAM data out
	signal SDRAM_ADD							: STD_LOGIC_VECTOR(15 downto 0); --port mapped to SDRAM address
	signal SDRAM_MSTRB						: STD_LOGIC; --port mapped to SDRAM strobe MSTRB
	signal SDRAM_W_R							: STD_LOGIC; --port mapped to SDRAM read/write strobe
	signal SDRAM_MM_Counter					: integer := 0; --port mapped to SDRAM main memory counter to check how many cycles have gone by on write backs and memory loading
	signal SDRAM_OFFSET						: integer := 0; --port mapped to SDRAM to keep track of the index of the contents current being loaded/written from main memory

	type CACHE_MEMORY is array (7 downto 0) of STD_LOGIC_VECTOR(7 downto 0);
		signal Memory_TAG : CACHE_MEMORY := ((others=> (others=>'0'))); --port mapped to create a cache array to evaluate hit/miss conditions based on CPU TAG

	--ICON & VIO  & ILA Signals 
	signal control0 							: STD_LOGIC_VECTOR(35 downto 0); 
	signal ila_data 							: std_logic_vector(99 downto 0);
	signal trig0 								: std_logic_vector(0 TO 0);

	-- FSM control unit State Signals
	--IDLE 										- 0000
	--COMPARE 									- 0001
	--HIT 										- 0010
	--Load from memory 						- 0011
	--Write back to main Memory 			- 0100
	--RDY 										- 0101
	signal st1 									: std_logic_vector(3 downto 0) := "0000"; --port mapped the main FSM control that will handle the state swap logic
	
	--Components
	COMPONENT SDRAMController -- SDRAM(Main Memory) Component
		Port ( 
			clk									: in  STD_LOGIC;
			ADDR 									: in  STD_LOGIC_VECTOR (15 downto 0);
			WR_RD 								: in  STD_LOGIC;
			MEMSTRB 								: in  STD_LOGIC;
			DIN 									: in  STD_LOGIC_VECTOR (7 downto 0);
			DOUT 									: out STD_LOGIC_VECTOR (7 downto 0));
	END COMPONENT;
	
	COMPONENT SRAM --SRAM(Cache Memroy) Component
		PORT (
			clka 									: IN STD_LOGIC;
			wea 									: IN STD_LOGIC_VECTOR(0 DOWNTO 0);
			addra 								: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
			dina 									: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
			douta 								: OUT STD_LOGIC_VECTOR(7 DOWNTO 0));
	END COMPONENT;
	
	COMPONENT CPU_gen --CPU Component
		Port ( 
			clk 									: in  STD_LOGIC;
			rst 									: in  STD_LOGIC;
			trig 									: in  STD_LOGIC;
			Address 								: out STD_LOGIC_VECTOR (15 downto 0);
			wr_rd 								: out STD_LOGIC;
			cs 									: out STD_LOGIC;
			Dout 									: out STD_LOGIC_VECTOR (7 downto 0));
	END COMPONENT;	
	
	COMPONENT icon --Icon component
		PORT (
			CONTROL0 							: INOUT STD_LOGIC_VECTOR(35 DOWNTO 0));
	END COMPONENT;
	
	COMPONENT ila --ILA component
		PORT (
			CONTROL 								: INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
			CLK 									: IN STD_LOGIC;
			DATA 									: IN STD_LOGIC_VECTOR(99 DOWNTO 0);
			TRIG0 								: IN STD_LOGIC_VECTOR(0 TO 0));
	END COMPONENT;

BEGIN
--PORT MAPS:
	myCPU_gen 									: CPU_gen			Port Map (clk,'0',CPU_RDY,CPU_ADD,CPU_W_R,CPU_CS,CPU_Dout);
	SDRAM 										: SDRAMController	Port Map (clk,SDRAM_ADD,SDRAM_W_R,SDRAM_MSTRB,SDRAM_Din,SDRAM_Dout);
	mySRAM 										: SRAM				Port Map (clk,SRAMWen,SRAMADD, SRAMDin, SRAMDout);
	myIcon 										: icon 				Port Map (CONTROL0);
	myILA 										: ila					Port Map (CONTROL0,CLK,ila_data, TRIG0);
	
	--main process for the cache controller
	process(clk, CPU_CS)
	begin
		--if rising edge
		if(clk'event and clk = '1') then
			--start the state transition process
			--if in "IDLE" state
			if(st1 = "0000") then
				--here to delay the system as without this delay code broke
				if(setup_hold = '0') then
						--set the CPU RDY strobe to ready state
						CPU_RDY <= '1';
				end if;
				--if the cpu clock is rising edge(1)
				if(CPU_CS = '1') then
					--set the next state to "READY" state
					st1 <= "0101";
				end if;
			--if in "COMPARE" state
			elsif(st1 = "0001") then
				--if the Valid is 1 and the current TAG in cache memory is equal to the TAG supplied by the CPU(checks for hit/miss)
				if(VALID_BIT(to_integer(unsigned(index))) = '1' 
					AND Memory_TAG(to_integer(unsigned(index))) = cpu_tag) then
					TAGWen <= '1';
					--switch to hit state
					st1 <= "0010";
				--else its a miss
				else
					TAGWen <= '0';
					--if the dirty bit is 1 and the valid bit is 1
					if(DIRTY_BIT(to_integer(unsigned(index))) = '1'
						AND VALID_BIT(to_integer(unsigned(index))) = '1') then
						--switch to write back state as the current TAG is incorrect
						st1 <= "0100";
					else
						--else load from main memory as the content in cache memory is empty
						st1 <= "0011";
					end if;
				end if;
			
			--if in "HIT" state
			elsif(st1 = "0010") then
				--if CPU read/write strobe is activated(Write)
				if (CPU_W_R = '1') then 
					-- set SRAM strobe to activated(Write)
					SRAMWen <= "1";
					-- set the dirty bit to 1
					DIRTY_BIT(to_integer(unsigned(index))) <= '1';
					-- set the valid bit to 1
					VALID_BIT(to_integer(unsigned(index))) <= '1';
					--set the SRAM data in to the CPU data out
					SRAMDin <= CPU_Dout;
					--set the CPU data in to 0
					CPU_Din <= "00000000";
				else
					--set the CPU data in to the SRAM data out
					CPU_Din <= SRAMDOUT;
				end if;
				st1 <= "0000";
			
			-- if in "Load Memory" state
			elsif(st1 = "0011") then
				--if the SDRAM memory iteration counter is 64(means 32 cycles have gone by to load memory needed)
				if(SDRAM_MM_Counter = 64) then
					--reset our counter for the next time we enter this state
					SDRAM_MM_Counter <= 0;
					--set the Valid bit to 1 as our Cache index now has a TAG
					VALID_BIT(to_integer(unsigned(index))) <= '1';
					--set the CPU TAG to the SRAM array(since the TAG correct TAG is loaded in, we will have a hit condition)
					Memory_TAG(to_integer(unsigned(index))) <= cpu_tag;
					--Reset the SDRAM offset that we used to load in the memory blocks
					SDRAM_OFFSET <= 0;
					--set to "HIT state"
					st1 <= "0010";
				--else if 32 cycles have not been completed, there is still memory to load in
				else
					--if the counter is 1(means the clk is on falling edge and we will not load from memory this iteration)
					if(SDRAM_MM_Counter mod 2 = 1) then
						--set the SDRAM MSTRB to 0
						SDRAM_MSTRB <= '0';
					--else the memory counter is 0(means the clk is on rising edge and we can load a block from main memory)
					else
						--load in the block that we want to read into SRAM cache
						SDRAM_ADD(4 downto 0) <= STD_LOGIC_VECTOR(to_unsigned(SDRAM_OFFSET, offset'length));
						--set the SDRAM read/write to read
						SDRAM_W_R <= '0';
						--set the SDRAM MSTRB to 0
						SDRAM_MSTRB <= '1';
						--set the SDRAM address(7 to 5) to the CPU index
						SRAMADD(7 downto 5) <= index;
						--set the SRAM address(4 to 0) to the block we want to load in from main memory
						SRAMADD(4 downto 0) <= STD_LOGIC_VECTOR(to_unsigned(SDRAM_OFFSET, offset'length));
						--set the SRAM data in to SDRAM data out
						SRAMDIN <= SDRAM_Dout;
						--set the SRAM write enabled to activated(1)
						SRAMWen <= "1";
						--increment the SDDRAM offset block to the next block we will read in on our next cycle
						SDRAM_OFFSET <= SDRAM_OFFSET + 1;
					end if;
					--increment the memory counter to keep track of of load memory iterations
					SDRAM_MM_Counter <= SDRAM_MM_Counter + 1;
				end if;
			
			--if in "write back" state
			elsif(st1 = "0100") then
				--if the SDRAM memory iteration counter is 64(means 32 cycles have gone by to write back memory needed)
				if(SDRAM_MM_Counter = 64) then
					--reset our counter for the next time we enter this state
					SDRAM_MM_Counter <= 0;
					--set the Dirty bit to 1 as the data that did not match the CPU has been written out from the cache memory to main memory
					DIRTY_BIT(to_integer(unsigned(index))) <= '0';
					--Reset the SDRAM offset that we used to write back the memory blocks
					SDRAM_OFFSET <= 0;
					--set to "load memory" state
					st1 <= "0011";
				--else if 32 cycles have not been completed, there is still memory in the cache memory to be written to main memory
				else
					--if the counter is 1(means the clk is on falling edge and we will not write from cache memory this iteration)
					if(SDRAM_MM_Counter mod 2 = 1) then
						--set the SDRAM MSTRB to 0
						SDRAM_MSTRB <= '0';
					--else the memory counter is 0(means the clk is on rising edge and we can write a block block from cache memory to main memory)
					else
						--load in the block that we want to read into SRAM cache
						SDRAM_ADD(4 downto 0) <= STD_LOGIC_VECTOR(to_unsigned(SDRAM_OFFSET, offset'length));
						--set the SDRAM read/write to write
						SDRAM_W_R <= '1';
						--set the SRAM address(7 to 5) to the CPU index
						SRAMADD(7 downto 5) <= index;
						--set the SRAM address(4 to 0) to the block we want to want to write out to main memory
						SRAMADD(4 downto 0) <= STD_LOGIC_VECTOR(to_unsigned(SDRAM_OFFSET, offset'length));
						--set the SRAM write enabled to 0
						SRAMWen <= "0";
						--set the SDRAM data in to the SRAM data out
						SDRAM_Din <= SRAMDout;
						--set the SDRAM MSTRB to 1
						SDRAM_MSTRB <= '1';
						--increment the SDDRAM offset block to the next block we will write back in on our next cycle
						SDRAM_OFFSET <= SDRAM_OFFSET + 1;
					end if;
					--increment the memory counter to keep track of of load memory iterations
					SDRAM_MM_Counter <= SDRAM_MM_Counter + 1;
				end if;
			--if in "READY" state
			elsif(st1 = "0101") then
				--set the CPU ready strobe to 0(as the cache controller will be busy)
				CPU_RDY <= '0';
				--initialize the CPU TAG to the TAG portion of the CPU address it wants to send to the cache controller
				cpu_tag <= CPU_ADD(15 downto 8);
				--set the CPU index to the index portion of the CPU address it wants to send to the cache controller
				index	<= CPU_ADD(7  downto 5);
				--set the CPU offset to the offset portion of the CPU address it wants to send to the cache controller
				offset <= CPU_ADD(4  downto 0);
				--set the SDRAM address(15 to 5) to the CPU address(15 to 0) << this sets the TAG and index from the CPU to the SDRAM
				SDRAM_ADD(15 downto 5) <= CPU_ADD(15 downto 5);
				--set the SRAM address to the Index and Offset of the CPU address
				SRAMADD(7 downto 0) <= CPU_ADD(7 downto 0);
				--set the SRAM write enabled to 0(we do not know what case we will have yet so set to 0 until we know the case)
				SRAMWen <= "0";
				--after all data is initialized set state to "COMPARE"
				st1 <= "0001";
			end if;
		end if;
	end process;
	
	--Set the data stored in the signals to the ports defined in the cache controller entity
	MEMSTRB <= SDRAM_MSTRB;
	ADDR <= CPU_ADD;
	WR_RD <= CPU_W_R;
	DOUT <= CPU_Din;
	RDY <= CPU_RDY;
	CS <= CPU_CS;
	
	--Set the data stored in the signals to the ports defined in the cache controller entity
	SRAM_ADD <= SRAMADD;
	SRAM_DIN <= SRAMDIN;
	SRAM_DOUT <= SRAMDout;
	
	--Set the data stored in the signals to the ports defined in the cache controller entity
	SDRAMADD <= SDRAM_ADD;
	SD_RAM_DIN <= SDRAM_Din;
	SD_RAM_DOUT <= SDRAM_Dout;
	
	-- MAP THE ILA PORTS
	ila_data(15 downto 0) <= CPU_ADD;
	ila_data(16) <= CPU_W_R;
	ila_data(17) <= CPU_RDY;
	ila_data(18) <= SDRAM_MSTRB;
	ila_data(26 downto 19) <= CPU_Din;
	ila_data(30 downto 27) <= st1;
	ila_data(31) <= CPU_CS;
	ila_data(32) <= VALID_BIT(to_integer(unsigned(index)));
	ila_data(33) <= DIRTY_BIT(to_integer(unsigned(index)));
	ila_data(34) <= TAGWen;
	ila_data(42 downto 35) <= SRAMADD;
	ila_data(50 downto 43) <= SRAMDin;
	ila_data(58 downto 51) <= SRAMDout;
	ila_data(74 downto 59) <= SDRAM_ADD;
	ila_data(82 downto 75) <= SDRAM_Din;
	ila_data(90 downto 83) <= SDRAM_Dout;
	ila_data(98 downto 91) <= CPU_ADD(15 downto 8);

end Behavioral;
