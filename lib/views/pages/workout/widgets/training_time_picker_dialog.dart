import 'package:flutter/material.dart';

/// 訓練時間選擇對話框
class TrainingTimePickerDialog extends StatefulWidget {
  final DateTime initialTime;

  const TrainingTimePickerDialog({
    super.key,
    required this.initialTime,
  });

  @override
  State<TrainingTimePickerDialog> createState() => _TrainingTimePickerDialogState();
}

class _TrainingTimePickerDialogState extends State<TrainingTimePickerDialog> {
  late int selectedHour;
  late int selectedMinute;

  @override
  void initState() {
    super.initState();
    selectedHour = widget.initialTime.hour;
    selectedMinute = widget.initialTime.minute;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('選擇訓練時間'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('請選擇訓練時間', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 20),

            // 顯示當前選擇的時間
            Text(
              '${selectedHour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')}',
              style: const TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // 時間選擇區
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 小時選擇
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text('小時', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).colorScheme.outline),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListWheelScrollView(
                          itemExtent: 40,
                          diameterRatio: 1.5,
                          onSelectedItemChanged: (index) {
                            setState(() {
                              selectedHour = index;
                            });
                          },
                          controller: FixedExtentScrollController(initialItem: selectedHour),
                          children: List.generate(24, (index) {
                            return Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: selectedHour == index ? Colors.blue.withOpacity(0.1) : Colors.transparent,
                              ),
                              child: Text(
                                index.toString().padLeft(2, '0'),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: selectedHour == index ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 20),

                // 分鐘選擇（只有0和30兩個選項）
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text('分鐘', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).colorScheme.outline),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedMinute = 0;
                                });
                              },
                              child: Container(
                                height: 80,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: selectedMinute == 0 ? Colors.blue.withOpacity(0.1) : Colors.transparent,
                                  border: Border(
                                    bottom: BorderSide(color: Theme.of(context).colorScheme.outline),
                                  ),
                                ),
                                child: Text(
                                  '00',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: selectedMinute == 0 ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedMinute = 30;
                                });
                              },
                              child: Container(
                                height: 80,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: selectedMinute == 30 ? Colors.blue.withOpacity(0.1) : Colors.transparent,
                                ),
                                child: Text(
                                  '30',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: selectedMinute == 30 ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            final now = DateTime.now();
            final newTime = DateTime(now.year, now.month, now.day, selectedHour, selectedMinute);
            Navigator.pop(context, newTime);
          },
          child: const Text('確定'),
        ),
      ],
    );
  }
}

