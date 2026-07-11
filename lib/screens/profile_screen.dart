import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../auth/user_repository.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_gradients.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_theme.dart';
import '../widgets/settings_section.dart';
import '../widgets/responsive_page.dart';
import '../widgets/ru_phone_formatter.dart';
import '../main.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _userRepository = UserRepository();

  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _regionCtrl;
  late TextEditingController _activityCtrl;
  late TextEditingController _innCtrl;
  late TextEditingController _ogrnipCtrl;

  bool _savingAvatar = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    // Email/телефон — если ещё не заполнены вручную, подставляем то, чем
    // человек зарегистрировался в Firebase (email/Google/SMS-вход).
    final fbUser = _userRepository.user;
    _nameCtrl = TextEditingController(text: state.userName);
    _phoneCtrl = TextEditingController(
      text: state.phoneNumber.isNotEmpty
          ? state.phoneNumber
          : (fbUser?.phoneNumber ?? ''),
    );
    _emailCtrl = TextEditingController(
      text: state.email.isNotEmpty ? state.email : (fbUser?.email ?? ''),
    );
    _regionCtrl = TextEditingController(text: state.region);
    _activityCtrl = TextEditingController(text: state.activityType);
    _innCtrl = TextEditingController(text: state.inn);
    _ogrnipCtrl = TextEditingController(text: state.ogrnip);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _regionCtrl.dispose();
    _activityCtrl.dispose();
    _innCtrl.dispose();
    _ogrnipCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final state = context.read<AppState>();
    state.setUserName(_nameCtrl.text.trim());
    state.setPhoneNumber(_phoneCtrl.text.trim());
    state.setEmail(_emailCtrl.text.trim());
    state.setRegion(_regionCtrl.text.trim());
    state.setActivityType(_activityCtrl.text.trim());
    state.setInn(_innCtrl.text.trim());
    state.setOgrnip(_ogrnipCtrl.text.trim());
    FocusScope.of(context).unfocus();
    Navigator.pop(context);
    rootMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: const Text('Данные сохранены'),
        backgroundColor: AppColors.surfaceAlt,
      ),
    );
  }

  Future<void> _pickAvatar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final bytes = result?.files.first.bytes;
    if (bytes == null || !mounted) return;
    setState(() => _savingAvatar = true);
    context.read<AppState>().setAvatarBase64(base64Encode(bytes));
    if (mounted) setState(() => _savingAvatar = false);
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Выйти из аккаунта?', style: AppTextStyles.titleMedium),
        content: Text(
          'Вы сможете снова войти в любой момент — локальные данные и расчёты останутся на этом устройстве.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.warning),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _userRepository.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.onAccent),
        ),
        body: SafeArea(
          bottom: true,
          top: false,
          child: ResponsivePage(
            maxWidth: 560,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _ProfileHeader(
                  name: state.userName,
                  subtitle: _emailCtrl.text.isNotEmpty
                      ? _emailCtrl.text
                      : (_phoneCtrl.text.isNotEmpty
                            ? _phoneCtrl.text
                            : 'Заполните данные ниже'),
                  avatarBase64: state.avatarBase64,
                  uploading: _savingAvatar,
                  onEditAvatar: _pickAvatar,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.sp16,
                    AppSpacing.sp16,
                    AppSpacing.sp16,
                    AppSpacing.sp32,
                  ),
                  child: Column(
                    children: [
                      SettingsSection(
                        title: 'Основное',
                        children: [
                          SettingsRow(
                            child: _Field(
                              label: 'Имя',
                              controller: _nameCtrl,
                              hint: 'Ваше имя',
                            ),
                          ),
                          SettingsRow(
                            child: _Field(
                              label: 'Номер телефона',
                              controller: _phoneCtrl,
                              hint: '+7 (900) 000-00-00',
                              keyboardType: TextInputType.phone,
                              formatters: [RuPhoneFormatter()],
                            ),
                          ),
                          SettingsRow(
                            child: _Field(
                              label: 'Email',
                              controller: _emailCtrl,
                              hint: 'you@example.com',
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sp16),
                      SettingsSection(
                        title: 'Деятельность',
                        children: [
                          SettingsRow(
                            child: _Field(
                              label: 'Регион ведения деятельности',
                              controller: _regionCtrl,
                              hint: 'Например: Москва',
                            ),
                          ),
                          SettingsRow(
                            child: _Field(
                              label: 'Вид деятельности',
                              controller: _activityCtrl,
                              hint: 'Например: Информационные услуги',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sp16),
                      SettingsSection(
                        title: 'Реквизиты',
                        children: [
                          SettingsRow(
                            child: _Field(
                              label: 'ИНН',
                              controller: _innCtrl,
                              hint: '000000000000',
                              keyboardType: TextInputType.number,
                              maxLength: 12,
                              formatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                          ),
                          SettingsRow(
                            child: _Field(
                              label: 'ОГРНИП',
                              controller: _ogrnipCtrl,
                              hint: '000000000000000',
                              keyboardType: TextInputType.number,
                              maxLength: 15,
                              formatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sp24),
                      FilledButton(
                        onPressed: _save,
                        child: const Text('Сохранить'),
                      ),
                      const SizedBox(height: AppSpacing.sp12),
                      OutlinedButton(
                        onPressed: _signOut,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.warning,
                          side: const BorderSide(color: AppColors.warning),
                        ),
                        child: const Text('Выйти из аккаунта'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Градиентный header профиля — переиспользует единственный в приложении
// градиент (AppGradients.primary, тот же, что у карточки налога на
// дашборде), а не изобретает новую палитру. Аватар перекрывает границу
// градиент/белый контент — классический профильный паттерн.
class _ProfileHeader extends StatelessWidget {
  final String name;
  final String subtitle;
  final String avatarBase64;
  final bool uploading;
  final VoidCallback onEditAvatar;

  static const _avatarSize = 88.0;

  const _ProfileHeader({
    required this.name,
    required this.subtitle,
    required this.avatarBase64,
    required this.uploading,
    required this.onEditAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              height: 148,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: AppGradients.primary,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(AppRadius.lg),
                ),
              ),
            ),
            Positioned(
              bottom: -_avatarSize / 2,
              child: _Avatar(
                base64: avatarBase64,
                size: _avatarSize,
                uploading: uploading,
                onEdit: onEditAvatar,
              ),
            ),
          ],
        ),
        SizedBox(height: _avatarSize / 2 + AppSpacing.sp12),
        Text(
          name.isNotEmpty ? name : 'Пользователь',
          style: AppTextStyles.titleXLarge,
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: AppTextStyles.bodyMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.sp16),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final String base64;
  final double size;
  final bool uploading;
  final VoidCallback onEdit;

  const _Avatar({
    required this.base64,
    required this.size,
    required this.uploading,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentSoft,
              border: Border.all(color: AppColors.surface, width: 4),
            ),
            clipBehavior: Clip.antiAlias,
            child: base64.isEmpty
                ? const Icon(
                    Icons.person_rounded,
                    size: 40,
                    color: AppColors.accent,
                  )
                : Image.memory(base64Decode(base64), fit: BoxFit.cover),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: GestureDetector(
              onTap: uploading ? null : onEdit,
              child: Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 2),
                ),
                child: uploading
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.onAccent,
                        ),
                      )
                    : const Icon(
                        Icons.camera_alt_rounded,
                        size: 14,
                        color: AppColors.onAccent,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? formatters;
  final int? maxLength;

  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.formatters,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelSmall),
        const SizedBox(height: AppSpacing.sp8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: formatters,
          maxLength: maxLength,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            counterText: maxLength != null ? '' : null,
          ),
        ),
      ],
    );
  }
}
