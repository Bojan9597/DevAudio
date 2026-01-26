import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import '../widgets/mini_player.dart';

class PdfViewerScreen extends StatefulWidget {
  final String pdfPath;
  final String title;

  const PdfViewerScreen({
    Key? key,
    required this.pdfPath,
    required this.title,
  }) : super(key: key);

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  int _totalPages = 0;
  int _currentPage = 0;
  bool _isReady = false;
  String _errorMessage = '';
  PDFViewController? _pdfController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (_isReady && _totalPages > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '${_currentPage + 1} / $_totalPages',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildPdfViewer(),
          ),
          const MiniPlayer(),
        ],
      ),
    );
  }

  Widget _buildPdfViewer() {
    final file = File(widget.pdfPath);

    if (!file.existsSync()) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'PDF file not found',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Please download the book first',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading PDF',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        PDFView(
          filePath: widget.pdfPath,
          enableSwipe: true,
          swipeHorizontal: false,
          autoSpacing: true,
          pageFling: true,
          pageSnap: true,
          fitPolicy: FitPolicy.BOTH,
          preventLinkNavigation: false,
          onRender: (pages) {
            setState(() {
              _totalPages = pages ?? 0;
              _isReady = true;
            });
          },
          onError: (error) {
            setState(() {
              _errorMessage = error.toString();
            });
            print('PDF Error: $error');
          },
          onPageError: (page, error) {
            print('PDF Page $page Error: $error');
          },
          onViewCreated: (controller) {
            _pdfController = controller;
          },
          onPageChanged: (page, total) {
            setState(() {
              _currentPage = page ?? 0;
              _totalPages = total ?? 0;
            });
          },
        ),
        if (!_isReady && _errorMessage.isEmpty)
          const Center(
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }
}
