import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class OCRPharmacyResultsScreen extends StatefulWidget {
  final List<String> medicineQueries;
  const OCRPharmacyResultsScreen({super.key, required this.medicineQueries});

  @override
  State<OCRPharmacyResultsScreen> createState() => _OCRPharmacyResultsScreenState();
}

class _OCRPharmacyResultsScreenState extends State<OCRPharmacyResultsScreen> {
  Position? _pos;
  bool _locTried = false;

  @override
  void initState() {
    super.initState();
    _tryGetLocation();
  }

  Future<void> _tryGetLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final p = await Geolocator.getCurrentPosition();
        if (mounted) setState(() => _pos = p);
      }
    } catch (_) {
      // ignore location failures; still show pharmacies
    } finally {
      if (mounted) setState(() => _locTried = true);
    }
  }

  double? _distanceKm(Map<String, dynamic> userData) {
    if (_pos == null) return null;
    final lat = userData['latitude'];
    final lng = userData['longitude'];
    if (lat == null || lng == null) return null;
    final meters = Geolocator.distanceBetween(_pos!.latitude, _pos!.longitude, (lat as num).toDouble(), (lng as num).toDouble());
    return meters / 1000.0;
  }

  @override
  Widget build(BuildContext context) {
    final queries = widget.medicineQueries.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Available Pharmacies', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: queries.isEmpty
          ? const Center(child: Text('No medicine detected.'))
          : FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance.collection('medicines').get(),
              builder: (context, medsSnap) {
                if (medsSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!medsSnap.hasData) {
                  return const Center(child: Text('No medicines found.'));
                }

                final matched = medsSnap.data!.docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final brand = (data['brand'] ?? '').toString().toLowerCase();
                  final stock = (data['stockCount'] ?? 0) as num;
                  if (stock <= 0) return false;
                  return queries.any((q) {
                    final ql = q.toLowerCase();
                    return name.contains(ql) || brand.contains(ql);
                  });
                }).toList();

                final pharmacyIds = <String>{};
                for (final d in matched) {
                  final data = d.data() as Map<String, dynamic>;
                  final pid = (data['pharmacyId'] ?? '').toString();
                  if (pid.isNotEmpty) pharmacyIds.add(pid);
                }

                if (pharmacyIds.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text('No pharmacies found with detected medicines in stock.'),
                    ),
                  );
                }

                return FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .where('role', isEqualTo: 'pharmacist')
                      .where('isApproved', isEqualTo: true)
                      .get(),
                  builder: (context, usersSnap) {
                    if (usersSnap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!usersSnap.hasData) {
                      return const Center(child: Text('No pharmacies found.'));
                    }

                    final pharmacies = usersSnap.data!.docs
                        .where((d) => pharmacyIds.contains(d.id))
                        .map((d) => {'id': d.id, ...(d.data() as Map<String, dynamic>)})
                        .toList();

                    pharmacies.sort((a, b) {
                      final da = _distanceKm(a);
                      final db = _distanceKm(b);
                      if (da == null && db == null) return 0;
                      if (da == null) return 1;
                      if (db == null) return -1;
                      return da.compareTo(db);
                    });

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Detected medicines', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: queries
                                    .take(8)
                                    .map((m) => Chip(label: Text(m)))
                                    .toList(),
                              ),
                              if (_locTried && _pos == null) ...[
                                const SizedBox(height: 8),
                                Text('Tip: enable location to sort by nearest pharmacy.', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                              ]
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...pharmacies.map((p) {
                          final name = (p['pharmacyName'] ?? 'Pharmacy').toString();
                          final phone = (p['phone'] ?? '').toString();
                          final km = _distanceKm(p);
                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              side: BorderSide(color: Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.local_pharmacy, color: Colors.green.shade700),
                              ),
                              title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (phone.isNotEmpty) Text('Phone: $phone'),
                                  if (km != null) Text('${km.toStringAsFixed(1)} km away'),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                );
              },
            ),
    );
  }
}

