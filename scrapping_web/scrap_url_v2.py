# Nombre: Scrapping Web List
# Descripciòn: Scarpping de un listado de URL con contenido dinámico, es una 
#           descarga masiva de páginas. Incluye limpieza extrayendo solo el 
#           texto útil con BeatifulSoup y evitando portecciones como Cloudlfare
#           La salida de texto la deja en un archivo para que pueda ser 
#           procesado por un LLM, según los parametros que se le indique, puede
#           ser un incluido en una prox versión.
#           El archivo de salida concatena todos los resultados, colocando un 
#           serpardor para indicar a que URL pertenece.
# Version: 2.0
# Autor: Agustin Alvarez
#################################################################################################
import os
import time
from bs4 import BeautifulSoup
from playwright.sync_api import sync_playwright

INPUT_FILE = "urls.txt"
OUTPUT_FILE = "contenido_limpio.txt"


def cargar_urls(archivo):
  """Lee el archivo TXT, elimina espacios y descarta duplicados manteniendo el orden."""
  if not os.path.exists(archivo):
    print(f"[X] No se encontró el archivo '{archivo}'.")
    return []

  with open(archivo, "r", encoding="utf-8") as f:
    lineas = [line.strip() for line in f if line.strip() and not line.startswith("#")]
    return list(dict.fromkeys(lineas))


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

  return soup.get_text(separator="\n", strip=True)


def main():
  urls = cargar_urls(INPUT_FILE)
  if not urls:
    print("No hay URLs válidas para procesar.")
    return

  print(f"[+] Se cargaron {len(urls)} URLs únicas desde {INPUT_FILE}.")
  print("[+] Iniciando Chromium con bypass anti-bot...\n")

  with open(OUTPUT_FILE, "w", encoding="utf-8") as outfile:
    with sync_playwright() as p:
      # Lanzamos Chromium con argumentos que ocultan que es controlado por Playwright
      browser = p.chromium.launch(
          headless=False,  # <--- Ponlo en False para que pase Cloudflare sin problemas
          args=[
              "--disable-blink-features=AutomationControlled",
              "--start-maximized",
              "--no-sandbox",
          ],
      )

      context = browser.new_context(
          user_agent=(
              "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
              "AppleWebKit/537.36 (KHTML, like Gecko) "
              "Chrome/124.0.0.0 Safari/537.36"
          ),
          viewport={"width": 1366, "height": 768},
          locale="es-AR",
      )

      page = context.new_page()

      # Script inyectado para borrar el flag navigator.webdriver
      page.add_init_script("""
                Object.defineProperty(navigator, 'webdriver', {
                    get: () => undefined
                });
            """)

      for i, url in enumerate(urls, 1):
        try:
          print(f"[{i}/{len(urls)}] Cargando: {url}")
          # Navegamos y esperamos a que el DOM cargue por completo
          page.goto(url, timeout=60000, wait_until="domcontentloaded")

          # Si detecta el cartel de Cloudflare, espera a que pase
          print("  ├─ Esperando resolución de Cloudflare/DOM...")
          time.sleep(5)  # Tiempo para que pase el reCAPTCHA / Turnstile solo

          # Verificación rápida de contenido cargado
          contenido_pagina = page.content()
          if "Verificación de seguridad" in contenido_pagina or "Cloudflare" in contenido_pagina:
            print("  ├─ [!] Detectado Cloudflare. Esperando 5 segundos más...")
            time.sleep(5)
            contenido_pagina = page.content()

          texto_limpio = limpiar_html(contenido_pagina)
          # Escribimos los datos limpios en el archivo consolidado con separadores claros
          outfile.write(f"\n\n{'='*70}\n")
          outfile.write(f"URL: {url}\n")
          outfile.write(f"{'='*70}\n\n")
          outfile.write(texto_limpio)

          print(f"  └─ [OK] Procesado y guardado.")

        except Exception as e:
          print(f"  └─ [ERROR] Falló la URL: {e}")
          outfile.write(f"\n\n{'='*70}\nURL: {url} [FALLIDA]\n{'='*70}\n\nError: {e}\n")

      browser.close()

  print(f"\n[¡Proceso Finalizado!] Revisa el archivo: {OUTPUT_FILE}")


if __name__ == "__main__":
  main()
