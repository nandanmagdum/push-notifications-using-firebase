import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:hive/hive.dart';
import 'package:push_notify/main.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

import 'package:push_notify/notification_screen.dart';

class PushNotifications {
  static FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

  static Future<void> initHive() async {
    final appDocumentDirectory =
        await path_provider.getApplicationDocumentsDirectory();
    Hive.init(appDocumentDirectory.path);
  }

  static final androidChannel = const AndroidNotificationChannel(
      "High imp channel", "High imp notifications",
      description: "This channels is used to send high imp notifications",
      importance: Importance.high);
  static final localNotifications = FlutterLocalNotificationsPlugin();

  static final String hiveBoxName = 'notifications';

  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    print(message.notification?.title);
    print(message.notification?.body);
    print(message.data);
    // await handleMessage(message);
  }

  static Future handleMessage(RemoteMessage? message) async {
    if (!Hive.isBoxOpen(hiveBoxName)) {
      final box = await Hive.openBox<Map<String, dynamic>>("${hiveBoxName}");
      if (message != null && message.notification != null) {
        box.add(message.notification!.toMap());
      }
    }
  }

  static Future initLocalNotifications() async {
    const android = AndroidInitializationSettings("@drawable/ic_launcher");
    const settings = InitializationSettings(android: android);

    await localNotifications.initialize(settings);

    final platform = localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await platform?.createNotificationChannel(androidChannel);

    if (!Hive.isBoxOpen(hiveBoxName)) {
      // Load notifications from Hive and schedule them locally
      final box = await Hive.openBox<Map<String, dynamic>>(hiveBoxName);
      for (var notification in box.values) {
        final notificationData = NotificationDetails(
          android: AndroidNotificationDetails(
            androidChannel.id,
            androidChannel.name,
            channelDescription: androidChannel.description,
            icon: "@drawable/ic_launcher",
          ),
        );
        final decodedNotification = RemoteMessage.fromMap(notification);
        final notificationPayload = jsonEncode(decodedNotification.toMap());
        localNotifications.show(
          decodedNotification.hashCode,
          decodedNotification.notification?.title ?? '',
          decodedNotification.notification?.body ?? '',
          notificationData,
          payload: notificationPayload,
        );
      }
    }
  }

  static Future<void> initPushNotifications() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
            alert: true, badge: true, sound: true);

    FirebaseMessaging.instance.getInitialMessage().then(handleMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;
      localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
              androidChannel.id, androidChannel.name,
              channelDescription: androidChannel.description,
              icon: "@drawable/ic_launcher"),
        ),
        payload: jsonEncode(message.toMap()),
      );
    });
  }

  static Future<void> init() async {
    await initHive();
    await firebaseMessaging.requestPermission();
    final fcmToken = await firebaseMessaging.getToken();
    print("FCM token is : ${fcmToken}");
    initPushNotifications();
    initLocalNotifications();
  }
}
