import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:landmark_finder/models/landmark_data.dart';
import 'package:landmark_finder/models/location.dart';
import 'package:landmark_finder/widgets/landmark_list.dart';

class NewLandmarkRequest extends StatefulWidget {
  const NewLandmarkRequest({
    required this.currentPosition,
    required this.flutterLocalNotificationsPlugin,
    super.key,
  });

  final Position? currentPosition;
  final FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;

  ///
  /// This function is used to create a new state of the NewLandmarkRequest widget.
  ///
  @override
  State<NewLandmarkRequest> createState() {
    return NewLandmarkRequestState();
  }
}

class NewLandmarkRequestState extends State<NewLandmarkRequest> {
  final _formKey = GlobalKey<FormState>();
  List<int> radiusOptions = [1, 2, 3, 4, 5, 10, 15, 20, 25];
  int _selectedRadius = 1;
  bool isRequestingData = false;

  ///
  /// This function is used to submit a request to the Google Places API to search for historical landmarks within a specified radius of the user's current location.
  ///
  void _submitRequest() async {
    // Check if location permission is granted
    // If not, show a snackbar message and return
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location permission is required to use this feature. When permission is granted please close app tab and reopen.',
          ),
        ),
      );
      return;
    }

    String? apiKey = dotenv.env['GOOGLE_API_KEY'];

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        isRequestingData = true;
      });

      showNotification();

      // Making a POST request to the Google Places API
      // Searching for historical landmarks within a specified radius of the user's current location
      var url =
          Uri.parse('https://places.googleapis.com/v1/places:searchNearby');

      var body = jsonEncode({
        "includedTypes": ["historical_landmark"],
        "excludedTypes": ["hotel", "lodging"],
        "locationRestriction": {
          "circle": {
            "center": {
              "latitude": widget.currentPosition!.latitude,
              "longitude": widget.currentPosition!.longitude
            },
            "radius": _selectedRadius * 1000,
          },
        },
      });

      var response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "X-Goog-Api-Key": apiKey ?? "",
          "X-Goog-FieldMask":
              "places.displayName,places.id,places.location,places.photos,places.formattedAddress,places.types,places.websiteUri,places.rating,places.nationalPhoneNumber",
        },
        body: body,
      );

// If the request is successful, the response is parsed and the data is displayed in the LandmarkList widget
// If the request fails, an error message is displayed in the console

      if (response.statusCode == 200) {
        var responseString = jsonDecode(response.body);
        var places = responseString["places"];
        var index = 0;

        if (places != null) {
          LandmarkDataList landmarkDataList = LandmarkDataList(
            landmarks: [],
          );

          places.forEach((place) {
            List<String> photosData = [];
            var photosArray = [];

            var photos = place["photos"] as List<dynamic>?;
            if (photos != null && photos.isNotEmpty) {
              for (int i = 0; i < photos.length && i < 3; i++) {
                photosData.add(photos[i]["name"] ?? "No photo available");
              }
            }
            while (photosData.length < 3) {
              photosData.add("No photo available");
            }

            for (var photo in photosData) {
              photosArray.add(photo == "No photo available"
                  ? "assets/images/ImagePlaceholder.jpg"
                  : Uri.parse(
                      "https://places.googleapis.com/v1/$photo/media?maxHeightPx=600&maxWidthPx=600&key=$apiKey"));
            }

            var landmarkData = LandmarkData(
              id: index = index + 1,
              placeID: place["id"],
              displayName: place["displayName"]["text"],
              location: Location(
                lat: place["location"]["latitude"],
                lng: place["location"]["longitude"],
              ),
              address: place["formattedAddress"],
              rating: place["rating"].runtimeType == int
                  ? place["rating"].toDouble()
                  : place["rating"],
              website: place["websiteUri"],
              phone: place["nationalPhoneNumber"],
              photos: photosArray,
            );

            landmarkDataList.landmarks.add(landmarkData);
          });

          if (mounted) {
            setState(() {
              isRequestingData = false;
            });

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LandmarkList(
                  landmarks: landmarkDataList,
                  flutterLocalNotificationsPlugin:
                      widget.flutterLocalNotificationsPlugin!,
                ),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No landmarks found within the specified radius.',
              ),
            ),
          );
          setState(() {
            isRequestingData = false;
          });
        }
      } else {
        print('Request failed with status: ${response.statusCode}.');
      }
    }
  }

  void showNotification() async {
    var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
      'landmark channel id',
      'Landmark Notifications',
      channelDescription: 'Landmark Notification Channel',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    var platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await widget.flutterLocalNotificationsPlugin!.show(
      0,
      'Searching...',
      'Landmarks within $_selectedRadius km of your location',
      platformChannelSpecifics,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Search Radius (km):', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 25),
                  DropdownButton<int>(
                    value: _selectedRadius,
                    menuMaxHeight: 250,
                    items: radiusOptions
                        .map((option) => DropdownMenuItem(
                            value: option, child: Text(option.toString())))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedRadius = value!;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 75),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: (widget.currentPosition == null || isRequestingData)? null : _submitRequest,
                  child: isRequestingData
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator())
                      : const Text('Search for Landmarks'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
