void main() {
  final now = DateTime.now();
  print('Today: $now');
  print('Weekday: ${now.weekday} (1=Mon, 7=Sun)');
  
  // 計算週一
  final daysFromMonday = now.weekday - 1;
  final monday = now.subtract(Duration(days: daysFromMonday));
  final mondayStart = DateTime(monday.year, monday.month, monday.day);
  
  print('');
  print('daysFromMonday: $daysFromMonday');
  print('Monday (start of week): $mondayStart');
  
  // 計算週日
  final sunday = mondayStart.add(Duration(days: 6));
  print('Sunday (end of week): $sunday');
  
  print('');
  print('Expected range: ${mondayStart.toString().substring(0, 10)} ~ ${sunday.toString().substring(0, 10)}');
}
