@echo off
setlocal EnableDelayedExpansion
REM ============================================================
REM Correcao TLS - Windows Server 2012 R2 / Windows 7 / 8.1
REM Habilita TLS 1.1/1.2, SchUseStrongCrypto, WinHTTP defaults
REM Uso via CMD remoto - sem interacao
REM ============================================================
set "LOG=%TEMP%\corrigir_tls.log"
echo ============================================================
echo  Correcao TLS - %COMPUTERNAME%
echo  Log: %LOG%
echo ============================================================
REM --- Verifica privilegios de admin ---
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERRO] Este script precisa ser executado como Administrador
    echo Abra o CMD com privilegios elevados e tente novamente
    exit /b 1
)
echo [OK] Executando como Administrador
echo [%date% %time%] Inicio > "%LOG%"

REM ============================================================
REM 1. SCHANNEL - Protocolos TLS
REM ============================================================
echo.
echo [1/5] Configurando SCHANNEL (protocolos TLS)...

REM --- TLS 1.2 (Client + Server) ---
reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client" /v Enabled /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client" /v DisabledByDefault /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server" /v Enabled /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server" /v DisabledByDefault /t REG_DWORD /d 0 /f >nul
echo       OK - TLS 1.2 habilitado (Client + Server)

REM --- TLS 1.1 (Client + Server) ---
reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client" /v Enabled /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client" /v DisabledByDefault /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server" /v Enabled /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server" /v DisabledByDefault /t REG_DWORD /d 0 /f >nul
echo       OK - TLS 1.1 habilitado (Client + Server)

REM --- TLS 1.0 (deixa habilitado para compatibilidade) ---
reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client" /v Enabled /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client" /v DisabledByDefault /t REG_DWORD /d 0 /f >nul
echo       OK - TLS 1.0 habilitado (compatibilidade)

REM --- SSL 2.0 e SSL 3.0 (desabilita - obsoletos/inseguros) ---
reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Client" /v Enabled /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Client" /v DisabledByDefault /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Server" /v Enabled /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Server" /v DisabledByDefault /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Client" /v Enabled /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Client" /v DisabledByDefault /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Server" /v Enabled /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Server" /v DisabledByDefault /t REG_DWORD /d 1 /f >nul
echo       OK - SSL 2.0 e SSL 3.0 desabilitados

REM ============================================================
REM 2. .NET Framework - SchUseStrongCrypto
REM ============================================================
echo.
echo [2/5] Configurando .NET Framework...

REM --- .NET 4.x (64-bit) ---
reg add "HKLM\SOFTWARE\Microsoft\.NETFramework\v4.0.30319" /v SchUseStrongCrypto /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\.NETFramework\v4.0.30319" /v SystemDefaultTlsVersions /t REG_DWORD /d 1 /f >nul
REM --- .NET 4.x (32-bit no SO 64-bit) ---
reg add "HKLM\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v4.0.30319" /v SchUseStrongCrypto /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v4.0.30319" /v SystemDefaultTlsVersions /t REG_DWORD /d 1 /f >nul
echo       OK - .NET 4.x configurado

REM --- .NET 2.0/3.5 (legacy apps) ---
reg add "HKLM\SOFTWARE\Microsoft\.NETFramework\v2.0.50727" /v SchUseStrongCrypto /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\.NETFramework\v2.0.50727" /v SystemDefaultTlsVersions /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v2.0.50727" /v SchUseStrongCrypto /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v2.0.50727" /v SystemDefaultTlsVersions /t REG_DWORD /d 1 /f >nul
echo       OK - .NET 2.0/3.5 configurado

REM ============================================================
REM 3. WinHTTP - DefaultSecureProtocols
REM 0xAA0 = TLS 1.0 (0x080) + TLS 1.1 (0x200) + TLS 1.2 (0x800)
REM ============================================================
echo.
echo [3/5] Configurando WinHTTP...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\WinHttp" /v DefaultSecureProtocols /t REG_DWORD /d 0xAA0 /f >nul
reg add "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Internet Settings\WinHttp" /v DefaultSecureProtocols /t REG_DWORD /d 0xAA0 /f >nul
echo       OK - WinHTTP DefaultSecureProtocols = 0xAA0

REM ============================================================
REM 4. Internet Explorer / WinINET (afeta apps que usam IE engine)
REM 0xA00 = TLS 1.1 + TLS 1.2 (sem SSL 2/3)
REM ============================================================
echo.
echo [4/5] Configurando Internet Explorer / WinINET...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" /v SecureProtocols /t REG_DWORD /d 0xA80 /f >nul
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" /v SecureProtocols /t REG_DWORD /d 0xA80 /f >nul
echo       OK - WinINET SecureProtocols = 0xA80 (TLS 1.0 + 1.1 + 1.2)

REM ============================================================
REM 5. Resumo + grava timestamp
REM ============================================================
echo.
echo [5/5] Resumo das chaves aplicadas:
echo ------------------------------------------------------------
reg query "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client" 2>nul | findstr /C:"Enabled" /C:"DisabledByDefault"
reg query "HKLM\SOFTWARE\Microsoft\.NETFramework\v4.0.30319" 2>nul | findstr /C:"SchUseStrongCrypto" /C:"SystemDefaultTlsVersions"
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\WinHttp" 2>nul | findstr /C:"DefaultSecureProtocols"
echo ------------------------------------------------------------
echo [%date% %time%] Concluido >> "%LOG%"

echo.
echo ============================================================
echo  ATENCAO: REBOOT OBRIGATORIO
echo ============================================================
echo As alteracoes do SCHANNEL so entram em vigor apos reiniciar.
echo.
echo Para reiniciar agora, execute:
echo     shutdown /r /t 10 /c "Reboot para aplicar correcao TLS"
echo.
echo Apos o reboot, valide com: testar_tls.bat
echo ============================================================
endlocal
