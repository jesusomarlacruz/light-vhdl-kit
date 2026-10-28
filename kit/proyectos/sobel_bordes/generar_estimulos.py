"""
generar_estimulos.py - PASO 1: preparar los ficheros del banco de pruebas.

    1. Lee una imagen y la pasa a escala de grises (0..255)
    2. La reduce si es grande (simular cada pixel lleva su tiempo)
    3. Recorre la imagen con una ventana y escribe cada ventana en
       estimulos.txt (una linea por ventana, pixeles separados por espacios)
    4. Calcula en Python el resultado correcto de cada ventana (MODELO DE
       REFERENCIA) y lo escribe en esperados.txt. ver_resultado.py compara
       la salida del circuito con estos valores.

Uso:  python generar_estimulos.py [imagen]       (por defecto imagen_prueba.png)
      o arrastre una imagen PNG sobre 1_generar_estimulos.bat
"""
import os
import sys

# Python portable: buscar imagenes.py en la carpeta de este script
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from imagenes import leer_gris, guardar_png

# ------------------------------------------------------------- parametros ---
IMAGEN = "imagen_prueba.png"
TAM_MAX = 128          # lado maximo de la imagen que se simula (en pixeles)

# Filtro que se simula: "sobel" (clase) o "suavizado" (tarea 2)
FILTRO = "sobel"

# Mascara de Sobel para Gx. La de Gy es la misma, traspuesta.
KX = [[-1, 0, 1],
      [-2, 0, 2],
      [-1, 0, 1]]

# Tarea 1: si UMBRAL > 0, Sobel da 255 si |Gx|+|Gy| > UMBRAL y 0 si no
UMBRAL = 0

# Tarea 2: mascara de suavizado. El resultado se divide entre 16
KS = [[1, 2, 1],
      [2, 4, 2],
      [1, 2, 1]]
# ------------------------------------------------------------------------------


def reducir(ancho, alto, filas, tam_max):
    """Reduce la imagen promediando bloques de f x f pixeles."""
    f = max(1, -(-max(ancho, alto) // tam_max))          # division hacia arriba
    if f == 1:
        return ancho, alto, filas
    nuevo_ancho, nuevo_alto = ancho // f, alto // f
    nuevas = []
    for y in range(nuevo_alto):
        fila = []
        for x in range(nuevo_ancho):
            bloque = [filas[y * f + j][x * f + i]
                      for j in range(f) for i in range(f)]
            fila.append(sum(bloque) // len(bloque))
        nuevas.append(fila)
    return nuevo_ancho, nuevo_alto, nuevas


def modelo_referencia(v):
    """Lo que debe calcular el circuito para una ventana v de 9 pixeles."""
    if FILTRO == "suavizado":
        suma = sum(KS[j][i] * v[3 * j + i] for j in range(3) for i in range(3))
        return suma // 16
    ky = [list(col) for col in zip(*KX)]          # Gy = Gx traspuesta
    gx = sum(KX[j][i] * v[3 * j + i] for j in range(3) for i in range(3))
    gy = sum(ky[j][i] * v[3 * j + i] for j in range(3) for i in range(3))
    mag = abs(gx) + abs(gy)
    if UMBRAL > 0:
        return 255 if mag > UMBRAL else 0
    return min(mag, 255)


def main():
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    ruta = sys.argv[1] if len(sys.argv) > 1 else IMAGEN

    # 1-2. Leer, pasar a grises y reducir
    ancho, alto, filas = leer_gris(ruta)
    ancho, alto, filas = reducir(ancho, alto, filas, TAM_MAX)
    guardar_png("entrada_gris.png", filas)

    r = 1                       # ventana 3x3: se pierde 1 pixel de borde

    # 3-4. Recorrer la imagen fila a fila con la ventana
    f_est = open("estimulos.txt", "w")
    f_esp = open("esperados.txt", "w")
    n = 0
    for y in range(r, alto - r):
        for x in range(r, ancho - r):
            ventana = [filas[y + j][x + i]
                       for j in range(-r, r + 1) for i in range(-r, r + 1)]
            f_est.write(" ".join(str(p) for p in ventana) + "\n")
            f_esp.write(str(modelo_referencia(ventana)) + "\n")
            n += 1
    f_est.close()
    f_esp.close()

    # Tamano de la imagen de salida (la usa ver_resultado.py)
    with open("info_imagen.txt", "w") as f:
        f.write(f"{ancho - 2 * r} {alto - 2 * r}\n")

    print(f"Imagen: {ruta}  ->  {ancho} x {alto} pixeles en grises")
    print(f"Filtro {FILTRO}: {n} ventanas escritas en estimulos.txt")
    print(f"Resultados esperados en esperados.txt")
    print(f"Tiempo minimo de simulacion: unos {(n + 10) * 10 / 1000:.0f} us "
          f"(reloj de 10 ns). Revise tiempo_sim.txt")


if __name__ == "__main__":
    main()
