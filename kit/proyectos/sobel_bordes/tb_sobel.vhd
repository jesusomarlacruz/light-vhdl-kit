-- ============================================================================
-- tb_sobel.vhd
-- Banco de pruebas de sobel_core que procesa una imagen completa.
--
--   estimulos.txt  (lo genera generar_estimulos.py): una ventana por linea,
--                  9 pixeles separados por espacios: p00 p01 p02 p10 ... p22
--   resultados.txt (lo escribe este banco de pruebas): un pixel por linea.
--                  ver_resultado.py lo convierte en imagen y lo compara con
--                  el resultado esperado que calcula Python.
--
-- Simular:  F6 en Notepad++ con este fichero activo. El tiempo de simulacion
--           sale de tiempo_sim.txt; el banco de pruebas se detiene solo con
--           std.env.stop al terminar la imagen.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;                        -- leer y escribir ficheros de texto

entity tb_sobel is
end entity tb_sobel;

architecture sim of tb_sobel is

  constant PERIODO : time := 10 ns;        -- periodo del reloj (100 MHz)

  signal clk      : std_logic := '0';
  signal rstn     : std_logic := '0';
  signal validIn  : std_logic := '0';
  signal p00, p01, p02 : std_logic_vector(7 downto 0) := (others => '0');
  signal p10, p11, p12 : std_logic_vector(7 downto 0) := (others => '0');
  signal p20, p21, p22 : std_logic_vector(7 downto 0) := (others => '0');
  signal validOut : std_logic;
  signal pix_out  : std_logic_vector(7 downto 0);

  -- Una ventana leida del fichero: 9 numeros enteros
  type ventana_t is array (0 to 8) of integer;

  -- Convierte un entero (0..255) en un bus de 8 bits
  function a_bus(x : integer) return std_logic_vector is
  begin
    return std_logic_vector(to_unsigned(x, 8));
  end function;

begin

  -- Unidad bajo prueba (UUT)
  uut : entity work.sobel_core
    port map (
      clk => clk, rstn => rstn, validIn => validIn,
      p00 => p00, p01 => p01, p02 => p02,
      p10 => p10, p11 => p11, p12 => p12,
      p20 => p20, p21 => p21, p22 => p22,
      validOut => validOut, pix_out => pix_out
    );

  -- Reloj: flancos de subida en 5, 15, 25... ns
  clk <= not clk after PERIODO / 2;

  -- --------------------------------------------------------------------------
  -- PROCESO 1: leer estimulos.txt y aplicar una ventana en cada ciclo.
  -- Los cambios se hacen en los flancos de bajada (20, 30, 40... ns), lejos
  -- de los flancos de subida, donde el circuito captura los datos.
  -- --------------------------------------------------------------------------
  estimulos : process
    file     f_in  : text open read_mode is "estimulos.txt";
    variable linea : line;
    variable w     : ventana_t;
  begin
    rstn    <= '0';                        -- reset durante 2 ciclos
    validIn <= '0';
    wait for 2 * PERIODO;
    rstn    <= '1';

    while not endfile(f_in) loop
      readline(f_in, linea);               -- una linea = una ventana
      for i in 0 to 8 loop
        read(linea, w(i));                 -- 9 enteros separados por espacios
      end loop;
      p00 <= a_bus(w(0));  p01 <= a_bus(w(1));  p02 <= a_bus(w(2));
      p10 <= a_bus(w(3));  p11 <= a_bus(w(4));  p12 <= a_bus(w(5));
      p20 <= a_bus(w(6));  p21 <= a_bus(w(7));  p22 <= a_bus(w(8));
      validIn <= '1';
      wait for PERIODO;                    -- siguiente ventana, siguiente ciclo
    end loop;

    validIn <= '0';                        -- no quedan ventanas
    wait for 10 * PERIODO;                 -- vaciar el segmentado (latencia 5)
    std.env.stop;                          -- termina la simulacion
  end process;

  -- --------------------------------------------------------------------------
  -- PROCESO 2: en cada flanco con validOut = '1', guardar el pixel en
  -- resultados.txt. La comparacion con el resultado esperado la hace Python.
  -- --------------------------------------------------------------------------
  escritura : process
    file     f_out : text open write_mode is "resultados.txt";
    variable l_out : line;
  begin
    wait until rising_edge(clk) and validOut = '1';
    write(l_out, to_integer(unsigned(pix_out)));   -- entero en texto
    writeline(f_out, l_out);                        -- una linea por pixel
  end process;

end architecture sim;
