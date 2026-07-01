Const HKEY_CURRENT_USER = &H80000001

strComputer = "adminbk"
Set objRegistry = GetObject("winmgmts:\\" & strComputer & "\root\default:StdRegProv")

strKeyPath = "SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings"

strValueName = "ProxyEnable"
dwValue = 1
objRegistry.SetDWORDValue HKEY_CURRENT_USER, strKeyPath, strValueName, dwValue

strValueName = "ProxyServer"
dwValue = "10.2.0.5:3128"
objRegistry.SetStringValue HKEY_CURRENT_USER, strKeyPath, strValueName, dwValue
