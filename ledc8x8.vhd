library IEEE;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity ledc8x8 is
	port(
		SMCLK: in std_logic;
		RESET: in std_logic;
		LED: out std_logic_vector(7 downto 0);
		ROW: out std_logic_vector(7 downto 0)
	);
end ledc8x8;

architecture behavioral of ledc8x8 is
	signal ce: std_logic := '0';
	signal switch: std_logic := '0';
	signal counter: std_logic_vector(21 downto 0);
	signal dec_out: std_logic_vector(7 downto 0) := "00000000";
	signal row_inner: std_logic_vector(7 downto 0) := "10000000";
begin
	-- generování 1/256 SMCLK
	ctrl_cnt: process (SMCLK, RESET)
	begin
		if RESET = '1'
		then
			counter <= "0000000000000000000000";
		elsif rising_edge(SMCLK)
		then
			if counter(7 downto 0) = "11111111"
			then
				ce <= '1';
			else
				ce <= '0';
			end if;

			switch <= counter(21);
			counter <= counter + 1;
		end if;
	end process;

	-- rotační registr
	row_cnt: process (SMCLK, RESET, row_inner)
	begin
		-- asynchroní reset
		if RESET = '1'
		then
			ROW <= "10000000";
			row_inner <= "10000000";
		elsif rising_edge(SMCLK) AND ce = '1'
		then
			case row_inner is
				when "10000000" => row_inner <= "01000000";
				when "00000001" => row_inner <= "10000000";
				when "00000010" => row_inner <= "00000001";
				when "00000100" => row_inner <= "00000010";
				when "00001000" => row_inner <= "00000100";
				when "00010000" => row_inner <= "00001000";
				when "00100000" => row_inner <= "00010000";
				when "01000000" => row_inner <= "00100000";
				when others => null;
			end case;
		end if;

		ROW <= row_inner;
	end process;

	-- dekodér pro displej
	dec: process (SMCLK, dec_out)
	begin
		if rising_edge(SMCLK)
		then
			case row_inner is
				when "00000001" => dec_out <= "01110110";
				when "00000010" => dec_out <= "01110110";
				when "00000100" => dec_out <= "01101110";
				when "00001000" => dec_out <= "01101110";
				when "00010000" => dec_out <= "01011110";
				when "00100000" => dec_out <= "01011110";
				when "01000000" => dec_out <= "00111110";
				when "10000000" => dec_out <= "01110000";
				when others => null;
			end case;
		end if;
	end process;

	-- efekt blikání
	unknown: process (SMCLK, RESET, dec_out, switch)
	begin
		if RESET = '1' then
			LED <= "11111111";
		elsif rising_edge(SMCLK)
		then
			if switch = '0'
			then
				LED <= dec_out;
			else
				LED <= (others => '1');
			end if;
		end if;
	end process;
end architecture;
