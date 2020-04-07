library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uartcore is
	generic(
		DBIT    : integer := 8;
		SB_TICK : integer := 16;
		DVSR    : integer := 163;
		DVSR_BIT: integer := 8;
		FIFO_W  : integer := 2
	);
	port(
		clk, reset        : in std_logic;
		rx                : in std_logic;
		w_data            : in std_logic_vector(7 downto 0);
		tx_full, data_available : out std_logic;
		r_data            : out std_logic_vector(7 downto 0);
		enter_tick, bck_spc_tick : out std_logic;
		tx                : out std_logic
	);
end uartcore;

architecture str_arch of uartcore is
	signal tick                        : std_logic;
	signal rx_done_tick                : std_logic;
	signal tx_fifo_out                 : std_logic_vector(7 downto 0);
	signal rx_data_out                 : std_logic_vector(7 downto 0);
	signal tx_empty, rx_empty, tx_fifo_not_empty : std_logic;
	signal tx_done_tick, rx_fifo_not_empty                : std_logic;
begin
	baud_gen_unit : entity work.mod_m_counter(arch)
		generic map(M => DVSR, N => DVSR_BIT)
		port map(clk => clk, reset => reset, 
					q => open, max_tick => tick);
	uart_rx_unit : entity work.uart_rx(arch)
		generic map(DBIT => DBIT, SB_TICK => SB_TICK)
		port map(clk => clk, reset => reset, rx => rx,
					s_tick => tick, rx_done_tick => rx_done_tick,
					dout => rx_data_out, enter_tick => enter_tick,
					bck_spc_tick => bck_spc_tick);
	fifo_rx_unit : entity work.fifo(arch)
		generic map (B => DBIT, W => FIFO_W)
		port map(clk => clk, reset => reset, rd => rx_fifo_not_empty,
					wr => rx_done_tick, w_data => rx_data_out,
					empty => rx_empty, full => open, r_data => r_data);
	fifo_tx_unit : entity work.fifo(arch)
		generic map (B => DBIT, W => FIFO_W)
		port map(clk => clk, reset => reset, rd => tx_done_tick,
					wr => rx_fifo_not_empty, w_data => w_data,
					empty => tx_empty, full => tx_full, r_data => tx_fifo_out);
	uart_tx_unit : entity work.uart_tx(arch)
		generic map(DBIT => DBIT, SB_TICK => SB_TICK)
		port map(clk => clk, reset => reset, 
					tx_start => tx_fifo_not_empty,
					s_tick => tick, din => tx_fifo_out,
					tx_done_tick => tx_done_tick, tx => tx);
	tx_fifo_not_empty <= not tx_empty;
	rx_fifo_not_empty <= not rx_empty;
	data_available <= rx_fifo_not_empty;
end str_arch;