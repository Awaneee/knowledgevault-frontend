class CategoryCreateRequest {
  const CategoryCreateRequest({required this.name});

  final String name;

  Map<String, dynamic> toJson() => {'name': name};
}
