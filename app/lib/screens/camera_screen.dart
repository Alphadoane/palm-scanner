import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/native_bridge.dart';
import '../widgets/ar_overlay.dart';
import '../widgets/confidence_card.dart';
import '../widgets/scanning_beam.dart';
import '../widgets/palm_label_chip.dart';
import 'analysis_result_screen.dart';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with SingleTickerProviderStateMixin {
  final NativeBridge bridge = NativeBridge();
  List<String> results = [];
  double confidence = 0.0;
  bool _isPermissionGranted = false;
  bool _isPermanentlyDenied = false;
  bool _showRetryButton = false;
  bool _isCapturing = false;
  late AnimationController _flashController;

  // AR Overlay Data
  List<dynamic> nodes = [];
  List<dynamic> edges = [];
  List<dynamic> labelPositions = [];

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _checkPermission();
    bridge.streamResults().listen((data) {
      if (mounted && !_isCapturing) {
        setState(() {
          results = List<String>.from(data['labels'] ?? []);
          confidence = (data['confidence'] ?? 0.0).toDouble();
          nodes = data['nodes'] ?? [];
        });
      }
    });
  }

  @override
  void dispose() {
    _flashController.dispose();
    super.dispose();
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
      if (mounted && results.isEmpty && _isPermissionGranted && !_isCapturing) {
        setState(() {
          _showRetryButton = true;
        });
      }
    });
  }

  void _handleRetry() {
    setState(() {
      _showRetryButton = false;
      results = [];
    });
    bridge.startCamera();
    _startRetryTimer();
  }

  void _handleCapture() async {
    if (_isCapturing) return;

    setState(() {
      _isCapturing = true;
    });

    // Trigger flash effect
    _flashController.forward().then((_) => _flashController.reverse());
    HapticFeedback.heavyImpact();

    // Call native capture and analyze
    final data = await bridge.capture().timeout(
      const Duration(seconds: 10),
      onTimeout: () => null,
    );

    if (data != null && mounted) {
      final capturedLabels = List<String>.from(data['labels'] ?? []);
      final capturedConfidence = (data['confidence'] ?? 0.0).toDouble();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AnalysisResultScreen(
            labels: capturedLabels,
            confidence: capturedConfidence,
          ),
        ),
      ).then((_) {
        if (mounted) {
          setState(() {
            _isCapturing = false;
          });
        }
      });
    } else if (mounted) {
      setState(() {
        _isCapturing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to analyze palm. Please try again.')),
      );
    }
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
              : _buildPermissionDenied(),
          
          // Scanning Beam Animation
          if (_isPermissionGranted && !_isCapturing)
            const ScanningBeam(),

          // AR Overlay (Preview Nodes)
          if (_isPermissionGranted && !_isCapturing)
            PalmOverlay(
              labels: results,
              nodes: nodes,
              edges: edges,
              labelPositions: labelPositions,
            ),
          
          // Flash Effect Overlay
          FadeTransition(
            opacity: _flashController,
            child: Container(color: Colors.white),
          ),

          // Navigation Back Button
          Positioned(
            top: 40,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black45,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          
          // Live Status Chips
          if (_isPermissionGranted && results.isNotEmpty && !_isCapturing)
            Positioned(
              top: 150,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: results.take(2).map((label) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: PalmLabelChip(text: label),
                )).toList(),
              ),
            ),

          // Bottom Controls
          if (_isPermissionGranted && !_isCapturing)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.only(bottom: 50.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ConfidenceCard(confidence: confidence),
                    const SizedBox(height: 30),
                    // Standard Capture Button
                    GestureDetector(
                      onTap: _handleCapture,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            height: 84,
                            width: 84,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                            ),
                          ),
                          Container(
                            height: 70,
                            width: 70,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "TAP TO SCAN PALM",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Full-screen Loading/Analyzing Overlay
          if (_isCapturing)
            Container(
              color: Colors.black.withOpacity(0.8),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.blueAccent),
                    const SizedBox(height: 30),
                    const Text(
                      "EXTRACTING FEATURES...",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPermissionDenied() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_outlined, color: Colors.white24, size: 80),
            const SizedBox(height: 20),
            const Text("Camera Access Required", style: TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isPermanentlyDenied ? openAppSettings : _checkPermission,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: Text(_isPermanentlyDenied ? "Open Settings" : "Grant Access"),
            ),
          ],
        ),
      ),
    );
  }
}
