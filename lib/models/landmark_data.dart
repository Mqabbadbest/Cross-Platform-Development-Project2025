import 'package:landmark_finder/models/location.dart';

class LandmarkData {
  const LandmarkData({
    required this.id,
    required this.placeID,
    required this.displayName,
    required this.location,
    this.address,
    this.rating,
    this.website,
    this.phone,
    this.photos,
  });

  final int id;
  final String placeID;
  final String displayName;
  final Location location;
  final String? address;
  final double? rating;
  final String? website;
  final String? phone;
  final List<dynamic>? photos;
}

class LandmarkDataList {
  final List<LandmarkData> landmarks;

  LandmarkDataList({required this.landmarks});
}
