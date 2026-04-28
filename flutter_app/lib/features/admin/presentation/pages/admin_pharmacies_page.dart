import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/admin_service.dart';

class AdminPharmaciesPage extends ConsumerStatefulWidget {
  const AdminPharmaciesPage({super.key});

  @override
  ConsumerState<AdminPharmaciesPage> createState() =>
      _AdminPharmaciesPageState();
}

class _AdminPharmaciesPageState extends ConsumerState<AdminPharmaciesPage> {
  String _filter = 'all';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPharmacies();
  }

  Future<void> _loadPharmacies() async {
    setState(() => _isLoading = true);
    try {
      final status = _filter == 'all' ? null : _filter;
      await ref.read(adminServiceProvider).getPharmacies(status: status);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _approvePharmacy(int id, bool approved) async {
    try {
      await ref
          .read(adminServiceProvider)
          .approvePharmacy(id, approved: approved);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              approved ? 'تمت الموافقة على الصيدلية' : 'تم رفض الصيدلية',
            ),
            backgroundColor: approved ? Colors.green : Colors.red,
          ),
        );
        _loadPharmacies();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminService = ref.watch(adminServiceProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدارة الصيدليات'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadPharmacies,
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'الكل',
                    selected: _filter == 'all',
                    onTap: () {
                      setState(() => _filter = 'all');
                      _loadPharmacies();
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'معلقة',
                    selected: _filter == 'pending',
                    onTap: () {
                      setState(() => _filter = 'pending');
                      _loadPharmacies();
                    },
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'معتمدة',
                    selected: _filter == 'approved',
                    onTap: () {
                      setState(() => _filter = 'approved');
                      _loadPharmacies();
                    },
                    color: Colors.green,
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : FutureBuilder(
                      future: adminService.getPharmacies(
                        status: _filter == 'all' ? null : _filter,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text('خطأ: ${snapshot.error}'));
                        }
                        final pharmacies = snapshot.data ?? [];
                        if (pharmacies.isEmpty) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.local_pharmacy,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'لا توجد صيدليات',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          );
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: pharmacies.length,
                          itemBuilder: (context, index) {
                            final pharmacy =
                                pharmacies[index] as Map<String, dynamic>;
                            return _PharmacyCard(
                              pharmacy: pharmacy,
                              onApprove: () =>
                                  _approvePharmacy(pharmacy['id'], true),
                              onReject: () =>
                                  _approvePharmacy(pharmacy['id'], false),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? chipColor : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _PharmacyCard extends StatelessWidget {
  final Map<String, dynamic> pharmacy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PharmacyCard({
    required this.pharmacy,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final isApproved = pharmacy['is_approved'] as bool? ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    pharmacy['name'] ?? 'صيدلية',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isApproved
                        ? Colors.green.shade100
                        : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isApproved ? 'معتمدة' : 'معلقة',
                    style: TextStyle(
                      color: isApproved ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${pharmacy['city'] ?? ''} - ${pharmacy['address'] ?? ''}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  pharmacy['phone'] ?? pharmacy['owner_phone'] ?? '',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            if (!isApproved) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: const Text(
                        'رفض',
                        style: TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(Icons.check),
                      label: const Text('موافقة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
