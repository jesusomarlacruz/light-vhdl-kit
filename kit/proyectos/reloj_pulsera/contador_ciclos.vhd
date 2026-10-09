-- ============================================================================
-- contador_ciclos.vhd
-- Contador de ciclos de reloj, configurable con el generico N.
--   - Cuenta un ciclo en cada flanco de subida mientras en = '1'.
--   - Al llegar a N se detiene (no vuelve a 0) y fin vale '1'.
--   - clr = '1' lo vuelve a poner a 0 para empezar una nueva cuenta.
--   - rst = '1' lo pone a 0 (reset sincrono, como el de la FSM).
--
-- Pensado para instanciarlo junto a la maquina de estados del reloj: la FSM
-- decide cuando contar (en) y cuando empezar de nuevo (clr), y reacciona
-- cuando el contador avisa de que han pasado N ciclos (fin).
-- ============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity contador_ciclos is
  Generic (
    N : positive := 10                   -- numero de ciclos a contar
  );
  Port (
    clk : in  std_logic;
    rst : in  std_logic;                 -- reset sincrono
    clr : in  std_logic;                 -- vuelve a empezar desde 0
    en  : in  std_logic;                 -- cuenta solo si en = '1'
    fin : out std_logic                  -- '1' cuando la cuenta ha llegado a N
  );
end contador_ciclos;

architecture Behavioral of contador_ciclos is

  signal cuenta : integer range 0 to N := 0;

begin

  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' or clr = '1' then
        cuenta <= 0;
      elsif en = '1' and cuenta < N then  -- se detiene al llegar a N
        cuenta <= cuenta + 1;
      end if;
    end if;
  end process;

  fin <= '1' when cuenta = N else '0';

end Behavioral;
