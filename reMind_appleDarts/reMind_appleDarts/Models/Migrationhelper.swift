//
//  Migrationhelper.swift
//  reMind_appleDarts
//
//  Created by user on 2025/06/08.
//

import Foundation

class DevelopmentHelper {
    // 開発用のテストユーザー作成
    static func createTestUser() -> User {
        return User(
            id: Int.random(in: 1000...9999),
            name: "Test User",
            email: "test@example.com",
            password: "password123",
            profileImg: "sample_avatar",
            avatars: []
        )
    }
    
    // Firebaseのユーザーデータを完全クリア（開発用）
    static func clearAllFirebaseUserData() {
        let firebaseUserManager = FirebaseUserManager()
        firebaseUserManager.clearUser()
        
        // UserDefaultsもクリア
        UserDefaults.standard.removeObject(forKey: "firebase_user_id")
        
        print("🗑️ 全てのユーザーデータをクリアしました")
    }
}
