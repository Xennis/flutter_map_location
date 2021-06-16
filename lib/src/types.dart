import 'package:latlong2/latlong.dart';

class LatLngData {
  const LatLngData(this.location, this.accuracy, this.heading);

  final LatLng location;

  /// Estimated horizontal accuracy, radial, in meters.
  ///
  /// If the accuracy is not available it's 0.0.
  final double accuracy;

  final double? heading;

  bool highAccuracy() {
    // Use > and not >= because 0.0 means no accurency.
    return accuracy > 0.0 && accuracy <= 30.0;
  }
}
