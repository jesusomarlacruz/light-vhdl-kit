-- ============================================================================
-- tb_mux.vhd
-- Banco de pruebas (testbench) del multiplexor mux4.
-- Prueba los 4 valores del selector con 4 juegos de datos distintos
-- (16 casos, 10 ns cada uno).
--
-- Simular:  F6 en Notepad++ con este fichero activo, o bien
--           sim.bat tb_mux 200ns   desde esta carpeta
-- En GTKWave: compruebe que y copia la entrada que indica sel
-- (sel=00 -> a, sel=01 -> b, sel=10 -> c, sel=11 -> d).
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Un banco de pruebas no tiene puertos: es el nivel superior de la simulacion
entity tb_mux is
end entity tb_mux;

architecture sim of tb_mux is

  -- Senales que se conectan a los puertos del multiplexor
  signal a, b, c, d : std_logic_vector(3 downto 0) := (others => '0');
  signal sel        : std_logic_vector(1 downto 0) := "00";
  signal y          : std_logic_vector(3 downto 0);

begin

  -- Unidad bajo prueba (UUT: Unit Under Test)
  uut : entity work.mux4
    port map (
      a   => a,
      b   => b,
      c   => c,
      d   => d,
      sel => sel,
      y   => y
    );

  -- Proceso de estimulos
  estimulos : process
  begin
    for juego in 0 to 3 loop

      -- Un valor distinto en cada entrada para saber cual se ha elegido:
      -- juego 0: a=0 b=1 c=2 d=3 / juego 1: a=4 b=5 c=6 d=7 / ...
      a <= std_logic_vector(to_unsigned(4 * juego + 0, 4));
      b <= std_logic_vector(to_unsigned(4 * juego + 1, 4));
      c <= std_logic_vector(to_unsigned(4 * juego + 2, 4));
      d <= std_logic_vector(to_unsigned(4 * juego + 3, 4));

      -- Recorre sel = 00, 01, 10, 11
      for s in 0 to 3 loop
        sel <= std_logic_vector(to_unsigned(s, 2));
        wait for 10 ns;
      end loop;

    end loop;

    wait;                                  -- detiene este proceso para siempre
  end process estimulos;

end architecture sim;
