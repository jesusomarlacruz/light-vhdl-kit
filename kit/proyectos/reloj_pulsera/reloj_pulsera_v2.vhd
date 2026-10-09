-- ============================================================================
-- reloj_pulsera_v2.vhd
-- Selector de pantalla de un reloj de pulsera.
-- Version 2: 4 estados y un detector de flanco de subida de B.
-- Un biestable D guarda el valor de B del ciclo anterior (B_r). La senal
--   B_s = not B_r and B
-- vale '1' durante un solo ciclo cuando B pasa de '0' a '1', por mucho
-- tiempo que se mantenga pulsado el boton.
--
--   S = "00" Hora   "01" Alarma   "10" Cronometro   "11" Fecha
-- ============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity reloj_pulsera_v2 is
  Port (
    clk : in  std_logic;
    rst : in  std_logic;
    B   : in  std_logic;
    S   : out std_logic_vector(1 downto 0)
  );
end reloj_pulsera_v2;

architecture Behavioral of reloj_pulsera_v2 is

  type st_type is (H_idle, A_idle, C_idle, F_idle);
  signal cs, ns : st_type;               -- estado actual y estado siguiente

  signal B_r, B_s : std_logic;           -- B retrasado un ciclo / flanco de B

begin

  -- Registro de estado con reset sincrono y biestable D para B
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        cs <= H_idle;
      else
        cs <= ns;
      end if;
      B_r <= B;
    end if;
  end process;

  -- Detector de flanco de subida: '1' solo en el ciclo en que B pasa a '1'
  B_s <= not B_r and B;

  -- Logica de estado siguiente y de salida (combinacional)
  process(B_s, cs)
  begin
    case cs is
      when H_idle =>
        S  <= "00";
        ns <= H_idle;
        if B_s = '1' then
          ns <= A_idle;
        end if;
      when A_idle =>
        S  <= "01";
        ns <= A_idle;
        if B_s = '1' then
          ns <= C_idle;
        end if;
      when C_idle =>
        S  <= "10";
        ns <= C_idle;
        if B_s = '1' then
          ns <= F_idle;
        end if;
      when F_idle =>
        S  <= "11";
        ns <= F_idle;
        if B_s = '1' then
          ns <= H_idle;
        end if;
      when others =>
        S  <= "00";
        ns <= H_idle;
    end case;
  end process;

end Behavioral;
