import 'package:geolocator/geolocator.dart';

class Coordinates {
  const Coordinates(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

class LocationFailure implements Exception {
  const LocationFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract class LocationRepository {
  Future<Coordinates> current();
}

class DeviceLocationRepository implements LocationRepository {
  @override
  Future<Coordinates> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationFailure('Hãy bật dịch vụ vị trí trên thiết bị.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationFailure(
        'Quyền vị trí đã bị từ chối vĩnh viễn. Hãy bật lại trong Cài đặt.',
      );
    }
    if (permission == LocationPermission.denied) {
      throw const LocationFailure(
        'Cần quyền vị trí để xem thời tiết nơi bạn ở.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return Coordinates(position.latitude, position.longitude);
    } catch (_) {
      throw const LocationFailure(
        'Không lấy được vị trí hiện tại. Bạn có thể tìm theo thành phố.',
      );
    }
  }
}
