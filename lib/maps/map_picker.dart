import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class MapPickerPage extends StatefulWidget {
  final LatLng? pickup;
  final LatLng? dropoff;

  const MapPickerPage({super.key, this.pickup, this.dropoff});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  GoogleMapController? mapController;

  LatLng? selectedLocation;

  LatLng? pickupLocation;
  LatLng? dropoffLocation;

  final TextEditingController searchController = TextEditingController();

  Timer? debounce;
  List predictions = [];

  final String apiKey = "AIzaSyAnTSfPxICAo0rQu56IK9aRmmlykCWSLgw";

  @override
  void initState() {
    super.initState();

    pickupLocation = widget.pickup;
    dropoffLocation = widget.dropoff;

    getCurrentLocation();
  }

  /// GET USER LOCATION
  Future<void> getCurrentLocation() async {
    await Geolocator.requestPermission();

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      selectedLocation = LatLng(position.latitude, position.longitude);
    });

    if (selectedLocation != null) {
      mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(selectedLocation!, 15),
      );
    }
  }

  /// SEARCH PLACES
  void onSearchChanged(String value) {
    if (debounce?.isActive ?? false) debounce!.cancel();

    debounce = Timer(const Duration(milliseconds: 500), () {
      searchPlaces(value);
    });
  }

  Future<void> searchPlaces(String input) async {
    if (input.isEmpty) {
      setState(() => predictions = []);
      return;
    }

    final url =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$apiKey";

    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    setState(() {
      predictions = data["predictions"];
    });
  }

  /// SELECT PLACE
  Future<void> selectPlace(String placeId) async {
    final url =
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$apiKey";

    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    final location = data["result"]["geometry"]["location"];

    final latLng = LatLng(location["lat"], location["lng"]);

    setState(() {
      selectedLocation = latLng;
      predictions = [];
      searchController.text = data["result"]["formatted_address"];
    });

    mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
  }

  /// CONFIRM LOCATION
  void confirmLocation() {
    if (selectedLocation == null) return;

    Navigator.pop(context, {
      "address": searchController.text.isNotEmpty
          ? searchController.text
          : "Selected Location",
      "lat": selectedLocation!.latitude,
      "lng": selectedLocation!.longitude,
    });
  }

  /// BUILD MARKERS
  Set<Marker> buildMarkers() {
    Set<Marker> markers = {};

    if (selectedLocation == null) return markers;

    markers.add(
      Marker(
        markerId: const MarkerId("selected"),
        position: selectedLocation!,
        draggable: true,
        onDragEnd: (pos) {
          setState(() {
            selectedLocation = pos;
          });
        },
      ),
    );

    if (pickupLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId("pickup"),
          position: pickupLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
    }

    if (dropoffLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId("dropoff"),
          position: dropoffLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// GOOGLE MAP
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: selectedLocation ?? const LatLng(0, 0),
              zoom: 14,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            onMapCreated: (controller) {
              mapController = controller;
            },
            markers: buildMarkers(),
          ),

          /// SEARCH BAR
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  child: TextField(
                    controller: searchController,
                    onChanged: onSearchChanged,
                    decoration: const InputDecoration(
                      hintText: "Search place",
                      prefixIcon: Icon(Icons.search),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(14),
                    ),
                  ),
                ),

                if (predictions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: predictions.length,
                      itemBuilder: (context, index) {
                        final place = predictions[index];

                        return ListTile(
                          title: Text(place["description"]),
                          onTap: () {
                            selectPlace(place["place_id"]);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          /// LOCATE ME BUTTON
          Positioned(
            bottom: 90,
            right: 16,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: getCurrentLocation,
              child: const Icon(Icons.my_location, color: Colors.black),
            ),
          ),

          /// CONFIRM CHECK BUTTON
          Positioned(
            bottom: 20,
            right: 16,
            child: FloatingActionButton(
              backgroundColor: Colors.black,
              onPressed: confirmLocation,
              child: const Icon(Icons.check, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
