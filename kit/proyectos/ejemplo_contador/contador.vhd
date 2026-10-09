-- ============================================================================
-- contador.vhd
-- Contador binario ascendente de 4 bits (0..15), sincrono, con reset y
-- habilitacion. Descripcion con un proceso sensible al reloj.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;      -- tipo unsigned y operador "+"

entity contador is
  port (
    clk : in  std_logic;                     -- reloj
    rst : in  std_logic;                     -- reset sincrono, activo a nivel alto
    en  : in  std_logic;                     -- habilitacion: cuenta si en = '1'
    q   : out std_logic_vector(3 downto 0)   -- valor de la cuenta
  );
end entity contador;

architecture rtl of contador is

  -- Senal interna de tipo unsigned para poder sumar con numeric_std.
  -- Ademas, en VHDL-93 (el estandar por defecto de Vivado) un puerto "out"
  -- no se puede leer dentro de la arquitectura: por eso se cuenta sobre
  -- esta senal y se copia a q.
  signal cuenta : unsigned(3 downto 0);

begin

  process (clk)
  begin
    if rising_edge(clk) then          -- solo actua en el flanco de subida
      if rst = '1' then               -- el reset tiene prioridad
        cuenta <= (others => '0');
      elsif en = '1' then
        cuenta <= cuenta + 1;         -- despues de 15 vuelve a 0
      end if;                         -- si en = '0' conserva el valor
    end if;
  end process;

  q <= std_logic_vector(cuenta);

end architecture rtl;
