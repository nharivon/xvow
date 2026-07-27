import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'shared/widgets/mobile_frame.dart';

class XVowApp extends ConsumerWidget {
  const XVowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'XVOW',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: ref.watch(appRouterProvider),

      builder: (context, child) {
        return MobileFrame(
          child: child ?? const SizedBox(),
        );
      },
    );
  }
}
