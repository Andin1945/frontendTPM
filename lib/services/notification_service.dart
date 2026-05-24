import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin notif =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(
      android: android,
    );

    await notif.initialize(settings);
  }

  static Future<void> showTransferSuccess(String phone, String amount) async {
    const androidDetails = AndroidNotificationDetails(
      'smartpay_transfer_channel',
      'SmartPay Transfer',
      channelDescription: 'Notifikasi transfer SmartPay AI',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
    );

    await notif.show(
      1,
      'Transfer Berhasil',
      'Rp$amount berhasil dikirim ke $phone',
      details,
    );
  }
}
