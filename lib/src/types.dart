import 'package:latlong/latlong.dart';

class LatLngData {
  const LatLngData(this.location, this.accuracy);

  final LatLng location;

  /// Estimated horizontal accuracy, radial, in meters.
  final double accuracy;
}
