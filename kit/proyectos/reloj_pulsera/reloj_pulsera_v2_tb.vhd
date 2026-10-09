-- ============================================================================
-- reloj_pulsera_v2_tb.vhd
-- Banco de pruebas de reloj_pulsera_v2: los mismos estimulos que el de la
-- version 1, para poder comparar las dos simulaciones.
--
-- Simular:  F6 en Notepad++ con este fichero activo, o bien
--           sim.bat reloj_pulsera_v2_tb 310ns   desde esta carpeta
-- En GTKWave: S cambia en cuanto se PULSA B (en el primer flanco de reloj
-- despues de que B pase a '1'), porque B_s vale '1' un solo ciclo por pulsacion.
-- ============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity reloj_pulsera_v2_tb is
end reloj_pulsera_v2_tb;

architecture Behavioral of reloj_pulsera_v2_tb is

  component reloj_pulsera_v2 is
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

  -- B: pulsaciones largas y cortas (las mismas que en la version 1)
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
  UUT: reloj_pulsera_v2 Port map (
    clk => clk,
    rst => rst,
    B   => B,
    S   => S
  );

end Behavioral;
