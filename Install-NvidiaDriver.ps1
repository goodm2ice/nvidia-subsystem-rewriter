<#
.SYNOPSIS
Script for install drivers on NVIDIA card with broken SUBSYS value.

.DESCRIPTION
Replaces selected card record in nvaci.inf chaing its subsys value.

.PARAMETER Print
Print all PCI devices with its DeviceName, DEV and SUBSYS.

.PARAMETER CardName
Videocard official name regex from NVIDIA. Like 'RTX 3050 Laptop GPU'
You can get it from Description property of PCI device.

.PARAMETER Subsystem
Sequence next to SUBSYS_ in Device Instance ID property of PCI Device.

.PARAMETER Dev
Sequence next to DEV_ in Device Instance ID property of PCI Device.

.PARAMETER DriverFile
Path to executable driver file which files will be modified.

.PARAMETER DriverTmpPath
Path to temporary folder for nvidia driver files which contains nvaci.inf.

.LINK
https://github.com/goodm2ice/nvidia-subsystem-rewriter

#>
#Requires -RunAsAdministrator
[CmdletBinding(DefaultParameterSetName = 'Install')]
param (
    [Parameter(Mandatory, ParameterSetName = 'Print', Position = 0)]
    [switch]$Print,

    [Parameter(ParameterSetName = 'Install')]
    [string]$CardName = 'RTX 3050 Laptop GPU',
    [Parameter(ParameterSetName = 'Install')]
    [string]$Subsystem = '11331043',
    [Parameter(ParameterSetName = 'Install')]
    [string]$Dev = '25A2',
    [Parameter(ParameterSetName = 'Install')]
    [string]$DriverFile = './591.59-notebook-win10-win11-64bit-international-dch-whql.exe',
    [Parameter(ParameterSetName = 'Install')]
    [string]$DriverTmpPath = 'C:\NVIDIA_TMP',
    [Parameter(ParameterSetName = 'Install')]
    [string]$NvidiaVendorID = '10DE'
)

function Main {
    # if (!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    #     Start-Process PowerShell -Verb RunAs "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" $args"
    #     exit
    # }

    if ($Print) {
        PrintDevices > $null
        exit 0
    }

    $NvaciPath="$DriverTmpPath\Display.Driver\nvaci.inf" # Путь к перезаписываемому файлу
    $installer_pid = $null

    
    $done = $false # Флаг успешного завершения кода
    try { # Отслеживаем Ctrl+C и ошибки
        Write-Host "Starting driver file..."
        Write-Host "!!DON'T TOUCH DRIVER WINDOWS!!" -BackgroundColor Yellow -ForegroundColor Black
        $installer_pid = (Start-Process $DriverFile -ErrorAction SilentlyContinue -PassThru).Id # Запускаем драйвер

        Write-Host "Waiting for driver to start..."
        if (!(WaitProcess -ProcessPid $installer_pid)) { # Ждём запуска процесса
            Write-Host "Process start timeout!" -ForegroundColor Red
            exit 1
        }
        ReplacePath -ProcessID $installer_pid -TmpPath $DriverTmpPath # Имитируем ввод пути пользователем
        WaitFile -FilePath $NvaciPath -ProcessPid $installer_pid # Ждём появления файла
        EditNvaciFile -Path $NvaciPath -CardName $CardName -Dev $Dev -Subsystem $Subsystem # Заменяем данные в файле
        $done = $true # Отмечаем успешное завершение чтобы не закрывать установщик при выходе
        Write-Host "Work done! Continue setup as usual!" -BackgroundColor Green -ForegroundColor Black
    } finally {
        if (!$done) {
            Write-Host "Stopping driver process..."
            Stop-Process -Id $installer_pid -Force
        }
    }
}

function PrintDevices { # Вывод списка PCI устройств от Nvidia  
    $devices = Get-PnpDevice -PresentOnly | Where-Object {
        ($_.InstanceId -match "^PCI\\") -and # Только PCI
        ($_.InstanceId -match "VEN_$NvidiaVendorID") -and # Только Nvidia
        ($_.InstanceId -match "DEV_(\w+)") -and # Имеет запись DEV
        ($_.InstanceId -match "SUBSYS_(\w+)") # Имеет запись SUBSYS
    }

    # @(TrueValue, FalseValue)[!condition] -- Замена тернарному оператору

    Write-Host "Available devices:"
    $idx = 0
    foreach ($device in $devices) {
        Write-Host ("   [{0,2}] NAME: " -f $idx) -NoNewline
        Write-Host $device.Name -ForegroundColor Cyan
        Write-Host "        STATUS: " -NoNewline
        Write-Host $device.Status -ForegroundColor $(@("Green", "Red")[$device.Status -ne 'OK'])
        Write-Host "        CLASS: " -NoNewline
        Write-Host $device.PNPClass -ForegroundColor $(@("Green", "Red")[$device.PNPClass -ne 'Display'])

        $device.DeviceID -match "DEV_(\w+)" > $null
        Write-Host "        DEV: " -NoNewline
        Write-Host $Matches[1] -ForegroundColor Blue

        $device.DeviceID -match "SUBSYS_(\w+)" > $null
        Write-Host "        SUBSYSTEM: " -NoNewline
        Write-Host $Matches[1] -ForegroundColor Blue
        Write-Host ""
        $idx++
    }

    return $devices
}

