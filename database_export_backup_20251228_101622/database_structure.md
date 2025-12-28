# StrengthWise Database Structure

Exported at: 2025-12-28T09:44:49.459740

================================================================================

## Table: users

**Record Count**: 3

### Columns (17)

| Column | Type | Sample Value |
|--------|------|--------------|
| id | str | 674b2d21-eaf3-4ab9-8751-d90126d3c75e |
| email | str | mark61102005@gmail.com |
| display_name | NoneType | None |
| photo_url | NoneType | None |
| nickname | NoneType | None |
| gender | NoneType | None |
| height | NoneType | None |
| weight | float | 150.0 |
| age | NoneType | None |
| birth_date | NoneType | None |
| is_coach | bool | False |
| is_student | bool | True |
| bio | NoneType | None |
| unit_system | str | metric |
| profile_created_at | str | 2025-12-27T07:18:36.627305+00:00 |
| profile_updated_at | str | 2025-12-27T07:26:36.656152+00:00 |
| last_login | str | 2025-12-27T07:18:36.627305+00:00 |

### Statistics
- Total records: 3

--------------------------------------------------------------------------------

## Table: exercises

**Record Count**: 794

### Columns (28)

| Column | Type | Sample Value |
|--------|------|--------------|
| id | str | 84i8R6FXn88ABbEDv9cf |
| name | str | TRX/衝刺 |
| name_en | str | Suspension trainer/Sprint |
| action_name | str | 衝刺 |
| training_type | str | 阻力訓練 |
| body_part | str | 全身 |
| body_parts | list | ['全身'] |
| specific_muscle | str | 全身綜合 |
| equipment | str | 徒手訓練 |
| equipment_category | str | 徒手訓練 |
| equipment_subcategory | str | 自身體重 |
| joint_type | str | 多關節 |
| level1 | str | TRX |
| level2 | str |  |
| level3 | str |  |
| level4 | str |  |
| level5 | str |  |
| description | str |  |
| image_url | str |  |
| video_url | str |  |
| user_id | NoneType | None |
| created_at | NoneType | None |
| updated_at | str | 2025-12-25T22:32:53.718418+00:00 |
| training_type_en | str | Resistance Training |
| body_part_en | str | Full Body |
| specific_muscle_en | str | Total Body |
| equipment_category_en | str | Bodyweight Training |
| equipment_subcategory_en | str | Bodyweight |

### Statistics
- Total records: 794

**Training Types:**
- 阻力訓練: 744
- 活動度與伸展: 30
- 心肺適能訓練: 20

--------------------------------------------------------------------------------

## Table: custom_exercises

**Record Count**: 6

### Columns (13)

| Column | Type | Sample Value |
|--------|------|--------------|
| id | str | AdQUEfIYoyC4aXoWXt7W |
| user_id | str | 674b2d21-eaf3-4ab9-8751-d90126d3c75e |
| name | str | 哈克深蹲 |
| body_part | str | 腿部 |
| equipment | str | 固定式機械 |
| description | str |  |
| notes | str |  |
| created_at | str | 2025-12-27T07:50:09.865525+00:00 |
| updated_at | str | 2025-12-27T07:50:09.865525+00:00 |
| training_type | str | 阻力訓練 |
| training_type_en | str | Resistance Training |
| body_part_en | str | Legs |
| equipment_en | str | Machine |

### Statistics
- Total records: 6

**Body Parts Distribution:**
- 腿部: 4
- 胸部: 2

--------------------------------------------------------------------------------

## Table: workout_plans

**Record Count**: 26

### Columns (19)

