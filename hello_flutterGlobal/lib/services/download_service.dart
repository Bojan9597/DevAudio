import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import 'connectivity_service.dart';

class DownloadService {
  final Dio _dio = Dio();

  // Track ongoing downloads to prevent duplicate requests
  static final Map<String, Future<void>> _activeDownloads = {};

  Future<String> _getLocalPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  /// Get user-specific directory for downloads
  Future<String> _getUserPath(int? userId) async {
    final basePath = await _getLocalPath();
    if (userId != null) {
      final userDir = Directory('$basePath/user_$userId');
      if (!await userDir.exists()) {
        await userDir.create(recursive: true);
      }
      return userDir.path;
    }
    return basePath;
  }

  /// Get local path for a book/track
  /// Structure: .../user_{userId}/book_{bookId}/{fileKey}.mp3
  Future<String> getLocalBookPath(
    String fileKey, {
    int? userId,
    String? bookId,
  }) async {
    final userPath = await _getUserPath(userId);

    if (bookId != null && userId != null) {
      final bookDir = Directory('$userPath/book_$bookId');
      if (!await bookDir.exists()) {
        await bookDir.create(recursive: true);
      }
      return '${bookDir.path}/$fileKey.mp3';
    }

    // Fallback or legacy path (if no bookId provided or no userId)
    // We strictly prefer the new structure, but for backward compat or transition:
    return '$userPath/$fileKey.mp3';
  }

  Future<bool> isBookDownloaded(
    String fileKey, {
    int? userId,
    String? bookId,
  }) async {
    // Check user-specific path first
    final filePath = await getLocalBookPath(
      fileKey,
      userId: userId,
      bookId: bookId,
    );
    final file = File(filePath);
    if (await file.exists()) {
      // Verify file is not empty/corrupted
      final size = await file.length();
      if (size > 0) {
        return true;
      }
    }

    // Fallback: check legacy location (before user-specific storage)
    if (userId != null) {
      final legacyPath = await getLocalBookPath(fileKey, userId: null);
      final legacyFile = File(legacyPath);
      if (await legacyFile.exists()) {
        final size = await legacyFile.length();
        if (size > 0) {
          // Move file to user-specific location
          print(
            '[DownloadService] Migrating legacy file to user-specific storage: $fileKey',
          );
          try {
            final userDir = Directory(await _getUserPath(userId));
            if (!await userDir.exists()) {
              await userDir.create(recursive: true);
            }
            await legacyFile.copy(filePath);
            await legacyFile.delete();
            return true;
          } catch (e) {
            print('[DownloadService] Migration failed, using legacy file: $e');
            return true; // Still available from legacy location
          }
        }
      }
    }

    // Clean up old .enc files (legacy format) - they need to be re-downloaded
    final basePath = await _getUserPath(userId);
    final oldEncPath = '$basePath/$fileKey.enc';
    final oldEncFile = File(oldEncPath);
    if (await oldEncFile.exists()) {
      print(
        '[DownloadService] Found legacy .enc file, will be re-downloaded: $oldEncPath',
      );
      await oldEncFile.delete();
    }

    return false;
  }

  /// Check if a download is currently in progress for this file
  bool isDownloadInProgress(String fileKey) {
    return _activeDownloads.containsKey(fileKey);
  }

  /// Download book/track to permanent storage
  /// If userId and bookId are provided, stores in structured folder.
  Future<void> downloadBook(
    String fileKey,
    String url, {
    int? userId,
    String? bookId,
  }) async {
    // Use user-specific key for active downloads tracking
    final downloadKey = userId != null ? '${userId}_$fileKey' : fileKey;

    // If download already in progress, wait for it
    if (_activeDownloads.containsKey(downloadKey)) {
      print(
        '[DownloadService] Download already in progress for $downloadKey, waiting...',
      );
      await _activeDownloads[downloadKey];
      return;
    }

    // Start new download
    final downloadFuture = _performDownload(
      fileKey,
      url,
      userId: userId,
      bookId: bookId,
    );
    _activeDownloads[downloadKey] = downloadFuture;

    try {
      await downloadFuture;
    } finally {
      _activeDownloads.remove(downloadKey);
    }
  }

  Future<bool> isPlaylistFullyDownloaded(
    List<Map<String, dynamic>> playlist, {
    int? userId,
    String? bookId,
  }) async {
    for (final track in playlist) {
      final trackId = track['id'].toString();
      final uniqueId = 'track_$trackId';
      final isDownloaded = await isBookDownloaded(
        uniqueId,
        userId: userId,
        bookId: bookId,
      );
      if (!isDownloaded) return false;
    }
    return true;
  }

