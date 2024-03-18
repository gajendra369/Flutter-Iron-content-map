import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_database/firebase_database.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure widgets are initialized
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp( const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Map App',
      home: MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  MapScreenState createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  Location def=Location(latitude: 13.341685, longitude: 74.742130, name: "Udupi", ironContent:8 );
  final DatabaseReference databaseReference = FirebaseDatabase.instance.ref();
  List<Location> locations = [];
  Location? selectedLocation;

  @override
  void initState() {
    super.initState();
    _fetchLocations();
  }

  Future<void> _fetchLocations() async {
  DataSnapshot dataSnapshot = (await databaseReference.child('locations').once()).snapshot;
  List<Location> newLocations = [];
  if (dataSnapshot.value != null && dataSnapshot.value is Map<dynamic, dynamic>) {
    Map<dynamic, dynamic> values = dataSnapshot.value as Map<dynamic, dynamic>;


    values.forEach((key, value) {
      if (value is Map<Object?, Object?>) { // Adjust type check
        Map<Object?, Object?> mapValue = value;
        // Now you can safely access the mapValue and its contents
        // Remember to cast the keys and values to the appropriate types if necessary
        if (mapValue.containsKey('name') &&
            mapValue.containsKey('iron_content') &&
            mapValue.containsKey('latitude') &&
            mapValue.containsKey('longitude')) {
          dynamic latitudeValue = value['latitude'];
          double latitude = latitudeValue is double ? latitudeValue : double.tryParse(latitudeValue.toString()) ?? 0.0;

          // Handle longitude
          dynamic longitudeValue = value['longitude'];
          double longitude = longitudeValue is double ? longitudeValue : double.tryParse(longitudeValue.toString()) ?? 0.0;

          // Handle iron_content
          dynamic ironContentValue = value['iron_content'];
          double ironContent = ironContentValue is double ? ironContentValue : double.tryParse(ironContentValue.toString()) ?? 0.0;

          Location location = Location(
            latitude: latitude,
            longitude: longitude,
            name: value['name'] as String,
            ironContent: ironContent,
          );
          newLocations.add(location);
        }
      }
    });
    setState(() {
      locations = newLocations.cast<Location>();
    });
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iron Content of Udupi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: LocationSearchDelegate(locations, (selectedLocation) {
                  setState(() {
                    this.selectedLocation = selectedLocation;
                  });
                }),
              );
            },
          ),

        ],
      ),
      body: FlutterMap(
          options: const MapOptions(
            // ignore: deprecated_member_use
            center: LatLng(13.341685, 74.742130), // San Francisco Coordinates
            // ignore: deprecated_member_use
            zoom: 15.0,
          ),
          children: [
            TileLayer(
              urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
              subdomains: const ['a', 'b', 'c'],
            ),
            if (selectedLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    width: 200.0,
                    height: 80.0,
                    point: selectedLocation!.latLng,
                    // Use the child parameter instead of builder
                    child: Column(
                      children: [
                        Text(
                          selectedLocation!.name,
                          style: const TextStyle(fontWeight: FontWeight.bold), // Make the text bold
                        ),
                        Text(
                          'Iron_Content: ${selectedLocation!.ironContent} Mg/L',
                          style: const TextStyle(fontWeight: FontWeight.bold), // Make the text bold
                        ),
                        const SizedBox(
                          width: 30, // Adjust the width according to your preference
                          height: 30, // Adjust the height according to your preference
                          child: Icon(Icons.location_on, color: Colors.red, size: 40), // Set the size property to change the icon size
                        ),

                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
    );
  }
}

class LocationSearchDelegate extends SearchDelegate<Location> {
  Location def=Location(latitude: 13.3519045, longitude: 74.736725, name: "Udupi", ironContent:8 );
  final List<Location> locations;

  LocationSearchDelegate(this.locations, this.onLocationSelected);
  final Function(Location) onLocationSelected;

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, def);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final List<Location> searchResults = query.isEmpty
        ? locations
        : locations.where((location) => location.name.toLowerCase().contains(query.toLowerCase())).toList();

    return ListView.builder(
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        final Location location = searchResults[index];
        return ListTile(
          title: Text(location.name),
          onTap: () {
            onLocationSelected(location); // Call the callback function with the selected location
            close(context, location);
          },
        );
      },
    );
  }
}


class Location {
  final double latitude;
  final double longitude;
  final String name;
  final double ironContent;

  Location({
    required this.latitude,
    required this.longitude,
    required this.name,
    required this.ironContent,
  });

  factory Location.fromMap(Map<dynamic, dynamic> map) {
    return Location(
      latitude: map['latitude'],
      longitude: map['longitude'],
      name: map['name'],
      ironContent: map['iron_content'],
    );
  }

  LatLng get latLng => LatLng(latitude, longitude);
}
