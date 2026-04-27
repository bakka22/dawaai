import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/data/auth_state.dart';

void main() {
  runApp(const ProviderScope(child: DawaaiApp()));
}

class DawaaiApp extends StatelessWidget {
  const DawaaiApp({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('Riverpod Ready');
    return MaterialApp(
      title: 'Dawaai',
      locale: const Locale('ar'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar'), Locale('en')],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState.status == AuthStatus.authenticated) {
      return const HomePage();
    }

    return const LoginPage();
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('دواي'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: const Directionality(
        textDirection: TextDirection.rtl,
        child: Center(child: Text('Dawaai App - Authenticated!')),
      ),
    );
  }
}
