import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:serbisyo_ph/theme/colors.dart';

class ProviderAlbumPage extends StatefulWidget {
  const ProviderAlbumPage({super.key});

  @override
  State<ProviderAlbumPage> createState() => _ProviderAlbumPageState();
}

class _ProviderAlbumPageState extends State<ProviderAlbumPage> {
  List<String> _imageUrls = [];
  bool _loading = true;
  bool _uploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    if (doc.exists && mounted) {
      final data = doc.data() as Map<String, dynamic>;
      setState(() {
        _imageUrls = List<String>.from(data['album'] ?? []);
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _uploadImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.kWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.kBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "ADD PHOTO",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildImageSourceButton(
                    icon: Icons.camera_alt,
                    label: "Camera",
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildImageSourceButton(
                    icon: Icons.photo_library,
                    label: "Gallery",
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.kBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.kBorder),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppColors.kBlack),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.kBlack,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context);

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() => _uploading = true);

        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId != null) {
          String newImageUrl = image.path;

          List<String> updatedImages = [..._imageUrls, newImageUrl];

          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .update({'album': updatedImages});

          setState(() {
            _imageUrls = updatedImages;
            _uploading = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Photo added!"),
                backgroundColor: AppColors.kBlack,
              ),
            );
          }
        }
      }
    } catch (e) {
      setState(() => _uploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteImage(int index) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Photo"),
        content: const Text("Are you sure you want to delete this photo?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      List<String> updatedImages = List.from(_imageUrls);
      updatedImages.removeAt(index);

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'album': updatedImages,
      });

      setState(() => _imageUrls = updatedImages);
    }
  }

  void _viewImage(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            _ImageViewer(imageUrls: _imageUrls, initialIndex: index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.kBlack),
        title: const Text(
          "ALBUM",
          style: TextStyle(
            color: AppColors.kBlack,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate),
            onPressed: _uploading ? null : _uploadImage,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.kBlack),
            )
          : _imageUrls.isEmpty
          ? _buildEmptyState()
          : _buildCarousel(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 64,
            color: AppColors.kGreyText,
          ),
          const SizedBox(height: 16),
          const Text(
            "No photos yet",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.kBlack,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Add photos to show customers your work",
            style: TextStyle(fontSize: 14, color: AppColors.kGreyText),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _uploading ? null : _uploadImage,
            icon: const Icon(Icons.add),
            label: const Text("Add Photo"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.kBlack,
              foregroundColor: AppColors.kWhite,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarousel() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          height: 250,
          child: PageView.builder(
            itemCount: _imageUrls.length,
            controller: PageController(viewportFraction: 0.85),
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _viewImage(index),
                onLongPress: () => _deleteImage(index),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      _imageUrls[index],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.kBorder,
                          child: const Icon(
                            Icons.broken_image,
                            size: 48,
                            color: AppColors.kGreyText,
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: AppColors.kBackground,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.kBlack,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _imageUrls.length,
            (index) => Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.kGreyText,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          "Tap to view • Long press to delete",
          style: TextStyle(fontSize: 12, color: AppColors.kGreyText),
        ),
      ],
    );
  }
}

class _ImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _ImageViewer({required this.imageUrls, required this.initialIndex});

  @override
  State<_ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<_ImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "${_currentIndex + 1} / ${widget.imageUrls.length}",
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        itemCount: widget.imageUrls.length,
        itemBuilder: (context, index) {
          return InteractiveViewer(
            child: Center(
              child: Image.network(
                widget.imageUrls[index],
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.broken_image,
                    size: 64,
                    color: Colors.white54,
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
