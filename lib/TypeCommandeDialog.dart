import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TypeSelectionDialog extends StatefulWidget {
  const TypeSelectionDialog({Key? key}) : super(key: key);

  @override
  _TypeSelectionDialogState createState() => _TypeSelectionDialogState();
}

class _TypeSelectionDialogState extends State<TypeSelectionDialog> {
  List<Map<String, dynamic>> types = [];
  List<Map<String, dynamic>> filteredtypes = [];
  bool isLoading = false;

  int currentPage = 1;
  int totalPages = 1;
  final int pageSize = 10;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchSites();
    searchController.addListener(_filtertypes);
  }

  Future<void> fetchSites() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
          'http://192.168.1.110:8000/api/typesCmd/?page=1&page_size=1000',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final List<dynamic> data = jsonData['results'] ?? [];

        setState(() {
          types = data.map((item) {
            return {
              "code": item['code_type'] ?? '',
              "designation": item['designation'] ?? '',
            };
          }).toList();

          filteredtypes = List.from(types);
          totalPages = (filteredtypes.length / pageSize).ceil();
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

  void _filtertypes() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredtypes = types.where((type) {
        final designation = type['designation'].toLowerCase();
        final code = type['code'].toLowerCase();
        return designation.contains(query) || code.contains(query);
      }).toList();

      totalPages = (filteredtypes.length / pageSize).ceil();
      currentPage = 1;
    });
  }

  List<Map<String, dynamic>> get paginatedSites {
    final startIndex = (currentPage - 1) * pageSize;
    final endIndex = (startIndex + pageSize).clamp(0, filteredtypes.length);
    return filteredtypes.sublist(startIndex, endIndex);
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
      title: const Text('Sélectionner un type'),
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
                        ? const Center(child: Text("Aucun type trouvé"))
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
                                onTap: () =>
                                    Navigator.pop(context, site['code']),
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
            if (mounted) {
              Future.microtask(() => Navigator.of(context).pop());
            }
          },
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}
