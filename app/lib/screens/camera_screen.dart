import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/native_bridge.dart';
import '../widgets/ar_overlay.dart';
import '../widgets/confidence_card.dart';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final NativeBridge bridge = NativeBridge();
  List<String> results = [];
  double confidence = 0.0;
  bool _isPermissionGranted = false;
  bool _isPermanentlyDenied = false;
  bool _showRetryButton = false;
  int _retryCount = 0;

  // AR Overlay Data
  List<dynamic> nodes = [];
  List<dynamic> edges = [];
  List<dynamic> labelPositions = [];

  @override
  void initState() {
    super.initState();
    _checkPermission();
    bridge.streamResults().listen((data) {
      if (mounted) {
        setState(() {
          results = List<String>.from(data['labels'] ?? []);
          confidence = (data['confidence'] ?? 0.0).toDouble();
          nodes = data['nodes'] ?? [];
          edges = data['edges'] ?? [];
          labelPositions = data['labelPositions'] ?? [];
        });
      }
    });
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      setState(() {
        _isPermissionGranted = true;
        _isPermanentlyDenied = false;
      });
      _startRetryTimer();
    } else if (status.isPermanentlyDenied) {
      setState(() {
        _isPermanentlyDenied = true;
        _isPermissionGranted = false;
      });
    }
  }

  void _startRetryTimer() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && results.isEmpty && _isPermissionGranted) {
        setState(() {
          _showRetryButton = true;
        });
      }
    });
  }

  void _handleRetry() {
    setState(() {
      _showRetryButton = false;
      _retryCount++;
      results = [];
    });
    bridge.startCamera();
    _startRetryTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Native camera preview
          _isPermissionGranted
              ? AndroidView(
                  viewType: 'native_camera_view',
                  layoutDirection: TextDirection.ltr,
                  creationParams: const {},
                  creationParamsCodec: StandardMessageCodec(),
                  onPlatformViewCreated: (_) {
                    bridge.startCamera();
                  },
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isPermanentlyDenied ? Icons.settings : Icons.camera_alt,
                        color: Colors.white54,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isPermanentlyDenied
                            ? "Camera access is permanently denied"
                            : "Camera Permission Required",
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isPermanentlyDenied
                            ? openAppSettings
                            : _checkPermission,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        ),
                        child: Text(_isPermanentlyDenied ? "Open Settings" : "Grant Permission"),
                      ),
                    ],
                  ),
                ),
          
          // Back Button
          Positioned(
            top: 40,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black38,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          
          // AR Overlay rendering
          if (_isPermissionGranted)
            PalmOverlay(
              labels: results,
              nodes: nodes,
              edges: edges,
              labelPositions: labelPositions,
            ),
          
          // Results Panel at the bottom
          if (_isPermissionGranted && results.isNotEmpty)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ConfidenceCard(confidence: confidence),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        children: results.map((label) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(
                            children: [
                              const Icon(Icons.auto_awesome, color: Colors.blueAccent, size: 18),
                              const SizedBox(width: 12),
                              Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        )).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Scanning Indicator if no results yet
          if (_isPermissionGranted && results.isEmpty)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_showRetryButton)
                    const CircularProgressIndicator(color: Colors.blueAccent),
                  const SizedBox(height: 16),
                  Text(
                    _showRetryButton 
                      ? "Still nothing? Try restarting the camera." 
                      : "Align palm within view...",
                    style: const TextStyle(color: Colors.white70),
                  ),
                  if (_showRetryButton) ...[
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _handleRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text("Retry Camera"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white10,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
