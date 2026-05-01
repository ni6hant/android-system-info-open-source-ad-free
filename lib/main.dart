// ============================================================
// main.dart — Entry point of our System Information app
// ============================================================

// Flutter's material design library — gives us widgets like
// Scaffold, AppBar, Text, Column etc.
// Docs: https://api.flutter.dev/flutter/material/material-library.html
import 'package:flutter/material.dart';

// dart:math gives us log() and pow() for the byte conversion
import 'dart:math';

// This is the package we installed via 'flutter pub add device_info_plus'
// It wraps Android's Build class and gives us device information
// Docs: https://pub.dev/packages/device_info_plus
import 'package:device_info_plus/device_info_plus.dart';

// battery_plus gives us access to battery level and charging state
// Docs: https://pub.dev/packages/battery_plus
import 'package:battery_plus/battery_plus.dart';

// connectivity_plus tells us the type of network connection
// Docs: https://pub.dev/packages/connectivity_plus
import 'package:connectivity_plus/connectivity_plus.dart';

// network_info_plus gives us detailed wifi information
// Docs: https://pub.dev/packages/network_info_plus
import 'package:network_info_plus/network_info_plus.dart';

// permission_handler lets us request runtime permissions
// Docs: https://pub.dev/packages/permission_handler
import 'package:permission_handler/permission_handler.dart';

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

  // Holds the list of current connection types
  // It's a list because you can be on wifi AND vpn simultaneously
  // Docs: https://pub.dev/documentation/connectivity_plus/latest/connectivity_plus/ConnectivityResult.html
  List<ConnectivityResult>? _connectivityResult;

  // Holds detailed wifi information
  // Nullable because user might not be on wifi at all
  String? _wifiName;
  String? _wifiBSSID;
  String? _wifiIPv4;
  String? _wifiIPv6;
  String? _wifiGateway;
  String? _wifiSubmask;
  String? _wifiBroadcast;

// Fixed just missing permissions: Added this varaible to see why the play store version isn't showing network data. Will be removed once it's fixed.
  String? _networkError;

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
    _fetchNetworkInfo(); // Fetch network info and request location permission
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
  // _fetchNetworkInfo() — Fetches connection type and wifi details.
  //
  // This is the most complex fetch so far because:
  // 1. We need to request a dangerous permission (location) first
  // 2. We only fetch wifi details if permission is granted
  // 3. We handle the case where user denies the permission
  //
  // This teaches an important pattern — always check permissions
  // before accessing sensitive data, and always handle denial
  // gracefully rather than crashing.
  // ============================================================
  Future<void> _fetchNetworkInfo() async {
    // Step 1 — Check connection type first, this needs no permission
    // Connectivity() is the main class from connectivity_plus
    // checkConnectivity() returns a List<ConnectivityResult>
    // Docs: https://pub.dev/documentation/connectivity_plus/latest/connectivity_plus/Connectivity/checkConnectivity.html
    final connectivity = Connectivity();
    final connectivityResult = await connectivity.checkConnectivity();

    setState(() {
      _connectivityResult = connectivityResult;
    });

    // Step 2 — Request location permission for wifi details
    // Permission.location refers to ACCESS_FINE_LOCATION that we
    // declared in AndroidManifest.xml earlier
    // .request() shows the system popup to the user
    // Docs: https://pub.dev/documentation/permission_handler/latest/permission_handler/Permission/location.html
    final locationPermission = await Permission.location.request();

    // Step 3 — Only fetch wifi details if permission was granted
    // We check for granted specifically — any other PermissionStatus
    // means we don't have access and should not attempt the call
    if (locationPermission == PermissionStatus.granted) {
      try{
      // NetworkInfo() is the main class from network_info_plus
      // Each method is a separate async call to the Android wifi API
      // Docs: https://pub.dev/documentation/network_info_plus/latest/network_info_plus/NetworkInfo-class.html
      final networkInfo = NetworkInfo();

      // We fetch all wifi properties in parallel using Future.wait
      // This is more efficient than awaiting them one by one since
      // they don't depend on each other
      // Docs: https://api.flutter.dev/flutter/dart-async/Future/wait.html
      final results = await Future.wait([
        networkInfo.getWifiName(),        // SSID e.g. "MyHomeWifi"
        networkInfo.getWifiBSSID(),       // Router MAC address
        networkInfo.getWifiIP(),          // Device IPv4 address
        networkInfo.getWifiIPv6(),        // Device IPv6 address
        networkInfo.getWifiGatewayIP(),   // Router IP address
        networkInfo.getWifiSubmask(),     // Subnet mask
        networkInfo.getWifiBroadcast(),
      ]);

      setState(() {
        _wifiName    = results[0] ?? 'Unavailable';
        _wifiBSSID   = results[1] ?? 'Unavailable';
        _wifiIPv4    = results[2] ?? 'Unavailable';
        _wifiIPv6    = results[3] ?? 'Unavailable';
        _wifiGateway = results[4] ?? 'Unavailable';
        _wifiSubmask = results[5] ?? 'Unavailable';
        _wifiBroadcast = results[6] ?? 'Unavailable';
      });
      } catch (e) {
    // Capture the exact error so we can display it in the UI
    // This is temporary debug code — remove before final release
    setState(() {
      _networkError = e.toString();
    });
  }

    } else {
      // Permission was denied — we update the state to reflect this
      // so the UI can show a meaningful message instead of empty fields
      setState(() {
        _wifiName    = 'Location permission denied';
        _wifiBSSID   = 'Location permission denied';
        _wifiIPv4    = 'Location permission denied';
        _wifiIPv6    = 'Location permission denied';
        _wifiGateway = 'Location permission denied';
        _wifiSubmask = 'Location permission denied';
        _wifiBroadcast = 'Location permission denied';
      });
    }
  }

