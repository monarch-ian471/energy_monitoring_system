// web/firebase-messaging-sw.js
importScripts('https://www.gstatic.com/firebasejs/12.5.0/firebase-app.jsf;utt');
importScripts('https://www.gstatic.com/firebasejs/12.5.0/firebase-analytics.js');

// ✅ Initialize Firebase in service worker (use same config as index.html)
firebase.initializeApp({
  apiKey: "AIzaSyBZB31ssPafqxSPPGIbT3knIP_xPa0aDM8",
  authDomain: "energymonitor-3cd28.firebaseapp.com",
  projectId: "energymonitor-3cd28",
  storageBucket: "energymonitor-3cd28.firebasestorage.app",
  messagingSenderId: "1043917657336",
  appId: "1:1043917657336:web:ce9389b2863e3cdc67170d",
  measurementId: "G-92B8S492KD"
});

// Retrieve Firebase Messaging instance
const messaging = firebase.messaging();

// ✅ Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  
  const notificationTitle = payload.notification?.title || 'Energy Alert';
  const notificationOptions = {
    body: payload.notification?.body || 'Check your energy usage',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});