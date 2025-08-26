import 'package:flutter/material.dart';
import 'CommandeFormPage.dart';
import 'clients_page.dart';
import 'articles_page.dart';
import 'CommandeValideePage.dart';
import 'CommandeNonValideePage.dart';

class SuccessPage extends StatefulWidget {
  const SuccessPage({Key? key}) : super(key: key);

  @override
  State<SuccessPage> createState() => _SuccessPageState();
}

class _SuccessPageState extends State<SuccessPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil'),
        backgroundColor: Colors.teal,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.teal.shade700),
              child: const Center(
                child: Text(
                  'Menu Commandes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Flèche Commandes Validées
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text("Commandes Validées"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CommandesValideesPage(),
                  ),
                );
              },
            ),

            // Flèche Commandes Non Validées
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.red),
              title: const Text("Commandes Non Validées"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CommandesNonValideesPage(),
                  ),
                );
              },
            ),

            const Spacer(),
            const Divider(),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Bienvenue ! Vous êtes connecté(e).',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 220,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.people),
                label: const Text(
                  'Consulter Clients',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ClientPage()),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 220,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.inventory),
                label: const Text(
                  'Consulter Articles',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ArticlesPage()),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 220,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text(
                  'Ajouter Commande',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CommandeFormPage()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
