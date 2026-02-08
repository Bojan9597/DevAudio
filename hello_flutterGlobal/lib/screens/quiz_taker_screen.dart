import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_constants.dart';
import '../models/quiz_question.dart';
import '../services/auth_service.dart';
import '../services/connectivity_service.dart';
import '../services/download_service.dart';

class QuizTakerScreen extends StatefulWidget {
  final String bookId;
  final int? playlistItemId;

  const QuizTakerScreen({Key? key, required this.bookId, this.playlistItemId})
    : super(key: key);

  @override
  _QuizTakerScreenState createState() => _QuizTakerScreenState();
}

class _QuizTakerScreenState extends State<QuizTakerScreen> {
  List<QuizQuestion> _questions = [];
  bool _isLoading = true;
  String? _error;

  // State for user answers: Map<questionIndex, selectedOptionChar>
  final Map<int, String> _userAnswers = {};

  // Page Controller
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    try {
      // Offline Check
      if (ConnectivityService().isOffline) {
        final cachedData = await DownloadService().getQuizJson(
          widget.bookId,
          playlistItemId: widget.playlistItemId,
        );

        if (cachedData != null) {
          if (mounted) {
            setState(() {
              _questions = cachedData
                  .map((json) => QuizQuestion.fromJson(json))
                  .toList();
              _isLoading = false;
            });
          }
          return;
        } else {
          throw Exception('Quiz not available offline.');
        }
      }

      String urlString = '${ApiConstants.baseUrl}/quiz/${widget.bookId}';
      if (widget.playlistItemId != null) {
        urlString += '?playlist_item_id=${widget.playlistItemId}';
      }
      final url = Uri.parse(urlString);
      final response = await http.get(
        url,
        headers: {ApiConstants.appSourceHeader: ApiConstants.appSourceValue},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        // Save for offline
        await DownloadService().saveQuizJson(
          widget.bookId,
          data,
          playlistItemId: widget.playlistItemId,
        );

        if (mounted) {
          setState(() {
            _questions = data
                .map((json) => QuizQuestion.fromJson(json))
                .toList();
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load quiz');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _finishQuiz() {
    int score = 0;
    _questions.asMap().forEach((index, q) {
      if (_userAnswers[index] == q.correctAnswer) {
        score++;
      }
    });

    double percentage = _questions.isEmpty
        ? 0
        : (score / _questions.length) * 100;

    _submitResult(percentage, score);
  }

  Future<void> _submitResult(double percentage, int score) async {
    try {
      final userId = await AuthService().getCurrentUserId();
      if (userId == null) {
        _showResultDialog(percentage, score);
        return;
      }

      if (ConnectivityService().isOffline) {
        // Offline: Just show result, don't submit
        _showResultDialog(percentage, score);
        return;
      }

      final url = Uri.parse('${ApiConstants.baseUrl}/quiz/result');
      await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          ApiConstants.appSourceHeader: ApiConstants.appSourceValue,
        },
        body: json.encode({
          'user_id': userId,
          'book_id': widget.bookId,
          'playlist_item_id': widget.playlistItemId,
          'score_percentage': percentage,
        }),
      );

      _showResultDialog(percentage, score);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving result: $e')));
      // Show dialog anyway
      _showResultDialog(percentage, score);
    }
  }

  void _showResultDialog(double percentage, int score) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Quiz Results'),
        content: Text(
          'You scored $score out of ${_questions.length}!\n\nScore: ${percentage.toStringAsFixed(1)}%\n${percentage > 50 ? "PASSED!" : "Keep trying!"}',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              // Stay on screen to review? User said "return to quiz, or finish"
            },
            child: const Text('Return to Quiz'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(
                context,
                percentage > 50,
              ); // Close screen with result
            },
            child: const Text('Finish'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null)
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.playlistItemId != null ? "Mini Quiz" : "Start Quiz",
          ),
        ),
        body: Center(child: Text("Error: $_error")),
      );
    if (_questions.isEmpty)
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.playlistItemId != null ? "Mini Quiz" : "Book Quiz",
          ),
        ),
        body: const Center(child: Text("No quiz available for this item.")),
      );

    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${_currentIndex + 1}/${_questions.length}'),
      ),
      body: PageView.builder(
        controller: _pageController,
        physics:
            const NeverScrollableScrollPhysics(), // Force navigation via buttons
        itemCount: _questions.length,
        onPageChanged: (idx) {
          setState(() {
            _currentIndex = idx;
          });
        },
        itemBuilder: (context, index) {
          final q = _questions[index];
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  q.question,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ...List.generate(4, (optIndex) {
                  final char = ['A', 'B', 'C', 'D'][optIndex];
                  final text = q.options[optIndex];
                  final isSelected = _userAnswers[index] == char;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isSelected
                            ? Colors.orange.withOpacity(0.2)
                            : null,
                        side: BorderSide(
                          color: isSelected ? Colors.orange : Colors.grey,
                        ),
                        padding: const EdgeInsets.all(16),
                      ),
                      onPressed: () {
                        setState(() {
                          _userAnswers[index] = char;
                        });
                      },
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 15,
                            backgroundColor: isSelected
                                ? Colors.orange
                                : Colors.grey.shade300,
                            child: Text(
                              char,
                              style: const TextStyle(color: Colors.black),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              text,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 32),

                Container(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).size.height * 0.1,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (index > 0)
                        TextButton(
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: const Text("Previous"),
                        ),

                      if (index < _questions.length - 1)
                        ElevatedButton(
                          onPressed: () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: const Text("Next Question"),
                        )
                      else
                        ElevatedButton(
                          onPressed: _finishQuiz,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          child: const Text("Submit Quiz"),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
