const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendSessionCountUpdate = functions.firestore
    .document('users/{userId}')
    .onUpdate((change, context) => {
        const before = change.before.data();
        const after = change.after.data();

        if (before.sessionCount !== after.sessionCount) {
            const fcmToken = after.fcmToken;

            // Send notification to the user's device
            const message = {
                notification: {
                    title: 'Session Count Updated',
                    body: `Your session count has changed to ${after.sessionCount}`,
                },
                token: fcmToken,
            };

            return admin.messaging().send(message)
                .then((response) => {
                    console.log('Notification sent successfully:', response);
                    return null;
                })
                .catch((error) => {
                    console.log('Error sending notification:', error);
                    return null;
                });
        }

        return null;
    });
