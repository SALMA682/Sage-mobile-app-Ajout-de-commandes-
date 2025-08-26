import 'package:flutter/material.dart';
import 'services/commande_service.dart';
import 'models/commande.dart';

class CommandesValideesPage extends StatefulWidget {
  const CommandesValideesPage({Key? key}) : super(key: key);

  @override
  State<CommandesValideesPage> createState() => _CommandesValideesPageState();
}

class _CommandesValideesPageState extends State<CommandesValideesPage> {
  late Future<List<Commande>> commandesFuture;

  @override
  void initState() {
    super.initState();
    _loadCommandes();
  }

  void _loadCommandes() {
    // Récupère les commandes validées depuis la base locale
    commandesFuture = CommandeService.getCommandesByStatut('validee');
  }

  // Méthode pour rafraîchir la liste
  void _refreshCommandes() {
    setState(() {
      _loadCommandes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Commandes validées"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshCommandes,
          ),
        ],
      ),
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
            return const Center(child: Text("Aucune commande validée."));
          }

          return ListView.builder(
            itemCount: commandes.length,
            itemBuilder: (context, index) {
              final cmd = commandes[index];
              return ListTile(
                title: Text("Commande : ${cmd.idSage ?? cmd.id}"),
                subtitle: Text("Date: ${cmd.dateCreated ?? ''}"),
              );
            },
          );
        },
      ),
    );
  }
}
