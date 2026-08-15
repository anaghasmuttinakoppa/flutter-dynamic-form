import '../models/media_value.dart';
import 'plugin_registry.dart';

/// Demo / test implementations that return deterministic fake media values.
///
/// Wire these in the example app or tests. Production apps should replace them
/// with wrappers around `image_picker`, `file_picker`, `geolocator`, etc.
class MockFormImagePicker implements FormImagePicker {
  /// Creates a mock gallery picker.
  MockFormImagePicker({this.path = 'mock/gallery.jpg'});

  /// Fake path returned by [pickFromGallery].
  final String path;

  @override
  Future<MediaFileValue?> pickFromGallery() async {
    return MediaFileValue(
      path: path,
      name: path.split('/').last,
      mimeType: 'image/jpeg',
      source: 'gallery',
    );
  }
}

/// Mock camera capture.
class MockFormCameraCapture implements FormCameraCapture {
  /// Creates a mock camera.
  MockFormCameraCapture({this.path = 'mock/camera.jpg'});

  /// Fake path returned by [capture].
  final String path;

  @override
  Future<MediaFileValue?> capture() async {
    return MediaFileValue(
      path: path,
      name: path.split('/').last,
      mimeType: 'image/jpeg',
      source: 'camera',
    );
  }
}

/// Mock file picker.
class MockFormFilePicker implements FormFilePicker {
  /// Creates a mock file picker.
  MockFormFilePicker({this.path = 'mock/document.pdf'});

  /// Fake path returned by [pickFiles].
  final String path;

  @override
  Future<List<MediaFileValue>> pickFiles({
    bool allowMultiple = false,
    List<String>? allowedExtensions,
  }) async {
    final file = MediaFileValue(
      path: path,
      name: path.split('/').last,
      mimeType: 'application/pdf',
      source: 'files',
    );
    return allowMultiple ? <MediaFileValue>[file, file] : <MediaFileValue>[file];
  }
}

/// Mock location provider (San Francisco).
class MockFormLocationProvider implements FormLocationProvider {
  /// Creates a mock location provider.
  const MockFormLocationProvider({
    this.latitude = 37.7749,
    this.longitude = -122.4194,
    this.address = 'San Francisco, CA',
  });

  /// Latitude.
  final double latitude;

  /// Longitude.
  final double longitude;

  /// Address label.
  final String address;

  @override
  Future<LocationValue?> getCurrentLocation() async {
    return LocationValue(
      latitude: latitude,
      longitude: longitude,
      accuracy: 10,
      address: address,
    );
  }
}

/// Convenience bundle of all mock media services.
FormMediaServices mockMediaServices() {
  return FormMediaServices(
    imagePicker: MockFormImagePicker(),
    camera: MockFormCameraCapture(),
    filePicker: MockFormFilePicker(),
    location: const MockFormLocationProvider(),
  );
}
