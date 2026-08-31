import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_spacing.dart';

/// Mesmo padrão de `_ZoomGallery` (galeria de fotos da Loja) — swipe entre
/// todas as fotos do carrossel a partir da que foi tocada, pinça pra dar
/// zoom, fundo preto sólido. [title] é o nome da competição/campanha
/// (fixo, não muda ao trocar de foto — é o mesmo carrossel inteiro).
Future<void> showTitleImageViewer(
  BuildContext context, {
  required List<String> images,
  required int initialIndex,
  required String title,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierColor: Colors.black,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    pageBuilder: (context, _, _) => _TitleImageViewer(
      images: images,
      initialIndex: initialIndex,
      title: title,
    ),
  );
}

class _TitleImageViewer extends StatefulWidget {
  const _TitleImageViewer({
    required this.images,
    required this.initialIndex,
    required this.title,
  });

  final List<String> images;
  final int initialIndex;
  final String title;

  @override
  State<_TitleImageViewer> createState() => _TitleImageViewerState();
}

class _TitleImageViewerState extends State<_TitleImageViewer> {
  late final _controller = PageController(initialPage: widget.initialIndex);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            itemBuilder: (context, i) => InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Center(
                child: Image.asset(widget.images[i], fit: BoxFit.contain),
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.lg,
            child: IgnorePointer(
              child: Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Positioned(
            right: AppSpacing.md,
            top: AppSpacing.md,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
