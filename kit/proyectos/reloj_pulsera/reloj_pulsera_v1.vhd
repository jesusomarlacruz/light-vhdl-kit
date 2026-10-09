-- ============================================================================
-- reloj_pulsera_v1.vhd
-- Selector de pantalla de un reloj de pulsera.
-- Version 1: maquina de estados de Moore con 8 estados. Cada pantalla tiene
-- un estado "idle" (esperando a que se pulse B) y un estado "wait" (B sigue
-- pulsado). Solo se avanza a la siguiente pantalla cuando B vuelve a '0',
-- asi el reloj avanza una sola vez por pulsacion.
--
--   S = "00" Hora   "01" Alarma   "10" Cronometro   "11" Fecha
-- ============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity reloj_pulsera_v1 is
  Port (
    clk, rst, B : in  std_logic;
    S           : out std_logic_vector(1 downto 0)
  );
end reloj_pulsera_v1;

architecture Behavioral of reloj_pulsera_v1 is

  type st_type is (H_idle, H_wait, A_idle, A_wait, C_idle,
                   C_wait, F_idle, F_wait);
  signal cs, ns : st_type;               -- estado actual y estado siguiente

begin

  -- Registro de estado (secuencial) con reset sincrono
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        cs <= H_idle;
      else
        cs <= ns;
      end if;
    end if;
  end process;

  -- Logica de estado siguiente y de salida (combinacional)
  process(B, cs)
  begin
    case cs is
      when H_idle =>
        S <= "00";
        if B = '1' then
          ns <= H_wait;
        else
          ns <= H_idle;
        end if;
      when H_wait =>
        S <= "00";
        if B = '1' then
          ns <= H_wait;
        else
          ns <= A_idle;
        end if;
      when A_idle =>
        S <= "01";
        if B = '1' then
          ns <= A_wait;
        else
          ns <= A_idle;
        end if;
      when A_wait =>
        S <= "01";
        if B = '1' then
          ns <= A_wait;
        else
          ns <= C_idle;
        end if;
      when C_idle =>
        S <= "10";
        if B = '1' then
          ns <= C_wait;
        else
          ns <= C_idle;
        end if;
      when C_wait =>
        S <= "10";
        if B = '1' then
          ns <= C_wait;
        else
          ns <= F_idle;
        end if;
      when F_idle =>
        S <= "11";
        if B = '1' then
          ns <= F_wait;
        else
          ns <= F_idle;
        end if;
      when F_wait =>
        S <= "11";
        if B = '1' then
          ns <= F_wait;
        else
          ns <= H_idle;
        end if;
      when others =>
        S <= "00";
        ns <= H_idle;
    end case;
  end process;

end Behavioral;
