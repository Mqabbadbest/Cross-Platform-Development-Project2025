import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NewLandmarkRequest extends StatefulWidget {
  const NewLandmarkRequest({
    required this.currentPosition,
    super.key,
  });

  final Position? currentPosition;

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

  void _submitRequest() async {
    String? apiKey = dotenv.env['GOOGLE_API_KEY'];

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        isRequestingData = true;
      });

      var url =
          Uri.parse('https://places.googleapis.com/v1/places:searchNearby');

      var body = jsonEncode({
        "includedTypes": ["historical_landmark"],
        "excludedTypes": ["hotel", "lodging"],
        "locationRestriction": {
          "circle": {
            "center": {
              "latitude": "${widget.currentPosition!.latitude}",
              "longitude": "${widget.currentPosition!.longitude}"
            },
            "radius": _selectedRadius * 1000,
          },
        },
      });

      var response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "X-Goog-Api-Key": "$apiKey",
          "X-Goog-FieldMask":
              "places.displayName,places.id,places.location,places.photos,places.formattedAddress,places.types,places.websiteUri,places.rating,places.nationalPhoneNumber",
        },
        body: body,
      );

      if (response.statusCode == 200) {
        var responseString = jsonDecode(response.body);
        var places = responseString["places"];
        var photosArray = [];
        if (places != null) {
          places.forEach((place) {
            var name = place["displayName"]?["text"] ?? "Unknown";
            var photos = place["photos"] as List<dynamic>?;
            List<String> photosData = [];

            if (photos != null && photos.isNotEmpty) {
              for (int i = 0; i < photos.length && i < 3; i++) {
                if (photos[i]["name"] != null) {
                  photosData.add(photos[i]["name"]);
                } else {
                  photosData.add("No photo available");
                }
              }
            }

            while (photosData.length < 3) {
              photosData.add("No photo available");
            }

            var object = {"displayName": name, "photosData": photosData};
            photosArray.add(object);
          });

          var index = 2;
          var photoResource = photosArray[index];
          var urlPhotos = [];
          photoResource["photosData"].forEach((resource) {
            if (resource == "No photo available") {
              urlPhotos.add(null);
              return;
            }
            urlPhotos.add(
              Uri.parse(
                "https://places.googleapis.com/v1/${resource}/media?maxHeightPx=200&key=$apiKey",
              ),
            );
          });
          setState(() {
            isRequestingData = false;
          });
          print("${photosArray[index]["displayName"]}: ");
          print("${urlPhotos[0]} \n");
          print("${urlPhotos[1]} \n");
          print("${urlPhotos[2]} \n");
        } else {
          print("No places found.");
        }
      } else {
        print('Request failed with status: ${response.statusCode}.');
      }
    }
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
                  const Text('Radius (km):', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 25),
                  DropdownButton<int>(
                    value: _selectedRadius,
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
                  onPressed: _submitRequest,
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
