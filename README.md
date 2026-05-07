# Corrigir TLS no Windows

## Script para corrigir configuração de TLS no Windows Server 2012 R2 / Windows 7 / 8.1

Habilita TLS 1.1 e TLS 1.2 (Client e Server), `SchUseStrongCrypto` para .NET, `DefaultSecureProtocols` para WinHTTP, e desabilita SSL 2.0 / 3.0. Resolve erro de conexão HTTPS com sites modernos que exigem TLS 1.2+ (GitHub, Cloudflare, APIs REST etc.).

### 1. No CMD remoto de cada PC (como Administrador):
```
del %TEMP%\corrigir_tls.cmd %TEMP%\testar_tls.cmd
curl -L -o %TEMP%\corrigir_tls.cmd https://raw.githubusercontent.com/viniciusbarretobr/corrigir_tls_windows/main/corrigir_tls.bat
curl -L -o %TEMP%\testar_tls.cmd https://raw.githubusercontent.com/viniciusbarretobr/corrigir_tls_windows/main/testar_tls.bat
%TEMP%\corrigir_tls.cmd
```

### 2. Reboot OBRIGATÓRIO:
Alterações em SCHANNEL só entram em vigor após reiniciar.
```
shutdown /r /t 10 /c "Reboot para aplicar correcao TLS"
```

### 3. Validar após reboot:
```
%TEMP%\testar_tls.cmd
```
Procurar `tls_version` = `TLS 1.2` ou `TLS 1.3` na saída e todos os testes `OK`.

---

## O que o script aplica

| Componente | Chave | Efeito |
|------------|-------|--------|
| SCHANNEL TLS 1.2 | `Enabled=1`, `DisabledByDefault=0` (Client + Server) | Habilita TLS 1.2 no SO |
| SCHANNEL TLS 1.1 | `Enabled=1`, `DisabledByDefault=0` (Client + Server) | Habilita TLS 1.1 no SO |
| SCHANNEL TLS 1.0 | `Enabled=1` (Client) | Mantém compat com sistemas antigos |
| SCHANNEL SSL 2.0/3.0 | `Enabled=0`, `DisabledByDefault=1` | Desabilita protocolos inseguros |
| .NET 4.x (64+32 bit) | `SchUseStrongCrypto=1`, `SystemDefaultTlsVersions=1` | Apps .NET passam a negociar TLS 1.2 |
| .NET 2.0/3.5 (64+32 bit) | `SchUseStrongCrypto=1`, `SystemDefaultTlsVersions=1` | Apps legados também |
| WinHTTP | `DefaultSecureProtocols=0xAA0` (TLS 1.0+1.1+1.2) | Apps WinHTTP (Office, updates) |
| WinINET (IE) | `SecureProtocols=0xA80` (TLS 1.0+1.1+1.2) | Internet Explorer e apps embarcados |

## Notas

1. A partir do Windows 10 1803 (abril/2018) o `curl.exe` vem nativo em `C:\Windows\System32\curl.exe`. No Windows 2012 R2 / 7 / 8.1 pode precisar instalar:
```
where curl >nul 2>&1 || (powershell -Command "Invoke-WebRequest -Uri 'https://curl.se/windows/latest.cgi?p=win64-mingw.zip' -OutFile $env:TEMP+'\curl.zip'; Expand-Archive -Path $env:TEMP+'\curl.zip' -DestinationPath $env:TEMP+'\curl' -Force; Get-ChildItem $env:TEMP+'\curl' -Filter 'curl.exe' -Recurse | Select-Object -First 1 | Copy-Item -Destination C:\Windows\System32\")
```

2. **Reboot é obrigatório** — sem reiniciar, SCHANNEL continua usando o estado anterior em memória.

3. Caso o servidor não acesse HTTPS para baixar os scripts (galinha-ovo), copie manualmente via SMB / RDP / outro caminho e execute local.

4. Decodificação de `0xAA0`:
   - `0x080` = TLS 1.0
   - `0x200` = TLS 1.1
   - `0x800` = TLS 1.2
   - Soma = `0xAA0` (habilita os três)

5. Log do `corrigir_tls.bat` fica em `%TEMP%\corrigir_tls.log`.
