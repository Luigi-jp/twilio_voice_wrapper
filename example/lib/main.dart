import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:twilio_voice_wrapper/twilio_voice_wrapper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  String _status = 'Not initialized';
  bool _isInitialized = false;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  CallState? _currentCallState;
  
  final _twilioVoiceWrapper = TwilioVoiceWrapper();
  final _phoneController = TextEditingController();
  final _tokenController = TextEditingController();
  
  StreamSubscription<CallEvent>? _callEventSubscription;

  @override
  void initState() {
    super.initState();
    initPlatformState();
    _listenToCallEvents();
  }

  @override
  void dispose() {
    _callEventSubscription?.cancel();
    _phoneController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> initPlatformState() async {
    String platformVersion;
    try {
      platformVersion = await _twilioVoiceWrapper.getPlatformVersion() ?? 'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  void _listenToCallEvents() {
    _callEventSubscription = _twilioVoiceWrapper.onCallEvents.listen(
      (event) {
        setState(() {
          _currentCallState = event.state;
          _status = 'Call ${event.state.toString().split('.').last}';
          if (event.error != null) {
            _status += ' - Error: ${event.error}';
          }
        });
      },
      onError: (error) {
        setState(() {
          _status = 'Event stream error: $error';
        });
      },
    );
  }

  Future<void> _initialize() async {
    if (_tokenController.text.isEmpty) {
      setState(() {
        _status = 'Please enter an access token';
      });
      return;
    }

    try {
      await _twilioVoiceWrapper.initialize(_tokenController.text);
      setState(() {
        _isInitialized = true;
        _status = 'Initialized successfully';
      });
    } catch (e) {
      setState(() {
        _status = 'Initialization failed: $e';
      });
    }
  }

  Future<void> _makeCall() async {
    if (!_isInitialized) {
      setState(() {
        _status = 'Please initialize first';
      });
      return;
    }

    if (_phoneController.text.isEmpty) {
      setState(() {
        _status = 'Please enter a phone number';
      });
      return;
    }

    try {
      await _twilioVoiceWrapper.makeCall(_phoneController.text);
      setState(() {
        _status = 'Making call to ${_phoneController.text}';
      });
    } catch (e) {
      setState(() {
        _status = 'Failed to make call: $e';
      });
    }
  }

  Future<void> _acceptCall() async {
    try {
      await _twilioVoiceWrapper.acceptCall();
      setState(() {
        _status = 'Accepting call';
      });
    } catch (e) {
      setState(() {
        _status = 'Failed to accept call: $e';
      });
    }
  }

  Future<void> _hangup() async {
    try {
      await _twilioVoiceWrapper.hangup();
      setState(() {
        _status = 'Call ended';
        _currentCallState = null;
      });
    } catch (e) {
      setState(() {
        _status = 'Failed to hangup: $e';
      });
    }
  }

  Future<void> _toggleMute() async {
    try {
      await _twilioVoiceWrapper.mute(!_isMuted);
      setState(() {
        _isMuted = !_isMuted;
        _status = _isMuted ? 'Muted' : 'Unmuted';
      });
    } catch (e) {
      setState(() {
        _status = 'Failed to toggle mute: $e';
      });
    }
  }

  Future<void> _toggleSpeaker() async {
    try {
      await _twilioVoiceWrapper.setSpeaker(!_isSpeakerOn);
      setState(() {
        _isSpeakerOn = !_isSpeakerOn;
        _status = _isSpeakerOn ? 'Speaker ON' : 'Speaker OFF';
      });
    } catch (e) {
      setState(() {
        _status = 'Failed to toggle speaker: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Twilio Voice Wrapper Demo'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Platform: $_platformVersion'),
              const SizedBox(height: 16),
              
              // Status
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Status: $_status',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),

              // Access Token Input
              TextField(
                controller: _tokenController,
                decoration: const InputDecoration(
                  labelText: 'Twilio Access Token',
                  border: OutlineInputBorder(),
                ),
                enabled: !_isInitialized,
              ),
              const SizedBox(height: 8),
              
              ElevatedButton(
                onPressed: _isInitialized ? null : _initialize,
                child: Text(_isInitialized ? 'Initialized' : 'Initialize'),
              ),
              const SizedBox(height: 16),

              // Phone Number Input
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  hintText: '+1234567890',
                ),
                enabled: _isInitialized,
              ),
              const SizedBox(height: 16),

              // Call Control Buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: _isInitialized && _currentCallState == null ? _makeCall : null,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('Make Call'),
                  ),
                  ElevatedButton(
                    onPressed: _currentCallState == CallState.ringing ? _acceptCall : null,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    child: const Text('Accept Call'),
                  ),
                  ElevatedButton(
                    onPressed: _currentCallState != null ? _hangup : null,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Hang Up'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Audio Control Buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: _currentCallState == CallState.connected ? _toggleMute : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isMuted ? Colors.orange : Colors.grey,
                    ),
                    child: Text(_isMuted ? 'Unmute' : 'Mute'),
                  ),
                  ElevatedButton(
                    onPressed: _currentCallState == CallState.connected ? _toggleSpeaker : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isSpeakerOn ? Colors.purple : Colors.grey,
                    ),
                    child: Text(_isSpeakerOn ? 'Speaker OFF' : 'Speaker ON'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Current Call State
              if (_currentCallState != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getCallStateColor(_currentCallState!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Call State: ${_currentCallState.toString().split('.').last.toUpperCase()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCallStateColor(CallState state) {
    switch (state) {
      case CallState.connecting:
        return Colors.orange;
      case CallState.connected:
        return Colors.green;
      case CallState.ringing:
        return Colors.blue;
      case CallState.disconnected:
        return Colors.grey;
      case CallState.failed:
        return Colors.red;
    }
  }
}