  /// Download multiple tracks for a playlist
  Future<void> downloadPlaylist(
    List<Map<String, dynamic>> playlist,
    String bookId, {
    int? userId,
  }) async {
    print('[DownloadService] Starting playlist download for book $bookId');

    final futures = <Future<void>>[];

    for (final track in playlist) {
      final trackId = track['id'].toString();
      final uniqueId = 'track_$trackId'; // Must match _getUniqueAudioId logic

      // OPTIMIZATION: Check if already downloaded
      final isDownloaded = await isBookDownloaded(
        uniqueId,
        userId: userId,
        bookId: bookId,
      );

      if (isDownloaded) {
        print('[DownloadService] Skipping existing track: $uniqueId');
        continue;
      }

      final url = track['file_path'];

      // Handle URL absolute/relative
      String absoluteUrl = url;
      if (!url.startsWith('http')) {
        final baseUrl = AuthService().baseUrl;
        absoluteUrl = '$baseUrl$url';
      }

      futures.add(
        downloadBook(uniqueId, absoluteUrl, userId: userId, bookId: bookId),
      );
    }

    if (futures.isEmpty) {
      print('[DownloadService] All tracks already downloaded.');
      return;
    }

    await Future.wait(futures);
    print('[DownloadService] Playlist download completed');
  }

  Future<void> _performDownload(
    String fileKey,
    String url, {
    int? userId,
    String? bookId,
  }) async {
    try {
      final filePath = await getLocalBookPath(
        fileKey,
        userId: userId,
        bookId: bookId,
      );

      print('[DownloadService] Downloading from: $url');

      // Download to a temporary file first
      final tempPath = '$filePath.tmp';
      print('[DownloadService] Downloading to temp: $tempPath');

      // Download directly (no encryption)
      await _dio.download(
        url,
        tempPath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final progress = (received / total * 100).toStringAsFixed(1);
            print('[DownloadService] Download progress: $progress%');
          }
        },
      );

      // Verify download
      final tempFile = File(tempPath);
      if (!await tempFile.exists()) {
        throw Exception('Download failed - temp file not created');
      }

      final fileSize = await tempFile.length();
      print('[DownloadService] Downloaded size: $fileSize bytes');

      if (fileSize == 0) {
        await tempFile.delete();
        throw Exception('Downloaded file is empty');
      }

      // Move temp file to final path
      final outputFile = File(filePath);
      await tempFile.rename(filePath);
      print('[DownloadService] Saved audio to: $filePath');

