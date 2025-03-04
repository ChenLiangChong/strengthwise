import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // 檢查用戶是否已完成資料設置
  Future<bool> isProfileCompleted() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return false;
      
      final userData = doc.data();
      if (userData == null) return false;
      
      // 检查必填字段是否已填写
      return userData['nickname'] != null && 
             userData['gender'] != null;
    } catch (e) {
      print('檢查用戶資料出錯: $e');
      return false;
    }
  }
  
  // 獲取當前用戶的完整資料
  Future<UserModel?> getCurrentUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        // 如果在 Firestore 中没有用户数据，创建一个基本记录
        final basicUserData = {
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'isCoach': false,
          'isStudent': true,
          'profileCreatedAt': FieldValue.serverTimestamp(),
        };
        
        await _firestore.collection('users').doc(user.uid).set(basicUserData);
        
        return UserModel(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName,
          photoURL: user.photoURL,
          isCoach: false,
          isStudent: true,
        );
      }
      
      final userData = doc.data()!;
      return UserModel.fromMap({...userData, 'uid': user.uid});
    } catch (e) {
      print('獲取用戶資料出錯: $e');
      return null;
    }
  }
  
  // 更新用戶資料
  Future<bool> updateUserProfile({
    String? displayName,
    String? nickname,
    String? gender,
    double? height,
    double? weight,
    int? age,
    bool? isCoach,
    bool? isStudent,
    File? avatarFile,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      // 获取当前用户数据
      final currentProfile = await getCurrentUserProfile();
      if (currentProfile == null) return false;
      
      // 处理头像上传
      String? photoURL = currentProfile.photoURL;
      if (avatarFile != null) {
        final storageRef = _storage.ref().child('user_avatars/${user.uid}');
        final uploadTask = storageRef.putFile(avatarFile);
        final snapshot = await uploadTask;
        photoURL = await snapshot.ref.getDownloadURL();
        
        // 更新 Firebase Auth 中的用户资料
        await user.updatePhotoURL(photoURL);
      }
      
      // 更新显示名称
      if (displayName != null && displayName.isNotEmpty) {
        await user.updateDisplayName(displayName);
      }
      
      // 创建更新后的用户模型
      final updatedUserData = currentProfile.copyWith(
        displayName: displayName,
        photoURL: photoURL,
        nickname: nickname,
        gender: gender,
        height: height,
        weight: weight,
        age: age,
        isCoach: isCoach,
        isStudent: isStudent,
      ).toMap();
      
      // 更新时间戳
      updatedUserData['profileUpdatedAt'] = FieldValue.serverTimestamp();
      if (currentProfile.profileCreatedAt == null) {
        updatedUserData['profileCreatedAt'] = FieldValue.serverTimestamp();
      }
      
      // 保存到 Firestore
      await _firestore.collection('users').doc(user.uid).set(updatedUserData, SetOptions(merge: true));
      
      return true;
    } catch (e) {
      print('更新用戶資料出錯: $e');
      return false;
    }
  }
  
  // 切換用戶角色
  Future<bool> toggleUserRole(bool isCoach) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      await _firestore.collection('users').doc(user.uid).update({
        'isCoach': isCoach,
      });
      
      return true;
    } catch (e) {
      print('切換用戶角色出錯: $e');
      return false;
    }
  }
} 