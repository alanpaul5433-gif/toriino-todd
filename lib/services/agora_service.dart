import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:toriino_todd/config/app_config.dart';

class AgoraService {
  static RtcEngine? _engine;
  static bool _initialized = false;

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

  // ── Register event handlers ──────────────────────────
  static void registerEventHandlers({
    void Function(RtcConnection, int, int)? onUserJoined,
    void Function(RtcConnection, int, UserOfflineReasonType)? onUserOffline,
    void Function(ErrorCodeType, String)? onError,
  }) {
    _engine?.registerEventHandler(
      RtcEngineEventHandler(
        onUserJoined: onUserJoined,
        onUserOffline: onUserOffline,
        onError: onError,
      ),
    );
  }

  // ── Cleanup ──────────────────────────────────────────
  static Future<void> dispose() async {
    await _engine?.release();
    _engine = null;
    _initialized = false;
  }

  static RtcEngine? get engine => _engine;
}