      // Verify final file
      final finalSize = await outputFile.length();
      print(
        '[DownloadService] Download complete. Final file size: $finalSize bytes',
      );
    } catch (e) {
      print('[DownloadService] Download failed: $e');
      // Clean up partial downloads
      try {
        final filePath = await getLocalBookPath(fileKey);
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
        final tempFile = File('$filePath.tmp');
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (_) {}
      throw Exception('Failed to download book: $e');
    }
  }

  Future<void> deleteBook(String fileKey, {int? userId, String? bookId}) async {
    try {
      // Delete .mp3 file
      final filePath = await getLocalBookPath(
        fileKey,
        userId: userId,
        bookId: bookId,
      );
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }

      // Legacy cleanup
      final basePath = await _getUserPath(userId);
      // Also try to delete old .enc files (legacy encrypted)
      final encPath = '$basePath/$fileKey.enc';
      final encFile = File(encPath);
      if (await encFile.exists()) {
        await encFile.delete();
      }

      // Also try to delete old .mp3 files (legacy)
      final legacyPath = '$basePath/$fileKey.mp3';
      final legacyFile = File(legacyPath);
      if (await legacyFile.exists()) {
        await legacyFile.delete();
      }

      // Also try legacy .audio
      final audioPath = '$basePath/$fileKey.audio';
      final audioFile = File(audioPath);
      if (await audioFile.exists()) {
        await audioFile.delete();
      }
    } catch (e) {
      print('Delete failed: $e');
    }
  }

  Future<String?> getEncryptionKey() async {
    return await AuthService().getEncryptionKey();
  }

  Future<void> registerServerDownload(String bookId) async {
    if (ConnectivityService().isOffline) return;

    final authService = AuthService();
    final userId = await authService.getCurrentUserId();
    if (userId == null) return;

    try {
      final uri = Uri.parse('${authService.baseUrl}/register-download');
      final token = await authService.getAccessToken();

      await _dio.post(
        uri.toString(),
        data: {'user_id': userId, 'book_id': int.tryParse(bookId)},
        options: Options(
          headers: {if (token != null) 'Authorization': 'Bearer $token'},
        ),
      );
      print('[DownloadService] Registered download on server for book $bookId');
    } catch (e) {
      print('Failed to register download on server: $e');
    }
  }

  // --- Playlist Metadata Management ---

  Future<void> savePlaylistJson(
    String bookId,
    Map<String, dynamic> data, {
    int? userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    // Use user-specific key if userId is provided, otherwise legacy/fallback
    final key = userId != null
        ? 'offline_playlist_json_${userId}_$bookId'
        : 'offline_playlist_json_$bookId';
    await prefs.setString(key, json.encode(data));
  }

  Future<Map<String, dynamic>?> getPlaylistJson(
    String bookId, {
    int? userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Try user specific key first
    String? key;
    if (userId != null) {
      key = 'offline_playlist_json_${userId}_$bookId';
    }

    String? data;
    if (key != null) {
      data = prefs.getString(key);
    }

    // Fallback to legacy key if not found
    if (data == null) {
      data = prefs.getString('offline_playlist_json_$bookId');
    }

    if (data != null) {
      return json.decode(data);
    }
    return null;
  }

  Future<bool> isPlaylistDownloaded(String bookId, {int? userId}) async {
    final prefs = await SharedPreferences.getInstance();

    // Check user specific key
    if (userId != null) {
      if (prefs.containsKey('offline_playlist_json_${userId}_$bookId')) {
        return true;
      }
    }

    // Fallback to legacy key
    return prefs.containsKey('offline_playlist_json_$bookId');
  }

  // --- Quiz Metadata Management ---

  Future<void> saveQuizJson(
    String bookId,
    List<dynamic> data, {
    int? playlistItemId,
    int? userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final suffix = playlistItemId != null ? '_$playlistItemId' : '';

    final key = userId != null
        ? 'offline_quiz_json_${userId}_$bookId$suffix'
        : 'offline_quiz_json_$bookId$suffix';

    await prefs.setString(key, json.encode(data));
  }

  Future<List<dynamic>?> getQuizJson(
    String bookId, {
    int? playlistItemId,
    int? userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final suffix = playlistItemId != null ? '_$playlistItemId' : '';

    // Try user specific key
    String? data;
    if (userId != null) {
      final key = 'offline_quiz_json_${userId}_$bookId$suffix';
      data = prefs.getString(key);
    }

    // Fallback
    if (data == null) {
      final key = 'offline_quiz_json_$bookId$suffix';
      data = prefs.getString(key);
    }

    if (data != null) {
      return json.decode(data);
    }
    return null;
  }

  // --- Generic File Download ---

  Future<void> downloadFile(String url, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);

      // Skip if exists
      if (await file.exists()) return;

      await _dio.download(url, filePath);
    } catch (e) {
      print('Failed to download file $fileName: $e');
    }
  }

  Future<String> getLocalFilePath(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$fileName';
  }

  // --- PDF Download Methods ---

  /// Get local path for a book's PDF
  Future<String> getPdfPath(String bookId, {int? userId}) async {
    final userPath = await _getUserPath(userId);
    if (userId != null) {
      final bookDir = Directory('$userPath/book_$bookId');
      if (!await bookDir.exists()) {
        await bookDir.create(recursive: true);
      }
      return '${bookDir.path}/book.pdf';
    }
    return '$userPath/book_$bookId.pdf';
  }

  /// Check if PDF is downloaded for a book
  Future<bool> isPdfDownloaded(String bookId, {int? userId}) async {
    final pdfPath = await getPdfPath(bookId, userId: userId);
    final file = File(pdfPath);
    if (await file.exists()) {
      final size = await file.length();
      return size > 0;
    }
    return false;
  }

  /// Download PDF for a book
  Future<void> downloadPdf(
    String bookId,
    String pdfUrl, {
    int? userId,
  }) async {
    final downloadKey = 'pdf_$bookId${userId != null ? '_$userId' : ''}';

    // If download already in progress, wait for it
    if (_activeDownloads.containsKey(downloadKey)) {
      print('[DownloadService] PDF download already in progress for $downloadKey');
      await _activeDownloads[downloadKey];
      return;
    }

    // Check if already downloaded
    if (await isPdfDownloaded(bookId, userId: userId)) {
      print('[DownloadService] PDF already downloaded for book $bookId');
      return;
    }

    final downloadFuture = _performPdfDownload(bookId, pdfUrl, userId: userId);
    _activeDownloads[downloadKey] = downloadFuture;

    try {
      await downloadFuture;
    } finally {
      _activeDownloads.remove(downloadKey);
    }
  }

  Future<void> _performPdfDownload(
    String bookId,
    String pdfUrl, {
    int? userId,
  }) async {
    try {
      final pdfPath = await getPdfPath(bookId, userId: userId);
      final tempPath = '$pdfPath.tmp';

      print('[DownloadService] Downloading PDF from: $pdfUrl');

      await _dio.download(
        pdfUrl,
        tempPath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final progress = (received / total * 100).toStringAsFixed(1);
            print('[DownloadService] PDF download progress: $progress%');
          }
        },
      );

      // Verify download
      final tempFile = File(tempPath);
      if (!await tempFile.exists()) {
        throw Exception('PDF download failed - temp file not created');
      }

      final fileSize = await tempFile.length();
      if (fileSize == 0) {
        await tempFile.delete();
        throw Exception('Downloaded PDF is empty');
      }

      // Move temp file to final path
      await tempFile.rename(pdfPath);
      print('[DownloadService] PDF saved to: $pdfPath');
    } catch (e) {
      print('[DownloadService] PDF download failed: $e');
      // Clean up partial downloads
      try {
        final pdfPath = await getPdfPath(bookId, userId: userId);
        final file = File(pdfPath);
        if (await file.exists()) await file.delete();
        final tempFile = File('$pdfPath.tmp');
        if (await tempFile.exists()) await tempFile.delete();
      } catch (_) {}
      throw Exception('Failed to download PDF: $e');
    }
  }
}
