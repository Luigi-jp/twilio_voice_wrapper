import '../enums/call_state.dart';
import '../enums/call_direction.dart';

/// Represents an event that occurs during a call lifecycle
class CallEvent {
  /// The current state of the call
  final CallState state;
  
  /// The direction of the call (incoming or outgoing)
  final CallDirection direction;
  
  /// The unique identifier for the call (if available)
  final String? callSid;
  
  /// The caller's phone number or identifier (for incoming calls)
  final String? from;
  
  /// The destination phone number or identifier (for outgoing calls)
  final String? to;
  
  /// Error message if the call failed
  final String? error;

  /// Creates a new [CallEvent] instance
  const CallEvent({
    required this.state,
    required this.direction,
    this.callSid,
    this.from,
    this.to,
    this.error,
  });

  /// Creates a [CallEvent] from a map representation
  factory CallEvent.fromMap(Map<String, dynamic> map) {
    return CallEvent(
      state: CallState.values.firstWhere(
        (e) => e.toString().split('.').last == map['state'],
      ),
      direction: CallDirection.values.firstWhere(
        (e) => e.toString().split('.').last == map['direction'],
      ),
      callSid: map['callSid'],
      from: map['from'],
      to: map['to'],
      error: map['error'],
    );
  }

  /// Converts the [CallEvent] to a map representation
  Map<String, dynamic> toMap() {
    return {
      'state': state.toString().split('.').last,
      'direction': direction.toString().split('.').last,
      'callSid': callSid,
      'from': from,
      'to': to,
      'error': error,
    };
  }

  @override
  String toString() {
    return 'CallEvent(state: $state, direction: $direction, callSid: $callSid, from: $from, to: $to, error: $error)';
  }
}