// ============================================================
  // _buildDisplaySection() — Builds the display info section.
  //
  // Unlike device/battery/network info, display info comes from
  // Flutter's MediaQuery which requires a BuildContext. This means
  // we can't fetch it in initState() — we read it directly in the
  // build method instead. No async needed, it's always instant.
  //
  // MediaQuery docs:
  // https://api.flutter.dev/flutter/widgets/MediaQuery-class.html
  // FlutterView docs:
  // https://api.flutter.dev/flutter/dart-ui/FlutterView-class.html
  // ============================================================
  Widget _buildDisplaySection(BuildContext context) {
    // MediaQuery.of(context) gives us a MediaQueryData object
    // containing everything Flutter knows about the current screen
    // Docs: https://api.flutter.dev/flutter/widgets/MediaQueryData-class.html
    final mediaQuery = MediaQuery.of(context);

    // size gives us the logical screen dimensions in points
    // These are NOT physical pixels — they're device independent
    // units that Flutter uses internally for layout
    // Docs: https://api.flutter.dev/flutter/widgets/MediaQueryData/size.html
    final size = mediaQuery.size;

    // devicePixelRatio is the number of physical pixels per logical pixel
    // e.g. 3.0 means the screen has 3x3 physical pixels per logical pixel
    // Multiply logical size by this to get actual physical pixel count
    // Docs: https://api.flutter.dev/flutter/widgets/MediaQueryData/devicePixelRatio.html
    final pixelRatio = mediaQuery.devicePixelRatio;

    // Calculate actual physical resolution by multiplying logical
    // dimensions by the pixel ratio
    final physicalWidth = (size.width * pixelRatio).round();
    final physicalHeight = (size.height * pixelRatio).round();

    // Convert devicePixelRatio to the familiar Android density bucket
    // These are the standard Android screen density classifications
    // Docs: https://developer.android.com/training/multiscreen/screendensities
    String densityBucket;
    if (pixelRatio <= 1.0) {
      densityBucket = 'mdpi (1x)';
    } else if (pixelRatio <= 1.5) {
      densityBucket = 'hdpi (1.5x)';
    } else if (pixelRatio <= 2.0) {
      densityBucket = 'xhdpi (2x)';
    } else if (pixelRatio <= 3.0) {
      densityBucket = 'xxhdpi (3x)';
    } else {
      densityBucket = 'xxxhdpi (4x)';
    }

    // padding gives us the system UI insets — status bar height,
    // navigation bar height, notch size etc.
    // Docs: https://api.flutter.dev/flutter/widgets/MediaQueryData/padding.html
    final padding = mediaQuery.padding;

    return InfoSection(
      title: 'Display',
      icon: Icons.monitor,
      children: [
        // Logical size — what Flutter uses for layout
        InfoCard(
          label: 'Logical Resolution',
          value: '${size.width.round()} x ${size.height.round()} dp',
          explanation: 'The screen dimensions in density independent pixels (dp). This is the unit Flutter and Android use for layout. Using dp instead of physical pixels ensures that buttons, text, and UI elements appear the same physical size on all screens regardless of pixel density. A button that is 200dp wide will look the same size on a budget phone and a flagship.',
        ),

        // Physical size — actual pixels on the screen
        InfoCard(
          label: 'Physical Resolution',
          value: '$physicalWidth x $physicalHeight px',
           explanation: 'The actual number of pixels on the screen panel. This is the resolution manufacturers advertise. It is calculated by multiplying the logical resolution by the pixel ratio. A higher physical resolution means sharper text and images but also uses more GPU power to render.',
        ),

        // The pixel density ratio
        InfoCard(
          label: 'Pixel Ratio',
          value: '${pixelRatio.toStringAsFixed(2)}x',
          explanation: 'The number of physical pixels per logical pixel. A ratio of 3.0 means there are 3x3 physical pixels for every 1x1 logical pixel. Higher ratios produce sharper displays. This is what Android uses to classify screens into density buckets like hdpi, xhdpi, and xxhdpi. Most modern flagships are between 2.5x and 4x.',
        ),

        // The Android density bucket this device falls into
        InfoCard(
          label: 'Density',
          value: densityBucket,
          explanation: 'The Android screen density classification for this device. mdpi is the baseline at 160dpi. hdpi is 240dpi. xhdpi is 320dpi. xxhdpi is 480dpi. xxxhdpi is 640dpi. Android uses these buckets to select the correct resolution assets from an app. Developers provide multiple versions of images at different densities so they look sharp on all screens.',
        ),

        // Status bar height — useful for UI development
        InfoCard(
          label: 'Status Bar Height',
          value: '${padding.top.round()} dp',
           explanation: 'The height of the status bar at the top of the screen in logical pixels. The status bar shows the time, battery, and signal icons. On devices with a notch or punch hole camera this value is larger to accommodate the cutout. Apps need to account for this space so their content is not hidden behind the status bar.',
        ),

        // Bottom inset — navigation bar or gesture area height
        InfoCard(
          label: 'Bottom Inset',
          value: '${padding.bottom.round()} dp',
           explanation: 'The height of the system navigation area at the bottom of the screen. On devices using gesture navigation this is a small area for the gesture indicator. On devices with navigation buttons it is taller to accommodate the back, home, and recents buttons. Apps must account for this so buttons and content are not hidden behind the navigation area.',
        ),

        // Whether the device is in portrait or landscape
        // Orientation docs: https://api.flutter.dev/flutter/widgets/Orientation.html
        InfoCard(
          label: 'Orientation',
          value: mediaQuery.orientation == Orientation.portrait
              ? 'Portrait'
              : 'Landscape',
               explanation: 'Whether the device is currently in portrait or landscape mode. Portrait means the screen is taller than it is wide. Landscape means the screen is wider than it is tall. This value updates automatically when you rotate the device. Apps can choose to support one or both orientations.',
        ),

        // Text scale factor — user's font size preference from
        // Android accessibility settings
        // Docs: https://api.flutter.dev/flutter/widgets/MediaQueryData/textScaler.html
        InfoCard(
          label: 'Text Scale Factor',
          value: mediaQuery.textScaler.scale(1.0).toStringAsFixed(2),
           explanation: 'The text size multiplier set by the user in Android accessibility settings. A value of 1.0 means default text size. A value of 1.3 means the user has increased text size by 30% system wide. Well designed apps respect this setting so users with visual impairments can read content comfortably. This app respects your text size preference.',
        ),
      ],
    );
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
  value: _deviceInfo!.version.release.toString(),
  explanation: 'The version of Android running on this device. Android versions are named numerically since Android 10. Each version brings new features, security improvements, and API changes that apps can use.',
),

