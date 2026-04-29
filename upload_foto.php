<?php
// upload_foto.php
// Requer: GD (imagens) + Ghostscript (PDF → imagem)
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Headers: X-Api-Key, Content-Type');

define('API_KEY',  'VanPro@2026#Secure');
define('BASE_DIR', __DIR__ . '/uploads/');
define('BASE_URL', 'https://novo.balcao2ponto0.com.br/uploads/');
define('GS_BIN',   '/usr/bin/gs');

// Configurações por tipo
const PERFIS    = ['alunos', 'motoristas/perfil'];
const DOCS      = ['motoristas/cnh', 'motoristas/crlv', 'motoristas/vistoria'];
const TIPOS_VALIDOS = ['alunos', 'motoristas/perfil', 'motoristas/cnh', 'motoristas/crlv', 'motoristas/vistoria'];

// Avatares: quadrado 200×200, qualidade 80
const AVATAR_SIZE    = 200;
const AVATAR_QUALITY = 80;

// Documentos: largura máx 1200px, qualidade 85
const DOC_MAX_WIDTH  = 1200;
const DOC_QUALITY    = 85;

// ── CORS preflight ────────────────────────────────────────────
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204); exit;
}

// ── Auth ──────────────────────────────────────────────────────
$apiKey = $_SERVER['HTTP_X_API_KEY'] ?? '';
if ($apiKey !== API_KEY) {
    http_response_code(401);
    echo json_encode(['erro' => 'Unauthorized']); exit;
}

// ── Método ────────────────────────────────────────────────────
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['erro' => 'Método não permitido']); exit;
}

// ── Tipo ──────────────────────────────────────────────────────
$tipo = $_POST['tipo'] ?? '';
if (!in_array($tipo, TIPOS_VALIDOS)) {
    http_response_code(400);
    echo json_encode(['erro' => 'Tipo inválido: ' . $tipo]); exit;
}

// ── Arquivo ───────────────────────────────────────────────────
if (empty($_FILES['foto']) || $_FILES['foto']['error'] !== UPLOAD_ERR_OK) {
    $cod = $_FILES['foto']['error'] ?? 'ausente';
    http_response_code(400);
    echo json_encode(['erro' => 'Arquivo inválido', 'codigo' => $cod]); exit;
}

$tmpPath = $_FILES['foto']['tmp_name'];

// ── Detecta MIME real ─────────────────────────────────────────
$finfo = finfo_open(FILEINFO_MIME_TYPE);
$mime  = finfo_file($finfo, $tmpPath);
finfo_close($finfo);

$mimePermitidos = ['image/jpeg','image/png','image/webp','application/pdf'];
if (!in_array($mime, $mimePermitidos)) {
    http_response_code(415);
    echo json_encode(['erro' => 'Formato não suportado: ' . $mime]); exit;
}

// PDF só é aceito em tipos de documento
if ($mime === 'application/pdf' && in_array($tipo, PERFIS)) {
    http_response_code(400);
    echo json_encode(['erro' => 'PDF não é aceito para avatares']); exit;
}

// ── Nome do arquivo de saída ──────────────────────────────────
$uid      = preg_replace('/[^a-zA-Z0-9_\-]/', '', $_POST['uid'] ?? uniqid('', true));
$filename = $uid . '_' . time() . '.webp';
$destDir  = BASE_DIR . $tipo . '/';
$destPath = $destDir . $filename;

// ── Converte PDF → JPG temporário via Ghostscript ─────────────
if ($mime === 'application/pdf') {
    $tmpJpg = tempnam(sys_get_temp_dir(), 'vanpro_pdf_') . '.jpg';
    $cmd = sprintf(
        '%s -dNOPAUSE -dBATCH -dSAFER -sDEVICE=jpeg -r150 -dFirstPage=1 -dLastPage=1 -sOutputFile=%s %s 2>/dev/null',
        GS_BIN,
        escapeshellarg($tmpJpg),
        escapeshellarg($tmpPath)
    );
    exec($cmd, $out, $ret);
    if ($ret !== 0 || !file_exists($tmpJpg)) {
        http_response_code(500);
        echo json_encode(['erro' => 'Falha ao converter PDF']); exit;
    }
    $tmpPath = $tmpJpg;
    $mime    = 'image/jpeg';
}

// ── Carrega imagem com GD ─────────────────────────────────────
$src = match($mime) {
    'image/png'  => imagecreatefrompng($tmpPath),
    'image/webp' => imagecreatefromwebp($tmpPath),
    default      => imagecreatefromjpeg($tmpPath),
};

if (!$src) {
    http_response_code(500);
    echo json_encode(['erro' => 'Falha ao ler imagem']); exit;
}

$srcW = imagesx($src);
$srcH = imagesy($src);

// ── Processa conforme tipo ────────────────────────────────────
if (in_array($tipo, PERFIS)) {
    // AVATAR: crop centralizado → quadrado 200×200
    $lado   = min($srcW, $srcH);
    $srcX   = (int)(($srcW - $lado) / 2);
    $srcY   = (int)(($srcH - $lado) / 2);
    $dst    = imagecreatetruecolor(AVATAR_SIZE, AVATAR_SIZE);
    imagecopyresampled($dst, $src, 0, 0, $srcX, $srcY, AVATAR_SIZE, AVATAR_SIZE, $lado, $lado);
    $quality = AVATAR_QUALITY;
} else {
    // DOCUMENTO: redimensiona mantendo proporção, máx 1200px largura
    if ($srcW > DOC_MAX_WIDTH) {
        $newW = DOC_MAX_WIDTH;
        $newH = (int)($srcH * DOC_MAX_WIDTH / $srcW);
    } else {
        $newW = $srcW;
        $newH = $srcH;
    }
    $dst     = imagecreatetruecolor($newW, $newH);
    imagecopyresampled($dst, $src, 0, 0, 0, 0, $newW, $newH, $srcW, $srcH);
    $quality = DOC_QUALITY;
}

// ── Salva como WebP ───────────────────────────────────────────
if (!imagewebp($dst, $destPath, $quality)) {
    http_response_code(500);
    echo json_encode(['erro' => 'Falha ao salvar WebP']); exit;
}

imagedestroy($src);
imagedestroy($dst);

// Limpa JPG temporário do PDF se existir
if (isset($tmpJpg) && file_exists($tmpJpg)) {
    unlink($tmpJpg);
}

// ── Retorna URL pública ───────────────────────────────────────
$url = BASE_URL . $tipo . '/' . $filename;
http_response_code(200);
echo json_encode(['url' => $url]);
