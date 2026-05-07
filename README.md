# Corrigir TLS no Windows

## Script para corrigir configuração de TLS no Windows Server 2012 R2 / Windows 7 / 8.1

Habilita TLS 1.1 e TLS 1.2 (Client e Server), `SchUseStrongCrypto` para .NET, `DefaultSecureProtocols` para WinHTTP, e desabilita SSL 2.0 / 3.0. Resolve erro de conexão HTTPS com sites modernos que exigem TLS 1.2+ (GitHub, Cloudflare, APIs REST etc.).

### 1. No CMD remoto de cada PC (como Administrador)

> ⚠️ **Importante:** abrir **CMD**, não PowerShell. No PowerShell o `curl` é alias de `Invoke-WebRequest` e quebra. No Windows Server 2012 R2 também **não existe curl nativo**, por isso o comando abaixo usa PowerShell + `Invoke-WebRequest` forçando TLS 1.2 (resolve o galinha-ovo onde o HTTPS está quebrado justamente pra baixar o fix).

**Comando único (CMD admin, copia e cola):**
```
powershell -Command "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -UseBasicParsing -Uri 'https://raw.githubusercontent.com/viniciusbarretobr/corrigir_tls_windows/main/corrigir_tls.bat' -OutFile $env:TEMP\corrigir_tls.bat; Invoke-WebRequest -UseBasicParsing -Uri 'https://raw.githubusercontent.com/viniciusbarretobr/corrigir_tls_windows/main/testar_tls.bat' -OutFile $env:TEMP\testar_tls.bat" && %TEMP%\corrigir_tls.bat
```

**Se mesmo o PowerShell falhar** (TLS 1.2 não habilitado nem no .NET ainda), use BITSAdmin que ignora SCHANNEL do .NET:
```
bitsadmin /transfer fixtls /priority foreground https://raw.githubusercontent.com/viniciusbarretobr/corrigir_tls_windows/main/corrigir_tls.bat %TEMP%\corrigir_tls.bat
bitsadmin /transfer testtls /priority foreground https://raw.githubusercontent.com/viniciusbarretobr/corrigir_tls_windows/main/testar_tls.bat %TEMP%\testar_tls.bat
%TEMP%\corrigir_tls.bat
```

### 2. Reboot OBRIGATÓRIO:
Alterações em SCHANNEL só entram em vigor após reiniciar.
```
shutdown /r /t 10 /c "Reboot para aplicar correcao TLS"
```

### 3. Validar após reboot:
```
%TEMP%\testar_tls.bat
```
Procurar `tls_version` = `TLS 1.2` na saída e todos os testes `OK`. (Win 2012 R2 não suporta TLS 1.3, então 1.2 é o máximo esperado.)

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
| Cipher Suite Order | `Functions` (ECDHE+GCM no topo) | Prioriza forward secrecy + AEAD; satisfaz bancos/APIs estritos |
| Curvas ECC | `EccCurves=NistP384,NistP256` | Curvas modernas suportadas no SO |
| Raízes confiáveis | `certutil -generateSSTFromWU` + `addstore` | Importa raízes novas (ISRG, Google GTS, etc.) sem esperar Windows Update |

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

6. **Atualização de raízes pode falhar antes do reboot** se o WinHTTP do `certutil` ainda usar o estado antigo de TLS. Caso veja `AVISO - generateSSTFromWU falhou`, re-execute `corrigir_tls.bat` após o reboot — só a parte `[6/7]` precisa rodar.

7. **Cipher suites** são apenas as nativas do SO. Win 2012 R2 não tem `X25519`, `ChaCha20-Poly1305` nem TLS 1.3 — script só reordena o que já existe.

## Sobrevida estimada

| Componente | Sem script | Com script |
|------------|-----------|------------|
| HTTPS sites modernos | já quebrado | 4-6 anos |
| Cadeia Let's Encrypt / Google GTS | quebra ao expirar raiz antiga | OK até nova raiz aparecer (re-rodar) |
| Compat com sites que exigirem TLS 1.3 | impossível | impossível (precisa migrar SO) |

**Recomendação:** Win 2012 R2 fora de suporte desde out/2023. Script é paliativo. Migração para Server 2022+ é solução definitiva.