InfoCard(
  label: 'API Level',
  value: _deviceInfo!.version.sdkInt.toString(),
  explanation: 'A number that identifies the Android framework version. Developers use this to check if a device supports specific features. For example, API 26 introduced notification channels, API 29 introduced dark mode support. Your device is on API ${_deviceInfo!.version.sdkInt}.',
),

InfoCard(
  label: 'BaseOS (Won\'t be populated if the manufacturer didn\'t bother putting it. It\'s basically for skinned OS.)',
  value: _deviceInfo!.version.baseOS.toString(),
  explanation: 'The base Android version that the manufacturer built their custom OS on top of. Most manufacturers like Xiaomi, Samsung, and OnePlus ship a heavily modified version of Android. This field is often left empty by manufacturers even when it applies.',
),

InfoCard(
  label: 'Board',
  value: _deviceInfo!.board.toString(),
  explanation: 'The name of the underlying hardware circuit board. This is the physical board that all components are mounted on. It often corresponds to the chipset platform name used internally by the manufacturer.',
),

InfoCard(
  label: 'Bootloader',
  value: _deviceInfo!.bootloader.toString(),
  explanation: 'The version of the bootloader installed on this device. The bootloader is the first program that runs when you power on your device — it loads the Android OS. An unlocked bootloader allows installing custom ROMs and recovery images.',
),

