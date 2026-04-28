import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:math' as math;

// ExtensÃ£o para cÃ¡lculo de distÃ¢ncia
extension LatLngDistance on LatLng {
  double distanceTo(LatLng other) {
    const double earthRadius = 6371;
    final dLat = (other.latitude - latitude) * math.pi / 180;
    final dLng = (other.longitude - longitude) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(latitude * math.pi / 180) *
            math.cos(other.latitude * math.pi / 180) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return earthRadius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }
}

class VanMapWidget extends StatefulWidget {
  final String motoristaUid;
  final double? alunoLat;
  final double? alunoLng;

  const VanMapWidget({
    Key? key,
    required this.motoristaUid,
    this.alunoLat,
    this.alunoLng,
  }) : super(key: key);

  @override
  State<VanMapWidget> createState() => _VanMapWidgetState();
}

class _VanMapWidgetState extends State<VanMapWidget> {
  GoogleMapController? _mapController;
  bool _seguirVan = true;
  LatLng? _alunoPosition;

  @override
  void initState() {
    super.initState();
    if (widget.alunoLat != null && widget.alunoLng != null) {
      _alunoPosition = LatLng(widget.alunoLat!, widget.alunoLng!);
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.motoristaUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Erro ao carregar mapa'));
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final geoPoint = data?['localizacao'];
        if (geoPoint is! GeoPoint) {
          return const Center(child: Text('Localização indisponível'));
        }
        final vanPosition = LatLng(geoPoint.latitude, geoPoint.longitude);


        if (_seguirVan && _mapController != null) {
          _mapController!.animateCamera(CameraUpdate.newLatLng(vanPosition));
        }

        return _buildMapStack(vanPosition);
      },
    );
  }

  Widget _buildMapStack(LatLng vanPosition) {
    final distancia = _alunoPosition?.distanceTo(vanPosition);

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: vanPosition, zoom: 15),
          markers: {
            Marker(markerId: const MarkerId('van'), position: vanPosition),
            if (_alunoPosition != null)
              Marker(markerId: const MarkerId('aluno'), position: _alunoPosition!, icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)),
          },
          polylines: _alunoPosition != null ? {
            Polyline(
              polylineId: const PolylineId('rota'),
              points: [vanPosition, _alunoPosition!],
              color: Colors.blue,
              width: 4,
              patterns: [PatternItem.dash(20), PatternItem.gap(10)],
            )
          } : {},
          onMapCreated: (c) => _mapController = c,
          onCameraMove: (_) => _seguirVan = false,
        ),
        if (distancia != null) _buildDistanceCard(distancia),
        Positioned(
          bottom: 80,
          right: 16,
          child: FloatingActionButton(
            mini: true,
            onPressed: () => setState(() => _seguirVan = true),
            child: const Icon(Icons.my_location),
          ),
        ),
      ],
    );
  }

  Widget _buildDistanceCard(double distancia) => Positioned(
    top: 16, left: 16, right: 16,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          distancia < 1 ? '${(distancia * 1000).toStringAsFixed(0)} metros' : '${distancia.toStringAsFixed(1)} km',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}