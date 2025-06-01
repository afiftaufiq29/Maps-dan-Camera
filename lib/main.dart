import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;
  runApp(MyApp(camera: firstCamera, cameras: cameras));
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;
  final List<CameraDescription> cameras;
  const MyApp({super.key, required this.camera, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Telkom Explorer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF0F1419),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A2332),
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1A2332),
          selectedItemColor: Color(0xFF00D4FF),
          unselectedItemColor: Color(0xFF6B7280),
          type: BottomNavigationBarType.fixed,
          elevation: 20,
        ),
      ),
      home: MainPage(camera: camera, cameras: cameras),
    );
  }
}

class MainPage extends StatefulWidget {
  final CameraDescription camera;
  final List<CameraDescription> cameras;
  const MainPage({super.key, required this.camera, required this.cameras});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late List<Widget> _pages;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _pages = [
      MapPage(),
      CameraPage(camera: widget.camera, cameras: widget.cameras),
    ];

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fabAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );

    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() => _selectedIndex = index);
            _fabAnimationController.reset();
            _fabAnimationController.forward();
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.explore),
              activeIcon: Icon(Icons.explore_outlined),
              label: 'Explorer',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt),
              activeIcon: Icon(Icons.camera_alt_outlined),
              label: 'Camera',
            ),
          ],
        ),
      ),
    );
  }
}

class GalleryPage extends StatelessWidget {
  final List<String> images;

