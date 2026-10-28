import 'dart:async';

import 'package:flutter/material.dart';

void main() {
  runApp(const AplicacionControlFlota());
}

class TelemetriaCamion {
  final String economico; // Identificador numérico del vehículo
  final int kilometraje;
  final double nivelCombustible; // Valor porcentual (0.0 a 1.0)
  final String ultimaAlerta;

  TelemetriaCamion({
    required this.economico,
    required this.kilometraje,
    required this.nivelCombustible,
    required this.ultimaAlerta,
  });
}

Future<Map<String, String>> recuperarConfiguracionCentral() async {
  return Future<Map<String, String>>.delayed(
    const Duration(seconds: 2),
    () => {
      'nombreCentroCarga': 'Centro de Distribución Norte',
      'enlace': 'https://central.flotas.example',
      'region': 'Noreste',
      'estado': 'Operativo',
    },
  );
}

Stream<List<TelemetriaCamion>> simularFlujoTelemetria() async* {
  var kilometrajes = <int>[125430, 98210, 201875];
  var nivelesCombustible = <double>[0.82, 0.47, 0.63];
  var iteracion = 0;

  while (true) {
    await Future<void>.delayed(const Duration(seconds: 2));
    iteracion++;

    kilometrajes = [
      kilometrajes[0] + 37,
      kilometrajes[1] + 24,
      kilometrajes[2] + 42,
    ];
    nivelesCombustible = [
      (nivelesCombustible[0] - 0.01).clamp(0.0, 1.0),
      (nivelesCombustible[1] - 0.015).clamp(0.0, 1.0),
      (nivelesCombustible[2] - 0.008).clamp(0.0, 1.0),
    ];

    yield [
      TelemetriaCamion(
        economico: '101',
        kilometraje: kilometrajes[0],
        nivelCombustible: nivelesCombustible[0],
        ultimaAlerta: iteracion % 3 == 0
            ? 'Mantenimiento preventivo próximo'
            : 'Sin alertas',
      ),
      TelemetriaCamion(
        economico: '202',
        kilometraje: kilometrajes[1],
        nivelCombustible: nivelesCombustible[1],
        ultimaAlerta: iteracion % 2 == 0
            ? 'Nivel de combustible bajo'
            : 'Sin alertas',
      ),
      TelemetriaCamion(
        economico: '303',
        kilometraje: kilometrajes[2],
        nivelCombustible: nivelesCombustible[2],
        ultimaAlerta: iteracion % 4 == 0
            ? 'Desvío de ruta detectado'
            : 'Sin alertas',
      ),
    ];
  }
}

class AplicacionControlFlota extends StatelessWidget {
  const AplicacionControlFlota({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Control de flota',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const TableroFlota(),
    );
  }
}

class TableroFlota extends StatefulWidget {
  const TableroFlota({super.key});

  @override
  State<TableroFlota> createState() => _TableroFlotaState();
}

class _TableroFlotaState extends State<TableroFlota> {
  late final Future<Map<String, String>> _configuracionFuture;
  late final StreamController<List<TelemetriaCamion>> _telemetriaController;
  late final Stream<List<TelemetriaCamion>> _telemetriaStream;
  late final StreamSubscription<List<TelemetriaCamion>> _telemetriaSubscription;

  @override
  void initState() {
    super.initState();
    _configuracionFuture = recuperarConfiguracionCentral();
    _telemetriaController =
        StreamController<List<TelemetriaCamion>>.broadcast();
    _telemetriaStream = _telemetriaController.stream;
    _telemetriaSubscription = simularFlujoTelemetria().listen((telemetria) {
      if (!_telemetriaController.isClosed) {
        _telemetriaController.add(telemetria);
      }
    });
  }

  @override
  void dispose() {
    unawaited(_telemetriaSubscription.cancel());
    unawaited(_telemetriaController.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Control de flota'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildEstadoServidor(),
          Expanded(child: _buildTelemetria()),
        ],
      ),
    );
  }

  Widget _buildEstadoServidor() {
    return FutureBuilder<Map<String, String>>(
      future: _configuracionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildPanel(
            const CircularProgressIndicator(),
            'Conectando con el servidor central...',
          );
        }

        if (snapshot.hasError) {
          return _buildPanel(
            const Icon(Icons.cloud_off, color: Colors.red, size: 32),
            'Error de red al recuperar la configuración central',
          );
        }

        if (snapshot.hasData) {
          final configuracion = snapshot.data!;
          return Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    configuracion['nombreCentroCarga'] ?? 'Centro sin nombre',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  _buildDatoServidor(
                    Icons.link,
                    'Enlace',
                    configuracion['enlace'],
                  ),
                  _buildDatoServidor(
                    Icons.public,
                    'Región',
                    configuracion['region'],
                  ),
                  _buildDatoServidor(
                    Icons.check_circle,
                    'Estado',
                    configuracion['estado'],
                  ),
                ],
              ),
            ),
          );
        }

        return _buildPanel(
          const Icon(Icons.info_outline),
          'No hay datos del servidor central',
        );
      },
    );
  }

  Widget _buildTelemetria() {
    return StreamBuilder<List<TelemetriaCamion>>(
      stream: _telemetriaStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error de telemetría: ${snapshot.error}'));
        }

        if (snapshot.hasData) {
          final camiones = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            itemCount: camiones.length,
            itemBuilder: (context, index) {
              return _buildCamionCard(camiones[index]);
            },
          );
        }

        return const Center(child: Text('Esperando datos de telemetría...'));
      },
    );
  }

  Widget _buildPanel(Widget indicador, String mensaje) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            indicador,
            const SizedBox(width: 16),
            Expanded(child: Text(mensaje)),
          ],
        ),
      ),
    );
  }

  Widget _buildDatoServidor(IconData icono, String etiqueta, String? valor) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icono, size: 18),
          const SizedBox(width: 8),
          Text('$etiqueta: ${valor ?? 'No disponible'}'),
        ],
      ),
    );
  }

  Widget _buildCamionCard(TelemetriaCamion camion) {
    final porcentaje = camion.nivelCombustible * 100;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Camión ${camion.economico}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text('${camion.kilometraje} km'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: camion.nivelCombustible,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(width: 12),
                Text('${porcentaje.toStringAsFixed(0)}%'),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              camion.ultimaAlerta,
              style: TextStyle(
                color: camion.ultimaAlerta == 'Sin alertas'
                    ? Colors.green
                    : Colors.orange.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
