import 'package:flutter/material.dart';
import 'ArticleSelectionDialog.dart';
import 'client_selection_dialog.dart';
import 'recap_page.dart';
import 'package:intl/intl.dart';
import 'SitesSelectionDialog.dart';
import 'TypeCommandeDialog.dart';

class CommandeFormPage extends StatefulWidget {
  final String? initialCodeClient;
  final Map<String, dynamic>? commandeInitiale;

  const CommandeFormPage({
    Key? key,
    this.initialCodeClient,
    this.commandeInitiale,
  }) : super(key: key);

  @override
  _CommandeFormPageState createState() => _CommandeFormPageState();
}

class _CommandeFormPageState extends State<CommandeFormPage> {
  final _formKey = GlobalKey<FormState>();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  // Controllers
  late TextEditingController codeClientController;
  late TextEditingController siteVenteController;
  late TextEditingController typeCommandeController;
  late TextEditingController siteExpeditionController;

  DateTime? dateCommande = DateTime.now();
  DateTime? dateLivraisonDemandee;
  DateTime? dateExpedition;

  // Liste de lignes d'articles avec controller
  List<Map<String, dynamic>> lignes = [];

  @override
  void initState() {
    super.initState();
    codeClientController = TextEditingController(
      text: widget.initialCodeClient ?? '',
    );
    siteVenteController = TextEditingController();
    typeCommandeController = TextEditingController();
    siteExpeditionController = TextEditingController();
    // --- Cas 1 : Commande déjà existante (erreur Sage) ---
    if (widget.commandeInitiale != null) {
      final entete = widget.commandeInitiale!["entete"];
      final livraison = widget.commandeInitiale!["livraison"];
      final lignesData = widget.commandeInitiale!["lignes"] as List<dynamic>;

      codeClientController.text = entete["code_client"] ?? "";
      siteVenteController.text = entete["site_vente"] ?? "";
      typeCommandeController.text = entete["type_commande"] ?? "";
      dateCommande = entete["date_commande"] != null
          ? DateTime.tryParse(entete["date_commande"])
          : DateTime.now();

      siteExpeditionController.text = livraison["site_expedition"] ?? "";
      dateLivraisonDemandee = livraison["date_livraison"] != null
          ? DateTime.tryParse(livraison["date_livraison"])
          : null;
      dateExpedition = livraison["date_expedition"] != null
          ? DateTime.tryParse(livraison["date_expedition"])
          : null;

      // Pré-remplir les lignes
      lignes = lignesData.map((l) {
        return {
          "code_article": l["code_article"],
          "quantite_commandee": l["quantite_commandee"],
          "controller": TextEditingController(text: l["code_article"] ?? ""),
        };
      }).toList();
    } else {
      lignes.add({
        "code_article": "",
        "quantite_commandee": null,
        "controller": TextEditingController(),
      });
    }
  }

  @override
  void dispose() {
    codeClientController.dispose();
    siteVenteController.dispose();
    typeCommandeController.dispose();
    siteExpeditionController.dispose();
    for (var ligne in lignes) {
      ligne['controller']?.dispose();
    }
    super.dispose();
  }

