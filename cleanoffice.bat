@echo off
setlocal EnableDelayedExpansion

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [LOI] Can chay voi quyen Administrator!
    pause
    exit /b
)

set "log=%temp%\office_clean_debug.txt"
echo === %date% %time% === > "%log%"

echo ============================================
echo TOOL XOA KEY OFFICE (Word, Excel, Powerpoint, Outlook) (Debug mode)
echo ============================================
echo.

:: --- Tim tat ca ospp.vbs ---
set "count=0"
for %%D in (
    "%ProgramFiles%\Microsoft Office\root\Office16"
    "%ProgramFiles(x86)%\Microsoft Office\root\Office16"
    "%ProgramFiles%\Microsoft Office\Office16"
    "%ProgramFiles(x86)%\Microsoft Office\Office16"
    "%ProgramFiles%\Microsoft Office\root\Office15"
    "%ProgramFiles(x86)%\Microsoft Office\root\Office15"
    "%ProgramFiles%\Microsoft Office\Office15"
    "%ProgramFiles(x86)%\Microsoft Office\Office15"
    "%ProgramFiles%\Microsoft Office\root\Office14"
    "%ProgramFiles(x86)%\Microsoft Office\root\Office14"
    "%ProgramFiles%\Microsoft Office\Office14"
    "%ProgramFiles(x86)%\Microsoft Office\Office14"
) do (
    if exist "%%~D\ospp.vbs" (
        set /a count+=1
        echo [+] Tim thay Office tai: %%~D
        echo. >> "%log%"
        echo ===== %%~D ===== >> "%log%"
        
        pushd "%%~D"
        
        :: Xoa host KMS truoc
        echo   -> Xoa host KMS...
        cscript //nologo ospp.vbs /remhst >> "%log%" 2>&1
        
        :: Lay trang thai ban quyen
        echo   -> Dang quet key hien co...
        cscript //nologo ospp.vbs /dstatus > "%temp%\ospp_raw.txt" 2>nul
        
        :: Ghi raw output vao log de debug
        type "%temp%\ospp_raw.txt" >> "%log%"
        echo. >> "%log%"
        echo --- Dang phan tich --- >> "%log%"
        
        :: Dung PowerShell + Regex de tim CHINH XAC 5 ky tu cuoi
        :: Regex: tim 5 ky tu chu/s o cuoi dong, co the sau dau ":"
        powershell -NoProfile -ExecutionPolicy Bypass -Command ^
            "$txt=Get-Content '%temp%\ospp_raw.txt' -Raw; " ^
            "$matches=[regex]::Matches($txt, '[: ]\s*([A-Z0-9]{5})\s*$', 'Multiline'); " ^
            "$keys=@(); foreach($m in $matches){$k=$m.Groups[1].Value; if($k -notin $keys){$keys+=$k}}; " ^
            "$keys | Out-File '%temp%\found_keys.txt' -Encoding ASCII"
        
        :: Kiem tra co tim duoc key khong
        if not exist "%temp%\found_keys.txt" (
            echo   [!] Khong tim thay key nao tai day.
            popd
            continue
        )
        
        :: Dem so key tim duoc
        for /f %%c in ('type "%temp%\found_keys.txt" ^| find /c /v ""') do set "keycount=%%c"
        echo   -> Tim thay !keycount! key can xoa
        echo Tim thay !keycount! key: >> "%log%"
        type "%temp%\found_keys.txt" >> "%log%"
        
        :: Xoa tung key
        for /f %%k in (%temp%\found_keys.txt%) do (
            echo     [-] Dang xoa key: %%k
            cscript //nologo ospp.vbs /unpkey:%%k >> "%log%" 2>&1
            if !errorlevel! equ 0 (
                echo       [OK] Da xoa thanh cong key %%k
            ) else (
                echo       [LOI] Khong xoa duoc key %%k
            )
        )
        
        :: Kiem tra lai sau khi xoa
        echo   -> Kiem tra lai...
        cscript //nologo ospp.vbs /dstatus > "%temp%\ospp_check.txt" 2>nul
        powershell -NoProfile -ExecutionPolicy Bypass -Command ^
            "$txt=Get-Content '%temp%\ospp_check.txt' -Raw; " ^
            "$m=[regex]::Matches($txt, '[: ]\s*([A-Z0-9]{5})\s*$', 'Multiline'); " ^
            "if($m.Count -eq 0){Write-Host '[THANH CONG] Da xoa toan bo key crack! Lien he : 0352 194 195 (gap Tuan) de mua key ban quyen)' -ForegroundColor Green}else{Write-Host '       [CANH BAO] Van con '$m.Count' key!' -ForegroundColor Red}"
        
        type "%temp%\ospp_check.txt" >> "%log%"
        popd
    )
)

if %count%==0 (
    echo.
    echo [LOI] Khong tim thay file ospp.vbs nao!
    echo Office cua ban co the la ban Microsoft Store (khong ho tro ospp.vbs)
)

echo.
echo ============================================
echo Log file: %log%
echo ============================================
echo.
pause
