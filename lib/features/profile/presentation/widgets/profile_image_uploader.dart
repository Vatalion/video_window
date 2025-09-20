import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/models/profile_media.dart';
import '../../data/repositories/profile_repository.dart';

class ProfileImageUploader extends StatefulWidget {
  final String userId;
  final ProfileMediaType mediaType;
  final String? currentImageUrl;
  final Function(ProfileMedia) onUploadComplete;

  const ProfileImageUploader({
    super.key,
    required this.userId,
    required this.mediaType,
    this.currentImageUrl,
    required this.onUploadComplete,
  });

  @override
  State<ProfileImageUploader> createState() => _ProfileImageUploaderState();
}

class _ProfileImageUploaderState extends State<ProfileImageUploader> {
  final ProfileRepository _repository = ProfileRepository();
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  String? _errorMessage;

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: widget.mediaType == ProfileMediaType.cover ? 1200 : 800,
        maxHeight: widget.mediaType == ProfileMediaType.cover ? 400 : 800,
      );

      if (image != null) {
        await _uploadImage(image.path);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick image: ${e.toString()}';
      });
    }
  }

  Future<void> _uploadImage(String imagePath) async {
    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      final profileMedia = await _repository.uploadProfileMedia(
        widget.userId,
        widget.mediaType,
        imagePath,
      );

      widget.onUploadComplete(profileMedia);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to upload image: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.mediaType == ProfileMediaType.photo
                  ? 'Profile Photo'
                  : 'Cover Image',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            _buildImagePreview(),
            const SizedBox(height: 16),
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade900),
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _pickAndUploadImage,
                child: _isUploading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Uploading...'),
                        ],
                      )
                    : Text(widget.currentImageUrl == null
                        ? 'Upload ${widget.mediaType == ProfileMediaType.photo ? 'Photo' : 'Cover'}'
                        : 'Change ${widget.mediaType == ProfileMediaType.photo ? 'Photo' : 'Cover'}'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (widget.currentImageUrl == null) {
      return Container(
        width: double.infinity,
        height: widget.mediaType == ProfileMediaType.photo ? 200 : 150,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.mediaType == ProfileMediaType.photo
                    ? Icons.person
                    : Icons.image,
                size: 48,
                color: Colors.grey.shade600,
              ),
              const SizedBox(height: 8),
              Text(
                'No ${widget.mediaType == ProfileMediaType.photo ? 'profile photo' : 'cover image'}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: widget.mediaType == ProfileMediaType.photo ? 1 : 3,
        child: Image.network(
          widget.currentImageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey.shade200,
              child: const Center(
                child: Icon(Icons.error, color: Colors.grey),
              ),
            );
          },
        ),
      ),
    );
  }
}