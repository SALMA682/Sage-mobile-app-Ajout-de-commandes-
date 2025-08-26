import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ClientSelectionDialog extends StatefulWidget {
  const ClientSelectionDialog({Key? key}) : super(key: key);

  @override
  _ClientSelectionDialogState createState() => _ClientSelectionDialogState();
}

class _ClientSelectionDialogState extends State<ClientSelectionDialog> {
  List<Map<String, dynamic>> clients = []; // Liste complète de clients
  List<Map<String, dynamic>> filteredClients = []; // Liste filtrée
  bool isLoading = true;

  int currentPage = 1;
  final int itemsPerPage = 10;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchClients(); // Charger tous les clients
    searchController.addListener(_filterClients); // Filtrage côté Flutter
  }

  Future<void> fetchClients() async {
    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse(
          'http://192.168.1.110:8000/api/clients/?page=1&page_size=1000',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> data = decoded['results'];

        setState(() {
          clients = data
              .map(
                (item) => {
                  "code": item['code'] ?? '',
                  "nom": item['nom'] ?? '',
                  "devise": item['devise'] ?? '',
                },
              )
              .toList();

          filteredClients = List.from(clients);
          isLoading = false;
        });
      } else {
        print('Erreur API: ${response.statusCode}');
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Erreur d’appel API: $e");
      setState(() => isLoading = false);
    }
  }

  void _filterClients() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredClients = clients.where((client) {
        final code = client['code'].toLowerCase();
        final nom = client['nom'].toLowerCase();
        return code.contains(query) || nom.contains(query);
      }).toList();
      currentPage = 1; // Reset page après filtrage
    });
  }

  List<Map<String, dynamic>> get paginatedClients {
    final startIndex = (currentPage - 1) * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage).clamp(
      0,
      filteredClients.length,
    );
    return filteredClients.sublist(startIndex, endIndex);
  }

  void nextPage() {
    if (currentPage * itemsPerPage < filteredClients.length) {
      setState(() => currentPage++);
    }
  }

  void previousPage() {
    if (currentPage > 1) {
      setState(() => currentPage--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (filteredClients.length / itemsPerPage).ceil();
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.person_search, color: Colors.blue),
          SizedBox(width: 8),
          Text(
            'Sélectionner un client',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: isLoading
          ? const SizedBox(
              height: 150,
              child: Center(child: CircularProgressIndicator()),
            )
          : SizedBox(
              width: double.maxFinite,
              height: 450,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: "Rechercher par code ou nom...",
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Scrollbar(
                      thumbVisibility: true,
                      child: ListView.separated(
                        itemCount: paginatedClients.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final client = paginatedClients[index];
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              leading: const Icon(
                                Icons.business,
                                color: Colors.indigo,
                              ),
                              title: Text(
                                client['nom'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                "Code: ${client['code']} | Devise: ${client['devise']}",
                                style: const TextStyle(fontSize: 13),
                              ),
                              onTap: () => Navigator.pop(context, client),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: currentPage > 1 ? previousPage : null,
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Précédent'),
                      ),
                      Text('Page $currentPage / $totalPages'),
                      TextButton.icon(
                        onPressed: currentPage < totalPages ? nextPage : null,
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Suivant'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}
