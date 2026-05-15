importScripts('https://www.gstatic.com/firebasejs/10.12.5/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.5/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyABVMqCkAoryjaYWpQjhrzyf6UF_tqPtrk',
  authDomain: 'khalbhi-dev.firebaseapp.com',
  databaseURL:
    'https://khalbhi-dev-default-rtdb.asia-southeast1.firebasedatabase.app',
  projectId: 'khalbhi-dev',
  storageBucket: 'khalbhi-dev.firebasestorage.app',
  messagingSenderId: '1076757814194',
  appId: '1:1076757814194:web:3964b4077df2bb83a222ab',
  measurementId: 'G-W8Y1M17NP6',
});

firebase.messaging();
