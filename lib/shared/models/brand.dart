import 'package:equatable/equatable.dart';

class Brand extends Equatable {
  final int id;
  final String name;
  final String logo;

  const Brand({required this.id, required this.name, required this.logo});

  factory Brand.fromJson(Map<String, dynamic> json) {
    return Brand(
      id: json['id'] as int,
      name: json['name'] as String,
      logo: json['logo'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logo': logo,
    };
  }

  @override
  List<Object?> get props => [id, name, logo];
}
