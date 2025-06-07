/**
 * app.js - reMind App エントリーポイント
 * Firebase + Cloudinary統合版
 */

import { mainController } from './mainController.js';

// DOMContentLoaded時にアプリケーション初期化
document.addEventListener('DOMContentLoaded', function() {
  const avatarId = getAvatarIdFromURL();
  if (avatarId) {
    console.log('🔗 URL Avatar ID:', avatarId);
    // avatarIdをappStateに保存
    appState.set('avatarId', avatarId);
    // 既存のアバター情報を取得
    loadExistingAvatar(avatarId);
  } else {
    console.log('⚠️ No Avatar ID found in URL');
  }
  
  mainController.initialize();
});

/**
 * URLからアバターIDを取得する関数
 * 2つの形式に対応:
 * 1. ?avatarId=avatar_1749297509_8523
 * 2. ?avatar_1749297509_8523
 */
function getAvatarIdFromURL() {
  const urlParams = new URLSearchParams(window.location.search);
  
  // 方式1: ?avatarId=xxx の形式
  const avatarIdParam = urlParams.get('avatarId');
  if (avatarIdParam) {
    return avatarIdParam;
  }
  
  // 方式2: ?avatar_1749297509_8523 の形式
  const queryString = window.location.search;
  if (queryString.startsWith('?avatar_')) {
    // '?' を除いてアバターIDを取得
    return queryString.substring(1);
  }
  
  // 方式3: URLパラメータの最初のキーがアバターIDの場合
  const firstParam = urlParams.keys().next().value;
  if (firstParam && firstParam.startsWith('avatar_')) {
    return firstParam;
  }
  
  return null;
}

/**
 * より堅牢なURL解析（デバッグ用）
 */
function debugURLParsing() {
  const currentURL = window.location.href;
  const queryString = window.location.search;
  const urlParams = new URLSearchParams(queryString);
  
  console.log('🔍 URL Debug Info:');
  console.log('  Full URL:', currentURL);
  console.log('  Query String:', queryString);
  console.log('  All Parameters:', [...urlParams.entries()]);
  
  const avatarId = getAvatarIdFromURL();
  console.log('  Extracted Avatar ID:', avatarId);
  
  return avatarId;
}

/**
 * 既存のアバター情報を読み込む
 */
async function loadExistingAvatar(avatarId) {
  try {
    console.log('📥 Loading existing avatar data for:', avatarId);
    
    // Firebase から既存のアバター情報を取得
    const avatarData = await firebaseService.getAvatar(avatarId);
    
    if (avatarData) {
      console.log('✅ Existing avatar found:', avatarData);
      
      // UI に既存情報を表示（必要に応じて）
      displayExistingAvatarInfo(avatarData);
    } else {
      console.log('⚠️ No existing avatar data found for ID:', avatarId);
    }
    
  } catch (error) {
    console.error('❌ Error loading existing avatar:', error);
    // エラーがあってもアプリの続行は可能
  }
}

/**
 * 既存アバター情報の表示
 */
function displayExistingAvatarInfo(avatarData) {
  // 受信者名がある場合は表示
  if (avatarData.recipient_name) {
    const headerText = document.querySelector('.header-text');
    if (headerText) {
      headerText.innerHTML = `Help ${avatarData.recipient_name} feel safer`;
    }
  }
  
  // 作成者名がある場合は表示
  if (avatarData.creator_name) {
    const subheaderText = document.querySelector('.subheader-text');
    if (subheaderText) {
      subheaderText.innerHTML = `${avatarData.creator_name} has requested you to create a personalized avatar.`;
    }
  }
  
  // ステータス表示
  console.log(`📊 Avatar Status: ${avatarData.status}`);
  if (avatarData.status === 'ready') {
    console.log('✅ This avatar is already complete');
    // 必要に応じて完了状態の UI を表示
  }
}

// テスト用関数（デバッグ時に使用）
function testURLParsing() {
  console.log('🧪 Testing URL parsing...');
  
  // テストケース
  const testURLs = [
    'http://127.0.0.1:5500/index.html?avatar_1749297509_8523',
    'http://127.0.0.1:5500/index.html?avatarId=avatar_1749297509_8523',
    'http://127.0.0.1:5500/index.html?avatar_1749297509_8523&test=1',
    'http://127.0.0.1:5500/index.html'
  ];
  
  testURLs.forEach(url => {
    // URL を一時的に設定してテスト
    const originalLocation = window.location.search;
    const testSearch = url.split('?')[1] || '';
    
    console.log(`Testing: ?${testSearch}`);
    
    // URLSearchParams でテスト
    const testParams = new URLSearchParams(testSearch);
    const testResult = testSearch.startsWith('avatar_') ? testSearch : testParams.get('avatarId');
    
    console.log(`  Result: ${testResult}`);
  });
}

console.log('📚 reMind App loaded successfully - Ready for Firebase + Cloudinary!');