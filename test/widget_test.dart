import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:camera/camera.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kamera/main.dart'; // Pastikan ini sesuai dengan nama folder/project kamu

void main() {
  testWidgets('App builds correctly with dummy camera', (
    WidgetTester tester,
  ) async {
    // Buat dummy CameraDescription
    final dummyCamera = CameraDescription(
      name: 'Dummy Camera',
      lensDirection: CameraLensDirection.back,
      sensorOrientation: 90,
    );

    // Jalankan aplikasi dengan kamera dummy
    await tester.pumpWidget(MyApp(camera: dummyCamera));

    // Periksa apakah halaman pertama (MapPage) tampil
    expect(find.byType(GoogleMap), findsOneWidget);
    expect(find.text('Peta Telkom University'), findsOneWidget);

    // Ubah halaman ke Kamera
    await tester.tap(find.byIcon(Icons.camera_alt));
    await tester.pumpAndSettle();

    // Periksa apakah halaman Kamera tampil
    expect(find.text('Kamera'), findsOneWidget);
  });
}