  Future<void> ouvrirPopupClient() async {
    final client = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ClientSelectionDialog(),
    );
    if (client != null) {
      setState(() {
        codeClientController.text = client['code'];
      });
    }
  }

  Future<void> ouvrirPopupArticle(int index) async {
    final article = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ArticleSelectionDialog(),
    );
    if (article != null) {
      setState(() {
        lignes[index]['code_article'] = article['code'];
        lignes[index]['controller'].text = article['code'];
      });
    }
  }

  Future<void> ouvrirPopupSiteVente() async {
    final site = await showDialog<String>(
      context: context,
      builder: (context) => SiteSelectionDialog(),
    );
    if (site != null) {
      setState(() {
        siteVenteController.text = site;
      });
    }
  }

  Future<void> ouvrirPopupSiteExpedition() async {
    final site = await showDialog<String>(
      context: context,
      builder: (context) => SiteSelectionDialog(),
    );
    if (site != null) {
      setState(() {
        siteExpeditionController.text = site;
      });
    }
  }

  Future<void> ouvrirPopupTypeCommande() async {
    final type = await showDialog<String>(
      context: context,
      builder: (context) => TypeSelectionDialog(),
    );
    if (type != null) {
      setState(() {
        typeCommandeController.text = type;
      });
    }
  }

  Future<void> envoyerCommande() async {
    if (codeClientController.text.isEmpty ||
        siteVenteController.text.isEmpty ||
        typeCommandeController.text.isEmpty ||
        siteExpeditionController.text.isEmpty ||
        lignes.any(
          (l) =>
              l['code_article'] == null ||
              l['code_article'].toString().isEmpty ||
              l['quantite_commandee'] == null,
        )) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez remplir tous les champs obligatoires.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final commande = {
      "entete": {
        "site_vente": siteVenteController.text,
        "type_commande": typeCommandeController.text,
        "date_commande": dateCommande?.toIso8601String(),
        "code_client": codeClientController.text,
      },
      "livraison": {
        "site_expedition": siteExpeditionController.text,
        "date_livraison": dateLivraisonDemandee?.toIso8601String(),
        "date_expedition": dateExpedition?.toIso8601String(),
      },
      "lignes": lignes
          .map(
            (l) => {
              "code_article": l['code_article'],
              "quantite_commandee": l['quantite_commandee'],
            },
          )
          .toList(),
    };

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RecapPage(commande: commande)),
    );
  }

  Future<void> _selectDate(
    BuildContext context,
    DateTime? initialDate,
    Function(DateTime) onDateSelected,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  Widget _buildDateField({
    required String label,
    DateTime? date,
    required Function(DateTime) onDateSelected,
  }) {
    return InkWell(
      onTap: () => _selectDate(context, date, onDateSelected),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          date != null ? _dateFormat.format(date) : 'Choisir une date',
        ),
      ),
    );
  }

  Widget _buildRequiredLabel(String label) {
    return RichText(
      text: TextSpan(
        text: label,
        style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        children: [
          TextSpan(
            text: ' *',
            style: TextStyle(color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required String label,
    TextEditingController? controller,
    bool requiredField = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        label: requiredField ? _buildRequiredLabel(label) : Text(label),
        border: OutlineInputBorder(),
        suffixIcon: suffixIcon,
      ),
      validator: (value) {
        if (requiredField && (value == null || value.isEmpty)) {
          return 'Ce champ est obligatoire';
        }
        return null;
      },
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nouvelle Commande'),
        backgroundColor: Colors.teal,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // ENTÊTE
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildTextFormField(
                          label: 'Code client',
                          requiredField: true,
                          controller: codeClientController,
                          suffixIcon: IconButton(
                            icon: Icon(Icons.search),
                            onPressed: ouvrirPopupClient,
                          ),
                        ),
                        SizedBox(height: 12),
                        _buildTextFormField(
                          label: 'Site de vente',
                          requiredField: true,
                          controller: siteVenteController,
                          suffixIcon: IconButton(
                            icon: Icon(Icons.search),
                            onPressed: ouvrirPopupSiteVente,
                          ),
                        ),
                        SizedBox(height: 12),
                        _buildTextFormField(
                          label: 'Type de commande',
                          requiredField: true,
                          controller: typeCommandeController,
                          suffixIcon: IconButton(
                            icon: Icon(Icons.search),
                            onPressed: ouvrirPopupTypeCommande,
                          ),
                        ),
                        SizedBox(height: 12),
                        _buildDateField(
                          label: 'Date commande',
                          date: dateCommande,
                          onDateSelected: (d) =>
                              setState(() => dateCommande = d),
                        ),
                      ],
                    ),
                  ),
                ),

                // LIVRAISON
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildTextFormField(
                          label: 'Site d\'expédition',
                          requiredField: true,
                          controller: siteExpeditionController,
                          suffixIcon: IconButton(
                            icon: Icon(Icons.search),
                            onPressed: ouvrirPopupSiteExpedition,
                          ),
                        ),
                        SizedBox(height: 12),
                        _buildDateField(
                          label: 'Date de livraison demandée',
                          date: dateLivraisonDemandee,
                          onDateSelected: (d) =>
                              setState(() => dateLivraisonDemandee = d),
                        ),
                        SizedBox(height: 12),
                        _buildDateField(
                          label: 'Date expédition',
                          date: dateExpedition,
                          onDateSelected: (d) =>
                              setState(() => dateExpedition = d),
                        ),
                      ],
                    ),
                  ),
                ),

                // LIGNES COMMANDES MULTIPLES
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        for (int i = 0; i < lignes.length; i++) ...[
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: _buildTextFormField(
                                  label: 'Code article',
                                  requiredField: true,
                                  controller: lignes[i]['controller'],
                                  suffixIcon: IconButton(
                                    icon: Icon(Icons.search),
                                    onPressed: () => ouvrirPopupArticle(i),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: _buildTextFormField(
                                  label: 'Quantité',
                                  requiredField: true,
                                  keyboardType: TextInputType.number,
                                  controller: TextEditingController(
                                    text: lignes[i]['quantite_commandee']
                                        ?.toString(),
                                  ),
                                  onChanged: (v) =>
                                      lignes[i]['quantite_commandee'] =
                                          int.tryParse(v),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    lignes[i]['controller'].dispose();
                                    lignes.removeAt(i);
                                  });
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                        ],
                        Align(
                          alignment: Alignment.centerLeft,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                lignes.add({
                                  "code_article": "",
                                  "quantite_commandee": null,
                                  "controller": TextEditingController(),
                                });
                              });
                            },
                            icon: Icon(Icons.add),
                            label: Text("Ajouter une ligne"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        envoyerCommande();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                    ),
                    child: Text(
                      "Envoyer Commande",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
