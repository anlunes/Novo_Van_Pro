importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyD9C1MakJDesxCarU1dkzwPXR1xvcxAaRs",
  authDomain: "vanpro-8d330.firebaseapp.com",
  projectId: "vanpro-8d330",
  storageBucket: "vanpro-8d330.firebasestorage.app",
  messagingSenderId: "1040938990718",
  appId: "1:1040938990718:web:0317f2a92790d84c32ac2f"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('Mensagem em background recebida: ', payload);

  const notificationTitle = payload.notification?.title || 'VanPro';
  const notificationOptions = {
    body: payload.notification?.body || '',
    icon: '/icons/Icon-192.png'
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});
