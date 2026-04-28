# deploy.ps1
# Coloque na raiz do projeto Flutter (ex: E:\Projetos\van_pro_novo\deploy.ps1)
# Uso: .\deploy.ps1
# Uso com mensagem custom: .\deploy.ps1 -msg "ajuste no formulario de aluno"

param(
    [string]$msg = "deploy $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
)

# ── CONFIGURACOES — edite apenas aqui ────────────────────────
$servidor    = "balcao2p@balcao2ponto0.com.br"
$destino     = "/home/balcao2p/novo.balcao2ponto0.com.br/"
$buildPath   = "build\web\*"
# ─────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "=== VanPro Deploy ===" -ForegroundColor Cyan
Write-Host "Mensagem: $msg" -ForegroundColor Gray

# 1. Build
Write-Host ""
Write-Host "[1/4] Flutter build web..." -ForegroundColor Yellow
flutter build web --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "BUILD FALHOU. Abortando." -ForegroundColor Red
    exit 1
}

# 2. Git
Write-Host ""
Write-Host "[2/4] Git commit..." -ForegroundColor Yellow
git add -A
git commit -m $msg
git push
if ($LASTEXITCODE -ne 0) {
    Write-Host "Git push falhou (pode ser que nao haja mudancas). Continuando..." -ForegroundColor DarkYellow
}

# 3. Upload para o servidor via SCP
Write-Host ""
Write-Host "[3/4] Enviando arquivos para o servidor..." -ForegroundColor Yellow
scp -r $buildPath "${servidor}:${destino}"
if ($LASTEXITCODE -ne 0) {
    Write-Host "SCP falhou. Verifique as credenciais SSH." -ForegroundColor Red
    exit 1
}

# 4. Pronto
Write-Host ""
Write-Host "[4/4] Deploy concluido!" -ForegroundColor Green
Write-Host "Site: https://novo.balcao2ponto0.com.br" -ForegroundColor Cyan
Write-Host ""