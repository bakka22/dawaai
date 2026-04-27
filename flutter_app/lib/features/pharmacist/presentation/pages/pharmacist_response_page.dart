import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/pharmacist_state.dart';

class PharmacistResponsePage extends ConsumerStatefulWidget {
  final int quoteId;

  const PharmacistResponsePage({super.key, required this.quoteId});

  @override
  ConsumerState<PharmacistResponsePage> createState() =>
      _PharmacistResponsePageState();
}

class _PharmacistResponsePageState
    extends ConsumerState<PharmacistResponsePage> {
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitResponse() async {
    final price = double.tryParse(_priceController.text);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('الرجاء إدخال سعر صحيح')));
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await ref
        .read(pharmacistProvider.notifier)
        .submitResponse(
          quoteId: widget.quoteId,
          totalPrice: price,
          notes: _notesController.text.isNotEmpty
              ? _notesController.text
              : null,
        );

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم إرسال العرض بنجاح')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pharmacistProvider);
    final quote = state.pendingQuotes
        .where((q) => q.quoteId == widget.quoteId)
        .firstOrNull;

    if (quote == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('العرض')),
        body: const Center(child: Text('لم يتم العثور على العرض')),
      );
    }

    final timeRemaining = quote.expiresAt.difference(DateTime.now());
    final minutesLeft = timeRemaining.inMinutes;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الرد على العرض'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: minutesLeft < 5
                      ? Colors.red.shade50
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer,
                      color: minutesLeft < 5 ? Colors.red : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'متبقي $minutesLeft دقيقة',
                      style: TextStyle(
                        color: minutesLeft < 5 ? Colors.red : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'الأدوية المطلوبة:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...quote.items.map(
                (item) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: Checkbox(
                      value: item.isOutOfStock,
                      onChanged: (value) {
                        ref
                            .read(pharmacistProvider.notifier)
                            .toggleItemOutOfStock(
                              widget.quoteId,
                              item.medicationId,
                            );
                      },
                    ),
                    title: Text(item.name),
                    subtitle: item.isOutOfStock
                        ? const Text(
                            'غير متوفر',
                            style: TextStyle(color: Colors.red),
                          )
                        : const Text(
                            'متوفر',
                            style: TextStyle(color: Colors.green),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'سعر العرض:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'أدخل السعر الإجمالي',
                  prefixText: ' SDG ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'ملاحظات (اختياري):',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'أضف ملاحظاتك هنا',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitResponse,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('إرسال العرض'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
