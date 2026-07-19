import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Тонкая обёртка над FirebaseAuth — инкапсулирует работу с авторизацией,
/// чтобы экраны не обращались к FirebaseAuth напрямую (см. раздел про
/// Firebase Authentication в Yandex Practicum Flutter Handbook).
class UserRepository {
  final FirebaseAuth _firebaseAuth;

  UserRepository([FirebaseAuth? firebaseAuth])
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  // iOS OAuth client ID (CLIENT_ID из GoogleService-Info.plist) — на вебе
  // signInWithPopup сам берёт конфигурацию из Firebase, поэтому нужен
  // только для нативного iOS/macOS-флоу через google_sign_in.
  static const _iosGoogleClientId =
      '1034356664038-cema4hb0cb9i4914a3m2csmrkji9qg3g.apps.googleusercontent.com';

  bool _googleSignInInitialized = false;

  bool get isAuthorized => _firebaseAuth.currentUser != null;

  User? get user => _firebaseAuth.currentUser;

  /// Стрим для реактивного отслеживания состояния авторизации (вход/выход).
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<void> signInWithEmail(String email, String password) async {
    await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signUpWithEmail(String email, String password) async {
    await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signInAnonymously() async {
    await _firebaseAuth.signInAnonymously();
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  /// Вход через Google. На вебе — стандартный попап провайдера
  /// (signInWithPopup работает только в браузере). На iOS/Android/macOS —
  /// нативный флоу через google_sign_in: получаем idToken выбранного
  /// аккаунта и обмениваем его на Firebase-credential. На Android для этого
  /// достаточно web-клиента (client_type 3) в google-services.json — он уже
  /// есть; SHA-1 отпечаток сборки регистрируется в Firebase Console отдельно
  /// и в код не входит.
  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      await _firebaseAuth.signInWithPopup(GoogleAuthProvider());
      return;
    }

    if (!_googleSignInInitialized) {
      await GoogleSignIn.instance.initialize(
        clientId: defaultTargetPlatform == TargetPlatform.iOS ||
                defaultTargetPlatform == TargetPlatform.macOS
            ? _iosGoogleClientId
            : null,
      );
      _googleSignInInitialized = true;
    }

    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    await _firebaseAuth.signInWithCredential(credential);
  }

  /// Шаг 1 телефонного входа — отправляет SMS-код на [phoneNumber]
  /// (формат E.164, напр. "+79251234567"). [codeSent] отдаёт verificationId,
  /// который нужен для подтверждения кода в [signInWithSmsCode].
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(FirebaseAuthException error) onFailed,
    required void Function(String verificationId) codeSent,
  }) {
    return _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      // На вебе/при мгновенной авто-верификации (Android) вход происходит
      // сразу этим коллбэком, минуя ручной ввод кода.
      verificationCompleted: (credential) async {
        await _firebaseAuth.signInWithCredential(credential);
      },
      verificationFailed: onFailed,
      codeSent: (verificationId, _) => codeSent(verificationId),
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  /// Шаг 2 телефонного входа — подтверждает код, полученный по SMS.
  Future<void> signInWithSmsCode({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    await _firebaseAuth.signInWithCredential(credential);
  }
}
