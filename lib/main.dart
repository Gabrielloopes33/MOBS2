import 'package:flutter/material.dart';
import 'package:mobs2/providers/telemetry_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' show pi;



void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TelemetryProvider())
      ],
      child: const MyApp(),
    )
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Telemetria Mobs2',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const TelemetryScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TelemetryScreen extends StatefulWidget {
  const TelemetryScreen({super.key});

  @override
  State<TelemetryScreen> createState() => _TelemetryScreenState();
}

class _TelemetryScreenState extends State<TelemetryScreen> {
  final MapController _mapController = MapController();
  bool _isExpanded = false; // Estado do painel expandido

  @override
  void initState() {
    super.initState();
    // Iniciar coleta automaticamente quando o app abre
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final telemetry = Provider.of<TelemetryProvider>(context, listen: false);
      if (!telemetry.isCollecting) {
        telemetry.startCollection();
      }
    });
  }

  String _formatDirection(double heading) {
    if (heading < 0) heading += 360;
    if (heading >= 360) heading -= 360;
    
    List<String> directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    int index = ((heading + 22.5) / 45).floor() % 8;
    return directions[index];
  }

  @override
  Widget build(BuildContext context) {
    final telemetry = context.watch<TelemetryProvider>();
    final pos = telemetry.position;

    if (pos != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Centralizar automaticamente quando há mudança de localização
        if (telemetry.isCollecting) {
          _mapController.move(
            LatLng(pos.latitude, pos.longitude),
            _mapController.camera.zoom,
          );
        }
      });
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: pos == null
          ? Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.grey[50]!,
                    Colors.grey[100]!,
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (telemetry.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(Icons.error_outline, 
                                         size: 48, 
                                         color: Colors.red[400]),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              telemetry.errorMessage!,
                              style: TextStyle(
                                color: Colors.red[600], 
                                fontSize: 16,
                                fontWeight: FontWeight.w500
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () {
                                telemetry.startCollection();
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Tentar Novamente'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple[500],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24, 
                                  vertical: 12
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple[50],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(Icons.gps_fixed, 
                                       size: 48, 
                                       color: Colors.deepPurple[400]),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            telemetry.isCollecting 
                                ? 'Aguardando GPS...' 
                                : 'Iniciando coleta...',
                            style: const TextStyle(
                              fontSize: 16, 
                              fontWeight: FontWeight.w500
                            ),
                          ),
                          const SizedBox(height: 16),
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple[400]!),
                            strokeWidth: 3,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Aguarde alguns segundos para o GPS se conectar',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            )
          : Stack(
              children: [
                // Mapa ocupando toda a tela
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(pos.latitude, pos.longitude),
                    initialZoom: 17.0,
                    minZoom: 5.0,
                    maxZoom: 20.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.mobs2',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(pos.latitude, pos.longitude),
                          width: 80,
                          height: 80,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.deepPurple[600],
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.deepPurple.withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Transform.rotate(
                              angle: telemetry.heading * (pi / 180),
                              child: const Icon(
                                Icons.navigation,
                                size: 24,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                // Controles do mapa (canto superior direito, todos agrupados)
                Positioned(
                  top: 60, // Espaço para status bar
                  right: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Botão de zoom in
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              final zoom = _mapController.camera.zoom;
                              _mapController.move(
                                _mapController.camera.center,
                                zoom + 1,
                              );
                            },
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: const BoxDecoration(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                              ),
                              child: Icon(
                                Icons.add,
                                size: 20,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ),
                        
                        // Divisor
                        Container(
                          height: 1,
                          width: 32,
                          color: Colors.grey[200],
                        ),
                        
                        // Botão de zoom out
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              final zoom = _mapController.camera.zoom;
                              _mapController.move(
                                _mapController.camera.center,
                                zoom - 1,
                              );
                            },
                            child: Container(
                              width: 48,
                              height: 48,
                              child: Icon(
                                Icons.remove,
                                size: 20,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ),
                        
                        // Divisor
                        Container(
                          height: 1,
                          width: 32,
                          color: Colors.grey[200],
                        ),
                        
                        // Botão de centralizar
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              _mapController.move(
                                LatLng(pos.latitude, pos.longitude),
                                17.0,
                              );
                            },
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: const BoxDecoration(
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(16),
                                  bottomRight: Radius.circular(16),
                                ),
                              ),
                              child: Icon(
                                Icons.my_location,
                                size: 20,
                                color: Colors.deepPurple[600],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Painel deslizante minimalista
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    onPanUpdate: (details) {
                      // Detectar arraste para cima/baixo
                      if (details.delta.dy < -5 && !_isExpanded) {
                        setState(() {
                          _isExpanded = true;
                        });
                      } else if (details.delta.dy > 5 && _isExpanded) {
                        setState(() {
                          _isExpanded = false;
                        });
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Indicador visual do painel (sempre visível)
                            Container(
                              width: 36,
                              height: 4,
                              decoration: BoxDecoration(
                                color: _isExpanded ? Colors.deepPurple[300] : Colors.grey[300],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Conteúdo compacto (sempre visível)
                            _buildCompactContent(telemetry),
                            
                            // Conteúdo expandido (só quando _isExpanded = true)
                            if (_isExpanded) ...[
                              const SizedBox(height: 20),
                              _buildExpandedContent(telemetry, pos),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
  
  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$minutes:$seconds";
  }
  
  Widget _buildCompactContent(TelemetryProvider telemetry) {
    return Column(
      children: [
        // Cards de velocidade e direção (sempre visíveis)
        Row(
          children: [
            // Velocidade
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    Icon(Icons.speed, color: Colors.deepPurple[400], size: 20),
                    const SizedBox(height: 8),
                    Text(
                      '${(telemetry.speed * 3.6).toStringAsFixed(1)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'km/h',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Direção
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    Transform.rotate(
                      angle: telemetry.heading * (pi / 180),
                      child: Icon(Icons.navigation, color: Colors.deepPurple[400], size: 20),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${telemetry.heading.toStringAsFixed(0)}°',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _formatDirection(telemetry.heading),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        // Botão de controle (sempre visível)
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () {
              telemetry.isCollecting 
                  ? telemetry.stopCollection() 
                  : telemetry.startCollection();
            },
            icon: Icon(
              telemetry.isCollecting ? Icons.stop : Icons.play_arrow,
              size: 20,
            ),
            label: Text(
              telemetry.isCollecting ? 'Parar Coleta' : 'Iniciar Coleta',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: telemetry.isCollecting 
                  ? Colors.red[400] 
                  : Colors.deepPurple[500],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
              shadowColor: Colors.transparent,
            ),
          ),
        ),
        
        // Dica visual para expandir
        if (!_isExpanded)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.keyboard_arrow_up, color: Colors.grey[400], size: 16),
                const SizedBox(width: 4),
                Text(
                  'Deslize para ver mais dados',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
  
  Widget _buildExpandedContent(TelemetryProvider telemetry, Position pos) {
    return Column(
      children: [
        // Métricas avançadas
        if (telemetry.dataPoints > 0)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.analytics, color: Colors.deepPurple[400], size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Estatísticas da Sessão',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Máx', '${telemetry.maxSpeed.toStringAsFixed(1)} km/h'),
                    _buildStatItem('Média', '${telemetry.avgSpeed.toStringAsFixed(1)} km/h'),
                    _buildStatItem('Distância', '${(telemetry.totalDistance / 1000).toStringAsFixed(2)} km'),
                    _buildStatItem('Tempo', _formatDuration(telemetry.sessionDuration)),
                  ],
                ),
              ],
            ),
          ),
        if (telemetry.dataPoints > 0)
          const SizedBox(height: 12),
        
        // Aceleração
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.speed, color: Colors.deepPurple[400], size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Aceleração',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        'X',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        telemetry.acceleration[0].toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        'Y',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        telemetry.acceleration[1].toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        'Z',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        telemetry.acceleration[2].toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Coordenadas
        Text(
          'Lat: ${pos.latitude.toStringAsFixed(6)}, Lon: ${pos.longitude.toStringAsFixed(6)}',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[500],
          ),
        ),
        
        // Dica para recolher
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.keyboard_arrow_down, color: Colors.grey[400], size: 16),
              const SizedBox(width: 4),
              Text(
                'Toque para recolher',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
