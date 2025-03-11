import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const MaterialApp(
    home: MainApp(),
    debugShowCheckedModeBanner: false,
  ));
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() {
    return MainAppState();
  }
}

class MainAppState extends State<MainApp> {
  Position? currentPosition;
  Stream<Position>? positionStream;

  @override
  void initState() {
    super.initState();
    getLocationAndListen();
  }

  void getLocationAndListen() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );

    positionStream!.listen((Position position) {
      setState(() {
        currentPosition = position;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Updates'),
      ),
      body: Center(
        child: currentPosition != null
            ? Text(
                "Latitude: ${currentPosition!.latitude}, Longitude: ${currentPosition!.longitude}",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18))
            : const Text("Waiting for location updates...",
                textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
