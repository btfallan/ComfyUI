#Requires -Version 5.1
<#
.SYNOPSIS
    Update every ComfyUI custom node in a folder and (re)install its Python deps.

.DESCRIPTION
    For each sub-folder of -CustomNodesPath:
      * git checkout      -> git fetch + fast-forward pull (+ submodules)
      * NOT a git repo    -> with -AdoptNonGit, and if pyproject.toml lists a
                             Repository URL, git is initialised in place and the
                             latest code checked out. Untracked files (models,
                             configs) are kept; local edits to *tracked* files
                             are overwritten with the upstream version.
      * requirements.txt  -> pip install into -Python
      * install.py        -> executed with -Python

    Close ComfyUI before running (Windows locks .pyd/__pycache__ files).

.PARAMETER Force
    Discard local changes to tracked files (git reset --hard origin/<branch>)
    instead of a fast-forward-only pull.

.PARAMETER AdoptNonGit
    Convert hand-installed (non-git) node folders into real git checkouts so
    they can be updated now and in the future.

.PARAMETER UpgradeDeps
    Pass --upgrade to pip.

.PARAMETER IncludeTorch
    Do NOT strip torch / torchvision / xformers / triton / nvidia-* lines from
    requirements.txt. By default those lines are skipped so a node cannot
    silently replace your CUDA-enabled torch build.

.PARAMETER NoDeps
    Skip all dependency installation.

.PARAMETER Node
    One or more folder names to limit the run to.

.EXAMPLE
    .\update_custom_nodes.ps1
.EXAMPLE
    .\update_custom_nodes.ps1 -AdoptNonGit -Force
.EXAMPLE
    .\update_custom_nodes.ps1 -Node rgthree-comfy,comfyui-kjnodes -UpgradeDeps
#>

[CmdletBinding()]
param(
    [string]   $CustomNodesPath = 'C:\temp\ComfyUI\ComfyUI_Custom\custom_nodes',
    [string]   $Python          = 'C:\Users\btfal\miniconda3\envs\comfyenv\python.exe',
    [string[]] $Node,
    [switch]   $Force,
    [switch]   $AdoptNonGit,
    [switch]   $UpgradeDeps,
    [switch]   $IncludeTorch,
    [switch]   $NoDeps
)

$ErrorActionPreference = 'Continue'
function Die($m) { Write-Host $m -ForegroundColor Red; exit 1 }

if (-not (Test-Path -LiteralPath $Python))          { Die "Python not found: $Python" }
if (-not (Test-Path -LiteralPath $CustomNodesPath)) { Die "custom_nodes not found: $CustomNodesPath" }
$gitExe = (Get-Command git -ErrorAction SilentlyContinue).Source
if (-not $gitExe) { Die "git was not found on PATH." }

$stamp   = Get-Date -Format 'yyyyMMdd_HHmmss'
$logFile = Join-Path $CustomNodesPath "_update_$stamp.log"
try { Start-Transcript -Path $logFile -Force | Out-Null } catch { }

# requirements.txt lines that must never be auto-(re)installed unless -IncludeTorch.
# Includes opencv: mixing opencv-python / -headless / -contrib overwrites cv2 and
# breaks nodes that need cv2.ximgproc (e.g. ComfyUI_LayerStyle guidedFilter).
$torchRx = '^\s*(torch|torchvision|torchaudio|torchsde|xformers|triton|flash[-_]attn|nvidia-|cuda-python|onnxruntime|onnxruntime-gpu|opencv-python|opencv-python-headless|opencv-contrib-python|opencv-contrib-python-headless)\b'

$dirs = Get-ChildItem -LiteralPath $CustomNodesPath -Directory |
        Where-Object { $_.Name -notmatch '^[._]' -and $_.Name -notlike '*.disabled' }
if ($Node) { $dirs = $dirs | Where-Object { $Node -contains $_.Name } }

$rows = New-Object System.Collections.Generic.List[object]

function Get-RepoUrl($folder) {
    $pp = Join-Path $folder 'pyproject.toml'
    if (Test-Path -LiteralPath $pp) {
        $m = [regex]::Match((Get-Content -LiteralPath $pp -Raw),
                            '(?im)^\s*Repository\s*=\s*"([^"]+)"')
        if ($m.Success) { return $m.Groups[1].Value.TrimEnd('/') }
    }
    return $null
}

function Get-DefaultBranch {
    $out = (& $gitExe ls-remote --symref origin HEAD 2>$null) -join "`n"
    $m = [regex]::Match($out, 'refs/heads/(\S+)\s+HEAD')
    if ($m.Success) { return $m.Groups[1].Value }
    return 'main'
}

