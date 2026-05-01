import 'dart:io';

import 'package:cadife_smart_travel/shared/models/document_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';

class DocumentViewerScreen extends StatefulWidget {
  const DocumentViewerScreen({super.key, required this.document});

  final DocumentModel document;

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  bool _isDownloading = false;

  Future<void> _shareDocument() async {
    try {
      final dio = Dio();
      final tempDir = await getTemporaryDirectory();
      final extension = widget.document.type == DocumentType.pdf ? 'pdf' : 'jpg';
      final tempPath = '${tempDir.path}/${widget.document.id}.$extension';
      
      await dio.download(widget.document.url, tempPath);
      
      await SharePlus.instance.share(
        ShareParams(files: [XFile(tempPath)], text: widget.document.name),
      );
    } catch (e) {
      Fluttertoast.showToast(msg: 'Erro ao compartilhar documento');
    }
  }

  Future<void> _downloadDocument() async {
    setState(() => _isDownloading = true);
    try {
      final dio = Dio();
      Directory? directory;
      
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final extension = widget.document.type == DocumentType.pdf ? 'pdf' : 'jpg';
      final fileName = '${widget.document.name.replaceAll(' ', '_')}.$extension';
      final savePath = '${directory!.path}/$fileName';

      await dio.download(widget.document.url, savePath);
      
      Fluttertoast.showToast(msg: 'Documento salvo em: $savePath');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Erro ao baixar documento');
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.document.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: _shareDocument,
            tooltip: 'Compartilhar',
          ),
          IconButton(
            icon: _isDownloading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.download_outlined),
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