| Column | Type | Sample Value |
|--------|------|--------------|
| id | str | yh191YNeyqiZuRYaziEV |
| user_id | str | d1798674-0b96-4c47-a7c7-ee20a5372a03 |
| creator_id | str | d1798674-0b96-4c47-a7c7-ee20a5372a03 |
| trainee_id | str | d1798674-0b96-4c47-a7c7-ee20a5372a03 |
| title | str | 胸肩三頭訓練 |
| description | NoneType | None |
| plan_type | str | personal |
| ui_plan_type | NoneType | None |
| scheduled_date | str | 2025-12-15T18:00:59.884022+00:00 |
| completed_date | str | 2025-12-15T19:30:59.884022+00:00 |
| training_time | NoneType | None |
| exercises | list | [{'sets': [{'note': '', 'reps': 8, 'weight': 63.0,... |
| completed | bool | True |
| total_exercises | int | 4 |
| total_sets | int | 17 |
| total_volume | float | 7497.8 |
| note | str | 週數 3 - 漸進式超負荷 |
| created_at | str | 2025-12-15T10:12:59.884022+00:00 |
| updated_at | str | 2025-12-26T04:31:54.415507+00:00 |

### Statistics
- Total records: 26
- Completed: 25
- Pending: 1
- Total training volume: 133398.9 kg

--------------------------------------------------------------------------------

## Table: workout_templates

**Record Count**: 8

### Columns (9)

| Column | Type | Sample Value |
|--------|------|--------------|
| id | str | 7pIo0ydHGN7c92dilavp |
| user_id | str | d1798674-0b96-4c47-a7c7-ee20a5372a03 |
| title | str | 下肢訓練 |
| description | str | 腿部和核心的全面訓練 |
| plan_type | str | 力量訓練 |
| exercises | list | [{'id': '2ff3605c-7021-4cee-8129-f292572b8f82', 'n... |
| training_time | NoneType | None |
| created_at | str | 2025-12-26T10:13:06.705166+00:00 |
| updated_at | str | 2025-12-26T10:13:06.705166+00:00 |

### Statistics
- Total records: 8
- User templates: 8

--------------------------------------------------------------------------------

## Table: body_data

**Record Count**: 14

### Columns (10)

| Column | Type | Sample Value |
|--------|------|--------------|
| id | str | vyhaMCqNdkzWfjiUU2Up |
| user_id | str | d1798674-0b96-4c47-a7c7-ee20a5372a03 |
| record_date | str | 2025-12-25T19:48:58.726153+00:00 |
| weight | int | 80 |
| body_fat | NoneType | None |
| muscle_mass | NoneType | None |
| bmi | NoneType | None |
| notes | NoneType | None |
| created_at | str | 2025-12-25T19:49:04.393438+00:00 |
| updated_at | NoneType | None |

### Statistics
- Total records: 14
- Weight range: 75.0 - 200.0 kg
- Average weight: 111.4 kg
- Body fat range: 25.0% - 50.0%

--------------------------------------------------------------------------------

## Table: notes

**Record Count**: 0

--------------------------------------------------------------------------------

## Table: body_parts

**Record Count**: 8

### Columns (8)

| Column | Type | Sample Value |
|--------|------|--------------|
| id | str | epHlrDTlBP4cARI4Q3cE |
| name | str | 全身 |
| description | str |  |
| count | int | 145 |
| created_at | str | 2025-12-24T22:28:45.222638+00:00 |
| updated_at | str | 2025-12-25T21:59:21.475545+00:00 |
| name_en | str | Full Body |
| description_en | str | Full body compound movements |

### Statistics
- Total records: 8

**Body Parts:**
- 全身
- 手
- 核心
- 肩, 背
- 肩部
- 背部
- 胸部
- 腿部

--------------------------------------------------------------------------------

## Table: exercise_types

**Record Count**: 3

### Columns (8)

| Column | Type | Sample Value |
|--------|------|--------------|
| id | str | uWL6kZ3GwSJ3DYZUMRh8 |
| name | str | 阻力訓練 |
| description | str |  |
| count | int | 744 |
| created_at | str | 2025-12-24T22:28:45.561825+00:00 |
| updated_at | str | 2025-12-25T21:59:21.475545+00:00 |
| name_en | str | Resistance Training |
| description_en | str | Training using resistance to build muscle strength... |

### Statistics
- Total records: 3

**Exercise Types:**
- 心肺適能訓練
- 活動度與伸展
- 阻力訓練

--------------------------------------------------------------------------------