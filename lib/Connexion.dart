import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'home.dart'; // SuccessPage

class VPNCheckPage extends StatefulWidget {
  @override
  _VPNCheckPageState createState() => _VPNCheckPageState();
}

class _VPNCheckPageState extends State<VPNCheckPage> {
  bool _vpnActive = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkVPN();
  }

  Future<void> _checkVPN() async {
    setState(() => _checking = true);

    final info = NetworkInfo();
    final ip = await info
        .getWifiIP(); // ou getWifiIP / getWifiIPv6 selon ton cas

    print("Adresse IP locale détectée: $ip");

    bool vpn = ip != null && ip.startsWith("10.11.12.");

    setState(() {
      _vpnActive = vpn;
      _checking = false;
    });

    if (vpn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ VPN Fortinet détecté "),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.green,
          ),
        );
      });

      Future.delayed(Duration(seconds: 3), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => SuccessPage()),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_vpnActive) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "🚨 Veuillez activer votre VPN pour accéder à l'application",
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(body: Center(child: Text("Connexion VPN détectée...")));
  }
}
