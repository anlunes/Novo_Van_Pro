import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_logger.dart';
 
class AuthService {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
 
  Future<String?> signUp({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String role,
  }) async {
    final emailTrim = email.trim();
    final phoneTrim = phone.trim();
    final nameTrim = name.trim();
 
    AppLogger.log('AUTH_SERVICE', 'SIGNUP_START', data: {
      'email': emailTrim,
      'role': role,
      'nameLen': nameTrim.length,
      'phoneLen': phoneTrim.length,
    });
 
    try {
      final cred = await auth.createUserWithEmailAndPassword(
        email: emailTrim,
        password: password,
      );
 
      final user = cred.user;
      if (user == null) {
        AppLogger.log('AUTH_SERVICE', 'SIGNUP_ERROR', data: {
          'email': emailTrim,
          'reason': 'user_null_after_create',
        });
        return 'Falha ao criar usuário.';
      }
 
      AppLogger.log('AUTH_SERVICE', 'SIGNUP_AUTH_CREATED', data: {
        'uid': user.uid,
        'email': user.email,
      });
 
      await user.updateDisplayName(nameTrim);
      await user.reload();
 
      AppLogger.log('AUTH_SERVICE', 'SIGNUP_FIRESTORE_WRITE_START', data: {
        'uid': user.uid,
        'role': role,
      });
 
      await firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': nameTrim,
        'phone': phoneTrim,
        'email': emailTrim,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'emailVerified': false,
      });
 
      AppLogger.log('AUTH_SERVICE', 'SIGNUP_FIRESTORE_WRITE_OK', data: {
        'uid': user.uid,
      });
 
            // Importante (web): precisamos de uma rota específica na app para
      // garantir que o link de verifyEmail seja entregue e processado
      // pelo nosso EmailActionHandlerScreen.
      const String continueUrl =
          'https://vanpro-oficial-2eb30.web.app/__/auth/action';

      final actionCodeSettings = ActionCodeSettings(
        url: continueUrl,
        handleCodeInApp: true,
      );

 
      AppLogger.log('AUTH_SERVICE', 'SIGNUP_VERIFICATION_SEND_START', data: {
        'uid': user.uid,
        'email': emailTrim,
        'continueUrl': continueUrl,
      });
 
      await user.sendEmailVerification(actionCodeSettings);
 
      AppLogger.log('AUTH_SERVICE', 'SIGNUP_VERIFICATION_SEND_OK', data: {
        'uid': user.uid,
      });
 
      await auth.signOut();
 
      AppLogger.log('AUTH_SERVICE', 'SIGNUP_SIGNOUT_OK', data: {
        'uid': user.uid,
      });
 
      return null;
    } on FirebaseAuthException catch (e) {
      AppLogger.log('AUTH_SERVICE', 'SIGNUP_ERROR', data: {
        'email': emailTrim,
        'code': e.code,
        'message': e.message,
      });
      return mapAuthError(e.code);
    } catch (e) {
      AppLogger.log('AUTH_SERVICE', 'SIGNUP_ERROR', data: {
        'email': emailTrim,
        'error': e.toString(),
      });
      return 'Erro inesperado ao criar conta.';
    }
  }
 
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    final emailTrim = email.trim();
 
    AppLogger.log('AUTH_SERVICE', 'LOGIN_START', data: {
      'email': emailTrim,
    });
 
    try {
      final cred = await auth.signInWithEmailAndPassword(
        email: emailTrim,
        password: password,
      );
 
      final user = cred.user;
      if (user == null) {
        AppLogger.log('AUTH_SERVICE', 'LOGIN_ERROR', data: {
          'email': emailTrim,
          'reason': 'user_null_after_login',
        });
        return 'Falha ao autenticar usuário.';
      }
 
      AppLogger.log('AUTH_SERVICE', 'LOGIN_AUTH_OK', data: {
        'uid': user.uid,
        'email': user.email,
        'emailVerifiedBeforeReload': user.emailVerified,
      });
 
      AppLogger.log('AUTH_SERVICE', 'LOGIN_RELOAD_START', data: {
        'uid': user.uid,
      });
 
      await user.reload();
 
      final refreshed = auth.currentUser;
 
      AppLogger.log('AUTH_SERVICE', 'LOGIN_RELOAD_OK', data: {
        'uid': refreshed?.uid,
        'emailVerifiedAfterReload': refreshed?.emailVerified,
      });
 
      if (refreshed != null && !refreshed.emailVerified) {
        AppLogger.log('AUTH_SERVICE', 'LOGIN_EMAIL_VERIFIED_FALSE', data: {
          'uid': refreshed.uid,
          'email': refreshed.email,
        });
        return 'E-mail não verificado.';
      }
 
      AppLogger.log('AUTH_SERVICE', 'LOGIN_EMAIL_VERIFIED_TRUE', data: {
        'uid': refreshed?.uid,
        'email': refreshed?.email,
      });
 
      return null;
    } on FirebaseAuthException catch (e) {
      AppLogger.log('AUTH_SERVICE', 'LOGIN_ERROR', data: {
        'email': emailTrim,
        'code': e.code,
        'message': e.message,
      });
      return mapAuthError(e.code);
    } catch (e) {
      AppLogger.log('AUTH_SERVICE', 'LOGIN_ERROR', data: {
        'email': emailTrim,
        'error': e.toString(),
      });
      return 'Erro inesperado ao entrar.';
    }
  }
 
  Future<String?> resetPassword(String email) async {
    final emailTrim = email.trim();
 
    AppLogger.log('AUTH_SERVICE', 'RESET_PASSWORD_START', data: {
      'email': emailTrim,
    });
 
    try {
      await auth.sendPasswordResetEmail(email: emailTrim);
 
      AppLogger.log('AUTH_SERVICE', 'RESET_PASSWORD_OK', data: {
        'email': emailTrim,
      });
 
      return null;
    } on FirebaseAuthException catch (e) {
      AppLogger.log('AUTH_SERVICE', 'RESET_PASSWORD_ERROR', data: {
        'email': emailTrim,
        'code': e.code,
        'message': e.message,
      });
      return mapAuthError(e.code);
    } catch (e) {
      AppLogger.log('AUTH_SERVICE', 'RESET_PASSWORD_ERROR', data: {
        'email': emailTrim,
        'error': e.toString(),
      });
      return 'Erro inesperado ao redefinir senha.';
    }
  }
 
  String mapAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Este e-mail já está em uso.';
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'weak-password':
        return 'A senha é muito fraca.';
      case 'user-not-found':
        return 'Usuário não encontrado.';
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'user-disabled':
        return 'Este usuário foi desativado.';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde.';
      case 'network-request-failed':
        return 'Sem conexão com a internet.';
      default:
        return 'Erro de autenticação: $code';
    }
  }
}
