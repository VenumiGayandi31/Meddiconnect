import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart';




const kPrimary  = Color(0xFF1A56DB);
const kDark     = Color(0xFF0F172A);
const kBg       = Color(0xFFF0F4FF);
const kApproved = Color(0xFF059669);
const kPending  = Color(0xFFD97706);
const kRejected = Color(0xFFDC2626);
const kCardBg   = Colors.white;
const kSubtext  = Color(0xFF94A3B8);


class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  int _selectedIndex = 0;
  bool _isBackfilling = false;

  final List<_NavItem> _navItems = const [
    _NavItem(label: 'Dashboard', icon: Icons.dashboard_rounded,    activeIcon: Icons.dashboard_rounded),
    _NavItem(label: 'Pending',   icon: Icons.access_time_outlined, activeIcon: Icons.access_time_filled),
    _NavItem(label: 'Approved',  icon: Icons.check_circle_outline, activeIcon: Icons.check_circle_rounded),
    _NavItem(label: 'Rejected',  icon: Icons.cancel_outlined,      activeIcon: Icons.cancel_rounded),
  ];

  void _logout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(28),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(color: kRejected.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.logout_rounded, color: kRejected, size: 30),
            ),
            const SizedBox(height: 16),
            const Text('Sign Out?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kDark)),
            const SizedBox(height: 8),
            const Text(
              'Are you sure you want to log out of the admin panel?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: kSubtext, height: 1.5),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await FirebaseAuth.instance.signOut();
                      if (mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kRejected,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                      shadowColor: kRejected.withOpacity(0.4),
                    ),
                    child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _backfillMedicinePharmacyIds() async {
    if (_isBackfilling) return;
    setState(() => _isBackfilling = true);
    try {
      // Build pharmacyName -> pharmacistUid map from users collection
      final pharmacistsSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'pharmacist')
          .get();

      final Map<String, String> pharmacyNameToUid = {};
      for (final doc in pharmacistsSnap.docs) {
        final data = doc.data();
        final name = (data['pharmacyName'] ?? '').toString().trim().toLowerCase();
        if (name.isNotEmpty) {
          pharmacyNameToUid[name] = doc.id;
        }
      }

      final medicinesSnap = await FirebaseFirestore.instance.collection('medicines').get();

      int updated = 0;
      int skippedNoMatch = 0;
      int skippedHasId = 0;

      WriteBatch batch = FirebaseFirestore.instance.batch();
      int batchOps = 0;

      Future<void> commitBatchIfNeeded({bool force = false}) async {
        if (batchOps == 0) return;
        if (force || batchOps >= 400) {
          await batch.commit();
          batch = FirebaseFirestore.instance.batch();
          batchOps = 0;
        }
      }

      for (final doc in medicinesSnap.docs) {
        final data = doc.data();
        final existing = data['pharmacyId'];
        if (existing != null && existing.toString().trim().isNotEmpty) {
          skippedHasId++;
          continue;
        }

        final pharmacyName = (data['pharmacyName'] ?? '').toString().trim().toLowerCase();
        final uid = pharmacyNameToUid[pharmacyName];
        if (uid == null || uid.isEmpty) {
          skippedNoMatch++;
          continue;
        }

        batch.update(doc.reference, {'pharmacyId': uid});
        batchOps++;
        updated++;
        await commitBatchIfNeeded();
      }

      await commitBatchIfNeeded(force: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Backfill complete. Updated: $updated, Skipped (already had id): $skippedHasId, Skipped (no match): $skippedNoMatch',
            ),
            backgroundColor: kApproved,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backfill error: $e'), backgroundColor: kRejected),
        );
      }
    } finally {
      if (mounted) setState(() => _isBackfilling = false);
    }
  }

  List<Widget> get _pages => [
    const _DashboardTab(),
    const _RequestsTab(status: 'pending'),
    const _RequestsTab(status: 'approved'),
    const _RequestsTab(status: 'rejected'),
  ];

  @override
  Widget build(BuildContext context) {
    final pageTitles = ['Dashboard', 'Pending Requests', 'Approved Requests', 'Rejected Requests'];

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: kDark),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text(pageTitles[_selectedIndex],
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kDark)),
        actions: [
          if (_selectedIndex == 0)
            IconButton(
              tooltip: 'Backfill medicine pharmacyId',
              onPressed: _isBackfilling ? null : _backfillMedicinePharmacyIds,
              icon: _isBackfilling
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync_rounded, color: kDark),
            ),
          Stack(
            children: [
              IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: kDark),
                  onPressed: () {}),
              Positioned(
                top: 10, right: 10,
                child: Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(color: kRejected, shape: BoxShape.circle)),
              ),
            ],
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_navItems.length, (i) {
                final item    = _navItems[i];
                final isActive = _selectedIndex == i;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive ? kPrimary.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(isActive ? item.activeIcon : item.icon,
                            color: isActive ? kPrimary : kSubtext, size: 22),
                        const SizedBox(height: 4),
                        Text(item.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                              color: isActive ? kPrimary : kSubtext,
                            )),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: kDark,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [kPrimary, Color(0xFF3B82F6)]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.medication_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PharmaAdmin',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                      Text('MANAGEMENT PANEL',
                          style: TextStyle(fontSize: 9, letterSpacing: 1.5, color: Color(0xFF64748B))),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFF1E293B), height: 1),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('NAVIGATION',
                    style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        letterSpacing: 2, color: Colors.white.withOpacity(0.3))),
              ),
            ),
            const SizedBox(height: 8),
            ...List.generate(_navItems.length, (i) {
              final item     = _navItems[i];
              final isActive = _selectedIndex == i;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                child: ListTile(
                  onTap: () {
                    setState(() => _selectedIndex = i);
                    Navigator.pop(context);
                  },
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: isActive ? kPrimary.withOpacity(0.15) : Colors.transparent,
                  leading: Icon(
                      isActive ? item.activeIcon : item.icon,
                      color: isActive ? const Color(0xFF60A5FA) : const Color(0xFF64748B),
                      size: 22),
                  title: Text(item.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive ? const Color(0xFF60A5FA) : const Color(0xFF94A3B8),
                      )),
                  trailing: i == 1
                      ? StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .where('role', isEqualTo: 'pharmacist')
                              .where('isApproved', isEqualTo: false)
                              .where('isRejected', isEqualTo: false)
                              .snapshots(),
                          builder: (_, snap) {
                            final count = snap.data?.docs.length ?? 0;
                            if (count == 0) return const SizedBox.shrink();
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                  color: kPending, borderRadius: BorderRadius.circular(20)),
                              child: Text('$count',
                                  style: const TextStyle(
                                      fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                            );
                          },
                        )
                      : null,
                ),
              );
            }),
            const Spacer(),
            const Divider(color: Color(0xFF1E293B), height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                              colors: [Color(0xFF7C3AED), Color(0xFFA855F7)]),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text('A',
                              style: TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Admin User',
                              style: TextStyle(
                                  color: Color(0xFFE2E8F0), fontSize: 14, fontWeight: FontWeight.w700)),
                          Text('Super Administrator',
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _logout();
                      },
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Sign Out',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kRejected,
                        side: BorderSide(color: kRejected.withOpacity(0.4)),
                        backgroundColor: kRejected.withOpacity(0.08),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}



