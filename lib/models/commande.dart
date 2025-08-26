import 'dart:convert';

class Commande {
  int? id;
  Map<String, dynamic> dataFormulaire;
  Map<String, dynamic>? clientSage;
  List<Map<String, dynamic>>? articlesSage;
  String statut;
  String? idSage;
  DateTime dateCreated;

  Commande({
    this.id,
    required this.dataFormulaire,
    this.clientSage,
    this.articlesSage,
    this.statut = 'non_validee',
    this.idSage,
    DateTime? dateCreated,
  }) : dateCreated = dateCreated ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'data_formulaire': jsonEncode(dataFormulaire),
      'client_sage': clientSage != null ? jsonEncode(clientSage) : null,
      'articles_sage': articlesSage != null ? jsonEncode(articlesSage) : null,
      'statut': statut,
      'id_sage': idSage,
      'date_created': dateCreated.toIso8601String(),
    };
  }

  factory Commande.fromMap(Map<String, dynamic> map) {
    return Commande(
      id: map['id'],
      dataFormulaire: jsonDecode(map['data_formulaire']),
      clientSage: map['client_sage'] != null
          ? Map<String, dynamic>.from(jsonDecode(map['client_sage']))
          : null,
      articlesSage: map['articles_sage'] != null
          ? List<Map<String, dynamic>>.from(
              (jsonDecode(map['articles_sage']) as List).map(
                (x) => Map<String, dynamic>.from(x),
              ),
            )
          : null,
      statut: map['statut'] ?? 'non_validee',
      idSage: map['id_sage'],
      dateCreated: map['date_created'] != null
          ? DateTime.parse(map['date_created'])
          : DateTime.now(),
    );
  }
}