foreach ($d in $dirs) {
    $name = $d.Name
    $path = $d.FullName
    Write-Host "`n=== $name ===" -ForegroundColor Cyan
    $upd = 'skipped'; $info = ''
    Push-Location $path
    try {
        $isGit = Test-Path -LiteralPath (Join-Path $path '.git')

        # ---- adopt a non-git folder -------------------------------------------
        if (-not $isGit -and $AdoptNonGit) {
            $url = Get-RepoUrl $path
            if (-not $url) {
                $upd = 'no-git'; $info = 'no Repository URL in pyproject.toml'
            }
            else {
                & $gitExe init -q
                & $gitExe remote add origin $url 2>$null
                & $gitExe fetch origin -q --depth=1
                if ($LASTEXITCODE -ne 0) {
                    $upd = 'adopt-failed'; $info = "git fetch failed: $url"
                }
                else {
                    $br = Get-DefaultBranch
                    & $gitExe checkout -f -B $br "origin/$br" -q
                    if ($LASTEXITCODE -eq 0) {
                        $isGit = $true; $upd = 'adopted'; $info = "$url ($br)"
                    } else {
                        $upd = 'adopt-failed'; $info = "checkout origin/$br failed"
                    }
                }
            }
        }
        elseif (-not $isGit) {
            $upd = 'no-git'; $info = 're-run with -AdoptNonGit to convert'
        }

        # ---- normal update of a git repo ------------------------------------
        if ($isGit -and $upd -ne 'adopted') {
            $before = (& $gitExe rev-parse --short HEAD 2>$null)
            $branch = (& $gitExe rev-parse --abbrev-ref HEAD 2>$null)
            & $gitExe fetch --all --prune --tags -q

            if ($branch -eq 'HEAD' -and -not $Force) {
                $upd = 'detached'; $info = 'detached HEAD - re-run with -Force'
            }
            else {
                if ($Force) {
                    $tgt = if ($branch -eq 'HEAD') { 'origin/HEAD' } else { "origin/$branch" }
                    & $gitExe reset --hard $tgt -q
                }
                else {
                    & $gitExe pull --ff-only -q
                }
                if ($LASTEXITCODE -ne 0) {
                    $upd = 'pull-failed'; $info = 'diverged / locked file - re-run with -Force'
                }
                else {
                    & $gitExe submodule update --init --recursive -q
                    $after = (& $gitExe rev-parse --short HEAD 2>$null)
                    if ($before -eq $after) { $upd = 'up-to-date'; $info = $after }
                    else                    { $upd = 'updated';    $info = "$before -> $after" }
                }
            }
        }
    }
    catch { $upd = 'error'; $info = $_.Exception.Message }
    finally { Pop-Location }

    # ---- dependencies -------------------------------------------------------
    $deps = ''
    if (-not $NoDeps -and $upd -notin @('error','pull-failed','adopt-failed','detached')) {
        $req = Join-Path $path 'requirements.txt'
        if (Test-Path -LiteralPath $req) {
            $useReq = $req
            if (-not $IncludeTorch) {
                $all  = @(Get-Content -LiteralPath $req)
                $keep = @($all | Where-Object { $_ -notmatch $torchRx })
                if ($keep.Count -ne $all.Count) {
                    $useReq = Join-Path $env:TEMP "req_${name}_$stamp.txt"
                    [System.IO.File]::WriteAllLines($useReq, [string[]]$keep)
                    $deps = 'deps (torch/cuda lines skipped)'
                } else { $deps = 'deps' }
            } else { $deps = 'deps' }

            $pipArgs = @('-m','pip','install','--no-input','--disable-pip-version-check','-r',$useReq)
            if ($UpgradeDeps) { $pipArgs += '--upgrade' }
            & $Python @pipArgs
            if ($LASTEXITCODE -ne 0) { $deps = 'pip FAILED' }
        }
        $ins = Join-Path $path 'install.py'
        if (Test-Path -LiteralPath $ins) {
            Push-Location $path; & $Python $ins; Pop-Location
            if ($deps) { $deps = "$deps + install.py" } else { $deps = 'install.py' }
        }
    }

    $rows.Add([pscustomobject]@{ Node = $name; Update = $upd; Deps = $deps; Info = $info })
}

Write-Host "`n==================== SUMMARY ====================" -ForegroundColor Yellow
($rows | Sort-Object Update, Node | Format-Table -AutoSize | Out-String -Width 200).TrimEnd() | Write-Host

$bad = $rows | Where-Object {
    $_.Update -in @('error','pull-failed','adopt-failed','detached','no-git') -or $_.Deps -eq 'pip FAILED'
}
if ($bad) {
    Write-Host "`nNeeds attention:" -ForegroundColor Red
    $bad | ForEach-Object { Write-Host ("  {0,-42} {1,-14} {2}" -f $_.Node, $_.Update, $_.Info) -ForegroundColor Red }
}

$u = ($rows | Where-Object { $_.Update -in @('updated','adopted') }).Count
Write-Host ("`n{0} folders scanned | {1} updated/adopted | {2} need attention" -f $rows.Count, $u, @($bad).Count)
try { Stop-Transcript | Out-Null } catch { }
Write-Host "Log: $logFile"
