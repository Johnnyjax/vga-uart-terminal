library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_uart_term_top is
	port(
		CLOCK_50 : in std_logic;
		KEY            : in std_logic_vector(3 downto 0);
		SW             : in std_logic_vector(6 downto 0);
		UART_RXD : in std_logic;
		UART_TXD : out std_logic;
		VGA_HS, VGA_VS : out std_logic;	
		VGA_R, VGA_B, VGA_G : out std_logic_vector(2 downto 0)
	);
end vga_uart_term_top;

architecture arch of vga_uart_term_top is
	signal pixel_x, pixel_y : std_logic_vector(9 downto 0);
	signal video_on, pixel_tick : std_logic;
	signal rgb_reg, rgb_next : std_logic_vector(2 downto 0);
	signal tx_full, rx_empty : std_logic;
	signal rec_data, rec_data1 : std_logic_vector(7 downto 0);
	signal data_available : std_logic;
	signal enter_tick : std_logic;
	signal bck_spc_tick : std_logic;
begin
	vga_sync_unit : entity work.vga_sync
		port map(clk => CLOCK_50, reset => not(KEY(0)),
					vsync => VGA_VS, hsync => VGA_HS, video_on => video_on,
					p_tick => pixel_tick, pixel_x => pixel_x, pixel_y => pixel_y);
	text_gen_unit : entity work.vga_uart_term
		port map(clk => CLOCK_50, reset => not(KEY(0)), key_code => rec_data(6 downto 0),
					video_on => video_on, pixel_x => pixel_x, pixel_y => pixel_y,
					text_rgb => rgb_next, we => data_available, enter_tick => enter_tick,
					bck_spc_tick => bck_spc_tick);
	uart_unit : entity work.uartcore(str_arch)
		port map(clk => CLOCK_50, reset => not(KEY(0)),
					 rx => UART_RXD, w_data => rec_data1,
					tx_full => tx_full, enter_tick => enter_tick, bck_spc_tick => bck_spc_tick,
					r_data => rec_data, tx => UART_TXD, data_available => data_available);
	process(CLOCK_50)
	begin
		if(CLOCK_50'event and CLOCK_50 = '1') then
			if(pixel_tick = '1') then
				rgb_reg <= rgb_next;
			end if;
		end if;
	end process;
	rec_data1 <= std_logic_vector(unsigned(rec_data));
	VGA_R <= (others => rgb_reg(2));
	VGA_G <= (others => rgb_reg(1));
	VGA_B <= (others => rgb_reg(0));
end arch;
		