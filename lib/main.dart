import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

void main() {
  runApp(const MyApp());
}

Future<AudioHandler> initAudioService() async {
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());
  return await AudioService.init(
    builder: () => MyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.audio',
      androidNotificationChannelName: 'Audio Playback',
      androidNotificationOngoing: true,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audio Player App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AudioPlayerScreen(),
    );
  }
}

class AudioPlayerScreen extends StatefulWidget {
  const AudioPlayerScreen({super.key});

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  late final AudioHandler _audioHandler;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    _audioHandler = await initAudioService();
    await _audioHandler.play();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audio Player')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            _audioHandler.stop();
          },
          child: const Text('Stop'),
        ),
      ),
    );
  }
}

class MyAudioHandler extends BaseAudioHandler {
  final _player = AudioPlayer();

  MyAudioHandler() {
    _init();
  }

  Future<void> _init() async {
    try {
      print('🔊 Carregando áudio...');
      await _player.setUrl(
        'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      );
      print('✅ Áudio carregado.');
    } catch (e) {
      print('❌ Erro ao carregar áudio: $e');
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> pause() => _player.pause();
}
