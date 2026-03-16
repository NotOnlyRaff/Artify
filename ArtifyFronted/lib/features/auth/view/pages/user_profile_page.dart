import 'package:client/core/theme/app_pallete.dart';
import 'package:client/core/utils.dart';
import 'package:client/core/widgets/loader.dart';
import 'package:client/features/auth/providers/current_user_notifier.dart';
import 'package:client/features/auth/view/pages/login_page.dart';
import 'package:client/features/auth/view/widgets/user_profile_account_info_card.dart';
import 'package:client/features/auth/view/widgets/user_profile_actions_row.dart';
import 'package:client/features/auth/view/widgets/user_profile_danger_zone.dart';
import 'package:client/features/auth/view/widgets/user_profile_form_card.dart';
import 'package:client/features/auth/view/widgets/user_profile_hero_card.dart';
import 'package:client/features/auth/view/widgets/user_profile_security_cart.dart';
import 'package:client/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_fonts/google_fonts.dart';

class UserProfilePage extends ConsumerStatefulWidget {
  const UserProfilePage({super.key});

  @override
  ConsumerState<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends ConsumerState<UserProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _currentPasswordController =
      TextEditingController();
  late final TextEditingController _newPasswordController =
      TextEditingController();

  bool _passwordVisible = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserNotifierProvider);
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserNotifierProvider);
    final authState = ref.watch(authViewModelProvider);

    ref.listen<AsyncValue>(authViewModelProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stackTrace) {
          showSnackBar(context, error.toString());
        },
        data: (data) {
          if (data == null && previous?.isLoading == true) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
              (_) => false,
            );
          } else if (data != null && previous?.isLoading == true) {
            showSnackBar(context, 'Profile updated successfully!');
          }
        },
      );
    });

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Loader()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Your profile',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF050509),
              Color(0xFF140813),
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UserProfileHeroCard(
                      user: currentUser,
                      isLoading: authState.isLoading,
                      onAvatarTap: _pickAndUploadImage,
                    ),
                    const SizedBox(height: 20),
                    UserProfileFormCard(
                      formKey: _formKey,
                      nameController: _nameController,
                      emailController: _emailController,
                    ),
                    const SizedBox(height: 16),
                    UserProfileAccountInfoCard(user: currentUser),
                    const SizedBox(height: 16),
                    UserProfileSecurityCard(
                      currentPasswordController: _currentPasswordController,
                      newPasswordController: _newPasswordController,
                      passwordVisible: _passwordVisible,
                      isLoading: authState.isLoading,
                      onToggleVisibility: () {
                        setState(() {
                          _passwordVisible = !_passwordVisible;
                        });
                      },
                      onChangePassword: _changePassword,
                    ),
                    const SizedBox(height: 32),
                    UserProfileActionsRow(
                      isLoading: authState.isLoading,
                      onSave: _saveProfile,
                      onLogout: () => _logout(context),
                    ),
                    const SizedBox(height: 24),
                    UserProfileDangerZone(
                      isLoading: authState.isLoading,
                      onDelete: _confirmDeleteAccount,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final pickedFile = result.files.single;

    if (pickedFile.bytes == null) {
      showSnackBar(context, 'Unable to read selected image.');
      return;
    }

    final res =
        await ref.read(authViewModelProvider.notifier).uploadProfilePicture(
              bytes: pickedFile.bytes!,
              fileName: pickedFile.name,
            );

    switch (res) {
      case Left(value: final l):
        showSnackBar(context, 'Image upload failed: ${l.message}');
        break;

      case Right(value: final imageUrl):
        await ref
            .read(authViewModelProvider.notifier)
            .updateProfilePicture(imageUrl);

        final state = ref.read(authViewModelProvider);

        if (state.hasError) {
          showSnackBar(context, state.error.toString());
        } else {
          showSnackBar(context, 'Profile picture updated!');
        }
        break;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      showSnackBar(context, 'Complete the required fields first.');
      return;
    }

    final newName = _nameController.text.trim();
    final currentUser = ref.read(currentUserNotifierProvider);

    if (newName != currentUser?.name) {
      ref.read(authViewModelProvider.notifier).updateUserName(newName);
    } else {
      showSnackBar(context, 'No changes detected to save.');
    }
  }

  Future<void> _logout(BuildContext context) async {
    await ref.read(authViewModelProvider.notifier).logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF140813),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Delete Account?',
            style: GoogleFonts.plusJakartaSans(color: Colors.white),
          ),
          content: Text(
            'This action cannot be undone. All your favorites and metadata will be permanently lost.',
            style: GoogleFonts.plusJakartaSans(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Pallete.errorColor,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      ref.read(authViewModelProvider.notifier).deleteUserAccount();
    }
  }

  Future<void> _changePassword() async {
    final currentUser = ref.read(currentUserNotifierProvider);

    if (currentUser == null) {
      showSnackBar(context, 'User not found.');
      return;
    }

    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();

    if (newPassword.isEmpty) {
      showSnackBar(context, 'New password is required.');
      return;
    }

    if (newPassword.length < 8) {
      showSnackBar(context, 'New password must be at least 8 characters.');
      return;
    }

    final res = await ref.read(authViewModelProvider.notifier).changePassword(
          userId: currentUser.id,
          currentPassword: currentPassword,
          newPassword: newPassword,
        );

    switch (res) {
      case Left(value: final l):
        showSnackBar(context, l.message);
        break;
      case Right():
        _currentPasswordController.clear();
        _newPasswordController.clear();
        showSnackBar(context, 'Password updated successfully!');
        break;
    }
  }
}
