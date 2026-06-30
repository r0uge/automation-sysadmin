# Este script verifica si hoy es un feriado en Argentina y, si no lo es, ejecuta el script.

# Ruta a tu script
$autoHotkeyScriptPath = "C:\Users\X\Scripts\script.ahk"
# Ruta al ejecutable del Intérprete
$autoHotkeyExePath = "C:\Users\X\EXE\AutoHotKey\AutoHotkey32.exe"

# Obtener la fecha actual en formato YYYY-MM-DD
$today = Get-Date -Format "yyyy-MM-dd"
$currentYear = (Get-Date).Year

# URL de la API de feriados de Argentina
$holidaysApiUrl = "https://argentinaferiados-api.vercel.app/$currentYear"

Write-Host "Verificando feriados para el año $currentYear..."

try {
    # Realizar la solicitud web a la API
    $holidaysJson = Invoke-RestMethod -Uri $holidaysApiUrl -Method Get
    
    # Convertir el JSON a un objeto PowerShell
    # La API devuelve un array de objetos, cada uno con una propiedad 'fecha'.
    $holidays = $holidaysJson | ForEach-Object { $_.fecha }

    # Verificar si la fecha actual es un feriado
    if ($holidays -contains $today) {
        Write-Host "Hoy ($today) es un feriado en Argentina. El script  NO se ejecutará."
    } else {
        Write-Host "Hoy ($today) NO es un feriado. Ejecutando el script ..."
      
        Start-Process -FilePath $autoHotkeyExePath -ArgumentList $autoHotkeyScriptPath -NoNewWindow -Wait
		
        Write-Host "Script ejecutado."
    }
}
catch {
    Write-Warning "No se pudo obtener la lista de feriados o hubo un error de red."
    Write-Warning "Mensaje de error: $($_.Exception.Message)"
    Write-Warning "Por precaución, el script NO se ejecutará."
    # Si no se pueden obtener los feriados, por seguridad, es mejor no ejecutar el script.
}

Write-Host "Proceso de verificación de feriados completado."