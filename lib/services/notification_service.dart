import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static bool _configured = false;

  static Future<void> onUserSignedIn(String uid, BuildContext context) async {
    if (!_configured) {
      _configured = true;

      await FirebaseMessaging.instance.requestPermission();

      FirebaseMessaging.onMessage.listen((message) {
        if (!context.mounted) return;

        final notification = message.notification;
        if (notification != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${notification.title ?? 'Notificação'}: ${notification.body ?? ''}',
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      });
    }

    await syncToken(uid);
  }

  static void onUserSignedOut() {}

  static Future<void> syncToken(String uid) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set(
          {
            'fcmToken': token,
            'lastTokenUpdate': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
    } catch (e) {
      debugPrint('Erro ao sincronizar token: $e');
    }
  }
}