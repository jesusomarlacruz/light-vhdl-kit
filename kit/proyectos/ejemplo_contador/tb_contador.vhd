-- ============================================================================
-- tb_contador.vhd
-- Banco de pruebas del contador de 4 bits.
-- Genera el reloj, aplica reset y activa y desactiva la habilitacion.
-- Termina llamando a std.env.stop.
--
-- Simular:  F6 en Notepad++ con este fichero activo, o bien
--           sim.bat tb_contador 1us   desde esta carpeta
-- En GTKWave, los valores de q que deben verse estan en los comentarios.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;

entity tb_contador is
end entity tb_contador;

architecture sim of tb_contador is

  constant PERIODO : time := 10 ns;          -- periodo del reloj (100 MHz)

  signal clk : std_logic := '0';
  signal rst : std_logic := '1';
  signal en  : std_logic := '0';
  signal q   : std_logic_vector(3 downto 0);

begin

  -- Unidad bajo prueba (UUT)
  uut : entity work.contador
    port map (
      clk => clk,
      rst => rst,
      en  => en,
      q   => q
    );

  -- Reloj: se invierte cada medio periodo. Flancos de subida en 5, 15, 25... ns
  clk <= not clk after PERIODO / 2;

  -- Estimulos. Los cambios se hacen en multiplos de 10 ns (flancos de bajada),
  -- lejos de los flancos de subida, para que el resultado sea facil de seguir.
  estimulos : process
  begin
    -- 1) Reset durante 2 ciclos: q = 0 desde el primer flanco (5 ns)
    rst <= '1';
    en  <= '0';
    wait for 2 * PERIODO;

    -- 2) Cuenta durante 5 ciclos: q = 1, 2, 3, 4, 5 (hasta 70 ns)
    rst <= '0';
    en  <= '1';
    wait for 5 * PERIODO;

    -- 3) Sin habilitacion durante 3 ciclos: q se queda en 5
    en <= '0';
    wait for 3 * PERIODO;

    -- 4) 12 ciclos mas: q = 6, 7, ..., 15, 0, 1 (desborda de 15 a 0)
    en <= '1';
    wait for 12 * PERIODO;

    -- 5) Reset con en='1': el reset tiene prioridad, q vuelve a 0
    rst <= '1';
    wait for PERIODO;

    std.env.stop;                            -- termina la simulacion
  end process estimulos;

end architecture sim;
