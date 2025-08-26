import 'package:commande_clt/CommandeFormPage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home.dart';
import 'services/commande_service.dart';

class RecapDialog extends StatefulWidget {
  final Map<String, dynamic> commande;
  final VoidCallback? onCommandeValidee;

  const RecapDialog({Key? key, required this.commande, this.onCommandeValidee})
    : super(key: key);

  @override
  State<RecapDialog> createState() => _RecapPageState();
}

class _RecapPageState extends State<RecapDialog> {
  Map<String, dynamic>? clientDetails;
  List<Map<String, dynamic>> articlesDetails = [];
  bool isLoading = true;
  int? commandeId;

  @override
  void initState() {
    super.initState();
    commandeId = widget.commande["id"];
    _loadRecapData();
  }

  Future<void> _loadRecapData() async {
    try {
      final codeClient = widget.commande["entete"]["code_client"];
      final lignes = widget.commande["lignes"] as List<dynamic>;
      final codesArticles = lignes.map((l) => l["code_article"]).toList();

      // Client Sage
      final clientResp = await http.get(
        Uri.parse("http://192.168.1.110:8000/api/clientsDetails/$codeClient/"),
        headers: {},
      );
      if (clientResp.statusCode == 200) {
        clientDetails = jsonDecode(clientResp.body);
      }
      // Articles Sage
      for (var codeArticle in codesArticles) {
        final codeArticleTrim = codeArticle.toString().trim();
        final artResp = await http.get(
          Uri.parse(
            "http://192.168.1.110:8000/api/articlesDetails/$codeArticleTrim/",
          ),
          headers: {},
        );
        if (artResp.statusCode == 200) {
          articlesDetails.add(jsonDecode(artResp.body));
        }
      }
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print("Erreur chargement recap: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _validerCommande() async {
    final confirmed = await _showConfirmationDialog(
      "Valider la commande",
      "Voulez-vous vraiment valider et envoyer cette commande à Sage ?",
    );
    if (!confirmed) return;

    final formulairePayload = {
      "entete": widget.commande["entete"],
      "livraison": widget.commande["livraison"],
      "lignes": widget.commande["lignes"],
    };

    try {
      final resp = await http.post(
        Uri.parse("http://192.168.1.110:8000/api/valider_commande/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(formulairePayload),
      );

      final jsonResp = jsonDecode(resp.body);

      if (resp.statusCode == 200 && jsonResp["status"] == "success") {
        // ✅ Succès
        final idSage = jsonResp["id_sage"]?.toString();

        if (commandeId != null) {
          final commandeLocale = await CommandeService.getCommandeById(
            commandeId!,
          );
          if (commandeLocale != null) {
            commandeLocale.statut = "validee";
            commandeLocale.idSage = idSage;
            await CommandeService.updateCommande(commandeLocale);
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Commande validée et envoyée à Sage")),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => SuccessPage()),
          (route) => false,
        );
      } else {
        // ❌ Erreur Sage
        final messages =
            (jsonResp["messages"] as List<dynamic>?)
                ?.map((m) => m.toString())
                .toList() ??
            ["Erreur inconnue"];

        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text("Erreur Sage"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: messages.map((msg) => Text("• $msg")).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx); // ferme le dialog

                  // 🔄 Retour vers FormPage avec commande pré-remplie
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CommandeFormPage(
                        commandeInitiale:
                            widget.commande, // 👈 on renvoie la commande
                      ),
                    ),
                  );
                },
                child: Text("Modifier"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de l'envoi à Sage : $e")),
      );
    }
  }

  // Méthode confirmation popup
  Future<bool> _showConfirmationDialog(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Annuler"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Confirmer"),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        child,
        SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Récapitulatif Commande"),
        backgroundColor: Colors.teal,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSection("Informations Client", _buildClientSection()),
                  SizedBox(width: 16),
                  _buildSection(
                    "Informations Articles",
                    _buildArticlesSection(),
                  ),
                  SizedBox(width: 16),
                  _buildSection(
                    "Récapitulatif de la commande",
                    _buildFormulaireSection(),
                  ),
                  SizedBox(width: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _validerCommande,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                          ),
                          child: Text("Valider et envoyer à Sage"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildClientSection() {
    if (clientDetails == null) return Text("Client introuvable.");

    return Card(
      child: ListTile(
        title: Text(clientDetails!["nom"] ?? ""),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Code: ${clientDetails!["code_client"] ?? ""}"),
            if (clientDetails!["raison_sociale"] != null)
              Text("Raison sociale: ${clientDetails!["raison_sociale"]}"),
            if (clientDetails!["devise"] != null)
              Text("Devise: ${clientDetails!["devise"]}"),
          ],
        ),
      ),
    );
  }

  Widget _buildArticlesSection() {
    if (articlesDetails.isEmpty) return Text("Aucun article trouvé.");

    return Column(
      children: articlesDetails.map((article) {
        return Card(
          child: ListTile(
            title: Text(article["designation"] ?? ""),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Code: ${article["code"] ?? ""}"),
                Text("Unité stock: ${article["unite_stock"] ?? ""}"),
                Text("Coef. stock/vente: ${article["coef_stock_vente"] ?? ""}"),
                Text("Prix: ${article["prix"] ?? ""}"),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFormulaireSection() {
    final entete = widget.commande["entete"];
    final livraison = widget.commande["livraison"];
    final lignes = widget.commande["lignes"] as List<dynamic>;

    double totalGeneral = 0;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Code client: ${entete["code_client"]}"),
            Text("Site vente: ${entete["site_vente"]}"),
            Text("Type commande: ${entete["type_commande"]}"),
            Text("Date commande: ${entete["date_commande"]}"),
            Divider(),
            Text("Site expédition: ${livraison["site_expedition"]}"),
            Text("Date livraison: ${livraison["date_livraison"]}"),
            Text("Date expédition: ${livraison["date_expedition"]}"),
            Divider(),
            ...lignes.map((l) {
              final codeArticle = l["code_article"];
              final qte =
                  double.tryParse(l["quantite_commandee"].toString()) ?? 0;

              // 🔍 Cherche l’article dans articlesDetails pour avoir le prix
              final article = articlesDetails.firstWhere(
                (a) => a["code"] == codeArticle,
                orElse: () => {"prix": 0},
              );

              final prix = double.tryParse(article["prix"].toString()) ?? 0;
              final montant = qte * prix;

              totalGeneral += montant;

              return Text(
                "Article: $codeArticle - Qté: $qte - Prix: $prix - Montant: $montant",
                style: TextStyle(fontWeight: FontWeight.w500),
              );
            }).toList(),
            Divider(thickness: 2),
            Text(
              "💰 Total général: $totalGeneral",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
