"""
ver_resultado.py - PASO 4: ver la salida del circuito y comprobarla.

    1. Lee resultados.txt (lo escribe tb_sobel.vhd, un pixel por linea)
       y esperados.txt (lo escribe generar_estimulos.py)
    2. Compara pixel a pixel: IGUALES o DISTINTAS
    3. Guarda comparacion.png: entrada | esperada (Python) | obtenida (VHDL)
       y, si hay errores, una cuarta imagen con los pixeles distintos en blanco
"""
import os
import sys

# Python portable: buscar imagenes.py en la carpeta de este script
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from imagenes import leer_gris, guardar_png, panel, lado_a_lado, abrir


def leer_numeros(ruta):
    with open(ruta) as f:
        return [int(linea) for linea in f if linea.strip()]


def como_imagen(pixeles, ancho, alto):
    pixeles = pixeles + [0] * (ancho * alto - len(pixeles))   # si faltan
    return [pixeles[y * ancho:(y + 1) * ancho] for y in range(alto)]


def main():
    os.chdir(os.path.dirname(os.path.abspath(__file__)))

    # 1. Leer el tamano y los dos ficheros
    with open("info_imagen.txt") as f:
        ancho, alto = (int(v) for v in f.read().split())
    esperados = leer_numeros("esperados.txt")      # modelo Python
    obtenidos = leer_numeros("resultados.txt")     # circuito VHDL

    # 2. Comparar pixel a pixel
    distintos = [i for i in range(len(esperados))
                 if i >= len(obtenidos) or obtenidos[i] != esperados[i]]
    if len(obtenidos) != len(esperados):
        print(f"AVISO: el circuito ha dado {len(obtenidos)} pixeles y se "
              f"esperaban {len(esperados)}. Revise tiempo_sim.txt")
    if not distintos:
        print(f"IGUALES: los {len(esperados)} pixeles coinciden con Python")
    else:
        print(f"DISTINTAS: {len(distintos)} pixeles no coinciden. Primeros:")
        for i in distintos[:10]:
            obt = obtenidos[i] if i < len(obtenidos) else "falta"
            print(f"  fila {i // ancho}, columna {i % ancho}: "
                  f"esperado {esperados[i]}, obtenido {obt}")

    # 3. Imagenes lado a lado
    esperada = como_imagen(esperados, ancho, alto)
    obtenida = como_imagen(obtenidos, ancho, alto)
    guardar_png("resultado_bordes.png", obtenida)

    _, alto_e, entrada = leer_gris("entrada_gris.png")
    r = (alto_e - alto) // 2                       # quitar el marco perdido
    entrada = [fila[r:r + ancho] for fila in entrada[r:r + alto]]

    paneles = [panel(entrada, "entrada"),
               panel(esperada, "esperada (python)"),
               panel(obtenida, "obtenida (vhdl)")]
    if distintos:
        marcas = set(distintos)
        dif = como_imagen([255 if i in marcas else 0
                           for i in range(ancho * alto)], ancho, alto)
        paneles.append(panel(dif, "diferencias"))
    guardar_png("comparacion.png", lado_a_lado(paneles))
    print("Imagenes lado a lado -> comparacion.png")
    abrir("comparacion.png")


if __name__ == "__main__":
    main()