class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'pharmacist')
          .snapshots(),
      builder: (context, totalSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'pharmacist')
              .where('isApproved', isEqualTo: true)
              .snapshots(),
          builder: (context, approvedSnap) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'pharmacist')
                  .where('isRejected', isEqualTo: true)
                  .snapshots(),
              builder: (context, rejectedSnap) {
                final total    = totalSnap.data?.docs.length ?? 0;
                final approved = approvedSnap.data?.docs.length ?? 0;
                final rejected = rejectedSnap.data?.docs.length ?? 0;
                final pending  = total - approved - rejected;

                final recentDocs = totalSnap.data?.docs.take(4).toList() ?? [];

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Welcome back, Admin 👋',
                          style: TextStyle(fontSize: 14, color: kSubtext)),
                      const SizedBox(height: 16),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.4,
                        children: [
                          _StatWidget(label: 'Total',    value: total,    icon: Icons.people_alt_rounded,   colors: const [kPrimary, Color(0xFF3B82F6)], sub: 'All pharmacists'),
                          _StatWidget(label: 'Approved', value: approved, icon: Icons.check_circle_rounded, colors: const [kApproved, Color(0xFF10B981)], sub: 'Active accounts'),
                          _StatWidget(label: 'Pending',  value: pending,  icon: Icons.access_time_rounded,  colors: const [kPending, Color(0xFFF59E0B)],  sub: 'Awaiting review'),
                          _StatWidget(label: 'Rejected', value: rejected, icon: Icons.cancel_rounded,       colors: const [kRejected, Color(0xFFEF4444)], sub: 'Not approved'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: kCardBg,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12)],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Request Breakdown',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: kDark)),
                            const SizedBox(height: 16),
                            _BreakdownBar(label: 'Approved', count: approved, total: total, color: kApproved),
                            const SizedBox(height: 12),
                            _BreakdownBar(label: 'Pending',  count: pending,  total: total, color: kPending),
                            const SizedBox(height: 12),
                            _BreakdownBar(label: 'Rejected', count: rejected, total: total, color: kRejected),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: kCardBg,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12)],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Recent Activity',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: kDark)),
                            const SizedBox(height: 14),
                            if (recentDocs.isEmpty)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text('No recent activity', style: TextStyle(color: kSubtext)),
                                ),
                              )
                            else
                              ...recentDocs.map((doc) {
                                final data      = doc.data() as Map<String, dynamic>;
                                final name      = data['pharmacyName'] ?? 'Unknown';
                                final initials  = (name.isNotEmpty) ? name[0].toUpperCase() : '?';
                                final isApproved = data['isApproved'] == true;
                                final isRejected = data['isRejected'] == true;
                                final status    = isApproved ? 'approved' : isRejected ? 'rejected' : 'pending';

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(12)),
                                    child: Row(
                                      children: [
                                        _AvatarWidget(initials: initials, size: 38),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(name,
                                                  style: const TextStyle(
                                                      fontSize: 13, fontWeight: FontWeight.w700, color: kDark)),
                                              Text(data['phone'] ?? '',
                                                  style: const TextStyle(fontSize: 11, color: kSubtext)),
                                            ],
                                          ),
                                        ),
                                        _StatusBadge(status: status),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}



