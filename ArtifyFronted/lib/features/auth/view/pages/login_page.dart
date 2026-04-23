import 'package:client/core/theme/app_pallete.dart';
import 'package:client/core/utils.dart';
import 'package:client/core/widgets/loader.dart';
import 'package:client/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:client/features/home/view/pages/home_page.dart';
import 'package:client/features/auth/view/widgets/auth_input_field.dart';
import 'package:client/features/auth/view/widgets/login_header.dart';
import 'package:client/features/auth/view/widgets/now_playing_promo_card.dart';
import 'package:client/features/auth/view/widgets/signup_redirect_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  bool _passwordVisible = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final isLoading = authState.isLoading;

    ref.listen(authViewModelProvider, (_, next) {
      next.whenOrNull(
        // FIX: aggiunto `data != null` — senza questo controllo il listener
        // navigava a HomePage anche quando il provider restituiva null
        // (stato iniziale al boot o dopo logout), portando l'utente non
        // autenticato direttamente alla home.
        data: (data) {
          if (data != null) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
              (_) => false,
            );
          }
        },
        error: (error, _) {
          showSnackBar(context, error.toString());
        },
      );
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: isLoading
          ? const Center(child: Loader())
          : Container(
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
                          const LoginHeader(),
                          const SizedBox(height: 28),
                          const NowPlayingPromoCard(),
                          const SizedBox(height: 28),
                          _buildLoginCard(context),
                          const SizedBox(height: 24),
                          const SignupRedirectText(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildLoginCard(BuildContext context) {
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
              label: 'Email',
              hintText: 'you@artify.com',
              prefixIcon: Icons.alternate_email_rounded,
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter your email'
                  : null,
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
                onPressed: () =>
                    setState(() => _passwordVisible = !_passwordVisible),
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Enter your password' : null,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Forgot password?',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) {
                    showSnackBar(context, 'Missing fields!');
                    return;
                  }
                  FocusManager.instance.primaryFocus?.unfocus();
                  await ref.read(authViewModelProvider.notifier).loginUser(
                        email: emailController.text.trim(),
                        password: passwordController.text,
                      );
                },
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
                      'Sign In',
                      style: GoogleFonts.roboto(
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
}
