"""
imagenes.py - Leer y guardar imagenes en escala de grises SIN instalar nada.

Funciona con el Python "embeddable" (portable) de python.org: solo usa la
biblioteca estandar. Lee PNG (8 bits, sin entrelazado) y PGM. Si el paquete
Pillow esta instalado, lee tambien JPG, BMP, GIF... (no es obligatorio).

No hace falta entender este fichero para la practica: solo se usan
    leer_gris(ruta)          -> (ancho, alto, filas)   filas[y][x] = 0..255
    guardar_png(ruta, filas)
    panel(filas, titulo)     -> imagen ampliada con un titulo encima
    lado_a_lado(paneles)     -> une varias imagenes en una sola
"""
import struct
import zlib


# ---------------------------------------------------------------- lectura ---
def leer_gris(ruta):
    """Devuelve (ancho, alto, filas) con la imagen en grises 0..255."""
    with open(ruta, "rb") as f:
        cab = f.read(8)
    if cab.startswith(b"\x89PNG"):
        return _leer_png(ruta)
    if cab[:2] in (b"P5", b"P2"):
        return _leer_pgm(ruta)
    try:
        from PIL import Image                      # opcional: JPG, BMP...
    except ImportError:
        raise SystemExit(
            "ERROR: sin Pillow solo se leen imagenes PNG. Guarde la imagen "
            "como PNG (por ejemplo con Paint: Archivo > Guardar como > PNG).")
    img = Image.open(ruta).convert("RGB")
    ancho, alto = img.size
    rgb = img.tobytes()
    gris = [(299 * rgb[i] + 587 * rgb[i + 1] + 114 * rgb[i + 2]) // 1000
            for i in range(0, len(rgb), 3)]
    return ancho, alto, [gris[y * ancho:(y + 1) * ancho] for y in range(alto)]


