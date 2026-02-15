import 'dart:async';
import 'package:bonsoir/bonsoir.dart';

/// DiscoveryService handles mDNS (Multicast DNS) for automatic device discovery.
/// It allows senders to broadcast their presence and receivers to find them.
class DiscoveryService {
  static const String type = '_fastshare._tcp';
  BonsoirBroadcast? _broadcast;
  BonsoirDiscovery? _discovery;
  final StreamController<List<BonsoirService>> _discoveredServicesController =
      StreamController<List<BonsoirService>>.broadcast();

  Stream<List<BonsoirService>> get discoveredServices =>
      _discoveredServicesController.stream;

  final Map<String, BonsoirService> _services = {};

  /// Start broadcasting this device as a sender.
  Future<void> startBroadcasting(String name, int port) async {
    await stopBroadcasting();

    BonsoirService service = BonsoirService(
      name: name,
      type: type,
      port: port,
      attributes: {'version': '1.0.0'},
    );

    _broadcast = BonsoirBroadcast(service: service);
    await _broadcast!.initialize();
    await _broadcast!.start();
  }

  /// Stop broadcasting.
  Future<void> stopBroadcasting() async {
    if (_broadcast != null) {
      await _broadcast!.stop();
      _broadcast = null;
    }
  }

  /// Start searching for nearby senders.
  Future<void> startDiscovery() async {
    await stopDiscovery();
    _services.clear();
    _discoveredServicesController.add([]);

    _discovery = BonsoirDiscovery(type: type);
    await _discovery!.initialize();

    _discovery!.eventStream!.listen((event) {
      if (event is BonsoirDiscoveryServiceFoundEvent ||
          event is BonsoirDiscoveryServiceResolvedEvent) {
        if (event.service != null) {
          _services[event.service!.name] = event.service!;
          _discoveredServicesController.add(_services.values.toList());
        }
      } else if (event is BonsoirDiscoveryServiceLostEvent) {
        _services.remove(event.service!.name);
        _discoveredServicesController.add(_services.values.toList());
            }
    });

    await _discovery!.start();
  }

  /// Stop searching for nearby senders.
  Future<void> stopDiscovery() async {
    if (_discovery != null) {
      await _discovery!.stop();
      _discovery = null;
    }
  }

  void dispose() {
    stopBroadcasting();
    stopDiscovery();
    _discoveredServicesController.close();
  }
}
