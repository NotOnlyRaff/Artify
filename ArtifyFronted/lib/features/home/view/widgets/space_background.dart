import 'package:flutter/material.dart';
import 'package:particles_network/particles_network.dart';

class SpaceBackground extends StatefulWidget {
  const SpaceBackground({super.key});

  @override
  State<SpaceBackground> createState() => SpaceBackgroundState();
}

class SpaceBackgroundState extends State<SpaceBackground> {
  final GlobalKey<ParticleNetworkState> _networkKey =
      GlobalKey<ParticleNetworkState>();

  void updateTouch(Offset? touchPoint) {
    final state = _networkKey.currentState;
    if (state == null) return;
    state.touchPoint = touchPoint ?? Offset.infinite;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF04050E),
                Color(0xFF0A0E1A),
              ],
            ),
          ),
        ),

        // il widget corretto per particelle
        ParticleNetwork(
          key: _networkKey,
          particleCount: 70,
          maxSpeed: 0.5,
          maxSize: 2,
          lineDistance: 100,
          particleColor: Colors.white24,
          lineColor: Colors.white12,
          touchActivation: true,
        ),
      ],
    );
  }
}

class SpaceShell extends StatefulWidget {
  final Widget child;

  const SpaceShell({
    super.key,
    required this.child,
  });

  @override
  State<SpaceShell> createState() => _SpaceShellState();
}

class _SpaceShellState extends State<SpaceShell> {
  final GlobalKey<SpaceBackgroundState> _backgroundKey =
      GlobalKey<SpaceBackgroundState>();

  void _forwardTouch(Offset? touchPoint) {
    _backgroundKey.currentState?.updateTouch(touchPoint);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) => _forwardTouch(event.localPosition),
      onPointerMove: (event) => _forwardTouch(event.localPosition),
      onPointerHover: (event) => _forwardTouch(event.localPosition),
      onPointerUp: (_) => _forwardTouch(null),
      onPointerCancel: (_) => _forwardTouch(null),
      child: Stack(
        children: [
          SpaceBackground(key: _backgroundKey),
          widget.child,
        ],
      ),
    );
  }
}