InfoCard(
  label: 'Brand',
  value: _deviceInfo!.brand.toString(),
  explanation: 'The consumer-facing brand name of this device. This is the brand shown in marketing materials. For example a device manufactured by Xiaomi might have a brand of Redmi or POCO depending on which product line it belongs to.',
),

InfoCard(
  label: 'Code Name',
  value: _deviceInfo!.version.codename.toString(),
  explanation: 'The development codename of this Android version. During development Google assigns alphabet-based codenames to Android releases. Once released this shows REL meaning it is a stable official release rather than a preview build.',
),

InfoCard(
  label: 'CPU Architecture',
  value: _deviceInfo!.supportedAbis.join(', ').toString(),
  explanation: 'The CPU instruction sets this device supports, listed in order of preference. arm64-v8a is the modern 64-bit ARM architecture. armeabi-v7a is the older 32-bit ARM. x86_64 and x86 appear on emulators. Apps are compiled for these architectures so the Play Store delivers the right version for your device.',
),

InfoCard(
  label: 'Device',
  value: _deviceInfo!.device.toString(),
  explanation: 'The internal hardware codename of this device used by the manufacturer during development. This is different from the marketing name — for example a Redmi Note 12 might have a device codename of spes or tapas internally.',
),
            InfoCard(
              label: 'Display',
              value: _deviceInfo!.display.toString(),
               explanation: 'A build identifier string for the display firmware. This is used internally by Android to identify the exact build running on this device and is useful for bug reports and debugging display related issues.',
            ),
      // ── Display Section ────────────────────────────────────
              // Note: we pass context here because MediaQuery needs it
              _buildDisplaySection(context),
InfoCard(
  label: 'Fingerprint',
  value: _deviceInfo!.fingerprint.toString(),
  explanation: 'A unique string that identifies this exact build of Android on this device. It combines the brand, device, build ID, and other identifiers into one string. Developers use this to identify exactly which software version a bug report came from.',
),

InfoCard(
  label: 'Hardware',
  value: _deviceInfo!.hardware.toString(),
  explanation: 'The name of the hardware platform this device is built on. This typically corresponds to the chipset or SoC (System on Chip) platform name. For Qualcomm devices this often matches the chipset codename used internally.',
),

InfoCard(
  label: 'Host',
  value: _deviceInfo!.host.toString(),
  explanation: 'The hostname of the build server that compiled this version of Android. This is set by the manufacturer during the build process and identifies which machine in their build infrastructure produced this firmware.',
),

InfoCard(
  label: 'ID',
  value: _deviceInfo!.id.toString(),
  explanation: 'A build ID string that identifies this specific Android build. Manufacturers use this to track firmware versions for updates and support. It often appears in settings under About Phone as the Build Number.',
),

