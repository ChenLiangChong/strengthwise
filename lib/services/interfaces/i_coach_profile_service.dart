import 'package:strengthwise/models/coach_profile/coach_profile_model.dart';

/// 教練公開檔案服務介面
/// 
/// 功能：
/// 1. 教練可以建立/讀取/更新自己的公開檔案
/// 2. 學員可以查看有綁定關係的教練檔案
/// 3. 與 users 表 1:1 關聯（共用 id）
abstract class ICoachProfileService {
  /// 取得教練檔案
  /// 
  /// [coachId] 教練 ID（與 users.id 相同）
  /// 
  /// 返回：教練檔案，如果不存在則返回 null
  Future<CoachProfileModel?> getProfile(String coachId);

  /// 建立教練檔案
  /// 
  /// [profile] 教練檔案資料
  /// 
  /// 返回：建立後的教練檔案
  /// 
  /// 前提條件：
  /// - 用戶必須是教練（users.is_coach = true）
  /// - 該用戶尚未有教練檔案
  Future<CoachProfileModel> createProfile(CoachProfileModel profile);

  /// 更新教練檔案
  /// 
  /// [profile] 教練檔案資料
  /// 
  /// 返回：更新後的教練檔案
  /// 
  /// 前提條件：
  /// - 用戶必須是教練
  /// - 只能更新自己的檔案
  Future<CoachProfileModel> updateProfile(CoachProfileModel profile);

  /// 建立或更新教練檔案（upsert）
  /// 
  /// [profile] 教練檔案資料
  /// 
  /// 返回：建立或更新後的教練檔案
  Future<CoachProfileModel> upsertProfile(CoachProfileModel profile);

  /// 檢查教練是否已有檔案
  /// 
  /// [coachId] 教練 ID
  /// 
  /// 返回：是否已有檔案
  Future<bool> hasProfile(String coachId);

  /// 刪除教練檔案
  /// 
  /// [coachId] 教練 ID
  /// 
  /// 說明：通常不需要使用，因為刪除 user 時會 CASCADE 刪除
  Future<void> deleteProfile(String coachId);
}

