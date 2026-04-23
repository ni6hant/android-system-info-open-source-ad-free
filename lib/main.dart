// ============================================================
// main.dart — Entry point of our System Information app
// ============================================================

// Flutter's material design library — gives us widgets like
// Scaffold, AppBar, Text, Column etc.
// Docs: https://api.flutter.dev/flutter/material/material-library.html
import 'package:flutter/material.dart';

// This is the package we installed via 'flutter pub add device_info_plus'
// It wraps Android's Build class and gives us device information
// Docs: https://pub.dev/packages/device_info_plus
import 'package:device_info_plus/device_info_plus.dart';

// ============================================================
// main() — Every Dart program starts here, no exceptions.
// runApp() inflates the given widget and attaches it to the screen.
// Docs: https://api.flutter.dev/flutter/widgets/runApp.html
// ============================================================
void main() {
  runApp(const SystemInfoApp());
}

// ============================================================
// SystemInfoApp — The root widget of our application.
//
// This is a StatelessWidget because the app shell itself never
// changes — it just sets up the theme and points to our home screen.
//
// Think of this as the frame of a painting, not the painting itself.
// Docs: https://api.flutter.dev/flutter/widgets/StatelessWidget-class.html
// ============================================================
class SystemInfoApp extends StatelessWidget {
  const SystemInfoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // The title shows up in the app switcher on Android
      title: 'System Info',

      // debugShowCheckedModeBanner removes the red DEBUG banner
      // in the top right corner during development
      debugShowCheckedModeBanner: false,

      // ThemeData controls the visual appearance of the entire app
      // Docs: https://api.flutter.dev/flutter/material/ThemeData-class.html
      theme: ThemeData(
        // useMaterial3 opts into the latest Material Design spec
        // Docs: https://m3.material.io/
        useMaterial3: true,

        // ColorScheme.fromSeed generates a full color palette from
        // a single seed color — we're using a dark techy green
        // Docs: https://api.flutter.dev/flutter/material/ColorScheme/ColorScheme.fromSeed.html
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          // brightness controls light vs dark mode
          brightness: Brightness.dark,
        ),
      ),

      // home is the first screen that loads when the app opens
      home: const SystemInfoScreen(),
    );
  }
}

// ============================================================
// SystemInfoScreen — The actual screen that displays system info.
//
// This is a StatefulWidget because we need to:
// 1. Fetch device info asynchronously (it takes a moment)
// 2. Store the fetched data and trigger a UI rebuild when ready
//
// Docs: https://api.flutter.dev/flutter/widgets/StatefulWidget-class.html
// ============================================================
class SystemInfoScreen extends StatefulWidget {
  const SystemInfoScreen({super.key});

  @override
  State<SystemInfoScreen> createState() => _SystemInfoScreenState();
}

// ============================================================
// _SystemInfoScreenState — The state that belongs to SystemInfoScreen.
//
// The underscore prefix means this class is private to this file.
// This is where our data lives and where the UI gets built.
// ============================================================
class _SystemInfoScreenState extends State<SystemInfoScreen> {

  // This will hold all the device info once fetched.
  // It's nullable (the ? mark) because it starts as null before
  // the async fetch completes.
  // Docs: https://developer.android.com/reference/android/os/Build
  AndroidDeviceInfo? _deviceInfo;

  // This flag tracks whether we're still loading data.
  // We'll show a loading spinner while this is true.
  bool _isLoading = true;

  // ============================================================
  // initState() — Called exactly once when this widget is first
  // inserted into the widget tree. This is the right place to
  // trigger one-time data fetching.
  // Docs: https://api.flutter.dev/flutter/widgets/State/initState.html
  // ============================================================
  @override
  void initState() {
    super.initState(); // Always call super first
    _fetchDeviceInfo(); // Start fetching as soon as screen loads
  }

  // ============================================================
  // _fetchDeviceInfo() — Async function that fetches device info.
  //
  // 'async' means this function can do work without blocking the UI.
  // 'await' means "wait for this to finish before continuing".
  // This is important — fetching info takes time and we don't want
  // to freeze the screen while waiting.
  // Docs: https://dart.dev/libraries/async/async-await
  // ============================================================
  Future<void> _fetchDeviceInfo() async {
    // DeviceInfoPlugin is the main class from device_info_plus
    // We create an instance of it to access device information
    final deviceInfoPlugin = DeviceInfoPlugin();

    // androidInfo() talks to Android's Build API and returns
    // an AndroidDeviceInfo object full of device properties
    final androidInfo = await deviceInfoPlugin.androidInfo;

    // setState() tells Flutter "data changed, please rebuild the UI"
    // Without this call, the screen would never update
    // Docs: https://api.flutter.dev/flutter/widgets/State/setState.html
    setState(() {
      _deviceInfo = androidInfo;
      _isLoading = false; // Data is ready, stop showing spinner
    });
  }

  // ============================================================
  // build() — Called by Flutter whenever it needs to draw this widget.
  // This runs after initState() and again after every setState() call.
  // Docs: https://api.flutter.dev/flutter/widgets/State/build.html
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar is the top bar of the screen
      // Docs: https://api.flutter.dev/flutter/material/AppBar-class.html
      appBar: AppBar(
        title: const Text('System Information'),
      ),

      // Show a loading spinner while data is being fetched,
      // otherwise show the actual info
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildInfoList(),
    );
  }

  // ============================================================
  // _buildInfoList() — Builds the scrollable list of info cards.
  // We separate this into its own method to keep build() clean.
  // ============================================================
  Widget _buildInfoList() {
    // ListView is a scrollable list of widgets
    // Docs: https://api.flutter.dev/flutter/widgets/ListView-class.html
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [

        // We'll build info cards here in the next step

        // For now just a placeholder to confirm everything compiles
        Text(
          'Device: ${_deviceInfo!.model}',
          style: const TextStyle(fontSize: 18),
        ),
      ],
    );
  }
}