InfoCard(
  label: 'Incremental',
  value: _deviceInfo!.version.incremental.toString(),
  explanation: 'The internal incremental build number assigned by the manufacturer. This changes with every software update and is more granular than the Build ID. Useful for identifying the exact software version when reporting bugs to manufacturers.',
),

InfoCard(
  label: 'Is Low Ram Device',
  value: _deviceInfo!.isLowRamDevice.toString(),
  explanation: 'Whether Android has classified this device as a low RAM device. Android applies this classification to devices with 1GB or less of RAM. Apps can check this flag to reduce memory usage, disable animations, or offer a lite experience on low end devices.',
),

InfoCard(
  label: 'Is Physical Device?',
  value: _deviceInfo!.isPhysicalDevice.toString(),
  explanation: 'Whether this is a real physical Android device as opposed to an emulator running on a computer. Developers use this to disable certain features during testing or to prevent apps from running on emulators for security reasons.',
),

InfoCard(
  label: 'Manufacturer',
  value: _deviceInfo!.manufacturer.toString(),
  explanation: 'The company that manufactured the physical hardware of this device. This is the actual hardware maker which may differ from the brand. For example Foxconn manufactures devices for many brands, or Xiaomi manufactures both Xiaomi and Redmi branded devices.',
),

InfoCard(
  label: 'Model',
  value: _deviceInfo!.model.toString(),
  explanation: 'The end-user visible model name of this device as defined by the manufacturer. This is what appears in marketing materials and what users typically refer to when identifying their device. It is the most recognizable identifier for a specific device.',
),
InfoCard(
  label: 'Product',
  value: _deviceInfo!.product.toString(),
  explanation: 'The name of the overall product that this device is part of. This is set by the manufacturer during the build process and often matches the device codename. It is used internally to identify which product configuration was used to build this firmware.',
),
InfoCard(
  label: 'Name',
  value: _deviceInfo!.name.toString(),
  explanation: 'The device name as reported by the Android system. This may match the model name or be a slightly different internal identifier depending on the manufacturer and Android version.',
),
InfoCard(
  label: 'Supported 32 Bit Abis',
  value: _deviceInfo!.supported32BitAbis.toString(),
  explanation: 'The 32-bit CPU instruction sets supported by this device. Even modern 64-bit devices support 32-bit instruction sets for backwards compatibility with older apps that have not been updated to 64-bit. The Play Store uses this to determine which version of an app to deliver.',
),
InfoCard(
  label: 'Supported 64 Bit Abis',
  value: _deviceInfo!.supported64BitAbis.toString(),
  explanation: 'The 64-bit CPU instruction sets supported by this device. 64-bit apps can access more memory, run faster, and are required by Google Play for all new apps. arm64-v8a is the standard 64-bit architecture for modern Android devices.',
),

InfoCard(
  label: 'Preview SDK',
  value: _deviceInfo!.version.previewSdkInt.toString(),
  explanation: 'The API level of a preview version of Android if this device is running a pre-release build. On stable production devices this is always 0, indicating this is a final released version of Android and not a developer preview.',
),
InfoCard(
  label: 'Available RAM Size',
  value: formatMB(_deviceInfo!.availableRamSize),
  explanation: 'The amount of RAM currently free and available for new apps and processes. Android actively manages memory by keeping recently used apps in RAM for faster switching. This number changes constantly as you open and close apps.',
),
InfoCard(
  label: 'Physical RAM Size',
  value: formatMB(_deviceInfo!.physicalRamSize),
  explanation: 'The total physical RAM installed in this device. This is less than the advertised RAM because the Android kernel, GPU, and system processes permanently reserve memory at boot. A device advertised as 8GB will typically show around 7GB here.',
),
InfoCard(
  label: 'Security Patch',
  value: _deviceInfo!.version.securityPatch.toString(),
  explanation: 'The date of the most recent Android security patch applied to this device. Google releases monthly security patches that fix vulnerabilities. Manufacturers then integrate these patches into their own firmware updates. A more recent date means fewer known security vulnerabilities.',
),
InfoCard(
  label: 'Free Disk Size',
  value: formatBytes(_deviceInfo!.freeDiskSize),
  explanation: 'The amount of internal storage currently available for new files and app installations. This decreases as you install apps, take photos, and download files. Android may reserve some space and not make it available to apps even when it appears free.',
),
InfoCard(
  label: 'Total Disk Size',
  value: formatBytes(_deviceInfo!.totalDiskSize),
  explanation: 'The total internal storage capacity of this device. This is usually less than the advertised storage because the Android OS, pre-installed apps, and system partitions occupy space before you ever use the device. Manufacturers advertise raw storage while Android reports usable storage.',
),
            // systemFeatures is a List<String> so we use InfoCardList
            // instead of InfoCard which only handles single string values
            InfoCardList(
              label: 'System Features',
              values: _deviceInfo!.systemFeatures,
            ),