function ReplacePath {
    param (
        [string]$ProcessID,
        [string]$TmpPath
    )

    $wshell = New-Object -ComObject WScript.Shell
    Start-Sleep -Milliseconds 500
    
    try {
        if (!$wshell.AppActivate($ProcessID)) { throw }
        Start-Sleep -Milliseconds 500
        $wshell.SendKeys("^a$TmpPath{ENTER}") > $null
        Start-Sleep -Milliseconds 400
        if (!$wshell.AppActivate("Security Warning")) { throw }
        Start-Sleep -Milliseconds 400
        $wshell.SendKeys("+{TAB}{LEFT}{ENTER}") > $null
    } catch {
        Write-Host "Can't focus installer window!" -ForegroundColor RED
        Write-Host "You need to " -ForegroundColor RED -NoNewline
        Write-Host "!!!WRITE EXTRACTION FOLDER BY YOURSELF!!!" -BackgroundColor RED
        Write-Host "as " -ForegroundColor RED -NoNewline
        Write-Host "'$TmpPath' " -ForegroundColor Blue -NoNewline
        Write-Host "and press OK and YES!" -ForegroundColor RED
    }
}

function WaitProcess {
    param (
        [string]$ProcessID
    )

    $StartTime = Get-Date
    while ($true) {
        if (Get-Process -Id $ProcessID -ErrorAction SilentlyContinue) {
            return $true
        }
        if (((Get-Date) - $StartTime).TotalSeconds -gt 15) {
            return $false
        }
        Start-Sleep -Milliseconds 200
    }
}

function WaitFile {
    param (
        [string]$ProcessPid,
        [string]$FilePath
    )
    
    Write-Host "Waiting for $FilePath to exists..."
    while ($true) {
        $ProcessCheck = Get-Process -Id $ProcessPid -ErrorAction SilentlyContinue
        if ($null -eq $ProcessCheck) {
            Write-Host "Installer closed!" -ForegroundColor Red
            exit 1
        }
        if (Test-Path -Path $FilePath) {
            break
        }
        Start-Sleep -Seconds 1
    }
}

function EditNvaciFile {
    param (
        [string]$Path,
        [string]$CardName,
        [string]$Dev,
        [string]$Subsystem
    )
    
    $record = Select-String -Path $Path -Pattern "(NVIDIA_DEV[^\s]+$Dev[^\s]+)\s+=.+$CardName" |
        ForEach-Object { $_.Matches.Groups[1].Value } |
        Select-Object -First 1
    
    
    if ($null -eq $record) {
        Write-Host "No fitting records!" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Editing file: " -NoNewline
    Write-Host "$Path" -ForegroundColor Blue
    
    Write-Host "Rewriting record: " -NoNewline
    Write-Host "$record" -ForegroundColor Cyan
    
    $old_lines = Select-String -Path $Path -Pattern $record | ForEach-Object { '---{0,10} :: {1}' -f $_.LineNumber, $_.Line }
    Write-Host
    
    $old_line = (Select-String -Path $Path -Pattern "%$record%" | Select-Object -First 1).Line
    $new_line = $old_line -replace 'SUBSYS_\w+', "SUBSYS_$Subsystem"

    $new_record = $record -replace "\w{4}\.\w{4}$", "$($Subsystem.Substring(0, 4)).$($Subsystem.Substring(4))"

    (Get-Content $Path).Replace($old_line, $new_line).Replace($record, $new_record) | Set-Content $Path
    Write-Host "File edited!" -ForegroundColor Yellow
    Write-Host
    
    Write-Host $old_lines -Separator "`n" -ForegroundColor Red
    Write-Host (Select-String -Path $Path -Pattern $new_record | ForEach-Object { '+++{0,10} :: {1}' -f $_.LineNumber, $_.Line }) -Separator "`n" -ForegroundColor Green
    Write-Host
}

Main
