import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotifService {
  NotifService._();
  static final NotifService instance = NotifService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'deadline_channel';
  static const String _channelName = 'Deadline Reminder';

  /// Default jam pengingat (ubah di sini)
  static const int _reminderHour = 15;
  static const int _reminderMinute = 59;

  /// WAJIB dipanggil di main() sebelum runApp()
  Future<void> init() async {
    tzdata.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(initSettings);

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Notifikasi pengingat deadline note',
      importance: Importance.high,
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(channel);

    // Android 13+ runtime permission
    await androidPlugin?.requestNotificationsPermission();

    // Android 12+/14 exact alarm permission (jika dibutuhkan perangkat)
    await androidPlugin?.requestExactAlarmsPermission();
  }

  /// Schedule notifikasi deadline
  /// - H-1 pada jam _reminderHour:_reminderMinute
  /// - Hari H pada jam _reminderHour:_reminderMinute
  ///
  /// Perbaikan utama: jika waktu target sudah lewat saat note dibuat,
  /// jadwalkan fallback "sekarang + 1 menit" agar tidak "hilang".
  Future<void> scheduleForNote({
    required String noteId,
    required String title,
    required DateTime? deadlineDateOnly,
  }) async {
    await cancelForNote(noteId);
    if (deadlineDateOnly == null) return;

    final dl = DateTime(
      deadlineDateOnly.year,
      deadlineDateOnly.month,
      deadlineDateOnly.day,
    );

    final hMinus1 = dl.subtract(const Duration(days: 1));

    final tHMinus1Raw = DateTime(
      hMinus1.year,
      hMinus1.month,
      hMinus1.day,
      _reminderHour,
      _reminderMinute,
    );

    final tHRaw = DateTime(
      dl.year,
      dl.month,
      dl.day,
      _reminderHour,
      _reminderMinute,
    );

    final tHMinus1 = _nextValidTime(tHMinus1Raw);
    final tH = _nextValidTime(tHRaw);

    await _scheduleAt(
      id: _notifId(noteId, 1),
      when: tHMinus1,
      title: 'Deadline mendekat',
      body: '$title (H-1)',
    );

    await _scheduleAt(
      id: _notifId(noteId, 2),
      when: tH,
      title: 'Deadline hari ini',
      body: title,
    );
  }

  /// Cancel semua notifikasi untuk satu note
  Future<void> cancelForNote(String noteId) async {
    await _plugin.cancel(_notifId(noteId, 1));
    await _plugin.cancel(_notifId(noteId, 2));
  }

  /// Debug: tampilkan notif sekarang
  Future<void> showNow({required String title, required String body}) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Notifikasi pengingat deadline note',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    await _plugin.show(9999, title, body, details);
  }

  // ====== PRIVATE ======

  int _notifId(String noteId, int variant) =>
      noteId.hashCode ^ (variant * 1000003);

  /// Jika waktu target sudah lewat, fallback ke "sekarang + 1 menit"
  /// agar pengingat tidak hilang (kasus deadline besok tapi H-1 sudah lewat).
  DateTime _nextValidTime(DateTime target) {
    final now = DateTime.now();
    if (target.isAfter(now)) return target;
    return now.add(const Duration(minutes: 1));
  }

  Future<void> _scheduleAt({
    required int id,
    required DateTime when,
    required String title,
    required String body,
  }) async {
    // Tidak perlu guard isBefore, karena sudah dibetulkan di _nextValidTime().
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Notifikasi pengingat deadline note',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(when, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: null,
    );
  }
}
