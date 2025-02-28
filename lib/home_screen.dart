// home_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> images = [];
  bool isLoading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadImages();
  }

  Future<void> _checkAuthAndLoadImages() async {
    if (supabase.auth.currentSession == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
    await _loadImages();
  }

  Future<void> _loadImages() async {
    try {
      setState(() => isLoading = true);
      final response = await supabase.storage.from('gallery').list();
      final userId = supabase.auth.currentUser?.id;

      print('Storage response: ${response.length} items found');
      final tempImages = response.map((file) {
        final url = supabase.storage.from('gallery').getPublicUrl(file.name);
        final isOwnImage = file.name.startsWith(userId ?? '');
        print('Image URL: $url');
        return {
          'url': url,
          'name': file.name,
          'likes': 0,
          'isLiked': false,
          'isOwnImage': isOwnImage,
        };
      }).toList();

      setState(() {
        images = tempImages;
        isLoading = false;
      });

      if (images.isEmpty) {
        print('No images found in gallery bucket');
      }
    } catch (e) {
      setState(() => isLoading = false);
      print('Error loading images: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading images: $e')),
      );
    }
  }

  Future<void> _uploadImage() async {
    try {
      if (supabase.auth.currentSession == null) {
        Navigator.pushNamed(context, '/login');
        return;
      }

      setState(() => isLoading = true);
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final fileName =
            '${supabase.auth.currentUser!.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';

        print('Uploading file: $fileName');
        await supabase.storage.from('gallery').upload(
              fileName,
              file,
              fileOptions:
                  const FileOptions(cacheControl: '3600', upsert: false),
            );
        print('Upload successful, refreshing images');
        await _loadImages();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image uploaded successfully!')),
        );
      }
    } catch (e) {
      print('Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _deleteImage(String fileName) async {
    try {
      print('Deleting image: $fileName');
      await supabase.storage.from('gallery').remove([fileName]);
      await _loadImages();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image deleted successfully')),
      );
    } catch (e) {
      print('Error deleting image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting image: $e')),
      );
    }
  }

  void _toggleLike(int index) {
    setState(() {
      images[index]['isLiked'] = !images[index]['isLiked'];
      images[index]['likes'] += images[index]['isLiked'] ? 1 : -1;
    });
  }

  void _showImagePreview(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Image.network(
          url,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(child: CircularProgressIndicator());
          },
          errorBuilder: (context, error, stackTrace) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error),
              Text('Failed to load image'),
              Text('URL: $url', style: TextStyle(fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await supabase.auth.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadImages,
        child: isLoading && images.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : images.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('No images yet'),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _uploadImage,
                          icon: const Icon(Icons.upload),
                          label: const Text('Upload your first image'),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _showImagePreview(images[index]['url']),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 2,
                                blurRadius: 5,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(12)),
                                  child: Image.network(
                                    images[index]['url'],
                                    fit: BoxFit.cover,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    },
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                      color: Colors.grey[300],
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.error),
                                          const Text('Failed to load'),
                                          Text('URL: ${images[index]['url']}',
                                              style: TextStyle(fontSize: 10)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.vertical(
                                      bottom: Radius.circular(12)),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            images[index]['isLiked']
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            color: images[index]['isLiked']
                                                ? Colors.red
                                                : null,
                                          ),
                                          onPressed: () => _toggleLike(index),
                                        ),
                                        Text('${images[index]['likes']}'),
                                      ],
                                    ),
                                    if (images[index]['isOwnImage'])
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () => showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Delete Image'),
                                            content: const Text(
                                                'Are you sure you want to delete this image?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  _deleteImage(
                                                      images[index]['name']);
                                                  Navigator.pop(context);
                                                },
                                                child: const Text('Delete'),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _uploadImage,
        child: const Icon(Icons.add_a_photo),
        tooltip: 'Upload Image',
      ),
    );
  }
}
