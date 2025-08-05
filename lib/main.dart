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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audio Player')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => _audioHandler.skipToPrevious(),
                onLongPress: () =>
                    (_audioHandler as MyAudioHandler).rewind10Seconds(),
                child: const Icon(Icons.skip_previous, size: 48),
              ),
              IconButton(
                icon: const Icon(Icons.play_arrow),
                iconSize: 64,
                onPressed: () => _audioHandler.play(),
              ),
              IconButton(
                icon: const Icon(Icons.pause),
                iconSize: 64,
                onPressed: () => _audioHandler.pause(),
              ),
              GestureDetector(
                onTap: () => _audioHandler.skipToNext(),
                onLongPress: () =>
                    (_audioHandler as MyAudioHandler).forward10Seconds(),
                child: const Icon(Icons.skip_next, size: 48),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _audioHandler.stop(),
            child: const Text('Stop'),
          ),
        ],
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
    // Lista de faixas com metadata
    final playlistItems = [
      MediaItem(
        id: 'https://www.learningcontainer.com/wp-content/uploads/2020/02/Kalimba.mp3',
        album: "Album 1",
        title: "SoundHelix Song 1",
        artist: "SoundHelix",
      ),
      MediaItem(
        id: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-15.mp3',
        album: "Album 2",
        title: "SoundHelix Song 2",
        artist: "SoundHelix",
      ),
      MediaItem(
        id: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-12.mp3',
        album: "Album 2",
        title: "SoundHelix Song 3",
        artist: "SoundHelix",
      ),
      MediaItem(
        id: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-10.mp3',
        album: "Album 2",
        title: "SoundHelix Song 4",
        artist: "SoundHelix",
      ),
    ];

    // Enviar lista de músicas (obrigatório para miniplayer Android)
    queue.add(playlistItems);
    mediaItem.add(playlistItems[0]);

    // Carregar playlist no player
    final playlist = ConcatenatingAudioSource(
      children: playlistItems
          .map((item) => AudioSource.uri(Uri.parse(item.id)))
          .toList(),
    );
    await _player.setAudioSource(playlist);

    // Atualizar MediaItem ao mudar de faixa
    _player.currentIndexStream.listen((index) {
      if (index != null && index < playlistItems.length) {
        mediaItem.add(playlistItems[index]);
      }
    });

    // Atualizar estado de reprodução (play, pause, buffering, etc.)
    _player.playbackEventStream.listen((event) {
      playbackState.add(playbackStateFor(event));
    });
  }

  // Transformar evento do just_audio em estado para o audio_service
  PlaybackState playbackStateFor(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        _player.playing ? MediaControl.pause : MediaControl.play,
        MediaControl.rewind,
        MediaControl.skipToNext,
        MediaControl.fastForward,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: _player.currentIndex,
    );
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> fastForward() async {
    final currentPosition = _player.position;
    final totalDuration = _player.duration;

    if (totalDuration != null) {
      final newPosition = currentPosition + Duration(seconds: 10);
      // Garante que não passe da duração total
      if (newPosition < totalDuration) {
        await _player.seek(newPosition);
      } else {
        await _player.seek(totalDuration);
      }
    }
  }

  @override
  Future<void> rewind() async {
    final currentPosition = _player.position;

    final newPosition = currentPosition - Duration(seconds: 10);
    // Garante que não vá abaixo de zero
    if (newPosition > Duration.zero) {
      await _player.seek(newPosition);
    } else {
      await _player.seek(Duration.zero);
    }
  }

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();
  }
