import 'package:flutter/material.dart';
import 'dart:async';

void main() {
  runApp(const RobotControlApp());
}

class RobotControlApp extends StatelessWidget {
  const RobotControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flower Harvester Control',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const DashboardScreen(),
      },
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // State variables for the robot simulation
  String _robotState = 'Idle'; // Idle, Moving, Stopped
  String _cameraState = 'Standby';
  String _rightArmState = 'Idle';
  String _leftArmState = 'Idle';
  
  bool _isSequenceRunning = false;
  final List<String> _logs = [];
  final ScrollController _scrollController = ScrollController();

  void _addLog(String message) {
    setState(() {
      final timestamp = DateTime.now().toIso8601String().split('T')[1].substring(0, 8);
      _logs.add('[$timestamp] $message');
    });
    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _startManualMove() async {
    if (_isSequenceRunning) return;
    setState(() {
      _robotState = 'Moving (Manual)';
      _cameraState = 'Standby';
    });
    _addLog('Robot is moving manually along the rows...');
  }

  Future<void> _stopAndHarvest() async {
    if (_isSequenceRunning || _robotState != 'Moving (Manual)') {
      if (_robotState != 'Moving (Manual)') {
        _addLog('Error: Robot must be moving to stop and harvest.');
      }
      return;
    }

    setState(() {
      _isSequenceRunning = true;
      _robotState = 'Stopped (Harvesting)';
    });

    _addLog('Robot stopped between rows. Initiating harvest sequence.');

    // 1. Camera Detection
    setState(() => _cameraState = 'Scanning...');
    _addLog('Camera: Scanning for flowers...');
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() => _cameraState = 'Flower Detected!');
    _addLog('Camera: Flower detected. Coordinates locked.');
    await Future.delayed(const Duration(seconds: 1));

    // 2. Right Arm Holds
    setState(() => _rightArmState = 'Reaching');
    _addLog('Right Arm: Reaching for flower stem...');
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() => _rightArmState = 'Holding Gently');
    _addLog('Right Arm: Perfect hold achieved on flower stem.');
    await Future.delayed(const Duration(seconds: 1));

    // 3. Left Arm Cuts
    setState(() => _leftArmState = 'Reaching');
    _addLog('Left Arm: Reaching to cut position...');
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() => _leftArmState = 'Cutting');
    _addLog('Left Arm: Cutting the flower stem.');
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() => _leftArmState = 'Retracting');
    _addLog('Left Arm: Retracting to idle position.');
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _leftArmState = 'Idle');

    // 4. Right Arm Collects
    setState(() => _rightArmState = 'Moving to Box');
    _addLog('Right Arm: Carrying flower to right-side collection box.');
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() => _rightArmState = 'Dropping');
    _addLog('Right Arm: Dropping flower into collection box.');
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() => _rightArmState = 'Retracting');
    _addLog('Right Arm: Retracting to idle position.');
    await Future.delayed(const Duration(seconds: 1));
    
    // Reset
    setState(() {
      _rightArmState = 'Idle';
      _cameraState = 'Standby';
      _robotState = 'Idle';
      _isSequenceRunning = false;
    });
    _addLog('Harvest sequence complete. Ready for manual move.');
  }

  void _emergencyStop() {
    setState(() {
      _robotState = 'EMERGENCY STOP';
      _cameraState = 'OFF';
      _rightArmState = 'LOCKED';
      _leftArmState = 'LOCKED';
      _isSequenceRunning = false;
    });
    _addLog('CRITICAL: Emergency stop activated. All systems locked.');
  }

  void _resetSystem() {
    setState(() {
      _robotState = 'Idle';
      _cameraState = 'Standby';
      _rightArmState = 'Idle';
      _leftArmState = 'Idle';
      _isSequenceRunning = false;
      _logs.clear();
    });
    _addLog('System reset. Ready for operations.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flower Harvester Control Center'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetSystem,
            tooltip: 'Reset System',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Status Row
            Row(
              children: [
                Expanded(
                  child: _buildStatusCard(
                    'Robot Base',
                    _robotState,
                    Icons.directions_car,
                    _robotState.contains('Moving') ? Colors.blue : (_robotState.contains('Stopped') ? Colors.orange : Colors.grey),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatusCard(
                    'Camera System',
                    _cameraState,
                    Icons.camera_alt,
                    _cameraState.contains('Detected') ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Arms Status Row
            Row(
              children: [
                Expanded(
                  child: _buildStatusCard(
                    'Left Arm (Cutter)',
                    _leftArmState,
                    Icons.content_cut,
                    _leftArmState != 'Idle' ? Colors.redAccent : Colors.grey,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatusCard(
                    'Right Arm (Holder)',
                    _rightArmState,
                    Icons.pan_tool,
                    _rightArmState != 'Idle' ? Colors.tealAccent : Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Controls
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Manual Controls', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isSequenceRunning || _robotState == 'EMERGENCY STOP' ? null : _startManualMove,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Start Manual Move'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.withOpacity(0.2),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isSequenceRunning || _robotState != 'Moving (Manual)' ? null : _stopAndHarvest,
                          icon: const Icon(Icons.precision_manufacturing),
                          label: const Text('Stop & Harvest Flower'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.withOpacity(0.2),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _emergencyStop,
                          icon: const Icon(Icons.warning),
                          label: const Text('E-STOP'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // System Logs
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('System Logs', style: Theme.of(context).textTheme.titleLarge),
                      const Divider(),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: ListView.builder(
                            controller: _scrollController,
                            itemCount: _logs.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Text(
                                  _logs[index],
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 14,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String title, String status, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(
              status,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
