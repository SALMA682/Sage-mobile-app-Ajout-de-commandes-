import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SiteSelectionDialog extends StatefulWidget {
  const SiteSelectionDialog({Key? key}) : super(key: key);

  @override
  _SiteSelectionDialogState createState() => _SiteSelectionDialogState();
}

class _SiteSelectionDialogState extends State<SiteSelectionDialog> {
  List<Map<String, dynamic>> sites = [];
  List<Map<String, dynamic>> filteredSites = [];
  bool isLoading = false;

  int currentPage = 1;
  int totalPages = 1;
  final int pageSize = 10;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchSites();
    searchController.addListener(_filterSites);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchSites() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://192.168.1.110:8000/api/sites/?page=1&page_size=1000'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final List<dynamic> data = jsonData['results'] ?? [];

        setState(() {
          sites = data.map((item) {
            return {
              "code": item['code_site'] ?? '',
              "designation": item['designation'] ?? '',
            };
          }).toList();

          filteredSites = List.from(sites);
          totalPages = (filteredSites.length / pageSize).ceil();
          currentPage = 1;
        });
      } else {
        print("Erreur ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      print("Erreur d’appel API: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _filterSites() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredSites = sites.where((site) {
        final designation = site['designation'].toLowerCase();
        final code = site['code'].toLowerCase();
        return designation.contains(query) || code.contains(query);
      }).toList();

      totalPages = (filteredSites.length / pageSize).ceil();
      currentPage = 1;
    });
  }

  List<Map<String, dynamic>> get paginatedSites {
    final startIndex = (currentPage - 1) * pageSize;
    final endIndex = (startIndex + pageSize).clamp(0, filteredSites.length);
    return filteredSites.sublist(startIndex, endIndex);
  }

  void nextPage() {
    if (currentPage < totalPages) {
      setState(() {
        currentPage++;
      });
    }
  }

  void previousPage() {
    if (currentPage > 1) {
      setState(() {
        currentPage--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Sélectionner un site'),
      content: isLoading
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : SizedBox(
              width: double.maxFinite,
              height: 500,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: "Rechercher par code ou désignation...",
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: paginatedSites.isEmpty
                        ? const Center(child: Text("Aucun site trouvé"))
                        : ListView.separated(
                            itemCount: paginatedSites.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final site = paginatedSites[index];
                              return ListTile(
                                leading: const Icon(
                                  Icons.location_on,
                                  color: Colors.green,
                                ),
                                title: Text(
                                  site['designation'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text("Code: ${site['code']}"),
                                onTap: () {
                                  final selectedCode = site['code'];
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    Navigator.pop(context, selectedCode);
                                  });
                                },
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                tileColor: Colors.grey.shade100,
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Page $currentPage / $totalPages'),
                      Row(
                        children: [
                          IconButton(
                            onPressed: currentPage > 1 ? previousPage : null,
                            icon: const Icon(Icons.arrow_back),
                          ),
                          IconButton(
                            onPressed: currentPage < totalPages
                                ? nextPage
                                : null,
                            icon: const Icon(Icons.arrow_forward),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pop(context);
            });
          },
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}
