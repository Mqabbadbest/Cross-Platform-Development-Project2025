import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:landmark_finder/models/landmark_data.dart';
import 'package:url_launcher/url_launcher.dart';

class LandmarkList extends StatelessWidget {
  final LandmarkDataList landmarks;

  const LandmarkList({super.key, required this.landmarks});

///
/// Builds the UI for the LandmarkList widget.
/// 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nearby Landmarks")),
      body: landmarks.landmarks.isEmpty
          ? const Center(child: Text("No landmarks found."))
          : ListView.builder(
              itemCount: landmarks.landmarks.length,
              itemBuilder: (context, index) {
                final landmark = landmarks.landmarks[index];

                return Card(
                  margin: const EdgeInsets.all(12),
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.hardEdge,
                  color: Colors.grey[800],
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        print("Tapped on ${landmark.displayName}");
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: FadeInImage(
                                placeholder: const AssetImage("assets/1x1.png"),
                                image: landmark.photos![0].toString() !=
                                        'assets/images/ImagePlaceholder.jpg'
                                    ? NetworkImage(
                                        landmark.photos![0].toString())
                                    : const AssetImage(
                                        "assets/images/ImagePlaceholder.jpg"),
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    landmark.displayName.toUpperCase(),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "⭐ Rating: ${landmark.rating ?? 'N/A'}",
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Column(children: [
                                  Row(children: <Widget>[
                                    Expanded(
                                      child: Container(
                                          margin: const EdgeInsets.only(
                                              left: 10.0, right: 20.0),
                                          child: const Divider(
                                            color: Colors.white,
                                            height: 36,
                                          )),
                                    ),
                                    const Text("Landmark Details"),
                                    Expanded(
                                      child: Container(
                                          margin: const EdgeInsets.only(
                                              left: 20.0, right: 10.0),
                                          child: const Divider(
                                            color: Colors.white,
                                            height: 36,
                                          )),
                                    ),
                                  ]),
                                ])),
                            Text(
                              landmark.address ?? "Address not available",
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16),
                            ),

                            const SizedBox(height: 8),
                            if (landmark.website != null)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => launchURL(landmark.website!, context),
                                  icon: const Icon(Icons.language,
                                      color: Colors.black),
                                  label: const Text("Go to Website",
                                      style: TextStyle(color: Colors.black)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color.fromARGB(255, 255, 145, 0),
                                  ),
                                ),
                              ),

                            const SizedBox(height: 8),
                            if (landmark.phone != null)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => launchPhone(landmark.phone!),
                                  icon: const Icon(Icons.phone,
                                      color: Colors.white),
                                  label: Text("Call ${landmark.phone}",
                                      style:
                                          const TextStyle(color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                ),
                              ),

                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => openGoogleMaps(
                                        landmark.location.lat,
                                        landmark.location.lng),
                                    icon: Image.asset(
                                      "assets/Simpleicons-Team-Simple-Google-maps.48.png",
                                      width: 24,
                                      height: 24,
                                    ),
                                    label: const Text("Maps",
                                        style: TextStyle(color: Colors.black)),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        )),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Waze Button
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => openWaze(
                                        landmark.location.lat,
                                        landmark.location.lng),
                                    icon: Image.asset(
                                      "assets/waze_logo.png",
                                      width: 24, 
                                      height: 24,
                                    ),
                                    label: const Text("Waze",
                                        style: TextStyle(color: Colors.white)),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF09B1EB),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        )),
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }


///
/// Launches the given [url] in the appropriate application.
/// If the URL cannot be opened, a fallback WebView mode is used.
/// If the URL still cannot be opened, a SnackBar is shown.
///
  void launchURL(String url, BuildContext context) async {
  final Uri uri = Uri.parse(url);

  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  } else {
    debugPrint("Could not open URL: $url. Trying WebView mode...");
    
    // Try opening inside WebView as a fallback
    bool webViewSuccess = await launchUrl(uri, mode: LaunchMode.inAppWebView);
    
    if (!webViewSuccess) {
      debugPrint("Still could not open URL: $url");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No application found to open this link."),
        ),
      );
    }
  }
}

///
/// Launches the phone dial pad with the given [phoneNumber].
///
  void launchPhone(String phoneNumber) async {
    String formattedPhoneNumber = phoneNumber.replaceAll(" ", "");
    Uri url = Uri(scheme: "tel", path: formattedPhoneNumber);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      print("Can't open dial pad.");
    }
  }

///
/// Opens Google Maps with the given latitude [lat] and longitude [lng].
///
  void openGoogleMaps(double lat, double lng) async {
    final Uri googleMapsUri =
        Uri(scheme: "google.navigation", queryParameters: {
          'q': '$lat,$lng'
        });
    if (await canLaunchUrl(googleMapsUri)) {
      await launchUrl(googleMapsUri);
    } else {
      print("Could not open Google Maps.");
    }
  }

///
/// Opens Waze with the given latitude [lat] and longitude [lng].
///   
  void openWaze(double lat, double lng) async {
    final Uri wazeUri =
        Uri.parse("https://waze.com/ul?ll=$lat,$lng&navigate=yes");
    if (await canLaunchUrl(wazeUri)) {
      await launchUrl(wazeUri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Could not open Waze.");
    }
  }
}