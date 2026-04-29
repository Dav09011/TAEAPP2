import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tae_app/core/errors/app_exception.dart';
import 'package:tae_app/features/admin/presentation/controllers/activity_detail_controller.dart';
import 'package:video_player/video_player.dart';

/// Detail screen for a single activity.
///
/// This cut only migrates the Firebase-backed exercise CRUD.
/// Local multimedia still lives in the widget state until we decide how it
/// should be persisted.
class ActivityDetailScreen extends StatefulWidget {
  const ActivityDetailScreen({
    super.key,
    required this.activityId,
    required this.groupId,
    required this.activityName,
    required this.exercises,
  });

  final String groupId;
  final String activityId;
  final String activityName;
  final List<String> exercises;

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  late final ActivityDetailController _controller;
  final Map<int, List<Map<String, dynamic>>> _mediaPerExercise = {};

  @override
  void initState() {
    super.initState();
    _controller = ActivityDetailController(
      groupId: widget.groupId,
      activityId: widget.activityId,
      initialExercises: widget.exercises,
    )..addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleControllerChanged)
      ..dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _addExercise() async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: const Color.fromARGB(255, 241, 241, 241),
            title: const Text('Agregar ejercicio'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Nombre del ejercicio',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await _controller.addExercise(controller.text.trim());
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ejercicio agregado con exito.'),
                        ),
                      );
                    }
                  } on AppException catch (error) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error.message)),
                      );
                    }
                  } catch (error) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al guardar el ejercicio: $error'),
                        ),
                      );
                    }
                  }
                  if (mounted) {
                    Navigator.pop(ctx);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 0, 156, 196),
                  foregroundColor: const Color.fromARGB(251, 248, 248, 248),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Guardar'),
              ),
            ],
          ),
    );
  }

  Future<void> _editExercise(int index) async {
    final currentExercises = _controller.exercises;
    if (index >= currentExercises.length) return;

    final controller = TextEditingController(text: currentExercises[index]);

    await showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: const Color.fromARGB(255, 241, 241, 241),
            title: const Text('Editar ejercicio'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Nuevo nombre',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await _controller.renameExerciseAt(
                      index,
                      controller.text.trim(),
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Nombre del ejercicio actualizado.'),
                        ),
                      );
                    }
                  } on AppException catch (error) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error.message)),
                      );
                    }
                  } catch (error) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al editar el ejercicio: $error'),
                        ),
                      );
                    }
                  }
                  if (mounted) {
                    Navigator.pop(ctx);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 0, 156, 196),
                  foregroundColor: const Color.fromARGB(251, 248, 248, 248),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Guardar'),
              ),
            ],
          ),
    );
  }

  void _deleteExercise(int index) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Confirmar eliminacion'),
            content: const Text('Seguro que quieres eliminar este ejercicio?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  try {
                    await _controller.deleteExerciseAt(index);
                    setState(() {
                      _mediaPerExercise.remove(index);
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ejercicio eliminado con exito.'),
                        ),
                      );
                    }
                  } catch (error) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al eliminar el ejercicio: $error'),
                        ),
                      );
                    }
                  }
                  if (mounted) {
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );
  }

  Future<void> _addMedia(int index) async {
    final picker = ImagePicker();

    await showModalBottomSheet(
      backgroundColor: const Color.fromARGB(251, 248, 248, 248),
      context: context,
      builder:
          (context) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.image, color: Colors.blue),
                  title: const Text('Agregar imagen'),
                  onTap: () async {
                    Navigator.pop(context);
                    final picked = await picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (picked != null) {
                      final bytes = await picked.readAsBytes();
                      setState(() {
                        _mediaPerExercise.putIfAbsent(index, () => []).add({
                          'type': 'image',
                          'bytes': bytes,
                        });
                      });
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.videocam, color: Colors.red),
                  title: const Text('Agregar video'),
                  onTap: () async {
                    Navigator.pop(context);
                    final picked = await picker.pickVideo(
                      source: ImageSource.gallery,
                    );
                    if (picked != null) {
                      final bytes = await picked.readAsBytes();
                      setState(() {
                        _mediaPerExercise.putIfAbsent(index, () => []).add({
                          'type': 'video',
                          'bytes': bytes,
                        });
                      });
                    }
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _deleteMedia(int exerciseIndex, int mediaIndex) {
    setState(() {
      _mediaPerExercise[exerciseIndex]?.removeAt(mediaIndex);
    });
  }

  void _viewMedia(Map<String, dynamic> mediaItem) {
    showDialog(
      context: context,
      builder: (ctx) {
        if (mediaItem['type'] == 'image') {
          return Dialog(
            backgroundColor: Colors.black,
            insetPadding: const EdgeInsets.all(10),
            child: GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: InteractiveViewer(
                child: Image.memory(mediaItem['bytes'], fit: BoxFit.contain),
              ),
            ),
          );
        } else {
          return Dialog(
            backgroundColor: Colors.black,
            insetPadding: const EdgeInsets.all(10),
            child: VideoViewer(videoBytes: mediaItem['bytes']),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final exercises = _controller.exercises;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.activityName),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _controller.isMutating ? null : _addExercise,
        backgroundColor: const Color.fromARGB(255, 3, 84, 150),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Agregar ejercicio'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ejercicios',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (exercises.isEmpty)
              const Text(
                'No hay ejercicios aun.',
                style: TextStyle(color: Colors.grey),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: exercises.length,
                itemBuilder: (context, index) {
                  final exercise = exercises[index];
                  final media = _mediaPerExercise[index] ?? [];

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.fitness_center),
                            title: Text(exercise),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') _editExercise(index);
                                if (value == 'delete') _deleteExercise(index);
                              },
                              itemBuilder:
                                  (context) => const [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, color: Colors.blue),
                                          SizedBox(width: 8),
                                          Text('Editar'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Eliminar'),
                                        ],
                                      ),
                                    ),
                                  ],
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Contenido multimedia:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.add_a_photo,
                                  color: Colors.blue,
                                ),
                                onPressed: () => _addMedia(index),
                              ),
                            ],
                          ),
                          if (media.isEmpty)
                            const Text(
                              'Sin contenido aun.',
                              style: TextStyle(color: Colors.grey),
                            )
                          else
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                  ),
                              itemCount: media.length,
                              itemBuilder: (context, mediaIndex) {
                                final item = media[mediaIndex];
                                final isVideo = item['type'] == 'video';
                                return GestureDetector(
                                  onTap: () => _viewMedia(item),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child:
                                            isVideo
                                                ? Container(
                                                  color: Colors.black26,
                                                  child: const Center(
                                                    child: Icon(
                                                      Icons.play_circle_fill,
                                                      color: Colors.redAccent,
                                                      size: 40,
                                                    ),
                                                  ),
                                                )
                                                : Image.memory(
                                                  item['bytes'],
                                                  fit: BoxFit.cover,
                                                  width: double.infinity,
                                                ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: GestureDetector(
                                          onTap:
                                              () => _deleteMedia(
                                                index,
                                                mediaIndex,
                                              ),
                                          child: Container(
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.black54,
                                            ),
                                            padding: const EdgeInsets.all(4),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class VideoViewer extends StatefulWidget {
  const VideoViewer({super.key, required this.videoBytes});

  final Uint8List videoBytes;

  @override
  State<VideoViewer> createState() => _VideoViewerState();
}

class _VideoViewerState extends State<VideoViewer> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    final videoBytes = widget.videoBytes;

    if (kIsWeb) {
      final videoUrl = Uri.dataFromBytes(
        videoBytes,
        mimeType: 'video/mp4',
      ).toString();

      _controller =
          VideoPlayerController.network(videoUrl)
            ..initialize().then((_) {
              setState(() {});
              _controller!.play();
            });
    } else {
      _loadVideoFile(videoBytes);
    }
  }

  Future<void> _loadVideoFile(Uint8List bytes) async {
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/temp_video.mp4');
    await tempFile.writeAsBytes(bytes);
    _controller =
        VideoPlayerController.file(tempFile)
          ..initialize().then((_) {
            setState(() {});
            _controller!.play();
          });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child:
          _controller != null && _controller!.value.isInitialized
              ? AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              )
              : const Center(child: CircularProgressIndicator()),
    );
  }
}
