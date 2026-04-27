import 'package:flutter/material.dart';

class SecaoHorariosWidget extends StatefulWidget {
  final String? horarioEntradaInicial;
  final String? horarioSaidaInicial;

  final Function(String) onEntradaChanged;
  final Function(String) onSaidaChanged;

  const SecaoHorariosWidget({
    super.key,
    this.horarioEntradaInicial,
    this.horarioSaidaInicial,
    required this.onEntradaChanged,
    required this.onSaidaChanged,
  });

  @override
  State<SecaoHorariosWidget> createState() => _SecaoHorariosWidgetState();
}

class _SecaoHorariosWidgetState extends State<SecaoHorariosWidget> {
  late TextEditingController _entradaController;
  late TextEditingController _saidaController;

  @override
  void initState() {
    super.initState();
    _entradaController = TextEditingController(text: widget.horarioEntradaInicial ?? '');
    _saidaController = TextEditingController(text: widget.horarioSaidaInicial ?? '');
  }

  @override
  void didUpdateWidget(covariant SecaoHorariosWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.horarioEntradaInicial != oldWidget.horarioEntradaInicial) {
      _entradaController.text = widget.horarioEntradaInicial ?? '';
    }
    if (widget.horarioSaidaInicial != oldWidget.horarioSaidaInicial) {
      _saidaController.text = widget.horarioSaidaInicial ?? '';
    }
  }

  @override
  void dispose() {
    _entradaController.dispose();
    _saidaController.dispose();
    super.dispose();
  }

  Future<void> _selecionarHorario(
    BuildContext context,
    TextEditingController controller,
    Function(String) callback,
  ) async {
    final initialTime = _parseTimeOfDay(controller.text);
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      final String horarioFormatado =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      controller.text = horarioFormatado;
      callback(horarioFormatado);
    }
  }

  TimeOfDay? _parseTimeOfDay(String time) {
    try {
      final parts = time.split(':');
      if (parts.length != 2) return null;
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (_) {
      return null;
    }
  }

  Widget _buildHorarioField({
    required String label,
    required TextEditingController controller,
    required Function(String) callback,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            readOnly: true,
            onTap: () => _selecionarHorario(context, controller, callback),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.access_time),
              suffixIcon: const Icon(Icons.edit),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: color,
              hintText: 'HH:MM',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HORÁRIOS DE TRANSPORTE',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildHorarioField(
                label: 'Horário de Entrada',
                controller: _entradaController,
                callback: widget.onEntradaChanged,
                color: Colors.amber.shade50,
              ),
              const SizedBox(width: 16),
              _buildHorarioField(
                label: 'Horário de Saída',
                controller: _saidaController,
                callback: widget.onSaidaChanged,
                color: Colors.green.shade50,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.info, color: Colors.blue, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Toque nos campos para definir os horários de saída e chegada na escola',
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}