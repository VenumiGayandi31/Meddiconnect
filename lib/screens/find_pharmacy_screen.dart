import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

// OOP Concepts Used:
// - Encapsulation: Data like _markers, _pharmacies, _currentPosition are kept private within the class
// - Inheritance: StatefulWidget and State classes are inherited
// - Abstraction: Complex logic (location handling, Firestore, map) is hidden behind methods
// - Polymorphism: Method overriding (createState, build, initState, dispose)

class FindPharmacyScreen extends StatefulWidget {
  const FindPharmacyScreen({super.key});

  @override
  // Creates the mutable state for this widget
  State<FindPharmacyScreen> createState() => _FindPharmacyScreenState();
}

// OOP Concepts Used:
// - Encapsulation: Private state variables control data internally
// - Inheritance: Extends State class
// - Abstraction: UI and logic separated into methods
class _FindPharmacyScreenState extends State<FindPharmacyScreen> {

  // Stores the Google Map controller to control map actions like camera movement
  GoogleMapController? _mapController;

  // Stores the user's current GPS position
  Position? _currentPosition;

  // Stores all map markers using MarkerId as key
  final Map<MarkerId, Marker> _markers = {};

  // Stores list of pharmacy data fetched from Firestore
  List<Map<String, dynamic>> _pharmacies = [];

  // Indicates whether the screen is still loading
  bool _isLoading = true;

  // Stores Firestore stream subscription to listen for real-time updates
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _pharmacySub;

  @override
  // Called when widget is first created; initializes location and pharmacy loading
  void initState() {
    super.initState();
    _initLocationAndPharmacies();
  }

  @override
  // Cleans up resources when widget is removed
  void dispose() {
    _pharmacySub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // Handles location permission, fetches current location, and starts loading pharmacies
  Future<void> _initLocationAndPharmacies() async {
    try {
      
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition();
        if (mounted) {
          setState(() {
            _currentPosition = position;
            _isLoading = false;
          });
          _loadPharmacies();
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Location permission denied")),
            );
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint("Error: $e");
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Location error: $e")),
          );
        });
      }
    }
  }

  // Fetches pharmacy data from Firestore and updates markers and list in real-time
  void _loadPharmacies() {
    _pharmacySub?.cancel();
    _pharmacySub = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'pharmacist')
        .where('isApproved', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      
      final Map<MarkerId, Marker> newMarkers = {};
      final List<Map<String, dynamic>> pharmacies = [];
      
      for (var doc in snapshot.docs) {
        var data = doc.data();
        if (data['latitude'] == null || data['longitude'] == null) continue;

        final markerId = MarkerId(doc.id);
        final marker = Marker(
          markerId: markerId,
          position: LatLng(data['latitude'], data['longitude']),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(
            title: data['pharmacyName'] ?? 'Pharmacy',
            snippet: "Location Captured ✅",
            // Avoid navigation here; keep tap safe.
          ),
        );
        newMarkers[markerId] = marker;

        pharmacies.add({
          'id': doc.id,
          ...data,
        });
      }
      
      setState(() {
        _markers
          ..clear()
          ..addAll(newMarkers);
        _pharmacies = pharmacies;
      });
    }, onError: (e) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load pharmacies: $e')),
        );
      });
    });
  }

  // Calculates distance (in KM) between user and a pharmacy
  double? _distanceKm(Map<String, dynamic> data) {
    if (_currentPosition == null) return null;
    final lat = data['latitude'];
    final lng = data['longitude'];
    if (lat == null || lng == null) return null;
    final meters = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      (lat as num).toDouble(),
      (lng as num).toDouble(),
    );
    return meters / 1000.0;
  }

  // Displays bottom sheet with sorted list of nearby pharmacies
  void _showPharmacyListSheet() {
    if (!mounted) return;
    final list = List<Map<String, dynamic>>.from(_pharmacies);
    list.sort((a, b) {
      final da = _distanceKm(a);
      final db = _distanceKm(b);
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final sheetHeight = MediaQuery.of(ctx).size.height * 0.70;
        return SafeArea(
          child: SizedBox(
            height: sheetHeight,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Nearby Pharmacies',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Showing ${list.length} verified pharmacies',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                      itemBuilder: (context, index) {
                        final p = list[index];
                        final name = (p['pharmacyName'] ?? 'Pharmacy').toString();
                        final phone = (p['phone'] ?? '').toString();
                        final km = _distanceKm(p);
                        return ListTile(
                          leading: const Icon(Icons.local_pharmacy, color: Colors.blueAccent),
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (phone.isNotEmpty) Text('Phone: $phone'),
                              if (km != null) Text('${km.toStringAsFixed(1)} km away'),
                            ],
                          ),
                          onTap: () {
                            final lat = p['latitude'];
                            final lng = p['longitude'];
                            if (lat is num && lng is num && _mapController != null) {
                              _mapController!.animateCamera(
                                CameraUpdate.newLatLngZoom(LatLng(lat.toDouble(), lng.toDouble()), 15),
                              );
                            }
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  // Builds the main UI of the screen
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Find Nearby Pharmacies', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                _currentPosition == null
                    ? const Center(child: Text("Location not available"))
                    : GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                          zoom: 13,
                        ),
                        onMapCreated: (controller) => _mapController = controller,
                        markers: Set<Marker>.of(_markers.values),
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        mapType: MapType.normal,
                        zoomControlsEnabled: false,
                        style: null, 
                      ),
                
                // Custom positioned container for status UI
                PositionContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildStatusCard(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // Builds the bottom status card showing number of pharmacies
  Widget _buildStatusCard() {
    final count = _markers.length;
    return InkWell(
      onTap: count == 0 ? null : _showPharmacyListSheet,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.local_pharmacy, color: Colors.blueAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Showing $count verified pharmacies near you',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.keyboard_arrow_up_rounded, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }
}

// Custom widget to position child at bottom of screen
class PositionContainer extends StatelessWidget {

  // Child widget to display inside positioned container
  final Widget child;

  // Padding applied to the container
  final EdgeInsets padding;

  const PositionContainer({super.key, required this.child, required this.padding});

  @override
  // Builds positioned widget at bottom of screen
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: child,
    );
  }
}
