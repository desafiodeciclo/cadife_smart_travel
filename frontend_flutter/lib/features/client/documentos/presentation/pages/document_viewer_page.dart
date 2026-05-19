import 'dart:io';

import 'package:cadife_smart_travel/core/di/service_locator.dart';
import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/documentos/domain/entities/documento.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';

class DocumentViewerPage extends StatefulWidget {
  const DocumentViewerPage({required this.document, super.key});

  final Documento document;

  @override
  State<DocumentViewerPage> createState() => _DocumentViewerPageState();
}

class _DocumentViewerPageState extends State<DocumentViewerPage> {
  bool _isDownloading = false;
  late final Dio _dio;

  @override
  void initState() {
    super.initState();
    // AVISO DE ARQUITETURA E SEGURANÇA:
    // Nunca instancie o cliente HTTP diretamente via `Dio()`.
    // Utilize sempre o `sl<Dio>()` fornecido pelo Service Locator para garantir
    // que interceptadores cruciais (como de autenticação com token JWT, tratamento de
    // erros robusto, persistência offline e SSL Pinning) não sejam contornados.
    _dio = sl<Dio>();
  }

  Future<void> _shareDocument() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final extension = widget.document.type == DocumentType.pdf ? 'pdf' : 'jpg';
      final tempPath = '${tempDir.path}/${widget.document.id}.$extension';

      await _dio.download(widget.document.url, tempPath);
      
      // ignore: deprecated_member_use
      await Share.shareXFiles([XFile(tempPath)], text: widget.document.name);
    } on Exception catch (_) {
      await Fluttertoast.showToast(msg: 'Erro ao compartilhar documento');
    }
  }

  Future<void> _downloadDocument() async {
    setState(() => _isDownloading = true);
    try {
      Directory? directory;
      
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!directory.existsSync()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final extension = widget.document.type == DocumentType.pdf ? 'pdf' : 'jpg';
      final fileName = '${widget.document.name.replaceAll(' ', '_')}.$extension';
      final savePath = '${directory!.path}/$fileName';

      await _dio.download(widget.document.url, savePath);
      
      await Fluttertoast.showToast(msg: 'Documento salvo em: $savePath');
    } on Exception catch (_) {
      await Fluttertoast.showToast(msg: 'Erro ao baixar documento');
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CadifeAppBar(
        title: widget.document.name,
        showProfile: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.white),
            onPressed: _shareDocument,
            tooltip: 'Compartilhar',
          ),
          IconButton(
            icon: _isDownloading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
              : const Icon(Icons.download_outlined, color: AppColors.white),
            onPressed: _isDownloading ? null : _downloadDocument,
            tooltip: 'Baixar',
          ),
        ],
      ),
      body: Center(
        child: widget.document.type == DocumentType.pdf
            ? PdfViewer.uri(Uri.parse(widget.document.url))
            : PhotoView(
                imageProvider: NetworkImage(widget.document.url),
                backgroundDecoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                ),
                loadingBuilder: (context, event) => const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
      ),
    );
  }
}



