// Import the scripts needed for Firebase messaging
importScripts('https://www.gstatic.com/firebasejs/8.10.0/firebase-app.js');
importScripts('https://www.gstatic.com/firebasejs/8.10.0/firebase-messaging.js');
importScripts('https://www.gstatic.com/firebasejs/8.10.0/firebase-firestore.js');

// Initialize the Firebase app in the service worker by passing in the
// messagingSenderId.
firebase.initializeApp({
    apiKey: "AIzaSyCYvYIaKvVwtncPODsRpPTXP0AD6VnHdvA",
    authDomain: "boosttrainingcourt-60158.firebaseapp.com",
    projectId: "boosttrainingcourt-60158",
    storageBucket: "boosttrainingcourt-60158.firebasestorage.app",
    messagingSenderId: "521925336650",
    appId: "1:521925336650:web:4c9ea332b13d12e53250b3"
});

// Retrieve an instance of Firebase Messaging so that it can handle background
// messages.
const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  // Customize notification here
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: payload.notification.icon,
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
