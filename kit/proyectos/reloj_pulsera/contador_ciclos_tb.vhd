-- ============================================================================
-- contador_ciclos_tb.vhd
-- Banco de pruebas de contador_ciclos con N = 5 (generic map).
-- Muestra que el contador solo cuenta con en = '1', que se detiene en N con
-- fin = '1' (no vuelve a empezar solo) y que clr lo reinicia.
--
-- Simular:  F6 en Notepad++ con este fichero activo, o bien
--           sim.bat contador_ciclos_tb   desde esta carpeta
-- En GTKWave, los valores de cuenta que deben verse estan en los comentarios.
-- ============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity contador_ciclos_tb is
end contador_ciclos_tb;

architecture Behavioral of contador_ciclos_tb is

  component contador_ciclos is
    Generic (
      N : positive := 10
    );
    Port (
      clk : in  std_logic;
      rst : in  std_logic;
      clr : in  std_logic;
      en  : in  std_logic;
      fin : out std_logic
    );
  end component;

  signal clk, rst, clr, en, fin : std_logic := '0';

  constant clk_p : time := 10 ns;

begin

  -- clk generation: flancos de subida en 5, 15, 25... ns
  clk <= not clk after clk_p/2;

  -- Estimulos (cambian en multiplos de 10 ns, lejos de los flancos de subida)
  process
  begin
    -- 1) Reset durante 2 ciclos: cuenta = 0
    rst <= '1'; en <= '0'; clr <= '0';
    wait for 2*clk_p;

    -- 2) Cuenta habilitada: 1, 2, 3, 4, 5 -> fin = '1' (a los 65 ns)
    --    y sigue en 5 aunque en siga a '1': no vuelve a empezar solo
    rst <= '0'; en <= '1';
    wait for 8*clk_p;

    -- 3) clr durante 1 ciclo: cuenta = 0 y fin = '0'
    clr <= '1';
    wait for clk_p;

    -- 4) Nueva cuenta: 1, 2
    clr <= '0';
    wait for 2*clk_p;

    -- 5) Sin habilitacion durante 3 ciclos: la cuenta se queda en 2
    en <= '0';
    wait for 3*clk_p;

    -- 6) Habilitacion otra vez: 3, 4, 5 -> fin = '1' (a los 185 ns)
    en <= '1';
    wait for 4*clk_p;

    std.env.stop;                        -- termina la simulacion
  end process;

  -- UUT instantiation: N = 5 en lugar del valor por defecto (10)
  UUT: contador_ciclos
    Generic map (
      N => 5
    )
    Port map (
      clk => clk,
      rst => rst,
      clr => clr,
      en  => en,
      fin => fin
    );

end Behavioral;
