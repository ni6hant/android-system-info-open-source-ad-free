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

// battery_plus gives us access to battery level and charging state
// Docs: https://pub.dev/packages/battery_plus
import 'package:battery_plus/battery_plus.dart';

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

    // Holds the current battery percentage (0-100)
  // Nullable because we haven't fetched it yet on startup
  int? _batteryLevel;

  // Holds the current charging state as a BatteryState enum
  // Remember BatteryState can be: charging, discharging, full,
  // connectedNotCharging, or unknown
  // Docs: https://pub.dev/documentation/battery_plus/latest/battery_plus/BatteryState.html
  BatteryState? _batteryState;

  // Battery() is the main class from battery_plus that we use
  // to query battery information.
  // We create one instance here and reuse it throughout the app —
  // creating multiple instances is wasteful.
  // Docs: https://pub.dev/documentation/battery_plus/latest/battery_plus/Battery-class.html
  final Battery _battery = Battery();

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
    _fetchBatteryInfo(); // Fetch battery info and start listening for changes
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
  // _fetchBatteryInfo() — Fetches battery level and state.
  //
  // Unlike device info which never changes, battery info changes
  // constantly so we do two things here:
  // 1. Fetch the current values immediately on startup
  // 2. Subscribe to a stream that gives us live updates whenever
  //    the battery state changes (e.g. user plugs in charger)
  //
  // A Stream is like a pipe that keeps sending you new values
  // over time, as opposed to a Future which gives you one value
  // and is done.
  // Docs on Streams: https://dart.dev/libraries/async/using-streams
  // ============================================================
  Future<void> _fetchBatteryInfo() async {
    // batteryLevel is a Future<int> — it gives us the percentage
    // once and that's it. We await it to get the actual integer.
    // Docs: https://pub.dev/documentation/battery_plus/latest/battery_plus/Battery/batteryLevel.html
    final level = await _battery.batteryLevel;

    // onBatteryStateChanged is a Stream<BatteryState> — it keeps
    // emitting new values whenever the charging state changes.
    // .first gets just the current value from the stream right now.
    // Docs: https://pub.dev/documentation/battery_plus/latest/battery_plus/Battery/onBatteryStateChanged.html
    final state = await _battery.onBatteryStateChanged.first;

    // Update the UI with what we just fetched
    setState(() {
      _batteryLevel = level;
      _batteryState = state;
    });

    // Now subscribe to ongoing battery state changes.
    // listen() is called every time a new value comes through
    // the stream — so if the user plugs in their charger while
    // the app is open, this fires and updates the UI automatically.
    // Docs: https://api.flutter.dev/flutter/dart-async/Stream/listen.html
    _battery.onBatteryStateChanged.listen((BatteryState newState) {
      setState(() {
        _batteryState = newState;
      });
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
  // _buildInfoList() — Builds the full scrollable screen content.
  //
  // Each InfoSection is a collapsible group of related InfoCards.
  // We pass children as a list of InfoCard widgets — this is the
  // same pattern you'll see everywhere in Flutter: a parent widget
  // takes a list of child widgets and decides how to lay them out.
  // ============================================================
  Widget _buildInfoList() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [

        // ── Device Section ─────────────────────────────────────
        // initiallyExpanded: true so the user sees data immediately
        // on first launch without having to tap anything
        InfoSection(
          title: 'Device',
          icon: Icons.phone_android,
          initiallyExpanded: true,
          // Children are sorted alphabetically by label
          children: [
            InfoCard(
              label: 'Android Version',
              value: _deviceInfo!.version.release,
            ),
            InfoCard(
              label: 'API Level',
              value: _deviceInfo!.version.sdkInt.toString(),
            ),
            InfoCard(
              label: 'Brand',
              value: _deviceInfo!.brand,
            ),
            InfoCard(
              label: 'CPU Architecture',
              value: _deviceInfo!.supportedAbis.join(', '),
            ),
            InfoCard(
              label: 'Device',
              value: _deviceInfo!.device,
            ),
            InfoCard(
              label: 'Fingerprint',
              value: _deviceInfo!.fingerprint,
            ),
            InfoCard(
              label: 'Hardware',
              value: _deviceInfo!.hardware,
            ),
            InfoCard(
              label: 'Manufacturer',
              value: _deviceInfo!.manufacturer,
            ),
            InfoCard(
              label: 'Model',
              value: _deviceInfo!.model,
            ),
          ],
        ),

        // ── Battery Section ────────────────────────────────────
        InfoSection(
          title: 'Battery',
          icon: Icons.battery_full,
          children: [

            // _batteryLevel is nullable so we use the null-coalescing
            // operator ?? to show 'Unknown' if data isn't ready yet.
            // Docs: https://dart.dev/language/operators#conditional-expressions
            InfoCard(
              label: 'Level',
              value: _batteryLevel != null
                  ? '$_batteryLevel%'
                  : 'Unknown',
            ),

            // _batteryState is a BatteryState enum so we call .name
            // on it to get a readable string like "charging"
            // Docs: https://dart.dev/language/enums
            InfoCard(
              label: 'State',
              value: _batteryState?.name ?? 'Unknown',
            ),

          ],
        ),

      ],
    );
  }


}

