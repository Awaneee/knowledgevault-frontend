class CategoryResponse {
  const CategoryResponse({required this.id, required this.name});

  final int id;
  final String name;

  factory CategoryResponse.fromJson(Map<String, dynamic> json) =>
      CategoryResponse(
        id: json['id'] as int,
        name: json['name'] as String,
      );
}
