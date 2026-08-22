import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/profile/domain/entities/profile.dart';
import 'package:goias_app/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:goias_app/features/profile/presentation/cubit/profile_state.dart';
import 'package:image_picker/image_picker.dart';

class ProfileAvatarHeader extends StatelessWidget {
  const ProfileAvatarHeader({super.key});

  Future<void> _pickAndUpload(BuildContext context) async {
    final source = await _pickSource(context);
    if (source == null || !context.mounted) return;

    final cubit = context.read<ProfileCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final picked = await ImagePicker().pickImage(source: source, maxWidth: 800, imageQuality: 85);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final ext = picked.name.contains('.') ? picked.name.split('.').last : 'jpg';
    final failure = await cubit.uploadAvatar(bytes, ext);
    if (failure != null) {
      messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  Future<ImageSource?> _pickSource(BuildContext context) {
    final colors = context.colors;
    return showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      backgroundColor: colors.surface,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_camera_outlined, color: colors.primary),
                title: const Text('Tirar foto'),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
              ),
              ListTile(
                leading: Icon(Icons.photo_library_outlined, color: colors.primary),
                title: const Text('Escolher da galeria'),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        final profile = state.profile;
        return Column(
          children: [
            _Avatar(profile: profile, uploading: state.uploadingAvatar, onTap: () => _pickAndUpload(context)),
            const SizedBox(height: AppSpacing.md),
            Text(
              profile?.displayName ?? '—',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: colors.textPrimary),
            ),
            if (profile != null) ...[
              const SizedBox(height: 2),
              Text(profile.email, style: TextStyle(fontSize: 13, color: colors.textSecondary)),
            ],
          ],
        );
      },
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.profile, required this.uploading, required this.onTap});

  final Profile? profile;
  final bool uploading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final avatarUrl = profile?.avatarUrl;
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

    return GestureDetector(
      onTap: uploading ? null : onTap,
      child: Stack(
        children: [
          Container(
            width: 84,
            height: 84,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
              image: hasAvatar ? DecorationImage(image: NetworkImage(avatarUrl), fit: BoxFit.cover) : null,
            ),
            child: hasAvatar
                ? null
                : Text(
                    _initials(profile?.displayName ?? ''),
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
          ),
          if (uploading)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.35), shape: BoxShape.circle),
                child: const Center(
                  child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                ),
              ),
            ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: colors.background, width: 2),
              ),
              child: const Icon(Icons.camera_alt_rounded, size: 13, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

String _initials(String name) {
  final words = name.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
  if (words.isEmpty) return '';
  if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
  return (words.first[0] + words.last[0]).toUpperCase();
}
