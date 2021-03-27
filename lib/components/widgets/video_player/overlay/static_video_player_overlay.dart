import 'package:flutter/material.dart';
import 'package:harpy/components/components.dart';

/// Builds a static overlay for a [HarpyVideoPlayer].
///
/// The static overlay always shows the action controls and does not detect
/// gestures when the video is tapped.
class StaticVideoPlayerOverlay extends StatefulWidget {
  const StaticVideoPlayerOverlay(
    this.model, {
    @required this.child,
    this.compact = false,
  });

  final HarpyVideoPlayerModel model;
  final Widget child;
  final bool compact;

  @override
  _StaticVideoPlayerOverlayState createState() =>
      _StaticVideoPlayerOverlayState();
}

class _StaticVideoPlayerOverlayState extends State<StaticVideoPlayerOverlay> {
  Widget _centerIcon;

  bool _replayFade = true;

  HarpyVideoPlayerModel get _model => widget.model;

  @override
  void initState() {
    super.initState();

    _model.addActionListener(_onVideoPlayerAction);
    _model.controller.addListener(_videoControllerListener);

    _replayFade = !_model.finished;
  }

  @override
  void dispose() {
    super.dispose();

    _model.removeActionListener(_onVideoPlayerAction);
    _model.controller.removeListener(_videoControllerListener);
  }

  void _videoControllerListener() {
    if (_model.finished && mounted) {
      // rebuild when finished
      setState(() {});
    }
  }

  void _onVideoPlayerAction(HarpyVideoPlayerAction action) {
    if (mounted) {
      setState(() {
        if (action == HarpyVideoPlayerAction.play) {
          _centerIcon = OverlayPlaybackIcon.play(compact: widget.compact);
        } else if (action == HarpyVideoPlayerAction.pause) {
          _centerIcon = OverlayPlaybackIcon.pause(compact: widget.compact);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        if (widget.child != null) widget.child,
        Positioned.fill(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: OverlayActionRow(
              widget.model,
              compact: widget.compact,
            ),
          ),
        ),
        if (widget.model.finished)
          Positioned.fill(
            child: OverplayReplayIcon(
              fadeIn: _replayFade,
              compact: widget.compact,
              onTap: () {
                _replayFade = true;
                _model.replay();
              },
            ),
          )
        else if (_centerIcon != null)
          Positioned.fill(child: _centerIcon),
      ],
    );
  }
}