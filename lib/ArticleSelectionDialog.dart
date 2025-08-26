import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ArticleSelectionDialog extends StatefulWidget {
  const ArticleSelectionDialog({Key? key}) : super(key: key);

  @override
  _ArticleSelectionDialogState createState() => _ArticleSelectionDialogState();
}

class _ArticleSelectionDialogState extends State<ArticleSelectionDialog> {
  List<Map<String, dynamic>> articles = [];
  List<Map<String, dynamic>> filteredArticles = [];
  bool isLoading = false;

  int currentPage = 1;
  int totalPages = 1;
  final int pageSize = 10;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchArticles();
    searchController.addListener(_filterArticles);
  }

  Future<void> fetchArticles() async {
    setState(() {
      isLoading = true;
    });

    try {
      // On récupère tous les articles pour filtrage côté Flutter
      final response = await http.get(
        Uri.parse(
          'http://192.168.1.110:8000/api/articles/?page=1&page_size=1000',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final List<dynamic> data = jsonData['results'] ?? [];

        setState(() {
          articles = data.map((item) {
            return {
              "code": item['code_article'] ?? '',
              "designation": item['designation'] ?? '',
            };
          }).toList();

          filteredArticles = List.from(articles);
          totalPages = (filteredArticles.length / pageSize).ceil();
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

  void _filterArticles() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredArticles = articles.where((article) {
        final designation = article['designation'].toLowerCase();
        final code = article['code'].toLowerCase();
        return designation.contains(query) || code.contains(query);
      }).toList();

      // Reset pagination après filtrage
      totalPages = (filteredArticles.length / pageSize).ceil();
      currentPage = 1;
    });
  }

  List<Map<String, dynamic>> get paginatedArticles {
    final startIndex = (currentPage - 1) * pageSize;
    final endIndex = (startIndex + pageSize).clamp(0, filteredArticles.length);
    return filteredArticles.sublist(startIndex, endIndex);
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
      title: const Text('Sélectionner un article'),
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
                    child: paginatedArticles.isEmpty
                        ? const Center(child: Text("Aucun article trouvé"))
                        : ListView.separated(
                            itemCount: paginatedArticles.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final article = paginatedArticles[index];
                              return ListTile(
                                leading: const Icon(
                                  Icons.inventory_2,
                                  color: Colors.blue,
                                ),
                                title: Text(
                                  article['designation'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text("Code: ${article['code']}"),
                                onTap: () => Navigator.pop(context, article),
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
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}