InfoCard(
  label: 'Tags',
  value: _deviceInfo!.tags.toString(),
  explanation: 'Build tags that describe the type of this Android build. release-keys means this is an official signed build from the manufacturer. test-keys indicates a development or custom ROM build. This is one way to detect if a device is running official firmware.',
),
InfoCard(
  label: 'Type',
  value: _deviceInfo!.type.toString(),
  explanation: 'The type of this Android build. user means a production build intended for end users with full security restrictions. userdebug is a debug build that still has most security restrictions. eng is a fully open engineering build used during development.',
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
                   explanation: 'The current battery charge level as a percentage from 0 to 100. Android reads this from the battery management IC via the power supply subsystem. The value updates automatically as the battery charges or discharges. Some manufacturers report slightly inaccurate percentages due to battery calibration differences.',
            ),

            // _batteryState is a BatteryState enum so we call .name
            // on it to get a readable string like "charging"
            // Docs: https://dart.dev/language/enums
            InfoCard(
              label: 'State',
              value: _batteryState?.name ?? 'Unknown',
              explanation: 'The current charging state of the battery. charging means power is connected and battery is increasing. discharging means running on battery power. full means connected to power and fully charged. connectedNotCharging means power is connected but battery is not increasing, which can happen when the battery is at capacity or the charger output is too low for the current usage.',
            ),

          ],
        ),

        // ── Network Section ────────────────────────────────────
        InfoSection(
          title: 'Network',
          icon: Icons.network_check,
          children: [

            // connectivityResult is a List<ConnectivityResult> so we
            // map each result to its name and join them together.
            // e.g. "wifi, vpn" if connected to both simultaneously
            // Docs: https://pub.dev/documentation/connectivity_plus/latest/connectivity_plus/ConnectivityResult.html
            InfoCard(
              label: 'Connection Type',
              value: _connectivityResult != null
                  ? _connectivityResult!
                      .map((r) => r.name)
                      .join(', ')
                  : 'Unknown',
                   explanation: 'The type of network connection currently active on this device. wifi means connected to a wireless network. mobile means using cellular data. ethernet applies to devices connected via a cable. vpn appears when a VPN is active. Multiple types can be active simultaneously.',
            ),

            // Wifi details are only meaningful if we're on wifi
            // We show them anyway so user can see what's available
            InfoCard(
              label: 'WiFi Name (SSID)',
              value: _wifiName ?? 'Unavailable',
                explanation: 'The name of the WiFi network this device is currently connected to. SSID stands for Service Set Identifier — it is the human readable name you see when browsing available networks. Android requires location permission to read this value because WiFi SSIDs can be used to determine your physical location.',
            ),
            InfoCard(
              label: 'WiFi BSSID',
              value: _wifiBSSID ?? 'Unavailable',
                explanation: 'The MAC address of the specific WiFi access point this device is connected to. BSSID stands for Basic Service Set Identifier. Unlike the SSID which is a name, the BSSID is a unique hardware identifier for the router or access point. Multiple access points can share the same SSID but each has a unique BSSID.',
            ),
            InfoCard(
              label: 'IPv4 Address',
              value: _wifiIPv4 ?? 'Unavailable',
                explanation: 'The IPv4 address assigned to this device on the current network. This is a 32-bit address written as four numbers separated by dots, for example 192.168.1.5. This address is local to your network and changes when you connect to different networks. Other devices on the same network use this address to communicate with yours.',
            ),
            InfoCard(
              label: 'IPv6 Address',
              value: _wifiIPv6 ?? 'Unavailable',
                explanation: 'The IPv6 address assigned to this device. IPv6 is the newer 128-bit addressing system designed to replace IPv4 which is running out of available addresses. IPv6 addresses are written as eight groups of four hexadecimal digits. Many networks now assign both IPv4 and IPv6 addresses simultaneously.',
            ),
            InfoCard(
              label: 'Gateway',
              value: _wifiGateway ?? 'Unavailable',
                explanation: 'The IP address of your router or access point. The gateway is the device that connects your local network to the internet. All traffic destined for the internet is sent to this address first, which then forwards it to the correct destination. It is typically the first address in your network range.',
            ),
            InfoCard(
              label: 'Subnet Mask',
              value: _wifiSubmask ?? 'Unavailable',
                explanation: 'A number that defines which part of an IP address identifies the network and which part identifies the device. A common subnet mask of 255.255.255.0 means the first three numbers identify the network and the last number identifies the specific device. It determines which devices are on the same local network.',
            ),
            InfoCard(
              label: 'Wifi Broadcast',
              value: _wifiBroadcast ?? 'Unavailable',
                explanation: 'The broadcast address for the current network. Messages sent to this address are received by all devices on the same network simultaneously. It is calculated from the IP address and subnet mask combined. Network discovery and local service announcements use this address.',
            ),
            // TEMPORARY DEBUG CARD — remove before final release
if (_networkError != null)
  InfoCard(
    label: '⚠️ Debug Error',
    value: _networkError!,
    explanation: 'This is a temporary debug card showing the exact error from the WiFi fetch. This will be removed once the issue is identified and fixed.',
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
// InfoCardList — A variant of InfoCard specifically for when
// the value is a list of strings rather than a single value.
//
// It shows a collapsed summary by default and expands to show
// each item on its own line when tapped.
//
// We build this as a separate widget instead of modifying
// InfoCard because InfoCard works perfectly for single values
// and we don't want to add complexity to something that already
// works. This is the Single Responsibility Principle — each
// widget does one thing well.
// ============================================================
class InfoCardList extends StatelessWidget {
  // The label shown in the header (e.g. "System Features")
  final String label;

  // The list of strings to display when expanded
  final List<String> values;

  const InfoCardList({
    super.key,
    required this.label,
    required this.values,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: ExpansionTile(
          // Show the label and item count in the header so the
          // user knows how many items are inside before expanding
          title: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 13.0,
            ),
          ),

          // Subtitle shows a preview so the user knows what's
          // inside without having to expand it
          subtitle: Text(
            '${values.length} items — tap to expand',
            style: const TextStyle(
              fontSize: 11.0,
            ),
          ),

          // Starts collapsed by default — 50+ items expanded
          // on load would be a terrible user experience
          initiallyExpanded: false,

          // Build one Text widget per item in the list
          // Each item gets its own row with a bullet point
          // and consistent padding
          children: values.map((item) {
            // .map() transforms each string in the list into
            // a widget. This is a core Dart pattern you'll use
            // constantly — transforming a list of data into a
            // list of widgets.
            // Docs: https://api.dart.dev/dart-core/Iterable/map.html
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 4.0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bullet point
                  Text(
                    '• ',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // The actual feature string, wrapped in Expanded
                  // so long strings wrap to the next line instead
                  // of overflowing off screen
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(fontSize: 12.0),
                    ),
                  ),
                ],
              ),
            );
          // .toList() converts the mapped Iterable back into a
          // List<Widget> which is what children: expects
          }).toList(),
        ),
      ),
    );
  }
}


