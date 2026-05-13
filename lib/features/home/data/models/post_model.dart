import 'package:json_annotation/json_annotation.dart';

part 'post_model.g.dart';

@JsonSerializable()
class PostModel {
  final int? id;
  final String? title;
  final String? body;
  final int? userId;

  PostModel({this.id, this.title, this.body, this.userId});

  factory PostModel.fromJson(Map<String, dynamic> json) => _$PostModelFromJson(json);
  Map<String, dynamic> toJson() => _$PostModelToJson(this);
}
