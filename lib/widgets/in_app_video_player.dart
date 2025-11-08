import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:pin_tag_client/services/api_service.dart';

class InAppVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const InAppVideoPlayer({Key? key, required this.videoUrl}) : super(key: key);

  @override
  State<InAppVideoPlayer> createState() => _InAppVideoPlayer();
}

class _InAppVideoPlayer extends State<InAppVideoPlayer> {
  late final _player = Player(
      configuration: const PlayerConfiguration(logLevel: MPVLogLevel.error)
  );
  late final _controller = VideoController(_player);
  bool _isLoading = true;
  double _aspectRatio = 16.0 / 9.0;

  @override
  void initState() {
    super.initState();
    _initializeVideoController();

    _player.stream.videoParams.listen((params) {
      if (params.aspect != null && params.aspect! > 0.0) {
        setState(() {
          _aspectRatio = params.aspect!;
        });
      }
    });
  }

  Future<void> _initializeVideoController() async {
    try {
      await _player.open(Media(
          widget.videoUrl,
          httpHeaders: await ApiService.getHeaders()
      ),
          play: true
      );

      await _player.setPlaylistMode(PlaylistMode.single);
      await _player.setVolume(0.0);
    } on Exception catch (ex) {
      print("Error on start playing: $ex");
    }

    if(mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading ? const Center(child: CircularProgressIndicator())
    : Container(
      child: Center(
        child: AspectRatio(
          aspectRatio: _aspectRatio > 0.0 ? _aspectRatio : 16/9,
          child: Video(controller: _controller, fit: BoxFit.contain),
        ),
      ),
    );
  }
}