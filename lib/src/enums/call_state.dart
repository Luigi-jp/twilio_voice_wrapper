/// Represents the current state of a call
enum CallState {
  /// The call is currently connecting
  connecting,
  
  /// The call is connected and active
  connected,
  
  /// The call has been disconnected
  disconnected,
  
  /// The call failed to connect or encountered an error
  failed,
  
  /// An incoming call is ringing
  ringing,
}