#Muestra cuanta memoria consume el script
#WorkingSet:
#Qué es: La cantidad de memoria física (RAM) que el proceso está usando actualmente.
#Incluye: Tanto memoria privada como compartida (por ejemplo, librerías DLL).
#Útil para: Saber cuánta RAM está ocupando realmente el proceso en este momento.
#PagedMemorySize
#Qué es: La cantidad de memoria que el proceso ha asignado, que puede estar en disco (en el archivo de paginación) o en RAM.
#Paged significa "paginada", es decir, intercambiable entre RAM y disco por el sistema operativo.
#Incluye: Solo memoria privada del proceso (no compartida con otros).
#PrivateMemorySize
#Qué es: La memoria privada del proceso que no puede ser compartida con otros procesos.
#Siempre es única para ese proceso.
#Puede estar en RAM o en disco, como PagedMemorySize, pero se enfoca solo en la porción privada.

#Solo muestra en tabla las memorias
$proc = Get-Process -Id $PID

[PSCustomObject]@{
    ProcessName        = $proc.ProcessName
    WorkingSet_GB      = "{0:N2}" -f ($proc.WorkingSet64 / 1GB)
    PagedMemorySize_GB = "{0:N2}" -f ($proc.PagedMemorySize64 / 1GB)
    PrivateMemory_GB   = "{0:N2}" -f ($proc.PrivateMemorySize64 / 1GB)
}


#-----------------------
#Genera un aviso si la memoria workingset es mayor a 2 Gb

$proc = Get-Process -Id $PID  # O usa -Name "nombre"

$workingSetGB = $proc.WorkingSet64 / 1GB

if ($workingSetGB -gt 2) {
    Write-Warning "⚠ El proceso '$($proc.ProcessName)' usa más de 2 GB de RAM ($([math]::Round($workingSetGB, 2)) GB)"
} else {
    Write-Output "✅ Memoria OK: $([math]::Round($workingSetGB, 2)) GB usada por '$($proc.ProcessName)'"
}
