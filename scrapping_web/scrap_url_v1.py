# Nombre: Scrapping Web List
# Descripciòn: script para realizar un scarpping de un listado de webs con contenido dinàmico
#               Incluye limpieza extrayendo el texto ùtil con BeatifulSoup
#               La salida de texto la deja en un archivo para que pueda ser procesado por un LLM,
#               según los parametros que se le indique, puede ser un incluido en una prox versión.
# Version: 1.0
# Autor: Agustin Alvarez
#################################################################################################
import os
from bs4 import BeautifulSoup
from playwright.sync_api import sync_playwright

# Archivos de entrada y salida
INPUT_FILE = "urls.txt"
OUTPUT_FILE = "contenido_limpio.txt"


def cargar_urls(archivo):
  """Lee el archivo TXT, elimina espacios y descarta duplicados manteniendo el orden."""
  if not os.path.exists(archivo):
    print(f"[X] No se encontró el archivo '{archivo}'.")
    return []

  with open(archivo, "r", encoding="utf-8") as f:
    lineas = [line.strip() for line in f if line.strip() and not line.startswith("#")]
    # Elimina duplicados usando un diccionario (preserva el orden de aparición)
    urls_unicas = list(dict.fromkeys(lineas))
    return urls_unicas


def limpiar_html(html_content):
  """Elimina la basura del DOM y extrae el texto limpio."""
  soup = BeautifulSoup(html_content, "html.parser")

  # Etiquetas a eliminar para reducir drásticamente el ruido y tamaño
  elementos_a_borrar = [
      "script",
      "style",
      "nav",
      "footer",
      "header",
      "aside",
      "form",
      "iframe",
      "noscript",
  ]
  for elem in soup(elementos_a_borrar):
    elem.decompose()

  # Extraer texto visible organizado con saltos de línea
  texto_limpio = soup.get_text(separator="\n", strip=True)
  return texto_limpio


def main():
  urls = cargar_urls(INPUT_FILE)
  if not urls:
    print("No hay URLs válidas para procesar.")
    return

  print(f"[+] Se cargaron {len(urls)} URLs únicas desde {INPUT_FILE}.")
  print("[+] Iniciando navegador automatizado...\n")

  with open(OUTPUT_FILE, "w", encoding="utf-8") as outfile:
    with sync_playwright() as p:
      # Lanzamos el navegador en modo headless (puedes cambiar a headless=False para debuguear)
      browser = p.chromium.launch(headless=True)

      # Creamos un contexto simulando un navegador real de escritorio
      context = browser.new_context(
          user_agent=(
              "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
              "AppleWebKit/537.36 (KHTML, like Gecko) "
              "Chrome/122.0.0.0 Safari/537.36"
          ),
          viewport={"width": 1366, "height": 768},
          locale="es-AR",
      )
      page = context.new_page()

      for i, url in enumerate(urls, 1):
        try:
          print(f"[{i}/{len(urls)}] Descargando: {url}")

          # Navegamos y esperamos a que el DOM cargue por completo
          page.goto(url, timeout=60000, wait_until="domcontentloaded")

          # Pequeña pausa adicional para asegurar que carguen los scripts de la propiedad
          page.wait_for_timeout(3500)

          html_content = page.content()
          texto_limpio = limpiar_html(html_content)

          # Escribimos los datos limpios en el archivo consolidado con separadores claros
          outfile.write(f"\n\n{'='*70}\n")
          outfile.write(f"URL: {url}\n")
          outfile.write(f"{'='*70}\n\n")
          outfile.write(texto_limpio)

          print(f"  └─ [OK] Procesado y guardado correctamente.")

        except Exception as e:
          print(f"  └─ [ERROR] No se pudo procesar la URL: {e}")
          outfile.write(f"\n\n{'='*70}\n")
          outfile.write(f"URL: {url} [FALLIDA]\n")
          outfile.write(f"{'='*70}\n\nError: {e}\n")

      browser.close()

  print(f"\n[¡Proceso Finalizado!] Archivo generado con éxito: {OUTPUT_FILE}")


if __name__ == "__main__":
  main()
