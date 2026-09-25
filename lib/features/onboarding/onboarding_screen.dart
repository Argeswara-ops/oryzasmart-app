import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardingPageData(
      icon: Icons.grass_rounded,
      title: 'Pantau Bibit Padi',
      description:
          'Lihat kondisi pembibitan secara ringkas agar keputusan harian lebih cepat.',
      color: AppTheme.primaryGreen,
    ),
    _OnboardingPageData(
      icon: Icons.sensors_rounded,
      title: 'Sensor Terhubung',
      description:
          'Cek suhu, kelembapan, dan status perangkat dari satu layar yang rapi.',
      color: AppTheme.infoBlue,
    ),
    _OnboardingPageData(
      icon: Icons.center_focus_strong_rounded,
      title: 'Deteksi Lebih Awal',
      description:
          'Gunakan pemantauan visual untuk mengenali risiko sebelum terlambat.',
      color: AppTheme.warning,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage == _pages.length - 1) {
      widget.onFinished();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final maxWidth = width > 520 ? 430.0 : double.infinity;
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: widget.onFinished,
                      child: const Text('Lewati'),
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _pages.length,
                      onPageChanged: (value) {
                        setState(() => _currentPage = value);
                      },
                      itemBuilder: (context, index) {
                        return _OnboardingPage(data: _pages[index]);
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppTheme.primaryGreen
                              : AppTheme.cardBorder,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _next,
                      icon: Icon(
                        isLastPage
                            ? Icons.login_rounded
                            : Icons.arrow_forward_rounded,
                      ),
                      label: Text(isLastPage ? 'Masuk Akun' : 'Lanjut'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data});

  final _OnboardingPageData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 164,
          height: 164,
          decoration: BoxDecoration(
            color: data.color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(data.icon, color: data.color, size: 74),
        ),
        const SizedBox(height: 34),
        Text(
          data.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppTheme.textStrong,
            fontSize: 27,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          data.description,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 1.55,
          ),
        ),
      ],
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
}
