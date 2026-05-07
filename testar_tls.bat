@echo off
setlocal EnableDelayedExpansion

REM ============================================================
REM Teste de TLS - Windows Server 2012 R2 / 7 / 8.1
REM Valida correcao de TLS via SCHANNEL, .NET e WinHTTP
REM Uso via CMD remoto - sem interacao
REM ============================================================

echo ============================================================
echo  Teste TLS - %COMPUTERNAME%
echo  Data: %date% %time%
echo ============================================================

REM --- 1. Chaves de registro ---
echo.
echo [1/6] Verificando chaves de registro...
echo ------------------------------------------------------------
echo --- SCHANNEL TLS 1.2 Client ---
reg query "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client" 2>nul | findstr /C:"Enabled" /C:"DisabledByDefault"
echo --- .NET 4.x SchUseStrongCrypto ---
reg query "HKLM\SOFTWARE\Microsoft\.NETFramework\v4.0.30319" 2>nul | findstr /C:"SchUseStrongCrypto" /C:"SystemDefaultTlsVersions"
echo --- WinHTTP DefaultSecureProtocols ---
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\WinHttp" 2>nul | findstr /C:"DefaultSecureProtocols"
echo ------------------------------------------------------------

REM --- 2. .NET WebClient (testa SchUseStrongCrypto) ---
echo.
echo [2/6] Teste .NET WebClient -^> https://www.google.com
echo ------------------------------------------------------------
powershell -NoProfile -Command "try { $r = (New-Object Net.WebClient).DownloadString('https://www.google.com'); Write-Host '       OK - .NET WebClient conectou (' $r.Length ' bytes)' } catch { Write-Host '       FALHOU -' $_.Exception.Message }"

REM --- 3. PowerShell Invoke-WebRequest TLS 1.2 forcado ---
echo.
echo [3/6] Teste Invoke-WebRequest com TLS 1.2 forcado -^> github.com API
echo ------------------------------------------------------------
powershell -NoProfile -Command "try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $r = Invoke-WebRequest -Uri 'https://api.github.com' -UseBasicParsing; Write-Host '       OK - HTTP' $r.StatusCode '(' $r.RawContentLength ' bytes)' } catch { Write-Host '       FALHOU -' $_.Exception.Message }"

REM --- 4. PowerShell sem forcar TLS (testa SystemDefaultTlsVersions) ---
echo.
echo [4/6] Teste Invoke-WebRequest SEM forcar TLS -^> github.com API
echo ------------------------------------------------------------
powershell -NoProfile -Command "try { $r = Invoke-WebRequest -Uri 'https://api.github.com' -UseBasicParsing; Write-Host '       OK - HTTP' $r.StatusCode '(default TLS funcionou)' } catch { Write-Host '       FALHOU -' $_.Exception.Message }"

REM --- 5. curl (testa SCHANNEL nativo) ---
echo.
echo [5/6] Teste curl (SCHANNEL nativo) -^> howsmyssl.com
echo ------------------------------------------------------------
where curl >nul 2>&1
if %errorLevel% equ 0 (
    curl -s --max-time 15 https://www.howsmyssl.com/a/check 2>nul | findstr /C:"tls_version" /C:"rating"
    if errorlevel 1 echo       FALHOU - curl nao conseguiu conectar
) else (
    echo       SKIP - curl nao instalado
)

REM --- 6. Versao TLS negociada com Cloudflare ---
echo.
echo [6/6] Versao TLS negociada -^> www.cloudflare.com
echo ------------------------------------------------------------
powershell -NoProfile -Command "try { $req = [Net.HttpWebRequest]::Create('https://www.cloudflare.com'); $req.Timeout=10000; $resp = $req.GetResponse(); Write-Host '       OK - Status:' $resp.StatusCode; $resp.Close() } catch { Write-Host '       FALHOU -' $_.Exception.Message }"

echo.
echo ============================================================
echo  Teste concluido em %COMPUTERNAME%
echo ============================================================
echo  Esperado: todos os testes OK e tls_version "TLS 1.2" ou "TLS 1.3"
echo  Se algum FALHOU: confirme reboot foi feito apos corrigir_tls
echo ============================================================
endlocal
