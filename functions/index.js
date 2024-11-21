const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendNotificationOnSessionChange = functions.firestore
    .document("users/{userId}")
    .onUpdate(async (change, context) => {
      const before = change.before.data();
      const after = change.after.data();

      // Check if sessionCount has changed
      if (before.sessionCount !== after.sessionCount) {
        const fcmToken = after.fcmToken;

        if (fcmToken) {
          const message = {
            notification: {
              title: "Session Count Updated",
              body: `Your session count has changed to ${after.sessionCount}`,
            },
            token: fcmToken,
          };

          // Send the notification
          try {
            await admin.messaging().send(message);
            console.log("Notification sent successfully");
          } catch (error) {
            console.error("Error sending notification:", error);
          }
        }
      }

      return null;
    });
