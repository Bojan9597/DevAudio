import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/category.dart';
import '../repositories/book_repository.dart';
import '../repositories/category_repository.dart';
import '../services/auth_service.dart';

class UploadBookScreen extends StatefulWidget {
  const UploadBookScreen({Key? key}) : super(key: key);

  @override
  State<UploadBookScreen> createState() => _UploadBookScreenState();
}

class _UploadBookScreenState extends State<UploadBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController(text: '0.0');

  String? _selectedCategoryId;
  String? _selectedAudioPath;
  String? _selectedCoverPath;

  bool _isUploading = false;
  List<Category> _categories = [];
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await CategoryRepository().getCategories();
      if (mounted) {
        setState(() {
          _categories = _flattenCategories(categories);
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCategories = false);
      }
      print('Error loading categories: $e');
    }
  }

  List<Category> _flattenCategories(
    List<Category> categories, [
    int level = 0,
  ]) {
    List<Category> flat = [];
    for (var cat in categories) {
      // Create a display title with indentation for subcategories
      final prefix = '— ' * level;
      final displayCat = Category(
        id: cat.id,
        title: '$prefix${cat.title}',
        children: cat.children,
        hasBooks: cat.hasBooks,
      );
      flat.add(displayCat);

      if (cat.children != null && cat.children!.isNotEmpty) {
        flat.addAll(_flattenCategories(cat.children!, level + 1));
      }
    }
    return flat;
  }

  Future<void> _pickAudio() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'm4a', 'wav', 'aac'],
    );
    if (result != null) {
      setState(() {
        _selectedAudioPath = result.files.single.path;
      });
    }
  }

  Future<void> _pickCover() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result != null) {
      setState(() {
        _selectedCoverPath = result.files.single.path;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }
    if (_selectedAudioPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an audio file')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final userId = await AuthService().getCurrentUserId();
      if (userId == null) {
        throw Exception("User not logged in");
      }

      await BookRepository().uploadBook(
        title: _titleController.text,
        author: _authorController.text,
        categoryId: _selectedCategoryId!,
        userId: userId.toString(),
        audioPath: _selectedAudioPath!,
        coverPath: _selectedCoverPath,
        description: _descriptionController.text,
        price: double.tryParse(_priceController.text) ?? 0.0,
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Upload successful!')));
        Navigator.pop(context, true); // Return success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Audio Book')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title *'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _authorController,
                decoration: const InputDecoration(labelText: 'Author *'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _isLoadingCategories
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                      isExpanded: true, // Allow dropdown to take full width
                      value: _selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Category *',
                      ),
                      items: _categories.map((c) {
                        return DropdownMenuItem(
                          value: c.id,
                          child: Text(
                            c.title,
                            overflow:
                                TextOverflow.ellipsis, // Truncate long text
                            maxLines: 1,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setState(() => _selectedCategoryId = val),
                    ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),

              // Audio Picker
              ListTile(
                title: Text(
                  _selectedAudioPath == null
                      ? 'Select Audio File *'
                      : 'Audio Selected: ...${_selectedAudioPath!.split(r'\').last}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                leading: const Icon(Icons.audio_file),
                tileColor: Colors.grey.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                onTap: _pickAudio,
              ),
              const SizedBox(height: 16),

              // Cover Picker
              ListTile(
                title: Text(
                  _selectedCoverPath == null
                      ? 'Select Cover Image (Optional)'
                      : 'Cover Selected: ...${_selectedCoverPath!.split(r'\').last}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                leading: const Icon(Icons.image),
                tileColor: Colors.grey.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                onTap: _pickCover,
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isUploading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isUploading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Upload Book', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
