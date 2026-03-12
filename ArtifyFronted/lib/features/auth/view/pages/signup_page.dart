import 'package:client/core/theme/app_pallete.dart';
import 'package:client/core/utils.dart';
import 'package:client/core/widgets/loader.dart';
import 'package:client/features/auth/view/pages/artist_onboarding_page.dart';
import 'package:client/features/auth/view/pages/login_page.dart';
import 'package:client/features/auth/view/widgets/artist_promo_card.dart';
import 'package:client/features/auth/view/widgets/auth_input_field.dart';
import 'package:client/features/auth/view/widgets/login_redirect_text.dart';
import 'package:client/features/auth/view/widgets/role_selector.dart';
import 'package:client/features/auth/view/widgets/signup_header.dart';
import 'package:client/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  bool _passwordVisible = false;
  bool isArtist = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: Colors.black,
      body: isLoading
          ? const Center(child: Loader())
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF050509), Color(0xFF140813)],
                ),
              ),
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SignupHeader(),
                          const SizedBox(height: 28),
                          const ArtistPromoCard(),
                          const SizedBox(height: 28),
                          _buildSignupCard(context),
                          const SizedBox(height: 24),
                          const LoginRedirectText(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSignupCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Pallete.surfacePrimary.withOpacity(0.72),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Pallete.primary.withOpacity(0.18),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AuthInputField(
              label: 'Name',
              hintText: 'Your name',
              prefixIcon: Icons.person_outline_rounded,
              controller: nameController,
              validator: (val) =>
                  val == null || val.trim().isEmpty ? 'Enter your name' : null,
            ),
            const SizedBox(height: 18),
            AuthInputField(
              label: 'Email',
              hintText: 'you@artify.com',
              prefixIcon: Icons.alternate_email_rounded,
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (val) =>
                  val == null || val.trim().isEmpty ? 'Enter your email' : null,
            ),
            const SizedBox(height: 18),
            RoleSelector(
              isArtist: isArtist,
              onRoleChanged: (val) {
                setState(() {
                  isArtist = val;
                });
              },
            ),
            const SizedBox(height: 18),
            AuthInputField(
              label: 'Password',
              hintText: '••••••••',
              prefixIcon: Icons.lock_outline_rounded,
              controller: passwordController,
              obscureText: !_passwordVisible,
              autofillHints: const [AutofillHints.password],
              suffixIcon: IconButton(
                icon: Icon(
                  _passwordVisible
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: Colors.white70,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _passwordVisible = !_passwordVisible;
                  });
                },
              ),
              validator: (val) =>
                  val == null || val.isEmpty ? 'Enter your password' : null,
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => _handleSubmit(context),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ).copyWith(
                  backgroundColor:
                      WidgetStateProperty.resolveWith((states) => null),
                  elevation: WidgetStateProperty.all(8),
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      colors: [
                        Pallete.gradient1,
                        Pallete.gradient2,
                        Pallete.gradient3,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      isArtist ? 'Continue as artist' : 'Create account',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.35,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit(BuildContext context) async {
    if (!formKey.currentState!.validate()) {
      showSnackBar(context, 'Missing fields!');
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (isArtist) {
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ArtistOnboardingPage(
            accountName: name,
            email: email,
            password: password,
          ),
        ),
      );
      return;
    }

    await ref.read(authViewModelProvider.notifier).signUpUser(
          name: name,
          email: email,
          password: password,
          isArtist: false,
        );

    final state = ref.read(authViewModelProvider);

    if (state.hasError) {
      if (!mounted) return;
      showSnackBar(context, state.error.toString());
      return;
    }

    if (state.valueOrNull != null) {
      if (!mounted) return;
      showSnackBar(context, 'Account created successfully! Please login.');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }
}
