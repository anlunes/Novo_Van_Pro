import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// Constantes de estilo para centralização e manutenção
class _AppCardStyles {
  static const double borderRadius = 12.0;
  static const double iconSize = 32.0;
  static const Color iconColorSuccess = Colors.green;
  static const Color iconColorDefault = Colors.grey;
  static const Color actionColor = Colors.amber;
}

class PerfilDocumentoCard extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final String? url;
  final IconData icone;
  final VoidCallback onUpload;
  final Color? corFundo;

  const PerfilDocumentoCard({
    super.key,
    required this.titulo,
    required this.subtitulo,
    this.url,
    required this.icone,
    required this.onUpload,
    this.corFundo,
  });

  @override
  Widget build(BuildContext context) {
    final bool temDocumento = url != null && url!.isNotEmpty;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_AppCardStyles.borderRadius)),
      margin: const EdgeInsets.only(bottom: 12),
      color: corFundo ?? (temDocumento ? Colors.green.shade50 : Colors.grey.shade50),
      child: ListTile(
        // UX: Mantido o onTap apenas para visualização, evitando conflito com o botão de upload
        onTap: temDocumento ? () => _abrirDocumento(context, url!) : null,
        leading: Icon(
          temDocumento ? Icons.check_circle : Icons.upload_file,
          color: temDocumento ? _AppCardStyles.iconColorSuccess : _AppCardStyles.iconColorDefault,
          size: _AppCardStyles.iconSize,
        ),
        title: Text(
          titulo,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(
          temDocumento ? 'Toque para visualizar' : subtitulo,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontStyle: temDocumento ? FontStyle.italic : FontStyle.normal,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.camera_alt, color: _AppCardStyles.actionColor),
          onPressed: onUpload,
          tooltip: 'Capturar/Fazer upload',
        ),
      ),
    );
  }

  Future<void> _abrirDocumento(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Não foi possível abrir o link: $url';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao abrir documento: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      debugPrint("Erro ao abrir documento: $e");
    }
  }
}