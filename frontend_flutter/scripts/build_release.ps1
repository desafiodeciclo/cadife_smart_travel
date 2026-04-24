# Build Release Script for Cadife Smart Travel (Windows)
# Usage: .\scripts\build_release.ps1 [apk|appbundle|ios]

param(
    [string]$Target = "apk"
)

$SymbolsDir = "symbols"

New-Item -ItemType Directory -Force -Path $SymbolsDir | Out-Null

Write-Host "🔒 Building release with obfuscation..."
Write-Host "Target: $Target"
Write-Host "Symbols: $SymbolsDir"

flutter build $Target `
  --release `
  --obfuscate `
  --split-debug-info="$SymbolsDir" `
  --dart-define=dart.vm.product=true

Write-Host "✅ Build completed."
Write-Host "📦 Output: build\app\outputs\$Target\release\"
Write-Host "🔑 Debug symbols saved to: $SymbolsDir\"
Write-Host ""
Write-Host "IMPORTANT: Store debug symbols securely for future crash symbolication."
