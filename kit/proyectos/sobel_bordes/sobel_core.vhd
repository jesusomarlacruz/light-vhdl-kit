-- ============================================================================
-- sobel_core.vhd
-- Detector de bordes de Sobel para una ventana de 3x3 pixeles de 8 bits.
-- Solo usa SUMAS y RESTAS. Multiplicar por 2 es poner un '0' a la derecha
-- (desplazar un bit), que en hardware son solo cables.
--
--   Ventana de entrada:   p00 p01 p02
--                         p10 p11 p12        (p11 tiene peso 0: no se usa)
--                         p20 p21 p22
--
--   Gx = (p02 + 2*p12 + p22) - (p00 + 2*p10 + p20)    -> bordes verticales
--   Gy = (p20 + 2*p21 + p22) - (p00 + 2*p01 + p02)    -> bordes horizontales
--   pix_out = min(|Gx| + |Gy|, 255)
--
-- Segmentado en 5 etapas: acepta una ventana nueva en cada ciclo de reloj y
-- el resultado sale 5 ciclos despues, junto con validOut = '1'.
-- ============================================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sobel_core is
  Port ( clk, rstn     : in  std_logic;
         validIn       : in  std_logic;
         p00, p01, p02 : in  std_logic_vector(7 downto 0);
         p10, p11, p12 : in  std_logic_vector(7 downto 0);
         p20, p21, p22 : in  std_logic_vector(7 downto 0);
         validOut      : out std_logic;
         pix_out       : out std_logic_vector(7 downto 0));
end sobel_core;

architecture Behavioral of sobel_core is

  -- Los registros arrancan a 0 (las FPGA lo permiten). Asi la simulacion no
  -- avisa de valores 'U' mientras el segmentado se llena.

  -- Etapa 1: ventana registrada (8 bits sin signo, 0..255)
  signal p00_r, p01_r, p02_r : unsigned(7 downto 0) := (others => '0');
  signal p10_r,        p12_r : unsigned(7 downto 0) := (others => '0');
  signal p20_r, p21_r, p22_r : unsigned(7 downto 0) := (others => '0');

  -- Etapa 2: suma de cada lado. Maximo 255 + 510 + 255 = 1020 -> 10 bits
  signal sx_pos, sx_neg : unsigned(9 downto 0) := (others => '0');
  signal sy_pos, sy_neg : unsigned(9 downto 0) := (others => '0');

  -- Etapa 3: diferencias con signo. -1020..1020 -> 11 bits (Ca2)
  signal gx, gy : signed(10 downto 0) := (others => '0');

  -- Etapa 4: valores absolutos. 0..1020 -> 10 bits
  signal ax, ay : unsigned(9 downto 0) := (others => '0');

  -- Etapa 5: magnitud |Gx| + |Gy|. 0..2040 -> 11 bits
  signal mag : unsigned(10 downto 0);

  -- La senal valid viaja junto a los datos: un registro por etapa
  signal valid1, valid2, valid3, valid4 : std_logic;

begin

  -- ETAPA 1: registrar la ventana de entrada
  etapa1 : process(clk)
  begin
    if rising_edge(clk) then
      p00_r <= unsigned(p00);  p01_r <= unsigned(p01);  p02_r <= unsigned(p02);
      p10_r <= unsigned(p10);                           p12_r <= unsigned(p12);
      p20_r <= unsigned(p20);  p21_r <= unsigned(p21);  p22_r <= unsigned(p22);
    end if;
  end process;

  -- ETAPA 2: suma ponderada de cada lado (2 sumadores en cadena por lado)
  --          x2  =  p & '0'  (desplazar un bit a la izquierda: solo cables)
  etapa2 : process(clk)
  begin
    if rising_edge(clk) then
      sx_pos <= resize(p02_r, 10) + resize(p12_r & '0', 10) + resize(p22_r, 10);
      sx_neg <= resize(p00_r, 10) + resize(p10_r & '0', 10) + resize(p20_r, 10);
      sy_pos <= resize(p20_r, 10) + resize(p21_r & '0', 10) + resize(p22_r, 10);
      sy_neg <= resize(p00_r, 10) + resize(p01_r & '0', 10) + resize(p02_r, 10);
    end if;
  end process;

  -- ETAPA 3: gradientes = lado positivo - lado negativo (restadores)
  --          Se usa un bit mas (11 bits) para que quepa el signo
  etapa3 : process(clk)
  begin
    if rising_edge(clk) then
      gx <= signed(resize(sx_pos, 11)) - signed(resize(sx_neg, 11));
      gy <= signed(resize(sy_pos, 11)) - signed(resize(sy_neg, 11));
    end if;
  end process;

  -- ETAPA 4: valor absoluto. Si el bit de signo vale '1', calcular 0 - g
  etapa4 : process(clk)
  begin
    if rising_edge(clk) then
      if gx(10) = '1' then
        ax <= resize(unsigned(0 - gx), 10);
      else
        ax <= resize(unsigned(gx), 10);
      end if;
      if gy(10) = '1' then
        ay <= resize(unsigned(0 - gy), 10);
      else
        ay <= resize(unsigned(gy), 10);
      end if;
    end if;
  end process;

  -- ETAPA 5: magnitud (un sumador) y saturacion a 8 bits (una comparacion)
  mag <= resize(ax, 11) + resize(ay, 11);

  etapa5 : process(clk)
  begin
    if rising_edge(clk) then
      if mag > 255 then
        pix_out <= x"FF";                              -- satura en blanco
      else
        pix_out <= std_logic_vector(mag(7 downto 0));
      end if;
    end if;
  end process;

  -- VALID: solo las senales de control necesitan reset. Los datos sin
  -- valid = '1' se ignoran, asi que no necesitan reset.
  control : process(clk)
  begin
    if rising_edge(clk) then
      if rstn = '0' then
        valid1 <= '0';  valid2 <= '0';  valid3 <= '0';  valid4 <= '0';
        validOut <= '0';
      else
        valid1 <= validIn;  valid2 <= valid1;  valid3 <= valid2;
        valid4 <= valid3;   validOut <= valid4;
      end if;
    end if;
  end process;

end Behavioral;
