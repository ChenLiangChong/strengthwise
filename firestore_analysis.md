# Firestore 数据库分析报告

**项目**: strengthwise-91f02
**分析时间**: "2025-12-25 06:08:10.084470"

## 集合概览

| 集合名称 | 文档数量 | 字段数量 |
|---------|---------|---------|
| `users` | 4 | 16 |
| `user` | 0 | 0 |
| `workoutPlans` | 54 | 18 |
| `bookings` | 0 | 0 |
| `exercise` | 100 | 22 |
| `exercises` | 0 | 0 |
| `bodyParts` | 8 | 3 |
| `exerciseTypes` | 3 | 3 |
| `notes` | 0 | 0 |
| `relationships` | 0 | 0 |
| `availabilities` | 0 | 0 |

## 详细字段结构

### users

**文档数量**: 4

| 字段名称 | 类型 | 可空比例 | 示例值 |
|---------|------|---------|--------|
| `age` | integer | 0.0% | 28, 28 |
| `bio` | string | 0.0% | 我是個好人, I am a good person |
| `birthDate` | DatetimeWithNanoseconds / null | 25.0% | - |
| `displayName` | string | 0.0% | 良允陳, 良允陳 |
| `email` | string | 0.0% | charlie8519960414@gmail.com, charlie8519960414@gmail.com |
| `gender` | string | 0.0% | 男, 男 |
| `height` | number | 0.0% | 178.0, 179.0 |
| `isCoach` | boolean | 0.0% | False, False |
| `isStudent` | boolean | 0.0% | True, True |
| `nickname` | string | 0.0% | 夢行, Charlie |
| `photoURL` | string | 0.0% | https://lh3.googleusercontent.com/a/ACg8ocKH4HT0mLinvbfVzKegc0vyCErRJy1wxb2CfPBQhvwNFO1R4A=s96-c, https://lh3.googleusercontent.com/a/ACg8ocKH4HT0mLinvbfVzKegc0vyCErRJy1wxb2CfPBQhvwNFO1R4A=s96-c |
| `profileCreatedAt` | DatetimeWithNanoseconds | 0.0% | - |
| `profileUpdatedAt` | DatetimeWithNanoseconds | 0.0% | - |
| `uid` | string | 0.0% | MmvGmxq15ZMNzAy67bRPhYVy6pG3, P5598FxYVpUBkSHwEVRLmK1HJlU2 |
| `unitSystem` | string | 0.0% | metric, metric |
| `weight` | number | 0.0% | 86.0, 85.0 |

### user

**文档数量**: 0

*无字段数据*

### workoutPlans

**文档数量**: 54

| 字段名称 | 类型 | 可空比例 | 示例值 |
|---------|------|---------|--------|
| `completed` | boolean | 0.0% | True, False |
| `completedDate` | DatetimeWithNanoseconds | 0.0% | - |
| `createdAt` | DatetimeWithNanoseconds | 0.0% | - |
| `creatorId` | string | 0.0% | zJ8UuJ3LUJSnkyxtf8One4YHRC72, MmvGmxq15ZMNzAy67bRPhYVy6pG3 |
| `description` | string | 0.0% | ,  |
| `exercises` | array<map> | 0.0% | [4 items], [1 items] |
| `note` | string | 0.0% | 訓練量: 3,354 kg, 訓練量: 3,740 kg |
| `planType` | string | 0.0% | self, self |
| `scheduledDate` | DatetimeWithNanoseconds | 0.0% | - |
| `title` | string | 0.0% | 第4週 推日 A - 個人記錄挑戰, 133 |
| `totalExercises` | integer | 0.0% | 4, 4 |
| `totalSets` | integer | 0.0% | 13, 13 |
| `totalVolume` | integer / number | 0.0% | 3354, 3740 |
| `traineeId` | string | 0.0% | zJ8UuJ3LUJSnkyxtf8One4YHRC72, MmvGmxq15ZMNzAy67bRPhYVy6pG3 |
| `trainingTime` | DatetimeWithNanoseconds / null | 5.56% | - |
| `uiPlanType` | string | 0.0% | 力量訓練, 力量訓練 |
| `updatedAt` | DatetimeWithNanoseconds | 0.0% | - |
| `userId` | string | 0.0% | zJ8UuJ3LUJSnkyxtf8One4YHRC72, MmvGmxq15ZMNzAy67bRPhYVy6pG3 |

### bookings

**文档数量**: 0

*无字段数据*

### exercise

**文档数量**: 100

| 字段名称 | 类型 | 可空比例 | 示例值 |
|---------|------|---------|--------|
| `actionName` | string | 0.0% | 內外波浪, 弓箭步，交替 |
| `apps` | array | 0.0% | - |
| `bodyPart` | string | 0.0% | 全身, 肩 |
| `bodyParts` | array<string> | 0.0% | [1 items], [1 items] |
| `createdAt` | DatetimeWithNanoseconds | 0.0% | - |
| `description` | string | 0.0% | ,  |
| `equipment` | string | 0.0% | 徒手, Cable滑輪機 |
| `equipmentCategory` | string | 0.0% | 徒手, 機械式 |
| `equipmentSubcategory` | string | 0.0% | 自身體重, Cable滑輪 |
| `imageUrl` | string | 0.0% | ,  |
| `jointType` | string | 0.0% | 多關節, 多關節 |
| `level1` | string | 0.0% | 戰繩, 拉 |
| `level2` | string | 0.0% | , 反向飛鳥 |
| `level3` | string | 0.0% | , 屈體式 |
| `level4` | string | 0.0% | , 半固定器材 |
| `level5` | string | 0.0% | ,  |
| `name` | string | 0.0% | 戰繩/內外波浪, 拉／反向飛鳥／屈體式／半固定器材／弓箭步，交替 |
| `nameEn` | string | 0.0% | Battle ropes/In and out waves, Pull/Reverse fly/Bent over/Pulley/Lunge steps, Alternating |
| `specificMuscle` | string | 0.0% | 綜合訓練, 後三角 |
| `trainingType` | string | 0.0% | 重訓, 重訓 |
| `type` | string | 0.0% | 重訓, 重訓 |
| `videoUrl` | string | 0.0% | ,  |

### exercises

**文档数量**: 0

*无字段数据*

### bodyParts

**文档数量**: 8

| 字段名称 | 类型 | 可空比例 | 示例值 |
|---------|------|---------|--------|
| `count` | integer | 0.0% | 53, 95 |
| `description` | string | 0.0% | ,  |
| `name` | string | 0.0% | 手, 肩 |

### exerciseTypes

**文档数量**: 3

| 字段名称 | 类型 | 可空比例 | 示例值 |
|---------|------|---------|--------|
| `count` | integer | 0.0% | 20, 30 |
| `description` | string | 0.0% | ,  |
| `name` | string | 0.0% | 有氧, 伸展 |

### notes

**文档数量**: 0

*无字段数据*

### relationships

**文档数量**: 0

*无字段数据*

### availabilities

**文档数量**: 0

*无字段数据*

