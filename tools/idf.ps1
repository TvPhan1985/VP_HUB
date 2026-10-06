# Kich hoat moi truong ESP-IDF roi chay idf.py trong thu muc du an IDF (-Dir, mac dinh firmware/examples/vph_demo)
# Vi du: powershell -ExecutionPolicy Bypass -File tools/idf.ps1 build
#        powershell -ExecutionPolicy Bypass -File tools/idf.ps1 -p COM5 flash
#        powershell -ExecutionPolicy Bypass -File tools/idf.ps1 -Dir firmware/test_app build
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

# Tach tham so -Dir (thu muc du an IDF), phan con lai chuyen cho idf.py
$projDir = Join-Path $root 'firmware/examples/vph_demo'
$rest = @()
for ($i = 0; $i -lt $args.Count; $i++) {
    if ($args[$i] -eq '-Dir') { $projDir = Join-Path $root $args[$i + 1]; $i++ }
    else { $rest += $args[$i] }
}

function Find-Idf {
    # 1. EIM: C:\Espressif\tools\eim_idf.json, truong activationScript
    $eim = 'C:\Espressif\tools\eim_idf.json'
    if (Test-Path $eim) {
        $j = Get-Content $eim -Raw | ConvertFrom-Json
        foreach ($inst in $j.idfInstalled) {
            if ($inst.path -match 'v5\.5' -and $inst.activationScript) {
                return @{ Kind = 'eim'; Script = $inst.activationScript }
            }
        }
    }
    # 2. Bo cai dat cu: <tools>\esp_idf.json
    foreach ($tp in 'C:\Espressif', 'D:\Espressif') {
        $f = Join-Path $tp 'esp_idf.json'
        if (Test-Path $f) {
            $j = Get-Content $f -Raw | ConvertFrom-Json
            foreach ($p in $j.idfInstalled.PSObject.Properties) {
                if ($p.Value.version -like '5.5*' -and (Test-Path $p.Value.path)) {
                    return @{ Kind = 'classic'; ToolsPath = $tp; IdfPath = $p.Value.path.TrimEnd('/', '\'); Git = $j.gitPath; Python = $p.Value.python }
                }
            }
        }
    }
    # 3. Bien moi truong IDF_PATH co san
    if ($env:IDF_PATH -and (Test-Path "$env:IDF_PATH\export.ps1")) {
        return @{ Kind = 'classic'; ToolsPath = $env:IDF_TOOLS_PATH; IdfPath = $env:IDF_PATH }
    }
    throw 'Khong tim thay ESP-IDF v5.5'
}

$idf = Find-Idf
# PS 5.1 coi stderr cua lenh ngoai la loi, nen khong dung 'Stop' tu day
$ErrorActionPreference = 'Continue'
if ($idf.Kind -eq 'eim') {
    . $idf.Script | Out-Null
} else {
    if ($idf.ToolsPath) { $env:IDF_TOOLS_PATH = $idf.ToolsPath }
    $env:IDF_PATH = $idf.IdfPath
    if ($idf.Git) { $env:PATH = "$(Split-Path -Parent $idf.Git);$env:PATH" }
    if ($idf.Python) { $env:PATH = "$(Split-Path -Parent $idf.Python);$env:PATH" }
    $env:PYTHONNOUSERSITE = 'True'
    $env:PYTHONPATH = $null
    $env:PYTHONHOME = $null
    . "$($idf.IdfPath)\export.ps1" *>&1 | Out-Null
}

if ($rest.Count -gt 0 -and $rest[0] -eq '--version') {
    idf.py --version
    exit $LASTEXITCODE
}

if (-not (Test-Path $projDir)) { New-Item -ItemType Directory -Force $projDir | Out-Null }
Set-Location $projDir
idf.py @rest
exit $LASTEXITCODE
