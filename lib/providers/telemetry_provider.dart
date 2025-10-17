import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

class TelemetryProvider extends ChangeNotifier {
  Position? _currentPosition;
  Position? _previousPosition;
  double _speed = 0.0;
  double _heading = 0.0;
  List<double> _acceleration = [0, 0, 0];
  bool _isCollecting = false;
  String? _errorMessage;
  
  List<double> _speedHistory = [];
  double _maxSpeed = 0.0;
  double _avgSpeed = 0.0;
  double _totalDistance = 0.0;
  DateTime? _sessionStartTime;
  int _dataPoints = 0;

  // Streams
  StreamSubscription<Position>? _locationStream;
  StreamSubscription<AccelerometerEvent>? _accelStream;
  StreamSubscription<MagnetometerEvent>? _compassStream;

  // Getters
  Position? get position => _currentPosition;
  double get speed => _speed;
  double get heading => _heading;
  List<double> get acceleration => _acceleration;
  bool get isCollecting => _isCollecting;
  String? get errorMessage => _errorMessage;
  
  // Getters para metricas avançadas
  List<double> get speedHistory => _speedHistory.length > 50 
      ? _speedHistory.sublist(_speedHistory.length - 50) 
      : _speedHistory;
  double get maxSpeed => _maxSpeed;
  double get avgSpeed => _avgSpeed;
  double get totalDistance => _totalDistance;
  Duration get sessionDuration => _sessionStartTime != null 
      ? DateTime.now().difference(_sessionStartTime!) 
      : Duration.zero;
  int get dataPoints => _dataPoints;

  Future<void> startCollection() async {
    _errorMessage = null;
    notifyListeners();

    // verificando as permissões de localizacao
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _errorMessage = 'Serviço de localização está desabilitado.\nPor favor, ative o GPS nas configurações do dispositivo.';
      notifyListeners();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _errorMessage = 'Permissão de localização negada.\nO aplicativo precisa acessar sua localização para funcionar.';
        notifyListeners();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _errorMessage = 'Permissão de localização permanentemente negada.\nVá em Configurações > Apps > Mobs2 > Permissões e habilite a localização.';
      notifyListeners();
      return;
    }

    _isCollecting = true;
    _sessionStartTime = DateTime.now();
    _speedHistory.clear();
    _maxSpeed = 0.0;
    _avgSpeed = 0.0;
    _totalDistance = 0.0;
    _dataPoints = 0;
    notifyListeners();

    _locationStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1, 
      )
    ).listen(
      (Position pos) {
        if (!_isValidGPSData(pos)) {
          debugPrint('⚠️ GPS data validation failed, skipping update');
          return;
        }

        if (_previousPosition != null) {
          if (pos.speed <= 0 || pos.speed < 0.1) {
            final distance = Geolocator.distanceBetween(
              _previousPosition!.latitude,
              _previousPosition!.longitude,
              pos.latitude,
              pos.longitude,
            );
            
            final timeDiff = pos.timestamp.difference(_previousPosition!.timestamp).inMilliseconds;
            if (timeDiff > 0) {
              _speed = (distance / timeDiff) * 1000; 
            }
          } else {
            _speed = pos.speed;
          }

          if (_speed > 0.5) { // só calcular heading se estiver se movendo
            if (pos.heading >= 0 && pos.heading <= 360) {
              _heading = pos.heading;
            } else {
              _heading = Geolocator.bearingBetween(
                _previousPosition!.latitude,
                _previousPosition!.longitude,
                pos.latitude,
                pos.longitude,
              );
              if (_heading < 0) _heading += 360;
            }
          }
        } else {
          _speed = pos.speed > 0 ? pos.speed : 0.0;
          _heading = pos.heading >= 0 && pos.heading <= 360 ? pos.heading : 0.0;
        }

        _previousPosition = _currentPosition;
        _currentPosition = pos;
        
        _updateMetrics();
        
        debugPrint('📍 Position: ${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}');
        debugPrint('⚡ Speed: ${_speed.toStringAsFixed(2)} m/s (${(_speed * 3.6).toStringAsFixed(2)} km/h)');
        debugPrint('🧭 Heading: ${_heading.toStringAsFixed(1)}°');
        debugPrint('📊 Max: ${_maxSpeed.toStringAsFixed(1)} km/h | Avg: ${_avgSpeed.toStringAsFixed(1)} km/h | Distance: ${_totalDistance.toStringAsFixed(0)}m');
        
        notifyListeners();
      },
      onError: (error) {
        debugPrint('❌ GPS Error: $error');
        _errorMessage = 'Erro ao obter localização.\nVerifique se o GPS está ativo e tente novamente.';
        _isCollecting = false;
        notifyListeners();
      },
    );

    _accelStream = accelerometerEvents.listen(
      (event) {
        _acceleration = [event.x, event.y, event.z];
        notifyListeners();
      },
      onError: (error) {
        debugPrint('❌ Accelerometer Error: ');
      },
    );

    _compassStream = magnetometerEvents.listen(
      (event) {
        if ((_heading == 0.0 || _speed < 0.3) && _currentPosition != null) {
          double magnetHeading = atan2(event.y, event.x) * (180 / pi);
          if (magnetHeading < 0) magnetHeading += 360;
          
          if (_speed < 0.3) {
            _heading = magnetHeading;
            notifyListeners();
          }
        }
      },
      onError: (error) {
        debugPrint('❌ Magnetometer Error: $error');
      },
    );

    debugPrint('✅ Telemetry collection started');
  }

  void stopCollection() {
    _isCollecting = false;
    _locationStream?.cancel();
    _accelStream?.cancel();
    _compassStream?.cancel();
    _previousPosition = null;
    debugPrint('⏹️ Telemetry collection stopped');
    notifyListeners();
  }

  void _updateMetrics() {
    if (_currentPosition == null) return;
    
    _dataPoints++;
    
    double speedKmh = _speed * 3.6;
    _speedHistory.add(speedKmh);
    
    if (_speedHistory.length > 100) {
      _speedHistory.removeAt(0);
    }
    
    if (speedKmh > _maxSpeed) {
      _maxSpeed = speedKmh;
    }
    
    if (_speedHistory.isNotEmpty) {
      _avgSpeed = _speedHistory.reduce((a, b) => a + b) / _speedHistory.length;
    }
    
    if (_previousPosition != null) {
      double distance = Geolocator.distanceBetween(
        _previousPosition!.latitude,
        _previousPosition!.longitude,
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      _totalDistance += distance;
    }
  }

  bool _isValidGPSData(Position pos) {
    
    if (pos.latitude.abs() > 90 || pos.longitude.abs() > 180) {
      return false;
    }
    
    if (pos.accuracy > 50) { // 50 metros de precisão maxima
      return false;
    }
    
    if (pos.speed > 55.5) { // 200 km/h em m/s
      return false;
    }
    
    if (_previousPosition != null) {
      double distance = Geolocator.distanceBetween(
        _previousPosition!.latitude,
        _previousPosition!.longitude,
        pos.latitude,
        pos.longitude,
      );
      
      int timeDiff = pos.timestamp.difference(_previousPosition!.timestamp).inSeconds;
      if (distance < 1 && timeDiff > 10) {
      }
      
      if (timeDiff > 0) {
        double calculatedSpeed = distance / timeDiff;
        if (calculatedSpeed > 138.8) { // 500 km/h em m/s
          return false;
        }
      }
    }
    
    return true;
  }

  @override
  void dispose() {
    stopCollection();
    super.dispose();
  }
}
