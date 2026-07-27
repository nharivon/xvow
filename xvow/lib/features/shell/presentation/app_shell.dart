import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _tabs = [
    _TabData(Icons.home_rounded, 'Focus'),
    _TabData(Icons.flag_rounded, 'Plan'),
    _TabData(Icons.insights_rounded, 'Bilan'),
    _TabData(Icons.person_rounded, 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFF1E7DB)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              children: List.generate(_tabs.length, (index) {
                final tab = _tabs[index];
                final selected = navigationShell.currentIndex == index;
                return Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => navigationShell.goBranch(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF1F4E5F).withValues(alpha: 0.10)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedScale(
                            scale: selected ? 1.08 : 1.0,
                            duration: const Duration(milliseconds: 240),
                            child: Icon(
                              tab.icon,
                              size: 22,
                              color: selected
                                  ? const Color.fromARGB(255, 197, 138, 28)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tab.label,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: selected
                                  ? const Color.fromARGB(255, 197, 138, 28)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
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
}

class _TabData {
  const _TabData(this.icon, this.label);

  final IconData icon;
  final String label;
}
