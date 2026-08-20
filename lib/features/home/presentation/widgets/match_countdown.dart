import 'dart:async';

import 'package:flutter/material.dart';

/// Contagem regressiva até `kickoff`. Cuida do próprio `Timer` e só chama
/// `setState` em si mesmo a cada segundo — a Home (e o resto do Hero) não
/// recompila junto. Quando o tempo zera, chama [onFinished] uma única vez
/// (quem decide o que fazer com isso — normalmente esconder o Hero — é de
/// quem usa este widget, não dele).
class MatchCountdown extends StatefulWidget {
  const MatchCountdown({required this.kickoff, this.onFinished, super.key});

  final DateTime kickoff;
  final VoidCallback? onFinished;

  @override
  State<MatchCountdown> createState() => _MatchCountdownState();
}

class _MatchCountdownState extends State<MatchCountdown> {
  Timer? _timer;
  late Duration _remaining;
  bool _finishedNotified = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.kickoff.difference(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void didUpdateWidget(covariant MatchCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kickoff != widget.kickoff) {
      _finishedNotified = false;
      _remaining = widget.kickoff.difference(DateTime.now());
    }
  }

  void _tick() {
    final remaining = widget.kickoff.difference(DateTime.now());
    if (!mounted) return;
    setState(() => _remaining = remaining);
    if (remaining <= Duration.zero && !_finishedNotified) {
      _finishedNotified = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onFinished?.call());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining <= Duration.zero) return const SizedBox.shrink();

    final days = _remaining.inDays;
    final hours = _remaining.inHours % 24;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;

    return Column(
      children: [
        Text(
          'O JOGO COMEÇA EM',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _CountdownBlock(value: days, label: 'DIAS'),
            const _Separator(),
            _CountdownBlock(value: hours, label: 'HORAS'),
            const _Separator(),
            _CountdownBlock(value: minutes, label: 'MIN'),
            const _Separator(),
            _CountdownBlock(value: seconds, label: 'SEG'),
          ],
        ),
      ],
    );
  }
}

class _CountdownBlock extends StatelessWidget {
  const _CountdownBlock({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Text(
            value.toString().padLeft(2, '0'),
            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

class _Separator extends StatelessWidget {
  const _Separator();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(width: 8);
  }
}
