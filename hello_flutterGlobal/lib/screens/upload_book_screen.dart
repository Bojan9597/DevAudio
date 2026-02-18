import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/category.dart';
import '../repositories/book_repository.dart';
import '../repositories/category_repository.dart';
import '../services/auth_service.dart';
import '../l10n/generated/app_localizations.dart';

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
  List<String> _selectedAudioPaths = [];
  String? _selectedCoverPath;
  String? _selectedPdfPath;

  bool _isUploading = false;
  bool _isPremium = false; // Premium flag
  List<Category> _categories = [];
  bool _isLoadingCategories = true;

  // Background Music State
  List<Map<String, dynamic>> _bgMusicList = [];
  int? _selectedBgMusicId;

  // Tab 2 State
  final _bgTitleController = TextEditingController();
  String? _selectedBgMusicPath;
  bool _isBgDefault = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadBgMusic();
  }

  Future<void> _loadBgMusic() async {
    try {
      final list = await BookRepository().getBackgroundMusicList();
      if (mounted) {
        setState(() {
          _bgMusicList = list;
          if (_selectedBgMusicId == null && _bgMusicList.isNotEmpty) {
            final defaultTrack = _bgMusicList.firstWhere(
              (e) => e['isDefault'] == true,
              orElse: () => _bgMusicList.first,
            );
            _selectedBgMusicId = defaultTrack['id'] as int?;
          }
        });
      }
    } catch (e) {
      print('Error loading bg music: $e');
    }
  }

  Future<void> _pickBgMusic() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio, // Audio type
    );
    if (result != null) {
      setState(() {
        _selectedBgMusicPath = result.files.single.path;
      });
    }
  }

  Future<void> _submitBgMusic() async {
    if (_bgTitleController.text.isEmpty || _selectedBgMusicPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select file and enter title')),
      );
      return;
    }

    setState(() => _isUploading = true);
    try {
      await BookRepository().uploadBackgroundMusic(
        _bgTitleController.text,
        _selectedBgMusicPath!,
        _isBgDefault,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Background music uploaded!')),
        );
        _bgTitleController.clear();
        setState(() {
          _selectedBgMusicPath = null;
          _isBgDefault = false;
        });
        _loadBgMusic(); // Refresh list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
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
      allowMultiple: true,
    );
    if (result != null) {
      setState(() {
        _selectedAudioPaths = result.paths.whereType<String>().toList();
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

  Future<void> _pickPdf() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      setState(() {
        _selectedPdfPath = result.files.single.path;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pleaseSelectCategory),
        ),
      );
      return;
    }
    if (_selectedAudioPaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pleaseSelectAudioFile),
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final userId = await AuthService().getCurrentUserId();
      if (userId == null) {
        throw Exception("User not logged in");
      }

      // Encryption and Duration Logic
      final authService = AuthService();
      String? keyString = await authService.getEncryptionKey();

      // If no key found (old user?), try to fetch from user object or warn?
      // Ideally backend ensures key exists. If null, maybe generate one locally and update?
      // For now, if null, we proceed with upload but maybe unencrypted or error?
      // Let's assume key exists. If not, we can't encrypt.

      if (keyString == null) {
        // Fallback: Check if user data has it (though _saveUser moves it).
        // Or maybe fetch user again?
        final user = await authService.getUser();
        // If still null, we might be an old user who hasn't logged in since migration.
        // We should probably force re-login or handle it.
        print("Warning: No encryption key found locally.");
      }

      List<String> finalPaths = [];
      int totalDuration = 0;

      for (String path in _selectedAudioPaths) {
        // Get Duration using AudioPlayer
        final player = AudioPlayer();
        try {
          await player.setFilePath(path);
          final d = player.duration;
          if (d != null) {
            totalDuration += d.inSeconds;
          }
        } catch (e) {
          print("Error getting duration for $path: $e");
        } finally {
          await player.dispose();
        }

        // No client-side encryption - server encrypts on-the-fly when serving
        finalPaths.add(path);
      }

      await BookRepository().uploadBook(
        title: _titleController.text,
        author: _authorController.text,
        categoryId: _selectedCategoryId!,
        userId: userId.toString(),
        audioPaths: finalPaths,
        coverPath: _selectedCoverPath,
        pdfPath: _selectedPdfPath,
        description: _descriptionController.text,
        price: double.tryParse(_priceController.text) ?? 0.0,
        duration: totalDuration,
        isEncrypted: true, // Always true - server encrypts when serving
        isPremium: _isPremium,
        backgroundMusicId: _selectedBgMusicId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.uploadSuccessful),
          ),
        );
        Navigator.pop(context, true); // Return success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.uploadFailed(e.toString()),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.uploadAudioBook),
          bottom: TabBar(
            tabs: [
              Tab(text: AppLocalizations.of(context)!.audioUpload),
              Tab(text: AppLocalizations.of(context)!.backgroundMusicUpload),
            ],
          ),
        ),
        body: TabBarView(
          children: [_buildBookUploadTab(), _buildBgMusicUploadTab()],
        ),
      ),
    );
  }

  Widget _buildBookUploadTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.titleRequired,
              ),
              validator: (v) => v == null || v.isEmpty
                  ? AppLocalizations.of(context)!.required
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _authorController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.authorRequired,
              ),
              validator: (v) => v == null || v.isEmpty
                  ? AppLocalizations.of(context)!.required
                  : null,
            ),
            const SizedBox(height: 16),
            _isLoadingCategories
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _selectedCategoryId,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.categoryRequired,
                    ),
                    items: _categories.map((c) {
                      return DropdownMenuItem(
                        value: c.id,
                        child: Text(
                          c.title,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) =>
                        setState(() => _selectedCategoryId = val),
                  ),
            const SizedBox(height: 16),

            // Background Music Dropdown
            DropdownButtonFormField<int>(
              isExpanded: true,
              value: _selectedBgMusicId,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(
                  context,
                )!.defaultBackgroundMusicOptional,
              ),
              items: _bgMusicList.map((bg) {
                return DropdownMenuItem<int>(
                  value: bg['id'] as int,
                  child: Text(
                    bg['title'] ?? AppLocalizations.of(context)!.unknown,
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedBgMusicId = val),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.description,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.price,
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Premium Checkbox
            CheckboxListTile(
              title: Text(AppLocalizations.of(context)!.premiumContent),
              subtitle: Text(
                AppLocalizations.of(context)!.onlySubscribersCanAccess,
              ),
              value: _isPremium,
              onChanged: (bool? value) {
                setState(() {
                  _isPremium = value ?? false;
                });
              },
              tileColor: Colors.grey.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 24),

            // Audio Picker
            ListTile(
              title: Text(
                _selectedAudioPaths.isEmpty
                    ? AppLocalizations.of(context)!.selectAudioFiles
                    : _selectedAudioPaths.length == 1
                    ? AppLocalizations.of(context)!.audioSelected(
                        _selectedAudioPaths.first.split(r'\').last,
                      )
                    : AppLocalizations.of(
                        context,
                      )!.audioFilesSelected(_selectedAudioPaths.length),
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
            const SizedBox(height: 16),

            // PDF Picker
            ListTile(
              title: Text(
                _selectedPdfPath == null
                    ? 'Select PDF (Optional)'
                    : 'PDF Selected: ...${_selectedPdfPath!.split(r'\').last}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              leading: const Icon(Icons.picture_as_pdf),
              tileColor: Colors.grey.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              onTap: _pickPdf,
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
                  : Text(
                      AppLocalizations.of(context)!.uploadBook,
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBgMusicUploadTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _bgTitleController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.musicTitleRequired,
            ),
          ),
          const SizedBox(height: 16),

          // File Picker
          ListTile(
            title: Text(
              _selectedBgMusicPath == null
                  ? AppLocalizations.of(context)!.selectBackgroundMusicFile
                  : AppLocalizations.of(
                      context,
                    )!.fileSelected(_selectedBgMusicPath!.split(r'\').last),
            ),
            leading: const Icon(Icons.music_note),
            onTap: _pickBgMusic,
            tileColor: Colors.grey.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: _isUploading ? null : _submitBgMusic,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isUploading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(AppLocalizations.of(context)!.uploadBackgroundMusic),
          ),
        ],
      ),
    );
  }
}
