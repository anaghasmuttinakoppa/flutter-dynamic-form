import 'package:flutter/foundation.dart';

/// Represents a picked file or image for media fields.
@immutable
class MediaFileValue {
  /// Creates a [MediaFileValue].
  const MediaFileValue({
    this.path,
    this.name,
    this.mimeType,
    this.sizeBytes,
    this.bytes,
    this.source,
  });

  /// Local filesystem / URI path when available.
  final String? path;

  /// Display file name.
  final String? name;

  /// MIME type if known.
  final String? mimeType;

  /// Size in bytes if known.
  final int? sizeBytes;

  /// Optional in-memory bytes (web / memory picks).
  final List<int>? bytes;

  /// Origin hint: `gallery`, `camera`, `files`, etc.
  final String? source;

  /// Whether this value has usable content.
  bool get isEmpty =>
      (path == null || path!.isEmpty) &&
      (bytes == null || bytes!.isEmpty) &&
      (name == null || name!.isEmpty);

  /// Parses from a JSON-compatible map or string path.
  factory MediaFileValue.fromJson(dynamic json) {
    if (json == null) {
      return const MediaFileValue();
    }
    if (json is String) {
      return MediaFileValue(path: json, name: json.split('/').last);
    }
    if (json is! Map) {
      throw ArgumentError.value(json, 'json', 'Expected Map or String');
    }
    final map = Map<String, dynamic>.from(json);
    return MediaFileValue(
      path: map['path'] as String? ?? map['uri'] as String?,
      name: map['name'] as String? ?? map['fileName'] as String?,
      mimeType: map['mimeType'] as String? ?? map['mime'] as String?,
      sizeBytes: (map['sizeBytes'] as num?)?.toInt() ??
          (map['size'] as num?)?.toInt(),
      bytes: (map['bytes'] as List?)?.cast<int>(),
      source: map['source'] as String?,
    );
  }

  /// Serializes to JSON (bytes omitted by default for size).
  Map<String, dynamic> toJson({bool includeBytes = false}) {
    return <String, dynamic>{
      if (path != null) 'path': path,
      if (name != null) 'name': name,
      if (mimeType != null) 'mimeType': mimeType,
      if (sizeBytes != null) 'sizeBytes': sizeBytes,
      if (source != null) 'source': source,
      if (includeBytes && bytes != null) 'bytes': bytes,
    };
  }

  @override
  String toString() =>
      'MediaFileValue(name: $name, path: $path, source: $source)';
}

/// Represents a geographic location value.
@immutable
class LocationValue {
  /// Creates a [LocationValue].
  const LocationValue({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
    this.address,
  });

  /// Latitude in degrees.
  final double latitude;

  /// Longitude in degrees.
  final double longitude;

  /// Accuracy in meters, if known.
  final double? accuracy;

  /// Altitude in meters, if known.
  final double? altitude;

  /// Optional reverse-geocoded address.
  final String? address;

  /// Parses from JSON map.
  factory LocationValue.fromJson(dynamic json) {
    if (json is! Map) {
      throw ArgumentError.value(json, 'json', 'Expected Map');
    }
    final map = Map<String, dynamic>.from(json);
    return LocationValue(
      latitude: ((map['latitude'] ?? map['lat']) as num).toDouble(),
      longitude: ((map['longitude'] ?? map['lng'] ?? map['lon']) as num).toDouble(),
      accuracy: (map['accuracy'] as num?)?.toDouble(),
      altitude: (map['altitude'] as num?)?.toDouble(),
      address: map['address'] as String?,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
        if (accuracy != null) 'accuracy': accuracy,
        if (altitude != null) 'altitude': altitude,
        if (address != null) 'address': address,
      };

  @override
  String toString() =>
      'LocationValue($latitude, $longitude${address != null ? ', $address' : ''})';
}
