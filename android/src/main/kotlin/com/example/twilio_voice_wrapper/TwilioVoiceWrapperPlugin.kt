package com.example.twilio_voice_wrapper

import android.content.Context
import android.media.AudioManager
import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

import com.twilio.voice.*

/** TwilioVoiceWrapperPlugin */
class TwilioVoiceWrapperPlugin: FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
  private lateinit var methodChannel: MethodChannel
  private lateinit var eventChannel: EventChannel
  private var eventSink: EventChannel.EventSink? = null
  
  private lateinit var context: Context
  private lateinit var audioManager: AudioManager
  
  private var activeCall: Call? = null
  private var activeCallInvite: CallInvite? = null
  private var accessToken: String? = null

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    context = flutterPluginBinding.applicationContext
    audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    
    methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "twilio_voice_wrapper")
    methodChannel.setMethodCallHandler(this)
    
    eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "twilio_voice_wrapper/events")
    eventChannel.setStreamHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "getPlatformVersion" -> {
        result.success("Android ${android.os.Build.VERSION.RELEASE}")
      }
      "initialize" -> {
        initialize(call, result)
      }
      "makeCall" -> {
        makeCall(call, result)
      }
      "acceptCall" -> {
        acceptCall(result)
      }
      "hangup" -> {
        hangup(result)
      }
      "mute" -> {
        mute(call, result)
      }
      "setSpeaker" -> {
        setSpeaker(call, result)
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  private fun initialize(call: MethodCall, result: Result) {
    try {
      accessToken = call.argument<String>("accessToken")
      if (accessToken == null) {
        result.error("INVALID_ARGUMENT", "Access token is required", null)
        return
      }
      
      Voice.register(accessToken!!, Voice.RegistrationChannel.FCM, null, context, registrationListener)
      result.success(null)
    } catch (e: Exception) {
      result.error("INITIALIZATION_ERROR", e.message, null)
    }
  }

  private fun makeCall(call: MethodCall, result: Result) {
    try {
      val to = call.argument<String>("to")
      val params = call.argument<Map<String, String>>("params") ?: emptyMap()
      
      if (to == null) {
        result.error("INVALID_ARGUMENT", "Destination number is required", null)
        return
      }
      
      if (accessToken == null) {
        result.error("NOT_INITIALIZED", "Plugin not initialized", null)
        return
      }
      
      val connectOptionsBuilder = ConnectOptions.Builder(accessToken!!)
        .params(params.toMutableMap())
        
      to.let { connectOptionsBuilder.to(it) }
      
      activeCall = Voice.connect(context, connectOptionsBuilder.build(), callListener)
      result.success(null)
    } catch (e: Exception) {
      result.error("CALL_ERROR", e.message, null)
    }
  }

  private fun acceptCall(result: Result) {
    try {
      activeCallInvite?.let { callInvite ->
        activeCall = callInvite.accept(context, callListener)
        activeCallInvite = null
        result.success(null)
      } ?: run {
        result.error("NO_INCOMING_CALL", "No incoming call to accept", null)
      }
    } catch (e: Exception) {
      result.error("ACCEPT_ERROR", e.message, null)
    }
  }

  private fun hangup(result: Result) {
    try {
      activeCall?.disconnect()
      activeCall = null
      result.success(null)
    } catch (e: Exception) {
      result.error("HANGUP_ERROR", e.message, null)
    }
  }

  private fun mute(call: MethodCall, result: Result) {
    try {
      val muted = call.argument<Boolean>("muted") ?: false
      activeCall?.mute(muted)
      result.success(null)
    } catch (e: Exception) {
      result.error("MUTE_ERROR", e.message, null)
    }
  }

  private fun setSpeaker(call: MethodCall, result: Result) {
    try {
      val speakerOn = call.argument<Boolean>("speakerOn") ?: false
      audioManager.isSpeakerphoneOn = speakerOn
      result.success(null)
    } catch (e: Exception) {
      result.error("SPEAKER_ERROR", e.message, null)
    }
  }

  private val registrationListener = object : RegistrationListener {
    override fun onRegistered(accessToken: String, fcmToken: String) {
      // Registration successful
    }

    override fun onError(registrationException: RegistrationException, accessToken: String, fcmToken: String) {
      sendCallEvent(mapOf(
        "state" to "failed",
        "direction" to "outgoing",
        "error" to registrationException.message
      ))
    }
  }

  private val callListener = object : Call.Listener {
    override fun onConnectFailure(call: Call, callException: CallException) {
      sendCallEvent(mapOf(
        "state" to "failed",
        "direction" to "outgoing",
        "callSid" to call.sid,
        "error" to callException.message
      ))
      activeCall = null
    }

    override fun onConnected(call: Call) {
      sendCallEvent(mapOf(
        "state" to "connected",
        "direction" to "outgoing",
        "callSid" to call.sid,
        "to" to call.to
      ))
    }

    override fun onDisconnected(call: Call, callException: CallException?) {
      sendCallEvent(mapOf(
        "state" to "disconnected",
        "direction" to "outgoing",
        "callSid" to call.sid,
        "error" to callException?.message
      ))
      activeCall = null
    }

    override fun onReconnecting(call: Call, callException: CallException) {
      sendCallEvent(mapOf(
        "state" to "connecting",
        "direction" to "outgoing",
        "callSid" to call.sid
      ))
    }

    override fun onReconnected(call: Call) {
      sendCallEvent(mapOf(
        "state" to "connected",
        "direction" to "outgoing",
        "callSid" to call.sid
      ))
    }
  }

  private fun sendCallEvent(event: Map<String, Any?>) {
    eventSink?.success(event)
  }

  // EventChannel.StreamHandler implementation
  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    eventSink = events
  }

  override fun onCancel(arguments: Any?) {
    eventSink = null
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    methodChannel.setMethodCallHandler(null)
    eventChannel.setStreamHandler(null)
  }
}