def _leer_png(ruta):
    with open(ruta, "rb") as f:
        datos = f.read()
    pos, idat, paleta = 8, b"", None
    while pos < len(datos):
        n, tipo = struct.unpack(">I4s", datos[pos:pos + 8])
        trozo = datos[pos + 8:pos + 8 + n]
        if tipo == b"IHDR":
            ancho, alto, prof, color, _, _, entrelazado = struct.unpack(">IIBBBBB", trozo)
        elif tipo == b"PLTE":
            paleta = [tuple(trozo[i:i + 3]) for i in range(0, n, 3)]
        elif tipo == b"IDAT":
            idat += trozo
        pos += 12 + n
    if prof != 8 or entrelazado:
        raise ValueError("PNG no soportado (necesita 8 bits por canal y sin "
                         "entrelazado). Vuelva a guardarlo con Paint como PNG.")
    canales = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}[color]
    bruto = zlib.decompress(idat)
    paso = ancho * canales
    filas, anterior, i = [], bytearray(paso), 0
    for _ in range(alto):
        filtro, fila = bruto[i], bytearray(bruto[i + 1:i + 1 + paso])
        i += 1 + paso
        for k in range(paso):                      # deshacer el filtro PNG
            a = fila[k - canales] if k >= canales else 0
            b = anterior[k]
            c = anterior[k - canales] if k >= canales else 0
            if filtro == 1:
                fila[k] = (fila[k] + a) & 255
            elif filtro == 2:
                fila[k] = (fila[k] + b) & 255
            elif filtro == 3:
                fila[k] = (fila[k] + (a + b) // 2) & 255
            elif filtro == 4:
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                pred = a if (pa <= pb and pa <= pc) else (b if pb <= pc else c)
                fila[k] = (fila[k] + pred) & 255
        anterior = fila
        gris = []
        for x in range(ancho):
            px = fila[x * canales:(x + 1) * canales]
            if color == 3:
                px = paleta[px[0]]
            if len(px) >= 3:                       # RGB -> gris (luminancia)
                gris.append((299 * px[0] + 587 * px[1] + 114 * px[2]) // 1000)
            else:
                gris.append(px[0])
        filas.append(gris)
    return ancho, alto, filas


def _leer_pgm(ruta):
    with open(ruta, "rb") as f:
        datos = f.read()
    tokens, pos = [], 0
    while len(tokens) < 4:                         # P5 ancho alto maximo
        while datos[pos:pos + 1].isspace():
            pos += 1
        if datos[pos:pos + 1] == b"#":
            pos = datos.index(b"\n", pos)
            continue
        ini = pos
        while not datos[pos:pos + 1].isspace():
            pos += 1
        tokens.append(datos[ini:pos])
    ancho, alto, maximo = int(tokens[1]), int(tokens[2]), int(tokens[3])
    if tokens[0] == b"P5":
        valores = list(datos[pos + 1:pos + 1 + ancho * alto])
    else:
        valores = [int(v) for v in datos[pos:].split()]
    valores = [v * 255 // maximo for v in valores]
    return ancho, alto, [valores[y * ancho:(y + 1) * ancho] for y in range(alto)]


# --------------------------------------------------------------- escritura ---
def guardar_png(ruta, filas):
    """Guarda una imagen en grises (lista de filas con valores 0..255)."""
    alto, ancho = len(filas), len(filas[0])
    bruto = b"".join(b"\x00" + bytes(fila) for fila in filas)

    def trozo(tipo, contenido):
        return (struct.pack(">I", len(contenido)) + tipo + contenido +
                struct.pack(">I", zlib.crc32(tipo + contenido) & 0xFFFFFFFF))

    with open(ruta, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(trozo(b"IHDR", struct.pack(">IIBBBBB", ancho, alto, 8, 0, 0, 0, 0)))
        f.write(trozo(b"IDAT", zlib.compress(bruto, 9)))
        f.write(trozo(b"IEND", b""))


def abrir(ruta):
    """Abre la imagen con el visor de Windows (en otros sistemas no hace nada)."""
    import os
    if hasattr(os, "startfile"):
        os.startfile(os.path.abspath(ruta))


# ------------------------------------------------- paneles con titulo ---
_LETRAS = {  # letras de 5x7 pixeles (solo las que se usan)
    "A": ["01110", "10001", "10001", "11111", "10001", "10001", "10001"],
    "B": ["11110", "10001", "10001", "11110", "10001", "10001", "11110"],
    "C": ["01111", "10000", "10000", "10000", "10000", "10000", "01111"],
    "D": ["11110", "10001", "10001", "10001", "10001", "10001", "11110"],
    "E": ["11111", "10000", "10000", "11110", "10000", "10000", "11111"],
    "F": ["11111", "10000", "10000", "11110", "10000", "10000", "10000"],
    "H": ["10001", "10001", "10001", "11111", "10001", "10001", "10001"],
    "I": ["01110", "00100", "00100", "00100", "00100", "00100", "01110"],
    "L": ["10000", "10000", "10000", "10000", "10000", "10000", "11111"],
    "N": ["10001", "11001", "10101", "10011", "10001", "10001", "10001"],
    "O": ["01110", "10001", "10001", "10001", "10001", "10001", "01110"],
    "P": ["11110", "10001", "10001", "11110", "10000", "10000", "10000"],
    "R": ["11110", "10001", "10001", "11110", "10100", "10010", "10001"],
    "S": ["01111", "10000", "10000", "01110", "00001", "00001", "11110"],
    "T": ["11111", "00100", "00100", "00100", "00100", "00100", "00100"],
    "V": ["10001", "10001", "10001", "10001", "10001", "01010", "00100"],
    "Y": ["10001", "10001", "01010", "00100", "00100", "00100", "00100"],
    "(": ["00010", "00100", "01000", "01000", "01000", "00100", "00010"],
    ")": ["01000", "00100", "00010", "00010", "00010", "00100", "01000"],
    " ": ["00000"] * 7,
}


def panel(filas, titulo, escala=3, gris_fondo=255):
    """Amplia la imagen (cada pixel -> escala x escala) y pone un titulo."""
    grande = []
    for fila in filas:
        f = [v for v in fila for _ in range(escala)]
        grande += [f] * escala
    ancho = len(grande[0])
    alto_titulo, t = 24, 2                       # letras a doble tamano
    titulo_filas = [[gris_fondo] * ancho for _ in range(alto_titulo)]
    x0 = max(0, (ancho - len(titulo) * 6 * t) // 2)
    for k, letra in enumerate(titulo.upper()):
        for j, linea in enumerate(_LETRAS.get(letra, _LETRAS[" "])):
            for i, bit in enumerate(linea):
                if bit == "1":
                    for dy in range(t):
                        for dx in range(t):
                            x = x0 + (k * 6 + i) * t + dx
                            if x < ancho:
                                titulo_filas[5 + j * t + dy][x] = 0
    return titulo_filas + grande


def lado_a_lado(paneles, separacion=8, gris_fondo=255):
    """Une varias imagenes de la misma altura, con un hueco entre ellas."""
    alto = max(len(p) for p in paneles)
    filas = []
    for y in range(alto):
        fila = []
        for k, p in enumerate(paneles):
            if k:
                fila += [gris_fondo] * separacion
            fila += p[y] if y < len(p) else [gris_fondo] * len(p[0])
        filas.append(fila)
    return filas
