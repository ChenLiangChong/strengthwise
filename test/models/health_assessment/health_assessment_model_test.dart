import 'package:flutter_test/flutter_test.dart';
import 'package:strengthwise/models/health_assessment/health_assessment_model.dart';
import 'package:strengthwise/models/health_assessment/injury_record.dart';
import 'package:strengthwise/models/health_assessment/training_goals.dart';
import 'package:strengthwise/models/health_assessment/enums.dart';

/// HealthAssessmentModel 測試
///
/// P1 優先級 - 約 15 個測試案例
/// 參考：docs/planning/TESTING_STRATEGY.md #P1
void main() {
  group('HealthAssessmentModel', () {
    // 測試用完整的 Supabase 格式 JSON
    final validSupabaseJson = <String, dynamic>{
      'id': 'assessment-001',
      'user_id': 'user-001',
      'assessed_by': 'coach-001',
      'assessment_date': '2025-12-15T10:00:00.000Z',

      // PAR-Q+ 7 題
      'heart_disease': false,
      'heart_disease_note': null,
      'chest_pain_exercise': false,
      'chest_pain_rest': false,
      'dizziness': false,
      'bone_joint_problem': true,
      'bone_joint_note': '左膝有舊傷',
      'medication': true,
      'medication_note': '降血壓藥物',
      'other_reason': false,
      'other_reason_note': null,
      'is_cleared': false,

      // 進階評估
      'cardiovascular_details': <String, dynamic>{'blood_pressure': '120/80'},
      'musculoskeletal_details': [
        {
          'site': '左膝',
          'status': 'chronic',
          'diagnosis': '半月板磨損',
          'limitations': '避免深蹲過低',
        },
      ],
      'metabolic_details': null,
      'respiratory_details': null,

      // 生活型態
      'training_experience': 'intermediate',
      'training_years': 2.5,
      'occupation_activity': 'moderate',
      'equipment_access': ['barbell', 'dumbbell', 'machine'],
      'weekly_sessions': 3,
      'sleep_hours': 7.5,

      // 訓練目標
      'training_goals': <String, dynamic>{
        'primary': 'muscle_gain',
        'target_kg': 5.0,
        'timeframe_months': 6,
        'notes': '增加上半身肌肉',
      },

      // 版本控制
      'version': 1,
      'is_current': true,
      'emergency_contact': <String, dynamic>{
        'name': '張大明',
        'phone': '0912345678',
        'relationship': '配偶',
      },
      'created_at': '2025-12-15T10:00:00.000Z',
      'updated_at': '2025-12-15T10:00:00.000Z',
    };

    // =========================================================================
    // P1-110: fromSupabase
    // =========================================================================
    group('fromSupabase', () {
      test('正確解析完整 Supabase 格式', () {
        // Act
        final model = HealthAssessmentModel.fromSupabase(validSupabaseJson);

        // Assert
        expect(model.id, 'assessment-001');
        expect(model.userId, 'user-001');
        expect(model.assessedBy, 'coach-001');
        expect(model.heartDisease, isFalse);
        expect(model.boneJointProblem, isTrue);
        expect(model.boneJointNote, '左膝有舊傷');
        expect(model.medication, isTrue);
        expect(model.medicationNote, '降血壓藥物');
        expect(model.isCleared, isFalse);
      });

      test('正確解析傷病史', () {
        // Act
        final model = HealthAssessmentModel.fromSupabase(validSupabaseJson);

        // Assert
        expect(model.injuries.length, 1);
        expect(model.injuries[0].site, '左膝');
        expect(model.injuries[0].status, InjuryStatus.chronic);
        expect(model.injuries[0].diagnosis, '半月板磨損');
        expect(model.injuries[0].limitations, '避免深蹲過低');
      });

      test('正確解析生活型態', () {
        // Act
        final model = HealthAssessmentModel.fromSupabase(validSupabaseJson);

        // Assert
        expect(model.trainingExperience, TrainingLevel.intermediate);
        expect(model.trainingYears, 2.5);
        expect(model.occupationActivity, ActivityLevel.moderate);
        expect(model.equipmentAccess, ['barbell', 'dumbbell', 'machine']);
        expect(model.weeklySessions, 3);
        expect(model.sleepHours, 7.5);
      });

      test('正確解析訓練目標', () {
        // Act
        final model = HealthAssessmentModel.fromSupabase(validSupabaseJson);

        // Assert
        expect(model.trainingGoals, isNotNull);
        expect(model.trainingGoals!.primary, 'muscle_gain');
        expect(model.trainingGoals!.targetKg, 5.0);
        expect(model.trainingGoals!.timeframeMonths, 6);
      });

      test('空陣列正確處理', () {
        // Arrange
        final json = Map<String, dynamic>.from(validSupabaseJson);
        json['musculoskeletal_details'] = null;
        json['equipment_access'] = null;

        // Act
        final model = HealthAssessmentModel.fromSupabase(json);

        // Assert
        expect(model.injuries, isEmpty);
        expect(model.equipmentAccess, isEmpty);
      });
    });

    // =========================================================================
    // P1-111: toSupabase
    // =========================================================================
    group('toSupabase', () {
      test('正確轉換為 Supabase 格式', () {
        // Arrange
        final model = HealthAssessmentModel.fromSupabase(validSupabaseJson);

        // Act
        final map = model.toSupabase();

        // Assert
        expect(map['user_id'], 'user-001');
        expect(map['heart_disease'], isFalse);
        expect(map['bone_joint_problem'], isTrue);
        expect(map['training_experience'], 'intermediate');
        expect(map['musculoskeletal_details'], isA<List>());
      });

      test('傷病史正確序列化', () {
        // Arrange
        final model = HealthAssessmentModel.fromSupabase(validSupabaseJson);

        // Act
        final map = model.toSupabase();
        final injuries = map['musculoskeletal_details'] as List;

        // Assert
        expect(injuries.length, 1);
        expect(injuries[0]['site'], '左膝');
        expect(injuries[0]['status'], 'chronic');
      });
    });

    // =========================================================================
    // P1-112: riskLevel getters
    // =========================================================================
    group('riskLevel getters', () {
      test('isCleared=false 返回 attention', () {
        // Act
        final model = HealthAssessmentModel.fromSupabase(validSupabaseJson);

        // Assert
        expect(model.riskLevel, 'attention');
        expect(model.riskLevelLabel, '需注意');
      });

      test('isCleared=true 返回 low', () {
        // Arrange
        final json = Map<String, dynamic>.from(validSupabaseJson);
        json['is_cleared'] = true;

        // Act
        final model = HealthAssessmentModel.fromSupabase(json);

        // Assert
        expect(model.riskLevel, 'low');
        expect(model.riskLevelLabel, '低風險');
      });
    });

    // =========================================================================
    // P1-113: hasWarnings
    // =========================================================================
    group('hasWarnings', () {
      test('有風險因子返回 true', () {
        // Act
        final model = HealthAssessmentModel.fromSupabase(validSupabaseJson);

        // Assert
        expect(model.hasWarnings, isTrue);
      });
    });

    // =========================================================================
    // P1-114: getWarningSummary
    // =========================================================================
    group('getWarningSummary', () {
      test('正確生成警示摘要', () {
        // Act
        final model = HealthAssessmentModel.fromSupabase(validSupabaseJson);
        final warnings = model.getWarningSummary();

        // Assert
        expect(warnings.length, greaterThanOrEqualTo(2));
        expect(warnings.any((w) => w.contains('安全篩檢未通過')), isTrue);
        expect(warnings.any((w) => w.contains('左膝')), isTrue);
      });
    });

    // =========================================================================
    // P1-115: copyWith
    // =========================================================================
    group('copyWith', () {
      test('複製並修改 isCleared', () {
        // Arrange
        final model = HealthAssessmentModel.fromSupabase(validSupabaseJson);

        // Act
        final updated = model.copyWith(isCleared: true);

        // Assert
        expect(updated.isCleared, isTrue);
        expect(updated.id, model.id);
      });
    });
  });

  // ===========================================================================
  // InjuryRecord 測試
  // ===========================================================================
  group('InjuryRecord', () {
    group('fromJson', () {
      test('正確解析 JSON', () {
        // Arrange
        final json = <String, dynamic>{
          'site': '右肩',
          'status': 'acute',
          'diagnosis': '肌腱發炎',
          'limitations': '避免過肩動作',
          'occurred_date': '2025-12-01T00:00:00.000Z',
        };

        // Act
        final record = InjuryRecord.fromJson(json);

        // Assert
        expect(record.site, '右肩');
        expect(record.status, InjuryStatus.acute);
        expect(record.diagnosis, '肌腱發炎');
        expect(record.limitations, '避免過肩動作');
        expect(record.occurredDate, isNotNull);
      });

      test('缺少可選欄位使用預設值', () {
        // Arrange
        final json = <String, dynamic>{
          'site': '腰椎',
          'status': 'chronic',
        };

        // Act
        final record = InjuryRecord.fromJson(json);

        // Assert
        expect(record.site, '腰椎');
        expect(record.status, InjuryStatus.chronic);
        expect(record.diagnosis, isNull);
        expect(record.limitations, isNull);
      });
    });

    group('toJson', () {
      test('正確序列化', () {
        // Arrange
        const record = InjuryRecord(
          site: '左膝',
          status: InjuryStatus.postSurgery,
          diagnosis: 'ACL 重建',
          limitations: '避免跳躍',
        );

        // Act
        final json = record.toJson();

        // Assert
        expect(json['site'], '左膝');
        expect(json['status'], 'post_surgery');
        expect(json['diagnosis'], 'ACL 重建');
      });
    });
  });

  // ===========================================================================
  // InjuryStatus 測試
  // ===========================================================================
  group('InjuryStatus', () {
    group('fromString', () {
      test('正確解析各狀態', () {
        expect(InjuryStatus.fromString('acute'), InjuryStatus.acute);
        expect(InjuryStatus.fromString('subacute'), InjuryStatus.subacute);
        expect(InjuryStatus.fromString('chronic'), InjuryStatus.chronic);
        expect(
            InjuryStatus.fromString('post_surgery'), InjuryStatus.postSurgery);
      });

      test('未知值使用預設值', () {
        expect(InjuryStatus.fromString('unknown'), InjuryStatus.chronic);
      });
    });
  });

  // ===========================================================================
  // TrainingGoals 測試
  // ===========================================================================
  group('TrainingGoals', () {
    group('fromJson', () {
      test('正確解析 JSON', () {
        // Arrange
        final json = <String, dynamic>{
          'primary': 'weight_loss',
          'target_kg': -5.0,
          'timeframe_months': 3,
          'notes': '減少腹部脂肪',
        };

        // Act
        final goals = TrainingGoals.fromJson(json);

        // Assert
        expect(goals.primary, 'weight_loss');
        expect(goals.targetKg, -5.0);
        expect(goals.timeframeMonths, 3);
        expect(goals.notes, '減少腹部脂肪');
      });
    });

    group('toJson', () {
      test('正確序列化', () {
        // Arrange
        const goals = TrainingGoals(
          primary: 'muscle_gain',
          targetKg: 5.0,
        );

        // Act
        final json = goals.toJson();

        // Assert
        expect(json['primary'], 'muscle_gain');
        expect(json['target_kg'], 5.0);
      });
    });

    group('primaryLabel', () {
      test('返回正確中文標籤', () {
        expect(
            const TrainingGoals(primary: 'weight_loss').primaryLabel, '減重減脂');
        expect(
            const TrainingGoals(primary: 'muscle_gain').primaryLabel, '增肌增重');
        expect(
            const TrainingGoals(primary: 'performance').primaryLabel, '運動表現');
        expect(const TrainingGoals(primary: 'health').primaryLabel, '健康維持');
        expect(const TrainingGoals(primary: 'rehabilitation').primaryLabel,
            '復健改善');
      });
    });
  });
}
