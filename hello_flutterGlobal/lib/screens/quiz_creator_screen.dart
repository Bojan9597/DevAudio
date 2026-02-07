import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_constants.dart';
import '../models/quiz_question.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuizCreatorScreen extends StatefulWidget {
  final String bookId;
  final int? playlistItemId;

  const QuizCreatorScreen({Key? key, required this.bookId, this.playlistItemId})
    : super(key: key);

  @override
  _QuizCreatorScreenState createState() => _QuizCreatorScreenState();
}

class _QuizCreatorScreenState extends State<QuizCreatorScreen> {
  List<QuizQuestion> _questions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExistingQuiz();
  }

  Future<void> _loadExistingQuiz() async {
    try {
      String urlString = '${ApiConstants.baseUrl}/quiz/${widget.bookId}';
      if (widget.playlistItemId != null) {
        urlString += '?playlist_item_id=${widget.playlistItemId}';
      }
      final url = Uri.parse(urlString);
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      final response = await http.get(
        url,
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _questions = data
                .map((json) => QuizQuestion.fromJson(json))
                .toList();
            _isLoading = false;
          });
        }
      } else {
        // 404 just means no quiz yet, which is fine
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false); // Fail silent/safe
    }
  }

  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _optionAController = TextEditingController();
  final _optionBController = TextEditingController();
  final _optionCController = TextEditingController();
  final _optionDController = TextEditingController();

  String _selectedCorrectAnswer = 'A';
  bool _isSaving = false;

  void _addQuestion() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _questions.add(
          QuizQuestion(
            question: _questionController.text,
            options: [
              _optionAController.text,
              _optionBController.text,
              _optionCController.text,
              _optionDController.text,
            ],
            correctAnswer: _selectedCorrectAnswer,
          ),
        );

        // Clear form
        _questionController.clear();
        _optionAController.clear();
        _optionBController.clear();
        _optionCController.clear();
        _optionDController.clear();
        _selectedCorrectAnswer = 'A';
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Question added!')));
    }
  }

  Future<void> _saveQuiz() async {
    // Check if there is a pending question filled in
    if (_questionController.text.isNotEmpty) {
      // Try to add it automatically
      if (_formKey.currentState!.validate()) {
        _questions.add(
          QuizQuestion(
            question: _questionController.text,
            options: [
              _optionAController.text,
              _optionBController.text,
              _optionCController.text,
              _optionDController.text,
            ],
            correctAnswer: _selectedCorrectAnswer,
          ),
        );
      }
    }

    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one question.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      print("[DEBUG] QuizCreator token: $token");

      final url = Uri.parse('${ApiConstants.baseUrl}/quiz');
      print("[DEBUG] Posting to $url");

      final headers = {
        'Content-Type': 'application/json',
        ApiConstants.appSourceHeader: ApiConstants.appSourceValue,
        if (token != null) 'Authorization': 'Bearer $token',
      };
      print("[DEBUG] Headers: $headers");

      final response = await http.post(
        url,
        headers: headers,
        body: json.encode({
          'book_id': widget.bookId,
          'playlist_item_id': widget.playlistItemId,
          'questions': _questions.map((q) => q.toJson()).toList(),
        }),
      );

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quiz saved successfully!')),
          );
          Navigator.pop(context);
        }
      } else {
        throw Exception('Failed to save quiz: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.playlistItemId != null
                ? 'Create Lesson Quiz'
                : 'Create Book Quiz',
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.playlistItemId != null
              ? 'Create Lesson Quiz'
              : 'Create Book Quiz',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // List of added questions
            if (_questions.isNotEmpty)
              Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: _questions.length,
                  itemBuilder: (context, index) {
                    final q = _questions[index];
                    return ListTile(
                      title: Text('Q${index + 1}: ${q.question}'),
                      subtitle: Text('Correct: ${q.correctAnswer}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _questions.removeAt(index);
                          });
                        },
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 20),
            const Text(
              "Add New Question",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _questionController,
                    decoration: const InputDecoration(
                      labelText: 'Question Text',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _optionAController,
                    decoration: const InputDecoration(
                      labelText: 'Option A',
                      prefixText: 'A. ',
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _optionBController,
                    decoration: const InputDecoration(
                      labelText: 'Option B',
                      prefixText: 'B. ',
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _optionCController,
                    decoration: const InputDecoration(
                      labelText: 'Option C',
                      prefixText: 'C. ',
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _optionDController,
                    decoration: const InputDecoration(
                      labelText: 'Option D',
                      prefixText: 'D. ',
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _selectedCorrectAnswer,
                    decoration: const InputDecoration(
                      labelText: 'Correct Answer',
                      border: OutlineInputBorder(),
                    ),
                    items: ['A', 'B', 'C', 'D']
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text("Option $e"),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedCorrectAnswer = v!),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _addQuestion,
                  icon: const Icon(Icons.add),
                  label: const Text('Next Question'),
                ),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveQuiz,
                  icon: const Icon(Icons.save),
                  label: _isSaving
                      ? const Text('Saving...')
                      : const Text('Finish & Save'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
