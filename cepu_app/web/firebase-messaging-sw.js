// Import Firebase scripts
importScripts('https://www.gstatic.com/firebasejs/10.13.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.0/firebase-messaging-compat.js');

// Initialize Firebase
try {
  firebase.initializeApp({
    apiKey: 'AIzaSyABVMqCkAoryjaYWpQjhrzyf6UF_tqPtrk',
    authDomain: 'khalbhi-dev.firebaseapp.com',
    databaseURL: 'https://khalbhi-dev-default-rtdb.asia-southeast1.firebasedatabase.app',
    projectId: 'khalbhi-dev',
    storageBucket: 'khalbhi-dev.firebasestorage.app',
    messagingSenderId: '1076757814194',
    appId: '1:1076757814194:web:3964b4077df2bb83a222ab',
    measurementId: 'G-W8Y1M17NP6',
  });

  const messaging = firebase.messaging();

  // Handle background messages
  messaging.onBackgroundMessage((payload) => {
    console.log('Received background message:', payload);
    
    const notificationTitle = payload.notification?.title || payload.data?.title || 'New Message';
    const notificationOptions = {
      body: payload.notification?.body || payload.data?.body || '',
      icon: '/icons/Icon-192.png',
      badge: '/icons/Icon-192.png',
      tag: payload.messageId || 'notification-' + Date.now(),
    };

    return self.registration.showNotification(notificationTitle, notificationOptions);
  });
} catch (error) {
  console.error('Service Worker initialization error:', error);
}