class _RequestsTab extends StatefulWidget {
  final String status; 
  const _RequestsTab({required this.status});

  @override
  State<_RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends State<_RequestsTab> {
  String _search = '';

  Query get _query {
    final base = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'pharmacist');
    switch (widget.status) {
      case 'approved': return base.where('isApproved', isEqualTo: true);
      case 'rejected': return base.where('isRejected', isEqualTo: true);
      default:         return base.where('isApproved', isEqualTo: false).where('isRejected', isEqualTo: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final allDocs = snapshot.data!.docs;
        final filtered = _search.isEmpty
            ? allDocs
            : allDocs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final q    = _search.toLowerCase();
                return (data['pharmacyName'] ?? '').toLowerCase().contains(q) ||
                       (data['phone'] ?? '').toLowerCase().contains(q);
              }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'Search by pharmacy name or phone...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final doc = filtered[i];
                  return _PharmacistCard(uid: doc.id, data: doc.data() as Map<String, dynamic>, status: widget.status);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PharmacistCard extends StatelessWidget {
  final String uid, status;
  final Map<String, dynamic> data;
  const _PharmacistCard({required this.uid, required this.data, required this.status});

  String get _name => data['pharmacyName'] ?? 'Unknown Pharmacy';
  String get _initials => (_name.isNotEmpty) ? _name[0].toUpperCase() : '?';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _AvatarWidget(initials: _initials, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: kDark)),
                    Text(data['fullName'] ?? 'No Name', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kSubtext)),
                    _StatusBadge(status: status),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showDetail(context),
                icon: const Icon(Icons.arrow_forward_ios, size: 16, color: kSubtext),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.6,
            children: [
              _InfoTile(emoji: '🏥', label: 'Pharmacy License', value: data['pharmacy_license_no'] ?? 'N/A'),
              _InfoTile(emoji: '🪪', label: 'SLMC Reg',         value: data['slmc_registration_no'] ?? 'N/A'),
              _InfoTile(emoji: '📱', label: 'Phone',            value: data['phone'] ?? 'N/A'),
              _InfoTile(emoji: '📋', label: 'Trade License',    value: data['trade_license_no'] ?? 'N/A'),
            ],
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: kSubtext.withOpacity(0.3), borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _AvatarWidget(initials: _initials, size: 60),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: kDark)),
                      Text(data['fullName'] ?? 'No Name', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kSubtext)),
                      _StatusBadge(status: status),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _detailRow('Pharmacist Full Name', data['fullName'], Icons.person_outline_rounded),
                  _detailRow('Phone Number', data['phone'], Icons.phone_android_rounded),
                  _detailRow('Trade License', data['trade_license_no'], Icons.assignment_rounded),
                  _detailRow('Pharmacy License', data['pharmacy_license_no'], Icons.local_hospital_rounded),
                  _detailRow('SLMC Registration', data['slmc_registration_no'], Icons.badge_rounded),
                  _detailRow('Email Address', data['email'], Icons.email_rounded),
                ],
              ),
            ),
            if (status == 'pending') 
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateUserStatus(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kApproved, foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Approve', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateUserStatus(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kRejected, side: const BorderSide(color: kRejected),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String title, dynamic value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: kPrimary.withOpacity(0.7)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, color: kSubtext, fontWeight: FontWeight.bold)),
              Text(value?.toString() ?? 'N/A', style: const TextStyle(fontSize: 15, color: kDark, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _updateUserStatus(BuildContext context, bool isApprove) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'isApproved': isApprove,
        'isRejected': !isApprove,
        'status': isApprove ? 'approved' : 'rejected',
      });
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isApprove ? 'Pharmacist Approved Successfully!' : 'Pharmacist Rejected'),
            backgroundColor: isApprove ? kApproved : kRejected,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error updating status: $e");
    }
  }
}


