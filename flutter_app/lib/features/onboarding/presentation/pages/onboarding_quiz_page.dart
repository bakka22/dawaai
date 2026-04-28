import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/data/auth_state.dart';
import '../../data/onboarding_service.dart';

class OnboardingQuizPage extends ConsumerStatefulWidget {
  const OnboardingQuizPage({super.key});

  @override
  ConsumerState<OnboardingQuizPage> createState() => _OnboardingQuizPageState();
}

class _OnboardingQuizPageState extends ConsumerState<OnboardingQuizPage> {
  int _currentQuestion = 0;
  String? _selectedSkinType;
  final List<String> _selectedConcerns = [];
  bool _isLoading = false;

  final List<Map<String, dynamic>> _questions = [
    {
      'title': 'ما هو نوع بشرتك؟',
      'options': [
        {'value': 'normal', 'label': 'عادية'},
        {'value': 'dry', 'label': 'جافة'},
        {'value': 'oily', 'label': 'دهنية'},
        {'value': 'combination', 'label': 'مختلطة'},
        {'value': 'sensitive', 'label': 'حساسة'},
      ],
    },
    {
      'title': 'ما هي مشاكل بشرتك الرئيسية؟ (اختر كل ما ينطبق)',
      'options': [
        {'value': 'acne', 'label': 'حب الشباب'},
        {'value': 'aging', 'label': 'تجاعيد'},
        {'value': 'dark_spots', 'label': 'بقع داكنة'},
        {'value': 'dryness', 'label': 'جفاف'},
        {'value': 'oiliness', 'label': 'دهون زائدة'},
        {'value': 'redness', 'label': 'احمرار'},
      ],
    },
    {
      'title': 'ما مدى حساسية بشرتك؟',
      'options': [
        {'value': 'low', 'label': 'غير حساسة'},
        {'value': 'medium', 'label': 'متوسطة'},
        {'value': 'high', 'label': 'حساسة جداً'},
      ],
    },
    {
      'title': 'هل تستخدمين منتجات العناية حالياً؟',
      'options': [
        {'value': 'yes', 'label': 'نعم'},
        {'value': 'no', 'label': 'لا'},
        {'value': 'sometimes', 'label': 'أحياناً'},
      ],
    },
  ];

  void _nextQuestion() {
    if (_currentQuestion < _questions.length - 1) {
      setState(() => _currentQuestion++);
    } else {
      _saveProfile();
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      final authState = ref.read(authProvider);
      if (authState.userId != null) {
        await ref
            .read(onboardingServiceProvider)
            .saveProfile(
              userId: authState.userId!,
              skinType: _selectedSkinType ?? 'normal',
              concerns: _selectedConcerns,
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حفظ ملفك الشخصي بنجاح')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ: ${e.toString()}')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = _questions[_currentQuestion];
    final progress = (_currentQuestion + 1) / _questions.length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('اختباري الشخصي'),
          backgroundColor: Colors.pink,
          foregroundColor: Colors.white,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade200,
                  color: Colors.pink,
                ),
                const SizedBox(height: 8),
                Text(
                  'السؤال ${_currentQuestion + 1} من ${_questions.length}',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),
                Text(
                  question['title'] as String,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ...(question['options'] as List).map((option) {
                  final isMultiSelect = _currentQuestion == 1;
                  final isSelected = isMultiSelect
                      ? _selectedConcerns.contains(option['value'])
                      : _selectedSkinType == option['value'];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          if (isMultiSelect) {
                            if (isSelected) {
                              _selectedConcerns.remove(option['value']);
                            } else {
                              _selectedConcerns.add(option['value']);
                            }
                          } else {
                            _selectedSkinType = option['value'];
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.pink.withValues(alpha: 0.1)
                              : Colors.white,
                          border: Border.all(
                            color: isSelected
                                ? Colors.pink
                                : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            if (isMultiSelect)
                              Checkbox(
                                value: isSelected,
                                onChanged: (_) {},
                                activeColor: Colors.pink,
                              ),
                            Expanded(
                              child: Text(
                                option['label'] as String,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const Spacer(),
                ElevatedButton(
                  onPressed: _isLoading ? null : _nextQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _currentQuestion < _questions.length - 1
                              ? 'التالي'
                              : 'حفظ وإرسال',
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
