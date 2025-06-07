/**
 * app.js - reMind App エントリーポイント
 * Firebase + Cloudinary統合版
 */

import { mainController } from './mainController.js';

// DOMContentLoaded時にアプリケーション初期化
document.addEventListener('DOMContentLoaded', function() {
  const avatarId = getURLParameter('avatarId');
  if (avatarId) {
    console.log('🔗 URL Avatar ID:', avatarId);
    // avatarIdをappStateに保存
    appState.set('avatarId', avatarId);
    // 既存のアバター情報を取得
    loadExistingAvatar(avatarId);
  }
  
  mainController.initialize();
});

function getURLParameter(name) {
  const urlParams = new URLSearchParams(window.location.search);
  return urlParams.get(name);
}

console.log('📚 reMind App loaded successfully - Ready for Firebase + Cloudinary!');