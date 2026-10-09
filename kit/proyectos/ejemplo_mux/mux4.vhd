-- ============================================================================
-- mux4.vhd
-- Multiplexor 4 a 1 de buses de 4 bits.
-- Descripcion con asignacion concurrente condicional (when ... else).
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;

entity mux4 is
  port (
    a   : in  std_logic_vector(3 downto 0);  -- entrada 0 (se elige con sel = "00")
    b   : in  std_logic_vector(3 downto 0);  -- entrada 1 (sel = "01")
    c   : in  std_logic_vector(3 downto 0);  -- entrada 2 (sel = "10")
    d   : in  std_logic_vector(3 downto 0);  -- entrada 3 (sel = "11")
    sel : in  std_logic_vector(1 downto 0);  -- selector
    y   : out std_logic_vector(3 downto 0)   -- salida
  );
end entity mux4;

architecture rtl of mux4 is
begin

  -- Las condiciones se evaluan en orden: la primera que se cumple
  -- decide la salida. El ultimo "else" cubre sel = "11" (y cualquier
  -- otro valor, por ejemplo 'U' si el selector no esta inicializado).
  y <= a when sel = "00" else
       b when sel = "01" else
       c when sel = "10" else
       d;

end architecture rtl;
