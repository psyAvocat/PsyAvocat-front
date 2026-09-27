// Scripts for firebase and firebase messaging
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js');

// Initialize the Firebase app in the service worker by passing the options
firebase.initializeApp({
  apiKey: "AIzaSyAyCcKHezpJ89Z4uMwLwIxUYLEMsWyQ4hA",
  authDomain: "psyavocat.firebaseapp.com",
  projectId: "psyavocat",
  storageBucket: "psyavocat.firebasestorage.app",
  messagingSenderId: "434795703982",
  appId: "1:434795703982:web:831984cce60ce32b25073f"
});

// Retrieve an instance of Firebase Messaging so that it can handle background messages
const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message: ', payload);
  const notificationTitle = payload.notification?.title || (payload.data && payload.data.title) || 'PsyAvocat';
  const notificationOptions = {
    body: payload.notification?.body || (payload.data && payload.data.body) || '',
    icon: '/favicon.png',
    data: payload.data
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});
