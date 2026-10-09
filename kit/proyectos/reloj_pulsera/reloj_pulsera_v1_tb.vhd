-- ============================================================================
-- reloj_pulsera_v1_tb.vhd
-- Banco de pruebas de reloj_pulsera_v1.
-- Genera el reloj, dos pulsos de reset y pulsaciones de B de distinta
-- duracion. El proceso de B se repite cada 31 ciclos (no termina en wait).
--
-- Simular:  F6 en Notepad++ con este fichero activo, o bien
--           sim.bat reloj_pulsera_v1_tb 310ns   desde esta carpeta
-- En GTKWave: S solo cambia cuando se SUELTA B (estados *_wait -> *_idle).
-- ============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity reloj_pulsera_v1_tb is
end reloj_pulsera_v1_tb;

architecture Behavioral of reloj_pulsera_v1_tb is

  component reloj_pulsera_v1 is
    Port (
      clk : in  std_logic;
      rst : in  std_logic;
      B   : in  std_logic;
      S   : out std_logic_vector(1 downto 0)
    );
  end component;

  signal S : std_logic_vector(1 downto 0);
  signal clk, rst, B : std_logic := '0';

  constant clk_p : time := 10 ns;

begin

  -- clk generation
  clk <= not clk after clk_p/2;

  -- rst generation
  process
  begin
    rst <= '1'; wait for 2*clk_p;
    rst <= '0'; wait for 15*clk_p;
    rst <= '1'; wait for 2*clk_p;
    rst <= '0'; wait;
  end process;

  -- B: pulsaciones largas y cortas
  process
  begin
    B <= '0'; wait for 4*clk_p;
    B <= '1'; wait for 5*clk_p;
    B <= '0'; wait for 2*clk_p;
    B <= '1'; wait for 1*clk_p;
    B <= '0'; wait for 2*clk_p;
    B <= '1'; wait for 3*clk_p;
    B <= '0'; wait for 2*clk_p;
    B <= '1'; wait for 1*clk_p;
    B <= '0'; wait for 1*clk_p;
    B <= '1'; wait for 10*clk_p;
  end process;

  -- UUT instantiation
  UUT: reloj_pulsera_v1 Port map (
    clk => clk,
    rst => rst,
    B   => B,
    S   => S
  );

end Behavioral;
