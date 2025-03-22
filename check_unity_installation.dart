// Save this file as check_unity_installation.dart and run with: flutter run -d <your-device> check_unity_installation.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Unity App Installation Checker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _resultMessage = "Press the buttons below to check Unity installation";
  String _log = "";
  bool _isLoading = false;

  void _log(String message) {
    setState(() {
      _log += "$message\n";
    });
    print(message);
  }

  Future<void> _testUnityLaunch(String uri, String description) async {
    setState(() {
      _isLoading = true;
      _resultMessage = "Testing: $description...";
    });

    try {
      final bool launched = await launchUrl(
        Uri.parse(uri),
        mode: LaunchMode.externalApplication,
      );

      if (launched) {
        setState(() {
          _resultMessage = "SUCCESS: $description worked!";
        });
        _log("SUCCESS: $description worked!");
      } else {
        setState(() {
          _resultMessage = "FAILED: Could not launch $description";
        });
        _log("FAILED: Could not launch $description");
      }
    } catch (e) {
      setState(() {
        _resultMessage = "ERROR: $description - $e";
      });
      _log("ERROR: $description - $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unity App Installation Checker')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      _resultMessage,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: CircularProgressIndicator(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed:
                  _isLoading
                      ? null
                      : () => _testUnityLaunch(
                        "android-app://com.BraveSpace.VR/com.unity3d.player.UnityPlayerActivity",
                        "Direct Activity Launch",
                      ),
              child: const Text('Test Direct Activity Launch'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed:
                  _isLoading
                      ? null
                      : () => _testUnityLaunch(
                        "android-app://com.BraveSpace.VR",
                        "Package Name Launch",
                      ),
              child: const Text('Test Package Name Launch'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed:
                  _isLoading
                      ? null
                      : () => _testUnityLaunch(
                        "unityapp://open",
                        "Deep Link Launch",
                      ),
              child: const Text('Test Deep Link Launch'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed:
                  _isLoading
                      ? null
                      : () => _testUnityLaunch(
                        "bravespace://vr/launch",
                        "Alternative Deep Link Launch",
                      ),
              child: const Text('Test Alternative Deep Link'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _log.isEmpty ? "Log will appear here..." : _log,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                setState(() {
                  _log = "";
                  _resultMessage = "Log cleared";
                });
              },
              child: const Text('Clear Log'),
            ),
          ],
        ),
      ),
    );
  }
}