  const GalleryPage({super.key, required this.images});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      appBar: AppBar(
        title: const Text('Galeri Foto'),
        backgroundColor: const Color(0xFF1A2332),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: images.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 80,
                    color: Color(0xFF6B7280),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Belum ada foto tersimpan',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Ambil foto pertama Anda!',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1,
              ),
              itemCount: images.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            FullScreenImage(imagePath: images[index]),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(images[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class FullScreenImage extends StatelessWidget {
  final String imagePath;

  const FullScreenImage({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              _showDeleteDialog(context);
            },
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.file(
            File(imagePath),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A2332),
          title: const Text(
            'Hapus Foto',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Apakah Anda yakin ingin menghapus foto ini?',
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Batal',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await File(imagePath).delete();
                  Navigator.of(context).pop(); 
                  Navigator.of(context).pop(); 
                } catch (e) {
                  print('Error deleting file: $e');
                }
              },
              child: const Text(
                'Hapus',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with TickerProviderStateMixin {
  late GoogleMapController mapController;
  final Set<Marker> _markers = {};
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  bool _isExpanded = false;

  static const CameraPosition _telkomUniversity = CameraPosition(
    target: LatLng(-6.973328, 107.633766),
    zoom: 15,
  );

  @override
  void initState() {
    super.initState();
    _addTelkomMarker();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _addTelkomMarker() {
    setState(() {
      _markers.add(
        const Marker(
          markerId: MarkerId('telkom_university'),
          position: LatLng(-6.973328, 107.633766),
          infoWindow: InfoWindow(
            title: 'Telkom University',
            snippet: 'Kampus Utama Tel-U',
          ),
        ),
      );
    });
  }

  void _goToPodomoro() {
    const podomoropark = LatLng(
        -6.975891338909002, 107.63667061837894); 

    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        const CameraPosition(target: podomoropark, zoom: 17),
      ),
    );

    setState(() {
      _markers.add(
        const Marker(
          markerId: MarkerId('podomoro_park'),
          position: podomoropark,
          infoWindow: InfoWindow(
            title: 'Podomoro Park Buah Batu',
            snippet: 'Wisata Keluarga & Kuliner',
          ),
        ),
      );
    });

    _animationController.forward();
    setState(() => _isExpanded = true);
  }

  void _resetView() {
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(_telkomUniversity),
    );
    setState(() {
      _markers
          .removeWhere((marker) => marker.markerId.value == 'podomoro_park');
      _isExpanded = false;
    });
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _telkomUniversity,
            markers: _markers,
            onMapCreated: (controller) => mapController = controller,
            mapType: MapType.normal,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            compassEnabled: true,
            mapToolbarEnabled: false,
          ),

          
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 10,
                left: 20,
                right: 20,
                bottom: 20,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF1A2332).withOpacity(0.95),
                    const Color(0xFF1A2332).withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D4FF).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.explore,
                      color: Color(0xFF00D4FF),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Telkom Explorer - Kelompok 2',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Jelajahi Bandung',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          
          if (_isExpanded)
            Positioned(
              bottom: 120,
              left: 20,
              right: 20,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(_slideAnimation),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2332),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00D4FF).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Color(0xFF00D4FF),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Podomoro Park Buah Batu',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Tempat wisata keluarga dengan berbagai wahana dan kuliner khas Bandung. Cocok untuk rekreasi bersama keluarga.',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _resetView,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00D4FF),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Kembali ke Tel-U'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToPodomoro,
        backgroundColor: const Color(0xFF00D4FF),
        foregroundColor: Colors.white,
        elevation: 8,
        icon: const Icon(Icons.travel_explore),
        label: const Text(
          'Jelajahi Wisata',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class CameraPage extends StatefulWidget {
  final CameraDescription camera;
  final List<CameraDescription> cameras;
  const CameraPage({super.key, required this.camera, required this.cameras});

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isSaving = false;
  String? _imagePath;
  bool _isFlashOn = false;
  List<String> _savedImages = [];
  int _currentCameraIndex = 0;
  bool _isFlipping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    _loadSavedImages();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        !_controller.value.isInitialized) {
      _initializeCamera();
    }
  }

  void _initializeCamera() {
    final camera = widget.cameras.isNotEmpty
        ? widget.cameras[_currentCameraIndex]
        : widget.camera;

    _controller = CameraController(camera, ResolutionPreset.high);
    _initializeControllerFuture = _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
    }).catchError((e) {
      print("Error initializing camera: $e");
    });
  }

  Future<void> _loadSavedImages() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final dir = Directory(directory.path);
      final files = dir.listSync();

      final imageFiles = files
          .where((file) =>
              file.path.contains('TELKOM_KELOMPOK2_') &&
              file.path.endsWith('.jpg'))
          .map((file) => file.path)
          .toList();

      imageFiles.sort((a, b) => b.compareTo(a)); 

      setState(() {
        _savedImages = imageFiles;
      });
    } catch (e) {
      print("Error loading saved images: $e");
    }
  }

  void _toggleFlash() async {
    try {
      await _controller.setFlashMode(
        _isFlashOn ? FlashMode.off : FlashMode.torch,
      );
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
    } catch (e) {
      print("Error toggling flash: $e");
    }
  }

  Future<void> _flipCamera() async {
    if (widget.cameras.length < 2 || _isFlipping) return;

    setState(() {
      _isFlipping = true;
    });

    try {
      await _controller.dispose();

      
      _currentCameraIndex = (_currentCameraIndex + 1) % widget.cameras.length;

      
      _controller = CameraController(
          widget.cameras[_currentCameraIndex], ResolutionPreset.high);

      _initializeControllerFuture = _controller.initialize();
      await _initializeControllerFuture;

      if (mounted) {
        setState(() {
          _isFlipping = false;
        });
      }
    } catch (e) {
      print("Error flipping camera: $e");
      setState(() {
        _isFlipping = false;
      });
    }
  }

  Future<void> _takePicture() async {
    try {
      if (!_controller.value.isInitialized) {
        await _initializeControllerFuture;
      }

      setState(() => _isSaving = true);

      final XFile picture = await _controller.takePicture();
      final directory = await getApplicationDocumentsDirectory();
      final path = directory.path;
      final fileName =
          'TELKOM_KELOMPOK2_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final newPath = '$path/$fileName';
      await File(picture.path).copy(newPath);

      setState(() {
        _imagePath = newPath;
        _isSaving = false;
      });

      
      await _loadSavedImages();

      print('Foto disimpan di: $newPath');
    } catch (e) {
      print("Error taking picture: $e");
      setState(() => _isSaving = false);
    }
  }

  void _resetCamera() {
    setState(() {
      _imagePath = null;
    });
  }

  void _openGallery() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GalleryPage(images: _savedImages),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_imagePath != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            SizedBox.expand(
              child: Image.file(File(_imagePath!), fit: BoxFit.cover),
            ),

            
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 20,
                  left: 20,
                  right: 20,
                  bottom: 20,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Telkom Explorer - Kelompok 2',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D4FF).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF00D4FF).withOpacity(0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Color(0xFF00D4FF),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Foto berhasil disimpan!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _resetCamera,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00D4FF),
                        foregroundColor: Colors.white,
                        elevation: 8,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Ambil Foto Lagi',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
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
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done &&
                  !_isFlipping) {
                return SizedBox.expand(
                  child: CameraPreview(_controller),
                );
              } else {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF00D4FF)),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isFlipping
                            ? 'Mengganti kamera...'
                            : 'Menyiapkan kamera...',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                );
              }
            },
          ),

          
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Kelompok 2',
                        style: TextStyle(
                          color: Color(0xFF00D4FF),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.cameras.length > 1) ...[
                        const SizedBox(width: 8),
                        Icon(
                          _currentCameraIndex == 0
                              ? Icons.camera_rear
                              : Icons.camera_front,
                          color: const Color(0xFF00D4FF),
                          size: 16,
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: GestureDetector(
                    onTap: _toggleFlash,
                    child: Icon(
                      _isFlashOn ? Icons.flash_on : Icons.flash_off,
                      color:
                          _isFlashOn ? const Color(0xFF00D4FF) : Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
          ),

          
          if (_isSaving)
            Container(
              color: Colors.black.withOpacity(0.8),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF00D4FF)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Menyimpan foto...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                
                GestureDetector(
                  onTap: _openGallery,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: const Color(0xFF00D4FF),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.photo_library,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),

                
                GestureDetector(
                  onTap: _takePicture,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF00D4FF),
                        width: 4,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00D4FF),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),

                
                GestureDetector(
                  onTap: _flipCamera,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: const Color(0xFF00D4FF),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.flip_camera_ios,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}