// ============================================================
// InfoSection — A collapsible section that groups related
// InfoCards together under a single expandable header.
//
// We use Flutter's built-in ExpansionTile widget which handles
// all the expand/collapse animation for us automatically.
//
// Docs: https://api.flutter.dev/flutter/material/ExpansionTile-class.html
// ============================================================
class InfoSection extends StatelessWidget {
  // The title shown in the header (e.g. "Battery", "Device")
  final String title;

  // The icon shown to the left of the title
  // IconData is the type for Flutter's built-in icons
  // Full icon list: https://api.flutter.dev/flutter/material/Icons-class.html
  final IconData icon;

  // The list of InfoCard widgets shown when expanded
  final List<Widget> children;

  // Whether the section starts expanded or collapsed
  // We default to false so everything starts collapsed
  final bool initiallyExpanded;

  const InfoSection({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    // Card wraps the ExpansionTile to give it the elevated
    // surface look consistent with our InfoCards
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),

      // ClipRRect clips the card's children to its rounded corners
      // Without this, the ExpansionTile background bleeds outside
      // the card's rounded edges when expanded
      // Docs: https://api.flutter.dev/flutter/widgets/ClipRRect-class.html
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),

        child: ExpansionTile(
          // leading is the icon on the left of the header
          leading: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
          ),

          // title is the main header text
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15.0,
            ),
          ),

          initiallyExpanded: initiallyExpanded,

          // childrenPadding adds padding around the expanded content
          childrenPadding: const EdgeInsets.symmetric(
            horizontal: 8.0,
            vertical: 4.0,
          ),

          // children is the list of widgets shown when expanded.
          // We pass our InfoCards here from whoever creates this
          // InfoSection.
          children: children,
        ),
      ),
    );
  }
}


// ============================================================
// InfoCard — A reusable widget that displays a single piece
// of system information as a labeled card.
//
// We build this once and reuse it for every single data point
// in the app. This is a core Flutter principle — don't repeat
// yourself, build reusable widgets instead.
//
// It takes two required parameters:
// - label: the name of the property (e.g. "Model")
// - value: the actual value (e.g. "Vivo I2305")
//
// Docs on StatelessWidget (this never changes after being built):
// https://api.flutter.dev/flutter/widgets/StatelessWidget-class.html
// ============================================================
class InfoCard extends StatelessWidget {
  // 'final' means these values can't be changed after the widget
  // is constructed — which makes sense since a card just displays
  // what it's given and never modifies it
  final String label;
  final String value;

  // This is the constructor. 'required' means you MUST pass these
  // values when creating an InfoCard — the compiler won't let you
  // forget them.
  // Docs: https://dart.dev/language/constructors
  const InfoCard({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    // Card gives us the elevated surface with rounded corners
    // Docs: https://api.flutter.dev/flutter/material/Card-class.html
    return Card(
      // margin adds space OUTSIDE the card, separating cards from
      // each other in the list
      // Docs: https://api.flutter.dev/flutter/painting/EdgeInsets-class.html
      margin: const EdgeInsets.symmetric(vertical: 6.0),

      // Padding adds space INSIDE the card, between the card edge
      // and its content
      child: Padding(
        padding: const EdgeInsets.all(16.0),

        // Row lays its children out horizontally
        // Docs: https://api.flutter.dev/flutter/widgets/Row-class.html
        child: Row(
          // crossAxisAlignment controls vertical alignment inside the Row
          // 'start' means children align to the top of the row
          // Docs: https://api.flutter.dev/flutter/rendering/CrossAxisAlignment.html
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // Expanded makes this widget fill all available horizontal
            // space. Without it, long text would overflow off screen.
            // Docs: https://api.flutter.dev/flutter/widgets/Expanded-class.html
            Expanded(
              // flex controls how much space this child gets relative
              // to other Expanded children. flex: 2 means this gets
              // twice as much space as a flex: 1 sibling.
              flex: 2,
              child: Text(
                label,
                style: TextStyle(
                  // Theme.of(context) reads the current app theme
                  // so our colors always stay consistent
                  // Docs: https://api.flutter.dev/flutter/material/Theme-class.html
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.0,
                ),
              ),
            ),

            // This gives us a small gap between label and value
            const SizedBox(width: 8.0),

            // The value gets more space (flex: 3) since values tend
            // to be longer than labels
            Expanded(
              flex: 3,
              child: Text(
                value,
                style: const TextStyle(fontSize: 13.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}