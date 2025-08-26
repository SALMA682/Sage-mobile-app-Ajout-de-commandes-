import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'StockPage.dart';

class ArticlesPage extends StatefulWidget {
  const ArticlesPage({Key? key}) : super(key: key);

  @override
  _ArticlesPageState createState() => _ArticlesPageState();
}

class _ArticlesPageState extends State<ArticlesPage> {
  List<Map<String, dynamic>> articles = []; // Liste complète d’articles
  List<Map<String, dynamic>> filteredArticles = []; // Liste filtrée
  bool isLoading = true;
  int currentPage = 1;
  final int pageSize = 10;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchArticles(); // Charger les articles depuis l’API
    searchController.addListener(
      _filterArticles,
    ); // Filtrage au moment de la saisie
  }

  Future<void> fetchArticles() async {
    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse(
          'http://192.168.1.110:8000/api/articles/?page=1&page_size=1000',
        ),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final List<dynamic> data = jsonData['results'] ?? [];

        setState(() {
          // Mapping identique à ce qui est récupéré depuis Sage
          articles = data
              .map(
                (item) => {
                  "code": item['code_article'] ?? '',
                  "designation": item['designation'] ?? '',
                },
              )
              .toList();

          filteredArticles = List.from(articles);
          isLoading = false;
        });
      } else {
        print("Erreur ${response.statusCode}: ${response.body}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Erreur d’appel API: $e");
      setState(() => isLoading = false);
    }
  }

  void _filterArticles() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredArticles = articles.where((article) {
        final code = article['code'].toLowerCase();
        final designation = article['designation'].toLowerCase();
        return code.contains(query) || designation.contains(query);
      }).toList();
      currentPage = 1; // Reset page après filtrage
    });
  }

  List<Map<String, dynamic>> get paginatedArticles {
    final startIndex = (currentPage - 1) * pageSize;
    final endIndex = (startIndex + pageSize).clamp(0, filteredArticles.length);
    return filteredArticles.sublist(startIndex, endIndex);
  }

  void nextPage() {
    if (currentPage * pageSize < filteredArticles.length) {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Liste des articles"),
        backgroundColor: Colors.teal,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Recherche
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

                // Liste paginée
                Expanded(
                  child: paginatedArticles.isEmpty
                      ? const Center(child: Text("Aucun article trouvé"))
                      : ListView.separated(
                          itemCount: paginatedArticles.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final article = paginatedArticles[index];
                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              color: Colors.grey.shade100,
                              margin: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 8,
                              ),
                              child: ListTile(
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
                                trailing: ElevatedButton(
                                  child: const Text("Consulter stock"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => StockPage(
                                          articleCode: article['code'],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // Pagination
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Page $currentPage / ${(filteredArticles.length / pageSize).ceil()}',
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: currentPage > 1 ? previousPage : null,
                            icon: const Icon(Icons.arrow_back),
                          ),
                          IconButton(
                            onPressed:
                                currentPage * pageSize < filteredArticles.length
                                ? nextPage
                                : null,
                            icon: const Icon(Icons.arrow_forward),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
