# Automation & SysAdmin

Repositorio con scripts de automatización y administración del sistema, orientados a tareas repetitivas, monitoreo de recursos, scraping de contenido web, entre otros.

## Índice de scripts

### 1. autohotkey-record-run/
Carpeta dedicada a la grabación y reproducción de macros de teclado y mouse con AutoHotkey.

- `recorder.ahk`: grabador avanzado de acciones del mouse y teclado. Permite iniciar, pausar, detener y reproducir una macro, además de exportarla a un archivo `.ahk` para reutilizarlo.
- `run.cmd`: lanzador simple que ejecuta el script de AutoHotkey.

### 2. ps-memory-use/
Script de PowerShell para monitorear el consumo de memoria del proceso actual.

- `memory_user_script.ps1`: muestra estadísticas de RAM del proceso, como `WorkingSet`, `PagedMemorySize` y `PrivateMemorySize`, y además alerta si supera un umbral de 2 GB.

### 3. ps-run-feriados/
Automatización basada en PowerShell para evitar ejecutar un script en días feriados.

- `run_autohotkey_feriados.ps1`: consulta la API de feriados de Argentina y solo ejecuta un script de AutoHotkey si el día actual no es feriado.

### 4. py-scrapping-web/
Scripts en Python para automatizar la extracción de contenido de sitios web.

- `scrap_url_v1.py`: versión inicial de scraping masivo de URLs desde un archivo `urls.txt`, carga el HTML con Playwright y limpia el texto con BeautifulSoup para dejarlo listo para procesamiento posterior.
- `scrap_url_v2.py`: versión mejorada con intentos de evitar detecciones anti-bot, manejo de contenido dinámico y protección parcial contra Cloudflare mediante argumentos del navegador y una limpieza de contenido más robusta.

### 5. vbs-onoff-proxy/
Scripts VBScript para activar o desactivar el proxy del sistema en Windows.

- `proxy_on.vbs`: habilita el proxy configurado en el registro del usuario actual.
- `proxy_off.vbs`: desactiva el proxy del sistema.

## Descripción general

Este proyecto reúne utilidades prácticas para:

- automatizar tareas de desktop con AutoHotkey;
- monitorear recursos del sistema con PowerShell;
- ejecutar jobs condicionados por calendario/feriados;
- extraer contenido web limpio con Python;
- controlar la configuración de proxy desde Windows.

## Requisitos

- Windows para los scripts de AutoHotkey, PowerShell y VBS.
- Python 3 + Playwright + BeautifulSoup para los scripts de scraping.
- Acceso a Internet para la verificación de feriados y para el scraping de páginas web.

## Nota

Cada carpeta representa un script o conjunto de scripts funcionales, pensados para ser reutilizados o adaptados según la necesidad del entorno.
