/* Firebase Cloud Messaging service worker for web push (NAD-39).
 *
 * ACTIVATION (not yet wired — web push is optional):
 *  1. Fill the firebaseConfig below with the web app config from
 *     Firebase console (same values as firebase_options.dart `web`).
 *  2. Generate a Web Push certificate (VAPID key) in Firebase console
 *     → Project settings → Cloud Messaging → Web configuration, and pass
 *     it to FirebaseMessaging.getToken(vapidKey: '...') in the client.
 *  3. Background notifications are then handled here.
 *
 * Until activated, FCM degrades gracefully — NotificationService catches
 * the failure and the app runs normally. Server-side push
 * (onActivityCreate → topic) is unaffected.
 */

importScripts(
    'https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js');
importScripts(
    'https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js');

// TODO(sprint4): paste the web config from firebase_options.dart.
firebase.initializeApp({
  apiKey: 'AIzaSyDznUAbEPzy5TO45EpqchwghkyKATgEZfA',
  appId: '1:209859165632:web:a9226dccef97f9e69b9c25',
  messagingSenderId: '209859165632',
  projectId: 'strayfriends-utm',
  authDomain: 'strayfriends-utm.firebaseapp.com',
  storageBucket: 'strayfriends-utm.firebasestorage.app',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const title = payload.notification?.title || 'Strayfriends';
  const options = {
    body: payload.notification?.body || '',
    icon: '/icons/Icon-192.png',
    data: payload.data || {},
  };
  self.registration.showNotification(title, options);
});
