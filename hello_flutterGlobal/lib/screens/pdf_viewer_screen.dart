import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
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
  final PdfViewerController _pdfViewerController = PdfViewerController();
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  PdfTextSearchResult _searchResult = PdfTextSearchResult();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchBarVisible = false;
  int _totalPages = 0;
  int _currentPage = 1;
  bool _isReady = false;
  String _errorMessage = '';
  bool _isSliderVisible = false;

  @override
  void dispose() {
    _pdfViewerController.dispose();
    _searchController.dispose();
    _searchResult.dispose();
    super.dispose();
  }

  void _toggleSearchBar() {
    setState(() {
      _isSearchBarVisible = !_isSearchBarVisible;
      if (!_isSearchBarVisible) {
        _searchController.clear();
        _searchResult.clear();
      }
    });
  }

  void _performSearch(String query) async {
    if (query.isEmpty) return;
    _searchResult = await _pdfViewerController.searchText(query);
    _searchResult.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearchBarVisible
            ? _buildSearchField()
            : Text(widget.title),
        actions: [
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
                  '$_currentPage / $_totalPages',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_isSearchBarVisible && _searchResult.totalInstanceCount > 0)
            _buildSearchNavigationBar(),
          if (_isSearchBarVisible &&
              _searchResult.totalInstanceCount == 0 &&
              _searchController.text.isNotEmpty)
            _buildNoMatchesBar(),
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
                  _searchResult.clear();
                  setState(() {});
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
            loc?.matchCount(_searchResult.currentInstanceIndex,
                    _searchResult.totalInstanceCount) ??
                '${_searchResult.currentInstanceIndex} of ${_searchResult.totalInstanceCount}',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.keyboard_arrow_up,
                color: isDark ? Colors.white70 : Colors.black54),
            onPressed: _searchResult.hasResult
                ? () {
                    _searchResult.previousInstance();
                  }
                : null,
          ),
          IconButton(
            icon: Icon(Icons.keyboard_arrow_down,
                color: isDark ? Colors.white70 : Colors.black54),
            onPressed: _searchResult.hasResult
                ? () {
                    _searchResult.nextInstance();
                  }
                : null,
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

  Widget _buildPageSlider() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Text(
            '$_currentPage',
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
                min: 1,
                max: _totalPages.toDouble(),
                divisions: _totalPages > 1 ? _totalPages - 1 : 1,
                label: '$_currentPage',
                onChanged: (value) {
                  setState(() {
                    _currentPage = value.toInt();
                  });
                },
                onChangeEnd: (value) {
                  _pdfViewerController.jumpToPage(value.toInt());
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

    return SfPdfViewer.file(
      file,
      key: _pdfViewerKey,
      controller: _pdfViewerController,
      canShowScrollHead: true,
      canShowScrollStatus: true,
      canShowPaginationDialog: true,
      pageSpacing: 4,
      onDocumentLoaded: (PdfDocumentLoadedDetails details) {
        setState(() {
          _totalPages = details.document.pages.count;
          _isReady = true;
        });
      },
      onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
        setState(() {
          _errorMessage = details.description;
        });
      },
      onPageChanged: (PdfPageChangedDetails details) {
        setState(() {
          _currentPage = details.newPageNumber;
        });
      },
    );
  }
}
