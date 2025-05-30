import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;
  runApp(MyApp(camera: firstCamera));
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;
  const MyApp({Key? key, required this.camera}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Telkom University & Wisata Bandung',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: MainPage(camera: camera),
    );
  }
}

class MainPage extends StatefulWidget {
  final CameraDescription camera;
  const MainPage({Key? key, required this.camera}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [MapPage(), CameraPage(camera: widget.camera)];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Peta'),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Kamera',
          ),
        ],
        backgroundColor: Colors.black,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}

class MapPage extends StatefulWidget {
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late GoogleMapController mapController;
  final Set<Marker> _markers = {};
  static const CameraPosition _telkomUniversity = CameraPosition(
    target: LatLng(-6.973328, 107.633766),
    zoom: 15,
  );

  @override
  void initState() {
    super.initState();
    _addTelkomMarker();
  }

  void _addTelkomMarker() {
    setState(() {
      _markers.add(
        const Marker(
          markerId: MarkerId('telkom_university'),
          position: LatLng(-6.973328, 107.633766),
          infoWindow: InfoWindow(title: 'Telkom University'),
        ),
      );
    });
  }

  void _goToWisata() {
    const gedungSate = LatLng(-6.903273, 107.618694);

    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        const CameraPosition(target: gedungSate, zoom: 15),
      ),
    );

    setState(() {
      _markers.add(
        const Marker(
          markerId: MarkerId('gedung_sate'),
          position: gedungSate,
          infoWindow: InfoWindow(title: 'Gedung Sate Bandung'),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Peta Telkom University'),
        backgroundColor: Colors.blue,
      ),
      body: GoogleMap(
        initialCameraPosition: _telkomUniversity,
        markers: _markers,
        onMapCreated: (controller) => mapController = controller,
        mapType: MapType.normal,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToWisata,
        child: const Icon(Icons.travel_explore),
        backgroundColor: Colors.blue,
        tooltip: 'Tampilkan Wisata Bandung',
      ),
    );
  }
}

class CameraPage extends StatefulWidget {
  final CameraDescription camera;
  const CameraPage({Key? key, required this.camera}) : super(key: key);

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isSaving = false;
  String? _imagePath; // Path untuk gambar yang baru diambil

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
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
    _controller = CameraController(widget.camera, ResolutionPreset.medium);
    _initializeControllerFuture = _controller
        .initialize()
        .then((_) {
          if (!mounted) return;
          setState(() {});
        })
        .catchError((e) {
          print("Error initializing camera: $e");
        });
  }

  Future<void> _takePicture() async {
    try {
      if (!_controller.value.isInitialized) {
        await _initializeControllerFuture;
      }

      setState(() => _isSaving = true);

      // Ambil gambar
      final XFile picture = await _controller.takePicture();

      // Simpan gambar
      final directory = await getApplicationDocumentsDirectory();
      final path = directory.path;
      final fileName = 'IMG_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final newPath = '$path/$fileName';
      await File(picture.path).copy(newPath);

      // Set state untuk menampilkan preview
      setState(() {
        _imagePath = newPath;
        _isSaving = false;
      });

      // Cetak path gambar ke konsol
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

  @override
  Widget build(BuildContext context) {
    // Tampilkan preview gambar jika sudah mengambil foto
    if (_imagePath != null) {
      return Scaffold(
        body: Stack(
          children: [
            // Gambar preview
            SizedBox.expand(
              child: Image.file(File(_imagePath!), fit: BoxFit.cover),
            ),

            // Tombol OKE untuk kembali
            Positioned(
              bottom: 40.0,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton(
                  onPressed: _resetCamera,
                  child: const Text(
                    'OKE',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 50,
                      vertical: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Tampilan normal kamera
    return Scaffold(
      appBar: null,
      body: Stack(
        children: [
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                      child: CameraPreview(_controller),
                    ),
                  ),
                );
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
          if (_isSaving)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Mengambil foto...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _takePicture,
        child: const Icon(Icons.camera),
        backgroundColor: Colors.blue,
        tooltip: 'Ambil Foto',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
