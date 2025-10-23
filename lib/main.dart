import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/browse_screen.dart';
import 'screens/bookmarks_screen.dart';
import 'screens/outputs_screen.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request camera and microphone permissions for WebView access
  // This allows WKWebView to use getUserMedia API for WebRTC
  await Permission.camera.request();
  await Permission.microphone.request();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gradio Mobile',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
        textTheme: GoogleFonts.sourceSans3TextTheme(),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.transparent,
          indicatorColor: Colors.black.withValues(alpha: 0.06),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const BrowseScreen(),
    const BookmarksScreen(),
    const OutputsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Material(
            elevation: 0,
            borderRadius: BorderRadius.circular(24),
            color: Colors.transparent,
            shadowColor: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: NavigationBar(
                height: 40,
                selectedIndex: _currentIndex,
                onDestinationSelected: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.explore_outlined),
                    selectedIcon: Icon(Icons.explore),
                    label: 'Browse',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.favorite_border),
                    selectedIcon: Icon(Icons.favorite),
                    label: 'Favorites',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.outbox_outlined),
                    selectedIcon: Icon(Icons.outbox),
                    label: 'Outputs',
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