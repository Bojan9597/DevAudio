import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class DownloadService {
  final Dio _dio = Dio();

  Future<String> _getLocalPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<String> getLocalBookPath(String bookId) async {
    final path = await _getLocalPath();
    // Assuming mp3 for now, matching the URLs
    return '$path/$bookId.mp3';
  }

  Future<bool> isBookDownloaded(String bookId) async {
    final filePath = await getLocalBookPath(bookId);
    return File(filePath).exists();
  }

  Future<void> downloadBook(String bookId, String url) async {
    try {
      final filePath = await getLocalBookPath(bookId);
      await _dio.download(url, filePath);
    } catch (e) {
      print('Download failed: $e');
      throw Exception('Failed to download book');
    }
  }

  Future<void> deleteBook(String bookId) async {
    try {
      final filePath = await getLocalBookPath(bookId);
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Delete failed: $e');
    }
  }
}
