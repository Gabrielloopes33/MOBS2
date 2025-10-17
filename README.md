# 🛰 Case Técnico Flutter - Mobs2

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![iOS](https://img.shields.io/badge/iOS-000000?style=for-the-badge&logo=ios&logoColor=white)

## 🎯 Sobre o Projeto

Aplicativo Flutter de **telemetria em tempo real** que coleta e exibe dados de GPS, sensores e movimento, desenvolvido como case técnico para demonstrar competências em desenvolvimento mobile nativo.

### ✨ Funcionalidades Principais

- 📍 **Localização GPS em tempo real** com precisão aprimorada
- 🏃‍♂️ **Velocidade dinâmica** (GPS + cálculo manual de fallback)
- 🧭 **Direção inteligente** (GPS + magnetômetro como backup)
- 📊 **Aceleração 3D** via sensores do dispositivo (X, Y, Z)
- 📈 **Métricas avançadas** (velocidade máx/média, distância, tempo de sessão)
- 🗺️ **Mapa interativo** com marcador rotativo baseado na direção

## 🚀 Demo em Vídeo

> 📱 *Grave um vídeo de 30-60s mostrando o app funcionando*

## 🏗️ Arquitetura & Tecnologias

### **📱 Stack Técnica**
```dart
dependencies:
  flutter: sdk
  provider: ^6.1.0          # Gerenciamento de estado reativo
  geolocator: ^10.1.0       # GPS e localização
  sensors_plus: ^3.0.0      # Acelerômetro e magnetômetro
  flutter_map: ^7.0.2       # Mapas OpenStreetMap
  latlong2: ^0.9.1          # Coordenadas geográficas
  fl_chart: ^1.1.1          # Gráficos (preparado para expansão)
```

### **🎯 Padrões Implementados**
- **Provider Pattern** para gerenciamento de estado
- **Reactive Programming** com Streams
- **Clean Architecture** com separação de responsabilidades
- **Error Handling** robusto com recovery automático
- **Memory Management** otimizado (dispose adequado de streams)

### **🛡️ Validações & Robustez**
- Filtro de precisão GPS (>50m rejeitado)
- Detecção de outliers de velocidade (>200 km/h)
- Validação de coordenadas geográficas
- Tratamento de drift de GPS
- Fallbacks inteligentes para dados corrompidos

## 🎨 UX/UI Design

### **📐 Interface Responsiva**
- **Design minimalista** inspirado em apps modernos de navegação
- **Painel deslizante** com conteúdo expansível
- **Animações suaves** (300ms easeInOut)
- **Estados visuais claros** para todas as interações
- **Tema consistente** seguindo identidade visual Mobs2

### **🎮 Interações Intuitivas**
- ☝️ **Toque**: Expande/recolhe painel
- 👆 **Arraste para cima**: Mostra estatísticas detalhadas
- 👇 **Arraste para baixo**: Recolhe para vista compacta
- 🎯 **Centralização automática**: GPS sempre em foco

## 📊 Métricas em Tempo Real

| Métrica | Descrição | Implementação |
|---------|-----------|---------------|
| **Velocidade** | km/h e m/s | GPS + cálculo manual de backup |
| **Direção** | Graus + cardeal (N,S,E,W) | GPS + magnetômetro híbrido |
| **Aceleração** | 3 eixos (X,Y,Z) | Sensores nativos do device |
| **Distância** | Total percorrido | Cálculo incremental GPS |
| **Tempo** | Duração da sessão | Timer formatado (HH:MM:SS) |
| **Velocidade Máx** | Pico registrado | Histórico da sessão |
| **Velocidade Média** | Média ponderada | Cálculo dinâmico |

## 🔧 Configuração & Execução

### **📋 Pré-requisitos**
```bash
Flutter SDK: >=3.9.2
Dart SDK: >=3.0.0
Android SDK: API 21+ (Android 5.0+)
iOS: 11.0+
```

### **⚡ Quick Start**
```bash
# Clone o repositório
git clone https://github.com/[seu-usuario]/mobs2-telemetry.git
cd mobs2-telemetry

# Instalar dependências
flutter pub get

# Executar em dispositivo/emulador
flutter run

# Build para produção
flutter build apk --release     # Android
flutter build ios --release     # iOS
```

### **🔐 Permissões Necessárias**

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>O app precisa acessar sua localização para mostrar dados de telemetria.</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>O app precisa acessar sua localização para mostrar dados de telemetria.</string>
```

## 🧪 Testes & Qualidade

### **📈 Performance**
- ✅ Histórico limitado a 100 pontos para otimização de memória
- ✅ Dispose adequado de streams evitando memory leaks
- ✅ Validação de dados na entrada para evitar processamento desnecessário
- ✅ Debounce em animações para fluidez

## 📱 Compatibilidade

| Plataforma | Versão Mínima | Status |
|------------|---------------|--------|
| **Android** | API 21 (5.0) | ✅ Testado |
| **iOS** | 11.0+ | ✅ Preparado |
| **Web** | Limitado* | ⚠️ GPS limitado |

*Web tem limitações nos sensores de movimento

## 👨‍💻 Sobre o Desenvolvimento

Este projeto foi desenvolvido como **demonstração técnica** focando em:

- **Clean Code** e boas práticas Flutter/Dart
- **Arquitetura escalável** pensando em manutenibilidade
- **Performance** e experiência do usuário
- **Robustez** com tratamento de edge cases
- **Documentação** clara e profissional

### **🛠️ Decisões Técnicas**

1. **Provider vs BLoC**: Escolhi Provider pela simplicidade para este escopo
2. **OpenStreetMap vs Google Maps**: OSM para evitar dependência de API keys
3. **Validação de GPS**: Implementei filtros customizados para dados mais confiáveis
4. **UI Responsiva**: Painel deslizante para aproveitar melhor o espaço da tela

---

## 📞 Contato

**Desenvolvido por:** [Seu Nome]  
**Email:** [seu.email@exemplo.com]  
**LinkedIn:** [linkedin.com/in/seu-perfil]  

---

<div align="center">

**Feito com ❤️ e Flutter**

![Made with Flutter](https://img.shields.io/badge/Made%20with-Flutter-blue?style=flat-square&logo=flutter)

</div>