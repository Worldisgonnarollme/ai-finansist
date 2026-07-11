import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../auth/user_repository.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_theme.dart';
import '../widgets/responsive_page.dart';
import '../widgets/ru_phone_formatter.dart';

enum _AuthMethod { email, phone }

/// Страница входа/регистрации: email+пароль, телефон по SMS-коду, Google.
/// Открывается после онбординга ('/login' в main.dart), а после успешного
/// входа ведёт на выбор налогового режима — см. onboarding.dart и
/// вызовы Navigator.pushReplacementNamed(context, '/tax-mode') ниже.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userRepository = UserRepository();
  final _formKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _smsCtrl = TextEditingController();

  _AuthMethod _method = _AuthMethod.email;
  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _loading = false;
  String? _error;

  // Телефонный вход — двухшаговый: сначала отправка кода, потом ввод.
  bool _codeSent = false;
  String? _verificationId;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    _smsCtrl.dispose();
    super.dispose();
  }

  // Единая точка для всех успешных сценариев входа (email, телефон,
  // Google) — сразу переносит данные зарегистрированного аккаунта Firebase
  // в AppState/локальное хранилище, чтобы профиль и статичная карточка на
  // экране "Настройки" не оставались пустыми до первого ручного сохранения
  // на экране "Изменить данные профиля".
  void _goToTaxMode() {
    if (!mounted) return;
    final state = context.read<AppState>();
    final fbUser = _userRepository.user;
    if (fbUser != null) {
      if (state.email.isEmpty && (fbUser.email ?? '').isNotEmpty) {
        state.setEmail(fbUser.email!);
      }
      if (state.phoneNumber.isEmpty && (fbUser.phoneNumber ?? '').isNotEmpty) {
        state.setPhoneNumber(fbUser.phoneNumber!);
      }
      if (state.userName.isEmpty && (fbUser.displayName ?? '').isNotEmpty) {
        state.setUserName(fbUser.displayName!);
      }
    }
    Navigator.pushReplacementNamed(context, '/tax-mode');
  }

  Future<void> _submitEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_isSignUp) {
        await _userRepository.signUpWithEmail(
          _emailCtrl.text.trim(),
          _passwordCtrl.text,
        );
      } else {
        await _userRepository.signInWithEmail(
          _emailCtrl.text.trim(),
          _passwordCtrl.text,
        );
      }
      _goToTaxMode();
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _messageFor(e.code));
    } catch (_) {
      setState(() => _error = 'Что-то пошло не так. Попробуйте ещё раз.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailCtrl.text.trim();
    if (!email.contains('@')) {
      setState(() => _error = 'Введите e-mail, чтобы восстановить пароль');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _userRepository.sendPasswordResetEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Письмо для сброса пароля отправлено на $email'),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _messageFor(e.code));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendSmsCode() async {
    final digits = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) {
      setState(() => _error = 'Введите номер телефона полностью');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _userRepository.verifyPhoneNumber(
        phoneNumber: RuPhoneFormatter.toE164(_phoneCtrl.text),
        onFailed: (e) {
          if (mounted) setState(() => _error = _messageFor(e.code));
        },
        codeSent: (verificationId) {
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
              _codeSent = true;
            });
          }
        },
      );
    } catch (_) {
      setState(() => _error = 'Не удалось отправить код. Попробуйте ещё раз.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmSmsCode() async {
    if (_smsCtrl.text.trim().length < 4 || _verificationId == null) {
      setState(() => _error = 'Введите код из SMS');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _userRepository.signInWithSmsCode(
        verificationId: _verificationId!,
        smsCode: _smsCtrl.text.trim(),
      );
      _goToTaxMode();
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _messageFor(e.code));
    } catch (_) {
      setState(
        () => _error = 'Не удалось подтвердить код. Попробуйте ещё раз.',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _userRepository.signInWithGoogle();
      _goToTaxMode();
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _messageFor(e.code));
    } catch (_) {
      setState(
        () => _error = 'Не удалось войти через Google. Попробуйте ещё раз.',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _messageFor(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Некорректный e-mail';
      case 'user-not-found':
        return 'Пользователь с таким e-mail не найден';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Неверный e-mail или пароль';
      case 'email-already-in-use':
        return 'Этот e-mail уже зарегистрирован';
      case 'weak-password':
        return 'Пароль слишком простой — минимум 6 символов';
      case 'invalid-phone-number':
        return 'Некорректный номер телефона';
      case 'invalid-verification-code':
        return 'Неверный код из SMS';
      case 'too-many-requests':
        return 'Слишком много попыток. Попробуйте позже';
      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
        return 'Окно входа закрыто раньше времени';
      default:
        return 'Не удалось войти. Попробуйте ещё раз.';
    }
  }

  String get _headline {
    if (_method == _AuthMethod.phone) {
      return _codeSent ? 'Введите код' : 'Вход по телефону';
    }
    return _isSignUp ? 'Создать аккаунт' : 'С возвращением!';
  }

  String get _subtitle {
    if (_method == _AuthMethod.phone) {
      return _codeSent
          ? 'Мы отправили SMS с кодом на ${_phoneCtrl.text}'
          : 'Пришлём код подтверждения по SMS';
    }
    return _isSignUp
        ? 'Заполните форму, чтобы начать работу с AI-Финансист'
        : 'Войдите, чтобы продолжить работу с AI-Финансист';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsivePage(
          maxWidth: 420,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.sp24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Badge(),
                  const SizedBox(height: AppSpacing.sp24),
                  Text(
                    _headline,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.displayLarge.copyWith(fontSize: 26),
                  ),
                  const SizedBox(height: AppSpacing.sp8),
                  Text(
                    _subtitle,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.sp24),
                  OutlinedButton(
                    onPressed: _loading ? null : _signInWithGoogle,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Text(
                            'G',
                            style: AppTextStyles.captionBold.copyWith(
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sp8 + 2),
                        const Text('Войти через Google'),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sp20),
                  Row(
                    children: [
                      Expanded(
                        child: Container(height: 1, color: AppColors.divider),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sp12,
                        ),
                        child: Text('или', style: AppTextStyles.labelSmall),
                      ),
                      Expanded(
                        child: Container(height: 1, color: AppColors.divider),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sp20),
                  if (!_codeSent)
                    _MethodToggle(
                      method: _method,
                      onChanged: (m) => setState(() {
                        _method = m;
                        _error = null;
                      }),
                    ),
                  if (!_codeSent) const SizedBox(height: AppSpacing.sp20),
                  Form(key: _formKey, child: _buildFields()),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.sp16),
                    _ErrorBanner(text: _error!),
                  ],
                  const SizedBox(height: AppSpacing.sp24),
                  FilledButton(
                    onPressed: _loading ? null : _handlePrimary,
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.onAccent,
                            ),
                          )
                        : Text(_primaryLabel),
                  ),
                  const SizedBox(height: AppSpacing.sp12),
                  _buildFooterLink(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFields() {
    if (_method == _AuthMethod.phone) {
      if (_codeSent) {
        return _FieldGroup(
          label: 'Код из SMS',
          child: TextField(
            controller: _smsCtrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            style: AppTextStyles.titleXLarge.copyWith(
              fontWeight: FontWeight.w400,
              letterSpacing: 6,
            ),
            decoration: const InputDecoration(
              hintText: '••••••',
              counterText: '',
            ),
          ),
        );
      }
      return _FieldGroup(
        label: 'Номер телефона',
        child: TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          inputFormatters: [RuPhoneFormatter()],
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
          decoration: const InputDecoration(hintText: '+7 (900) 000-00-00'),
        ),
      );
    }

    return Column(
      children: [
        _FieldGroup(
          label: 'E-mail',
          child: TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
            decoration: const InputDecoration(hintText: 'you@example.com'),
            validator: (v) => (v == null || !v.contains('@'))
                ? 'Введите корректный e-mail'
                : null,
          ),
        ),
        const SizedBox(height: AppSpacing.sp16),
        _FieldGroup(
          label: 'Пароль',
          trailing: !_isSignUp
              ? GestureDetector(
                  onTap: _loading ? null : _resetPassword,
                  child: Text(
                    'Забыли пароль?',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.accent,
                      letterSpacing: 0,
                    ),
                  ),
                )
              : null,
          child: TextFormField(
            controller: _passwordCtrl,
            obscureText: _obscurePassword,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: '••••••••',
              suffixIcon: IconButton(
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            validator: (v) =>
                (v == null || v.length < 6) ? 'Минимум 6 символов' : null,
          ),
        ),
      ],
    );
  }

  String get _primaryLabel {
    if (_method == _AuthMethod.phone) {
      return _codeSent ? 'Подтвердить' : 'Получить код';
    }
    return _isSignUp ? 'Зарегистрироваться' : 'Войти';
  }

  Future<void> _handlePrimary() {
    if (_method == _AuthMethod.phone) {
      return _codeSent ? _confirmSmsCode() : _sendSmsCode();
    }
    return _submitEmail();
  }

  Widget _buildFooterLink() {
    if (_method == _AuthMethod.phone) {
      if (!_codeSent) return const SizedBox.shrink();
      return Center(
        child: TextButton(
          onPressed: _loading
              ? null
              : () => setState(() {
                  _codeSent = false;
                  _verificationId = null;
                  _smsCtrl.clear();
                  _error = null;
                }),
          child: const Text('Изменить номер телефона'),
        ),
      );
    }
    return Center(
      child: TextButton(
        onPressed: _loading
            ? null
            : () => setState(() {
                _isSignUp = !_isSignUp;
                _error = null;
              }),
        child: Text(
          _isSignUp
              ? 'Уже есть аккаунт? Войти'
              : 'Нет аккаунта? Зарегистрироваться',
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 64,
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.accent,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(
          Icons.calculate_rounded,
          size: 30,
          color: AppColors.onAccent,
        ),
      ),
    );
  }
}

/// Переключатель способа входа — Email / Телефон.
class _MethodToggle extends StatelessWidget {
  final _AuthMethod method;
  final ValueChanged<_AuthMethod> onChanged;
  const _MethodToggle({required this.method, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: _MethodOption(
              label: 'Email',
              active: method == _AuthMethod.email,
              onTap: () => onChanged(_AuthMethod.email),
            ),
          ),
          Expanded(
            child: _MethodOption(
              label: 'Телефон',
              active: method == _AuthMethod.phone,
              onTap: () => onChanged(_AuthMethod.phone),
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodOption extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _MethodOption({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sp8 + 3),
        decoration: BoxDecoration(
          color: active ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w700,
            color: active ? AppColors.onAccent : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _FieldGroup extends StatelessWidget {
  final String label;
  final Widget child;
  final Widget? trailing;
  const _FieldGroup({required this.label, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.labelSmall),
            ?trailing,
          ],
        ),
        const SizedBox(height: AppSpacing.sp8),
        child,
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String text;
  const _ErrorBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sp12,
        vertical: AppSpacing.sp8 + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        border: Border.all(color: AppColors.warningBorder),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        text,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.warningText),
      ),
    );
  }
}
