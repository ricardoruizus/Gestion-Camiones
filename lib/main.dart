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
  late final StreamSubscription<List<TelemetriaCamion>> _telemetriaSubscription;

  List<TelemetriaCamion> _telemetriaActual = const [];

  @override
  void initState() {
    super.initState();
    _configuracionFuture = recuperarConfiguracionCentral();
    _telemetriaSubscription = simularFlujoTelemetria().listen((telemetria) {
      if (!mounted) {
        return;
      }

      setState(() {
        _telemetriaActual = telemetria;
      });
    });
  }

  @override
  void dispose() {
    unawaited(_telemetriaSubscription.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FutureBuilder<Map<String, String>>(
          future: _configuracionFuture,
          builder: (context, snapshot) {
            final camionesConectados = _telemetriaActual.length;
            final estado = snapshot.hasData
                ? 'Configuración recibida'
                : 'Conectando...';
            return Text(
              'Tablero de control de flota\n$estado\n'
              'Camiones conectados: $camionesConectados',
              textAlign: TextAlign.center,
            );
          },
        ),
      ),
    );
  }
}