// ============================================================
// InfoCard — A reusable widget that displays a single piece
// of system information as a labeled card with an explanation
// button.
//
// Every InfoCard requires an explanation — this is enforced by
// the 'required' keyword so the compiler catches any missing ones.
// ============================================================
class InfoCard extends StatelessWidget {
  final String label;
  final String value;

  // explanation is required — every field must have one
  // This ensures we never ship a ? button with no content
  final String explanation;

  const InfoCard({
    super.key,
    required this.label,
    required this.value,
    required this.explanation,
  });

  // ============================================================
  // _showExplanation() — Shows a bottom sheet with the explanation
  // text when the user taps the ? button.
  //
  // showModalBottomSheet displays a panel that slides up from the
  // bottom of the screen. It's modal meaning the user can't interact
  // with anything behind it until they dismiss it by swiping down.
  //
  // Docs: https://api.flutter.dev/flutter/material/showModalBottomSheet.html
  // ============================================================
  void _showExplanation(BuildContext context) {
    showModalBottomSheet(
      context: context,

      // isScrollControlled: true allows the sheet to take up more
      // than 50% of screen height if the content needs it
      // Docs: https://api.flutter.dev/flutter/material/showModalBottomSheet.html
      isScrollControlled: true,

      // Shape gives the bottom sheet rounded top corners
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16.0),
        ),
      ),

      builder: (context) {
        // DraggableScrollableSheet lets the user drag the sheet
        // up and down to resize it, and scroll inside it when
        // content is longer than the sheet height
        // Docs: https://api.flutter.dev/flutter/material/DraggableScrollableSheet-class.html
        return DraggableScrollableSheet(
          // initialChildSize is how much of the screen it takes
          // up when first shown (0.4 = 40% of screen height)
          initialChildSize: 0.4,

          // minChildSize is how small the user can drag it
          minChildSize: 0.2,

          // maxChildSize is how large the user can drag it
          maxChildSize: 0.9,

          // expand: false is required when used inside
          // showModalBottomSheet
          expand: false,

          builder: (context, scrollController) {
            return SingleChildScrollView(
              // Pass the scrollController so the sheet and
              // scroll are connected — dragging scrolls content
              // rather than dismissing the sheet
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag handle — visual indicator that the
                    // sheet is draggable
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16.0),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade600,
                          borderRadius: BorderRadius.circular(2.0),
                        ),
                      ),
                    ),

                    // Label as the sheet title
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),

                    const SizedBox(height: 8.0),

                    // Current value shown in the sheet too
                    // so user doesn't lose context
                    Text(
                      'Current value: $value',
                      style: TextStyle(
                        fontSize: 13.0,
                        color: Colors.grey.shade400,
                      ),
                    ),

                    const Divider(height: 24.0),

                    // The actual explanation text
                    Text(
                      explanation,
                      style: const TextStyle(
                        fontSize: 15.0,
                        height: 1.6, // line height for readability
                      ),
                    ),

                    // Bottom padding so content doesn't sit
                    // right at the edge on gesture nav devices
                    const SizedBox(height: 32.0),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.0,
                ),
              ),
            ),

            const SizedBox(width: 8.0),

            // Value
            Expanded(
              flex: 3,
              child: Text(
                value,
                style: const TextStyle(fontSize: 13.0),
              ),
            ),

            // ? button — tapping it shows the explanation
            // GestureDetector wraps any widget and makes it
            // tappable — here we use it on a simple icon
            // Docs: https://api.flutter.dev/flutter/widgets/GestureDetector-class.html
            GestureDetector(
              onTap: () => _showExplanation(context),
              child: Icon(
                Icons.info_outline,
                size: 16.0,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// Converts bytes to a human readable string
// Used for disk size which is reported in bytes
// e.g. 128849018880 → "120.0 GB"
String formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
  int i = (log(bytes) / log(1024)).floor();
  i = i.clamp(0, suffixes.length - 1);
  double value = bytes / pow(1024, i);
  return '${value.toStringAsFixed(1)} ${suffixes[i]}';
}

// Converts megabytes to a human readable string
// Used for RAM which is reported in MB by AndroidDeviceInfo
// e.g. 7305 → "7.1 GB"
String formatMB(int mb) {
  if (mb <= 0) return '0 MB';
  if (mb < 1024) return '$mb MB';
  double gb = mb / 1024;
  return '${gb.toStringAsFixed(1)} GB';
}