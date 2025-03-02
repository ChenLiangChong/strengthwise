import 'package:cloud_firestore/cloud_firestore.dart';

class Exercise {
  final String id;
  final String name;
  final String nameEn;
  final List<String> bodyParts;
  final String type;
  final String equipment;
  final String jointType;
  final String level1;
  final String level2;
  final String level3;
  final String level4;
  final String level5;
  final String? actionName;
  final String description;
  final String imageUrl;
  final String videoUrl;
  final List<String> apps;
  final DateTime createdAt;

  Exercise({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.bodyParts,
    required this.type,
    required this.equipment,
    required this.jointType,
    required this.level1,
    required this.level2,
    required this.level3,
    required this.level4,
    required this.level5,
    this.actionName,
    required this.description,
    this.imageUrl = '',
    required this.videoUrl,
    required this.apps,
    required this.createdAt,
  });

  factory Exercise.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Exercise(
      id: doc.id,
      name: data['name'] ?? '',
      nameEn: data['nameEn'] ?? '',
      bodyParts: List<String>.from(data['bodyParts'] ?? []),
      type: data['type'] ?? '',
      equipment: data['equipment'] ?? '',
      jointType: data['jointType'] ?? '',
      level1: data['level1'] ?? '',
      level2: data['level2'] ?? '',
      level3: data['level3'] ?? '',
      level4: data['level4'] ?? '',
      level5: data['level5'] ?? '',
      actionName: data['actionName'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      videoUrl: data['videoUrl'] ?? '',
      apps: List<String>.from(data['apps'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // JSON 序列化方法
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'actionName': actionName,
      'nameEn': nameEn,
      'bodyParts': bodyParts,
      'jointType': jointType,
      'equipment': equipment,
      'type': type,
      'level1': level1,
      'level2': level2,
      'level3': level3,
      'level4': level4,
      'level5': level5,
      'description': description,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'apps': apps,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  // 從 JSON 創建對象
  static Exercise fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      actionName: json['actionName'],
      nameEn: json['nameEn'] ?? '',
      bodyParts: List<String>.from(json['bodyParts'] ?? []),
      jointType: json['jointType'] ?? '',
      equipment: json['equipment'] ?? '',
      type: json['type'] ?? '',
      level1: json['level1'] ?? '',
      level2: json['level2'] ?? '',
      level3: json['level3'] ?? '',
      level4: json['level4'] ?? '',
      level5: json['level5'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
      apps: List<String>.from(json['apps'] ?? []),
      createdAt: json['createdAt'] != null ? 
                 DateTime.fromMillisecondsSinceEpoch(json['createdAt']) : 
                 DateTime.now(),
    );
  }
} 