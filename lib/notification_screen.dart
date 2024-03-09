import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:push_notify/push_notifications.dart';

class NotificationScreen extends StatelessWidget {
  final RemoteMessage? message;

  const NotificationScreen({Key? key, this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Notifications"),
      ),
      body: FutureBuilder(
        future: _loadNotifications(),
        builder: (context, AsyncSnapshot<List<Map>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final notifications = snapshot.data ?? [];
            return ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return ListTile(
                  title: Text(notification['title'] ?? ''),
                  subtitle: Text(notification['body'] ?? ''),
                );
              },
            );
          }
        },
      ),
    );
  }

  Future<List<Map>> _loadNotifications() async {
    try {
      if (Hive.isBoxOpen(PushNotifications.hiveBoxName)) {
        final box =
            Hive.box<Map<String, dynamic>>(PushNotifications.hiveBoxName);
        return box.values.toList();
      } else {
        // Return empty list if box is not open
        return [];
      }
    } catch (e) {
      // Handle error
      print("Error loading notifications: $e");
      return [];
    }
  }
}
