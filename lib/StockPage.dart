import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'SitesSelectionDialog.dart';

class StockPage extends StatefulWidget {
  final String articleCode;

  const StockPage({Key? key, required this.articleCode}) : super(key: key);

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  final TextEditingController _siteController = TextEditingController();
  final TextEditingController _dateController = TextEditingController(
    text:
        "${DateTime.now().day.toString().padLeft(2, '0')}/"
        "${DateTime.now().month.toString().padLeft(2, '0')}/"
        "${DateTime.now().year}",
  );

  String? _quantite;
  bool _loading = false;

  Future<void> _selectSite() async {
    final selectedSite = await showDialog<String>(
      context: context,
      builder: (context) => SiteSelectionDialog(),
    );

    if (selectedSite != null) {
      setState(() {
        _siteController.text = selectedSite;
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        // Formater en DD/MM/YYYY
        _dateController.text =
            "${picked.day.toString().padLeft(2, '0')}/"
            "${picked.month.toString().padLeft(2, '0')}/"
            "${picked.year}";
      });
    }
  }

  Future<void> _sendData() async {
    if (_siteController.text.isEmpty || _dateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez remplir site et date")),
      );
      return;
    }

    setState(() {
      _loading = true;
      _quantite = null; // reset avant envoi
    });

    final url = Uri.parse("http://192.168.1.110:8000/api/stock/");
    final body = {
      "site": _siteController.text,
      "date": _dateController.text,
      "article": widget.articleCode,
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _quantite = data["quantite"]?.toString() ?? "0";
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("❌ Erreur : ${response.body}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Erreur réseau : $e")));
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Stock de l'article ${widget.articleCode}")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _siteController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: "Site de stockage",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _selectSite,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _dateController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: "Date",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _selectDate,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              readOnly: true,
              decoration: InputDecoration(
                labelText: "Référence article",
                hintText: widget.articleCode,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _loading ? null : _sendData,
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Rechercher la quantité"),
            ),
            const SizedBox(height: 24),
            if (_quantite != null)
              Text(
                "Quantité disponible : $_quantite",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
