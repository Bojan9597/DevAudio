import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:read_pdf_text/read_pdf_text.dart';
import '../widgets/mini_player.dart';
import '../l10n/generated/app_localizations.dart';

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
  PDFViewController? _pdfController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchBarVisible = false;
  bool _isSliderVisible = false;
  int _totalPages = 0;
  int _currentPage = 0;
  bool _isReady = false;
  String _errorMessage = '';
  bool _nightMode = false;

  // Search state
  List<String> _pageTexts = [];
  List<int> _matchingPages = [];
  int _currentMatchIndex = -1;
  bool _isSearching = false;
  bool _textExtracted = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearchBar() {
    setState(() {
      _isSearchBarVisible = !_isSearchBarVisible;
      if (!_isSearchBarVisible) {
        _searchController.clear();
        _matchingPages = [];
        _currentMatchIndex = -1;
      }
    });
  }

  Future<void> _extractText() async {
    if (_textExtracted) return;
    try {
      final texts = await ReadPdfText.getPDFtextPaginated(widget.pdfPath);
      _pageTexts = texts;
      _textExtracted = true;
    } on PlatformException {
      _pageTexts = [];
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _matchingPages = [];
        _currentMatchIndex = -1;
      });
      return;
    }

    setState(() => _isSearching = true);

    await _extractText();

    final queryLower = query.toLowerCase();
    final matches = <int>[];
    for (int i = 0; i < _pageTexts.length; i++) {
      if (_pageTexts[i].toLowerCase().contains(queryLower)) {
        matches.add(i);
      }
    }

    setState(() {
      _matchingPages = matches;
      _currentMatchIndex = matches.isNotEmpty ? 0 : -1;
      _isSearching = false;
    });

    if (_matchingPages.isNotEmpty) {
      _pdfController?.setPage(_matchingPages[0]);
    }
  }

  void _goToNextMatch() {
    if (_matchingPages.isEmpty) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex + 1) % _matchingPages.length;
    });
    _pdfController?.setPage(_matchingPages[_currentMatchIndex]);
  }

  void _goToPreviousMatch() {
    if (_matchingPages.isEmpty) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex - 1 + _matchingPages.length) %
          _matchingPages.length;
    });
    _pdfController?.setPage(_matchingPages[_currentMatchIndex]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearchBarVisible ? _buildSearchField() : Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(_nightMode ? Icons.wb_sunny : Icons.bedtime),
            onPressed: () {
              setState(() {
                _nightMode = !_nightMode;
              });
            },
            tooltip: _nightMode ? 'Day mode' : 'Night mode',
          ),
          IconButton(
            icon: Icon(_isSearchBarVisible ? Icons.close : Icons.search),
            onPressed: _toggleSearchBar,
            tooltip: 'Search',
          ),
          if (_isReady && _totalPages > 0)
            IconButton(
              icon: const Icon(Icons.linear_scale),
              onPressed: () {
                setState(() {
                  _isSliderVisible = !_isSliderVisible;
                });
              },
              tooltip: 'Page slider',
            ),
          if (_isReady && _totalPages > 0 && !_isSearchBarVisible)
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
          if (_isSearchBarVisible && _matchingPages.isNotEmpty)
            _buildSearchNavigationBar(),
          if (_isSearchBarVisible &&
              _matchingPages.isEmpty &&
              _searchController.text.isNotEmpty &&
              !_isSearching)
            _buildNoMatchesBar(),
          if (_isSearching) _buildSearchingBar(),
          Expanded(
            child: _buildPdfViewer(),
          ),
          if (_isSliderVisible && _isReady && _totalPages > 1)
            _buildPageSlider(),
          const MiniPlayer(),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    final loc = AppLocalizations.of(context);
    return TextField(
      controller: _searchController,
      autofocus: true,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: loc?.searchInPdf ?? 'Search in PDF...',
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
        border: InputBorder.none,
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.white70),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _matchingPages = [];
                    _currentMatchIndex = -1;
                  });
                },
              )
            : null,
      ),
      onSubmitted: (value) {
        _performSearch(value);
      },
      onChanged: (value) {
        setState(() {});
      },
    );
  }

  Widget _buildSearchNavigationBar() {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 48,
      color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[200],
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            loc?.matchCount(
                    _currentMatchIndex + 1, _matchingPages.length) ??
                '${_currentMatchIndex + 1} of ${_matchingPages.length} pages',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.keyboard_arrow_up,
                color: isDark ? Colors.white70 : Colors.black54),
            onPressed: _goToPreviousMatch,
          ),
          IconButton(
            icon: Icon(Icons.keyboard_arrow_down,
                color: isDark ? Colors.white70 : Colors.black54),
            onPressed: _goToNextMatch,
          ),
        ],
      ),
    );
  }

  Widget _buildNoMatchesBar() {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 48,
      color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[200],
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Text(
        loc?.noMatchesFound ?? 'No matches found',
        style: TextStyle(
          color: isDark ? Colors.white70 : Colors.black87,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildSearchingBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 48,
      color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[200],
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(
            'Searching...',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageSlider() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Text(
            '${_currentPage + 1}',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.amber[700],
                inactiveTrackColor: isDark
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.grey[400],
                thumbColor: Colors.amber[700],
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape:
                    const RoundSliderOverlayShape(overlayRadius: 16),
                trackHeight: 4,
              ),
              child: Slider(
                value: _currentPage.toDouble(),
                min: 0,
                max: (_totalPages - 1).toDouble(),
                divisions: _totalPages > 1 ? _totalPages - 1 : 1,
                label: '${_currentPage + 1}',
                onChanged: (value) {
                  setState(() {
                    _currentPage = value.toInt();
                  });
                },
                onChangeEnd: (value) {
                  _pdfController?.setPage(value.toInt());
                },
              ),
            ),
          ),
          Text(
            '$_totalPages',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
              fontSize: 14,
            ),
          ),
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
            const Text(
              'Error loading PDF',
              style: TextStyle(fontSize: 18),
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

    return PDFView(
      key: ValueKey('pdf_night_$_nightMode'),
      filePath: widget.pdfPath,
      defaultPage: _currentPage,
      enableSwipe: true,
      swipeHorizontal: false,
      autoSpacing: true,
      pageFling: true,
      pageSnap: true,
      fitPolicy: FitPolicy.BOTH,
      nightMode: _nightMode,
      onRender: (pages) {
        setState(() {
          _totalPages = pages ?? 0;
          _isReady = true;
        });
      },
      onViewCreated: (PDFViewController controller) {
        _pdfController = controller;
      },
      onPageChanged: (int? page, int? total) {
        setState(() {
          _currentPage = page ?? 0;
          if (total != null) _totalPages = total;
        });
      },
      onError: (error) {
        setState(() {
          _errorMessage = error.toString();
        });
      },
      onPageError: (page, error) {
        setState(() {
          _errorMessage = 'Error on page $page: ${error.toString()}';
        });
      },
    );
  }
}
