$ErrorActionPreference = 'Stop'

Write-Host "Initializing any missing submodules..." -ForegroundColor Cyan
git submodule update --init --recursive

Write-Host "`nPulling latest commits for every submodule (fast-forward only)..." -ForegroundColor Cyan
git submodule foreach --recursive 'git fetch --quiet; git pull --ff-only --quiet || echo SKIPPED-dirty-or-diverged-check-manually; true'

Write-Host "`nSubmodules with new commit pointers to review/commit:" -ForegroundColor Yellow
git status --porcelain -- ':(glob)**/*' | Select-String '^ M'

Write-Host "`nDone. Run 'git add <path>' + 'git commit' to record the updated pointers, or 'git diff --submodule' to review what changed first." -ForegroundColor Cyan
