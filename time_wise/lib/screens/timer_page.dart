import 'package:flutter/material.dart';
import 'dart:async';

class TimerPage extends StatefulWidget {
  const TimerPage({super.key});

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  static const int _defaultSeconds = 25 * 60;
  int _seconds = _defaultSeconds;
  bool _isRunning = false;
  Timer? _timer;
  int _session = 1;

  void _startStop() {
    if (_isRunning) {
      _timer?.cancel();
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_seconds == 0) {
          _timer?.cancel();
          setState(() {
            _isRunning = false;
            _session++;
            _seconds = _defaultSeconds;
          });
        } else {
          setState(() => _seconds--);
        }
      });
    }
    setState(() => _isRunning = !_isRunning);
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _seconds = _defaultSeconds;
      _isRunning = false;
    });
  }

  String get _timeDisplay {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double get _progress => _seconds / _defaultSeconds;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF5EE09A), Color(0xFF2EAD65)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Timer',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // Timer circle
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Sesi ke-$_session',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: 220,
                        height: 220,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 220,
                              height: 220,
                              child: CircularProgressIndicator(
                                value: _progress,
                                strokeWidth: 10,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            Text(
                              _timeDisplay,
                              style: const TextStyle(
                                fontSize: 52,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Reset
                          GestureDetector(
                            onTap: _reset,
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.refresh,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          // Play/Pause
                          GestureDetector(
                            onTap: _startStop,
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isRunning
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: const Color(0xFF2EAD65),
                                size: 36,
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          // Skip
                          GestureDetector(
                            onTap: () {
                              _timer?.cancel();
                              setState(() {
                                _seconds = _defaultSeconds;
                                _isRunning = false;
                                _session++;
                              });
                            },
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.skip_next_rounded,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Info card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildInfoItem('Durasi', '25 menit'),
                    _buildInfoItem('Istirahat', '5 menit'),
                    _buildInfoItem('Total Sesi', '$_session sesi'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black38),
        ),
      ],
    );
  }
}