param([switch]$RequireNative)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$root = Split-Path -Parent $PSScriptRoot
function Invoke-Checked([string]$Program, [string[]]$Arguments) {
  Write-Host ('> ' + $Program + ' ' + ($Arguments -join ' '))
  & $Program @Arguments
  if ($LASTEXITCODE -ne 0) { throw "$Program failed with exit code $LASTEXITCODE" }
}
Push-Location -LiteralPath $root
try {
  Invoke-Checked 'moon' @('version', '--all')
  Invoke-Checked 'node' @('--version')
  Invoke-Checked 'ffprobe' @('-version')
  Invoke-Checked 'moon' @('fmt', '--check')
  foreach ($target in @('wasm-gc', 'wasm', 'js')) {
    Invoke-Checked 'moon' @('check', '--target', $target, '--deny-warn')
    Invoke-Checked 'moon' @('build', '--target', $target)
    Invoke-Checked 'moon' @('test', '--target', $target)
    Invoke-Checked 'moon' @('run', 'examples/inventory', '--target', $target)
  }
  Invoke-Checked 'moon' @('check', '--target', 'native', '--deny-warn')
  $nativeCompiler = @('cl','cc','gcc','clang') | Where-Object { Get-Command $_ -ErrorAction SilentlyContinue } | Select-Object -First 1
  if ($nativeCompiler) {
    Invoke-Checked 'moon' @('build', '--target', 'native')
    Invoke-Checked 'moon' @('test', '--target', 'native')
    Invoke-Checked 'moon' @('run', 'examples/inventory', '--target', 'native')
  } elseif ($RequireNative) {
    throw 'Native runtime validation required, but no C compiler is on PATH.'
  } else {
    Write-Warning 'SKIP native build/test/example: no C compiler. Native static check passed; runtime verification remains a CI requirement.'
  }
  Invoke-Checked 'moon' @('info')
  Invoke-Checked 'git' @('diff', '--exit-code', '--', '*.mbti')
  Invoke-Checked 'node' @('scripts/cli-smoke.cjs')
  Invoke-Checked 'node' @('scripts/crosscheck.cjs')
  Write-Host 'PASS available local gates. SKIP is not PASS; remote CI and publication are separate gates.'
} finally { Pop-Location }
