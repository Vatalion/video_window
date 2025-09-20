import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/models/user_profile.dart';
import '../../data/repositories/profile_repository.dart';

class ProfileEditor extends StatefulWidget {
  final UserProfile initialProfile;
  final Function(UserProfile) onSave;

  const ProfileEditor({
    super.key,
    required this.initialProfile,
    required this.onSave,
  });

  @override
  State<ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends State<ProfileEditor> {
  late final TextEditingController _displayNameController;
  late final TextEditingController _bioController;
  late final TextEditingController _websiteController;
  late final TextEditingController _locationController;
  final ProfileRepository _repository = ProfileRepository();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(text: widget.initialProfile.displayName);
    _bioController = TextEditingController(text: widget.initialProfile.bio ?? '');
    _websiteController = TextEditingController(text: widget.initialProfile.website ?? '');
    _locationController = TextEditingController(text: widget.initialProfile.location ?? '');
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _websiteController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_displayNameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Display name is required';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final updatedProfile = widget.initialProfile.copyWith(
        displayName: _displayNameController.text.trim(),
        bio: _bioController.text.trim().isNotEmpty ? _bioController.text.trim() : null,
        website: _websiteController.text.trim().isNotEmpty ? _websiteController.text.trim() : null,
        location: _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null,
      );

      final savedProfile = await _repository.updateUserProfile(updatedProfile);
      widget.onSave(savedProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade900),
                ),
              ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _displayNameController,
              label: 'Display Name',
              hintText: 'Enter your display name',
              maxLength: 50,
              required: true,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _bioController,
              label: 'Bio',
              hintText: 'Tell us about yourself',
              maxLength: 500,
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _websiteController,
              label: 'Website',
              hintText: 'https://yourwebsite.com',
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _locationController,
              label: 'Location',
              hintText: 'City, Country',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    int? maxLength,
    int maxLines = 1,
    bool required = false,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (required)
              const Text(
                ' *',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLength: maxLength,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            border: const OutlineInputBorder(),
            counterText: maxLength != null ? null : '',
          ),
        ),
      ],
    );
  }
}