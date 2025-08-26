import 'package:flutter/material.dart';
import 'RecapDialog.dart';
import 'services/commande_service.dart';
import 'models/commande.dart';

class CommandesNonValideesPage extends StatefulWidget {
  const CommandesNonValideesPage({Key? key}) : super(key: key);

  @override
  State<CommandesNonValideesPage> createState() =>
      _CommandesNonValideesPageState();
}

class _CommandesNonValideesPageState extends State<CommandesNonValideesPage> {
  late Future<List<Commande>> commandesFuture;

  @override
  void initState() {
    super.initState();
    _loadCommandes();
  }

  void _loadCommandes() {
    commandesFuture = CommandeService.getCommandesByStatut('non_validee');
  }

  void _showRecap(Commande cmd) async {
    final commandePourRecap = {
      "id": cmd.id,
      "entete": cmd.dataFormulaire["entete"],
      "livraison": cmd.dataFormulaire["livraison"],
      "lignes": cmd.dataFormulaire["lignes"],
    };

    await showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.maxFinite,
          height: 500,
          child: RecapDialog(
            commande: commandePourRecap,
            onCommandeValidee: () {
              setState(() {
                _loadCommandes();
              });
            },
          ),
        ),
      ),
    );

    setState(() {
      _loadCommandes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Commandes non validées")),
      body: FutureBuilder<List<Commande>>(
        future: commandesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Erreur: ${snapshot.error}"));
          }
          final commandes = snapshot.data!;
          if (commandes.isEmpty) {
            return const Center(child: Text("Aucune commande non validée."));
          }

          return ListView.builder(
            itemCount: commandes.length,
            itemBuilder: (context, index) {
              final cmd = commandes[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => _showRecap(cmd),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Commande #${cmd.id}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Icon(Icons.arrow_forward),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
