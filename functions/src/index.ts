import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";

admin.initializeApp();

// Notification 문서 생성 시 FCM 푸시 전송
export const sendGiftAcceptedPush = functions.firestore
  .document("Notifications/{notificationId}")
  .onCreate(async (snap, context) => {
    const notification = snap.data() as any;

    console.log("[Push] 알림 문서 생성됨:", context.params.notificationId);
    console.log("[Push] receiverId:", notification.receiverId);
    console.log("[Push] senderId:", notification.senderId);

    // receiverId로 FCM 토큰 조회
    const userDoc = await admin.firestore()
      .collection("User")
      .doc(notification.receiverId)
      .get();

    const fcmToken = userDoc.data()?.fcmToken;

    if (!fcmToken) {
      console.log("[Push] FCM 토큰 없음 - 푸시 전송 스킵");
      return;
    }

    console.log("[Push] FCM 토큰 찾음:", fcmToken);

    const unreadNotificationSnapshot = await admin.firestore()
      .collection("Notifications")
      .where("receiverId", "==", notification.receiverId)
      .where("isRead", "==", false)
      .get();

    const unreadCount = unreadNotificationSnapshot.size;
    console.log("[Push] 읽지 않은 알림 개수:", unreadCount);

    try {
      // FCM 메시지 전송
      await admin.messaging().send({
        token: fcmToken,
        notification: {
          title: "🎁 키링 전달 완료!",
          body: `${notification.senderNickname}님이 키링을 받았어요. `,
        },
        data: {
          type: "giftAccepted",
          postOfficeId: notification.postOfficeId,
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: unreadCount,
            },
          },
        },
      });

      console.log("[Push] FCM 전송 완료");
    } catch (error) {
      console.error("[Push] FCM 전송 실패:", error);
    }
  });
