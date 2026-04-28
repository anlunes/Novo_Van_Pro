import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

/// Service de rastreamento GPS com gerenciamento de ciclo de vida.
/// Implementado como Singleton para garantir instância única.
class TrackingService {
  // Singleton Pattern
  TrackingService._internal();
  static final TrackingService _instance = TrackingService._internal();
  factory TrackingService() => _instance;

  StreamSubscription<Position>? _positionSubscription;
  String? _motoristaUid;

  bool get estaRastreando => _positionSubscription != null;

  /// Inicia rastreamento GPS.
  Future<void> iniciarRastreamento(String motoristaUid) async {
    if (estaRastreando) await pararRastreamento();

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('GPS desabilitado.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Permissão de localização negada.');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Permissão negada permanentemente.');
    }

    _motoristaUid = motoristaUid;
    
    // Configuração corrigida: removido timeLimit inválido e ajustado para melhor precisão
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 30,
      ),
    ).listen(
      _atualizarFirestore,
      onError: (error) => debugPrint('❌ Erro GPS: $error'),
    );

    debugPrint('✅ Rastreamento iniciado — motorista: $motoristaUid');
  }

  /// Salva localização usando set com merge para evitar erro de documento inexistente.
  Future<void> _atualizarFirestore(Position position) async {
    final uid = _motoristaUid;
    if (uid == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'localizacao': GeoPoint(position.latitude, position.longitude),
        'localizacao_atualizada_em': FieldValue.serverTimestamp(),
        'velocidade_ms': position.speed,
        'precisao_gps': position.accuracy,
      }, SetOptions(merge: true));
      debugPrint('📍 ${position.latitude}, ${position.longitude}');
    } catch (e) {
      debugPrint('❌ Erro ao salvar localização: $e');
    }
  }

  /// Para o rastreamento e limpa os dados no Firestore.
  Future<void> pararRastreamento() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;

    final uid = _motoristaUid;
    if (uid != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'localizacao': FieldValue.delete(),
          'localizacao_atualizada_em': FieldValue.delete(),
          'velocidade_ms': FieldValue.delete(),
          'precisao_gps': FieldValue.delete(),
        });
      } catch (e) {
        debugPrint('⚠️ Erro ao limpar dados no Firestore: $e');
      }
    }

    _motoristaUid = null;
    debugPrint('⏸️ Rastreamento pausado');
  }

  void dispose() {
    pararRastreamento();
  }
}