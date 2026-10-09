import 'dart:convert';
import 'dart:typed_data';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:toriino_todd/config/app_config.dart';

class AgoraService {
  static RtcEngine? _engine;
  static bool _initialized = false;
  static int? _chatStreamId;
  static RtcEngineEventHandler? _handler;

  /// Agora data-stream packets are limited to 1 KB.
  static const int maxChatBytes = 1024;

  // ── Initialize ───────────────────────────────────────
  static Future<void> initialize() async {
    if (_initialized) return;

    _engine = createAgoraRtcEngine();
    await _engine!.initialize(
      RtcEngineContext(
        appId: AppConfig.agoraAppId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ),
    );
    _initialized = true;
  }

  // ── Join a channel (student or teacher joining a live session) ──
  // token: fetched from Lambda's /sessions/token endpoint (server-generated)
  // channelName: usually the sessionId
  // uid: numeric user ID (0 = auto-assigned by Agora)
  static Future<void> joinChannel({
    required String token,
    required String channelName,
    int uid = 0,
    bool isBroadcaster = false,
  }) async {
    if (_engine == null) await initialize();

    await _engine!.setClientRole(
      role: isBroadcaster
          ? ClientRoleType.clientRoleBroadcaster
          : ClientRoleType.clientRoleAudience,
    );

    await _engine!.enableVideo();
    await _engine!.startPreview();

    await _engine!.joinChannel(
      token: token,
      channelId: channelName,
      uid: uid,
      options: const ChannelMediaOptions(
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
      ),
    );
  }

  // ── Leave channel ────────────────────────────────────
  static Future<void> leaveChannel() async {
    _chatStreamId = null;
    await _engine?.leaveChannel();
    await _engine?.stopPreview();
  }

  // ── Toggle microphone ────────────────────────────────
  static Future<void> muteLocalAudio(bool mute) async {
    await _engine?.muteLocalAudioStream(mute);
  }

  // ── Toggle camera ────────────────────────────────────
  static Future<void> muteLocalVideo(bool mute) async {
    await _engine?.muteLocalVideoStream(mute);
  }

  // ── Switch camera (front/back) ───────────────────────
  static Future<void> switchCamera() async {
    await _engine?.switchCamera();
  }

  // ── In-call text chat over an Agora data stream ──────
  /// Sends [text] to everyone in the channel. Returns false if the message
  /// could not be sent (not joined, too large, or the SDK rejected it).
  static Future<bool> sendChatMessage(String text) async {
    final engine = _engine;
    if (engine == null) return false;
    final bytes = Uint8List.fromList(utf8.encode(text));
    if (bytes.isEmpty || bytes.length > maxChatBytes) return false;
    try {
      _chatStreamId ??= await engine.createDataStream(
        const DataStreamConfig(syncWithAudio: false, ordered: true),
      );
      await engine.sendStreamMessage(
        streamId: _chatStreamId!,
        data: bytes,
        length: bytes.length,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Register event handlers ──────────────────────────
  static void registerEventHandlers({
    void Function(RtcConnection, int, int)? onUserJoined,
    void Function(RtcConnection, int, UserOfflineReasonType)? onUserOffline,
    void Function(ErrorCodeType, String)? onError,
    void Function(int remoteUid, String text)? onChatMessage,
  }) {
    final engine = _engine;
    if (engine == null) return; // call initialize() first
    final previous = _handler;
    if (previous != null) engine.unregisterEventHandler(previous);
    _handler = RtcEngineEventHandler(
        onUserJoined: onUserJoined,
        onUserOffline: onUserOffline,
        onError: onError,
        onStreamMessage: onChatMessage == null
            ? null
            : (conn, remoteUid, streamId, data, length, sentTs) {
                try {
                  onChatMessage(
                    remoteUid,
                    utf8.decode(data.sublist(0, length.clamp(0, data.length))),
                  );
                } catch (_) {}
              },
    );
    engine.registerEventHandler(_handler!);
  }

  // ── Cleanup ──────────────────────────────────────────
  static Future<void> dispose() async {
    await _engine?.release();
    _engine = null;
    _handler = null;
    _chatStreamId = null;
    _initialized = false;
  }

  static RtcEngine? get engine => _engine;
}
