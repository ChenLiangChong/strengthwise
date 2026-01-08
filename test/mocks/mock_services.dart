/// 測試用 Mock 類
///
/// 使用 mocktail 建立 Service Interface 的 Mock

import 'package:mocktail/mocktail.dart';
import 'package:strengthwise/services/interfaces/i_readiness_service.dart';
import 'package:strengthwise/services/interfaces/i_appointment_service.dart';
import 'package:strengthwise/services/interfaces/i_workout_service.dart';
import 'package:strengthwise/services/interfaces/i_session_note_service.dart';
import 'package:strengthwise/models/readiness/daily_readiness_model.dart';

/// IReadinessService Mock
class MockReadinessService extends Mock implements IReadinessService {}

/// IAppointmentService Mock
class MockAppointmentService extends Mock implements IAppointmentService {}

/// IWorkoutService Mock
class MockWorkoutService extends Mock implements IWorkoutService {}

/// ISessionNoteService Mock
class MockSessionNoteService extends Mock implements ISessionNoteService {}

/// 註冊 fallback values（用於 any() matcher）
void registerFallbackValues() {
  // 註冊 DailyReadinessModel 的 fallback
  registerFallbackValue(DailyReadinessModel(
    id: 'fallback',
    userId: 'fallback',
    logDate: DateTime.now(),
    metrics: const ReadinessMetrics(
      sleepQuality: 3,
      sleepHours: 7.0,
      soreness: 3,
      stress: 3,
      energyLevel: 3,
    ),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ));
}
