import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pomodoro_app/widgets/progress_painter.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  int _focusMinutes = 25;
  int _restMinutes = 5;

  late int _totalSeconds;
  bool _isTimerRunning = false;
  bool _isFocusTime = true;
  int _sessionCount = 0;
  Timer? _timer;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _focusMinutes = prefs.getInt('focusMinutes') ?? 25;
      _restMinutes = prefs.getInt('restMinutes') ?? 5;
      _totalSeconds = _focusMinutes * 60;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('focusMinutes', _focusMinutes);
    prefs.setInt('restMinutes', _restMinutes);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _startTimer() {
    if (_timer != null && _timer!.isActive) return;

    setState(() {
      _isTimerRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_totalSeconds > 0) {
          _totalSeconds--;
        } else {
          _timer?.cancel();
          _isTimerRunning = false;
          _playSound();
          _switchTimerMode();
        }
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isTimerRunning = false;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _isFocusTime = true;
      _totalSeconds = _focusMinutes * 60;
      _sessionCount = 0;
    });
  }

  void _switchTimerMode() {
    setState(() {
      if (_isFocusTime) {
        _sessionCount++;
        _isFocusTime = false;
        _totalSeconds = _restMinutes * 60;
      } else {
        _isFocusTime = true;
        _totalSeconds = _focusMinutes * 60;
      }
      _isTimerRunning = false;
    });
    // Start the timer automatically for the next session
    _startTimer();
  }

  Future<void> _playSound() async {
    // In a real app, you would place a sound file in assets
    // and load it. For simplicity, we use a placeholder.
    // Example: await _audioPlayer.play(AssetSource('sounds/finish_sound.mp3'));
    print("Timer finished! Sound placeholder.");
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pomodoro Timer'),
        actions: [
          
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetTimer,
            tooltip: 'Reset Timer',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              _isFocusTime ? 'Focus' : 'Rest',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 250,
              height: 250,
              child: CustomPaint(
                painter: ProgressPainter(
                  progress: _totalSeconds / (_isFocusTime ? _focusMinutes * 60 : _restMinutes * 60),
                  backgroundColor: Colors.grey.shade300,
                  progressColor: _isFocusTime ? Theme.of(context).primaryColor : Colors.green,
                ),
                child: Center(
                  child: Text(
                    _formatTime(_totalSeconds),
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            _buildTimeControls(),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  onPressed: _isTimerRunning ? _pauseTimer : _startTimer,
                  tooltip: _isTimerRunning ? 'Pause' : 'Start',
                  child: Icon(_isTimerRunning ? Icons.pause : Icons.play_arrow),
                ),
                const SizedBox(width: 20),
                FloatingActionButton(
                  onPressed: _switchTimerMode,
                  tooltip: 'Skip Session',
                  child: const Icon(Icons.skip_next),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Text(
              'Completed Sessions: $_sessionCount',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildTimeAdjuster('Focus', _focusMinutes, (val) => _updateTime('focus', val)),
        _buildTimeAdjuster('Rest', _restMinutes, (val) => _updateTime('rest', val)),
      ],
    );
  }

  Widget _buildTimeAdjuster(String label, int value, Function(int) onChanged) {
    return Card(
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(label, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Text(value.toString(), style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 10),
            Slider(
              value: value.toDouble(),
              min: 1.0,
              max: 60.0, // Max 60 minutes for both focus and rest
              divisions: 59, // 1 to 60 minutes
              label: value.round().toString(),
              onChanged: _isTimerRunning ? null : (double newValue) {
                onChanged(newValue.round());
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 60,
                  child: ElevatedButton(
                    onPressed: _isTimerRunning ? null : () => onChanged(value - 1),
                    child: const Icon(Icons.remove),
                  ),
                ),
                const SizedBox(width: 20),
                SizedBox(
                  width: 60,
                  child: ElevatedButton(
                    onPressed: _isTimerRunning ? null : () => onChanged(value + 1),
                    child: const Icon(Icons.add),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _updateTime(String type, int newValue) {
    if (newValue < 1) return; // Minimum 1 minute
    setState(() {
      if (type == 'focus') {
        _focusMinutes = newValue;
      } else {
        _restMinutes = newValue;
      }
      _saveSettings();
      if (!_isTimerRunning) {
        _totalSeconds = _isFocusTime ? _focusMinutes * 60 : _restMinutes * 60;
      }
    });
  }

  
}