class _NavItem {
  final String label;
  final IconData icon, activeIcon;
  const _NavItem({required this.label, required this.icon, required this.activeIcon});
}



class _StatWidget extends StatelessWidget {
  final String label, sub;
  final int value;
  final IconData icon;
  final List<Color> colors;
  const _StatWidget({required this.label, required this.value, required this.icon, required this.colors, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.8), size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$value', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BreakdownBar extends StatelessWidget {
  final String label;
  final int count, total;
  final Color color;
  const _BreakdownBar({required this.label, required this.count, required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    double progress = total == 0 ? 0 : count / total;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Text('$count', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(value: progress, backgroundColor: kBg, color: color, minHeight: 6),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String emoji, label, value;
  const _InfoTile({required this.emoji, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$emoji $label', style: const TextStyle(fontSize: 9, color: kSubtext, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: kDark), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color = status == 'approved' ? kApproved : status == 'rejected' ? kRejected : kPending;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900)),
    );
  }
}

class _AvatarWidget extends StatelessWidget {
  final String initials;
  final double size;
  const _AvatarWidget({required this.initials, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: const BoxDecoration(color: Color(0xFFE2E8F0), shape: BoxShape.circle),
      child: Center(child: Text(initials, style: TextStyle(color: kDark, fontWeight: FontWeight.w800, fontSize: size * 0.35))),
    );
  }
}
