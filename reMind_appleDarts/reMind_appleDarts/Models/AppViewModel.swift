//
//  Untitled.swift
//  reMind_appleDarts
//
//  Created by user on 2025/06/03.
//

import Foundation
import SwiftUI
import Combine

/// Firebase専用のアプリケーションビューモデル（UserDefaults使用停止）
class AppViewModel: ObservableObject {
    @Published var authViewModel: AuthenticationViewModel
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Firebase認証のみを管理（UserDefaults依存を削除）
        self.authViewModel = AuthenticationViewModel()
        
        // ユーザー変更の監視
        setupUserObserver()
    }
    
    // MARK: - Setup
    
    private func setupUserObserver() {
        // ユーザー情報が変更された際の処理
        authViewModel.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                print("🔄 User changed: \(user?.name ?? "None")")
            }
            .store(in: &cancellables)
        
        // ローディング状態の監視
        authViewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { loading in
                print("🔄 Auth loading: \(loading)")
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Convenience Properties (User情報のみ)
    
    /// ユーザー表示情報
    var userDisplayName: String {
        return authViewModel.userDisplayName
    }
    
    var userProfileImage: String {
        return authViewModel.userProfileImage
    }
    
    var isLoggedIn: Bool {
        return authViewModel.isLoggedIn
    }
    
    var hasUser: Bool {
        return authViewModel.hasUser
    }
    
    var isLoading: Bool {
        return authViewModel.isLoading
    }
    
    var errorMessage: String {
        return authViewModel.errorMessage
    }
    
    // MARK: - User Management Methods
    
    func login(email: String, password: String) {
        // 開発用: 簡易ログイン（実際は認証ロジックが必要）
        let user = User(
            id: Int.random(in: 1000...9999),
            name: "User",
            email: email,
            password: password,
            profileImg: "sample_avatar",
            avatars: []
        )
        authViewModel.login(with: user)
    }
    
    func register(name: String, email: String, password: String) {
        let user = User(
            id: Int.random(in: 1000...9999),
            name: name,
            email: email,
            password: password,
            profileImg: "sample_avatar",
            avatars: []
        )
        authViewModel.login(with: user)
    }
    
    func logout() {
        authViewModel.logout()
    }
    
    func updateProfile(name: String? = nil, email: String? = nil, profileImg: String? = nil, password: String? = nil) {
        authViewModel.updateUserProfile(name: name, email: email, profileImg: profileImg, password: password)
    }
    
    // MARK: - Initialization Methods
    
    /// アプリ開始時にユーザーが存在することを確認
    func initializeApp() {
        if !authViewModel.hasUser {
            print("ℹ️ ユーザーが見つかりません - 新規ユーザーを作成")
            authViewModel.createDummyUser()
        } else {
            print("✅ 既存ユーザーを読み込み完了")
        }
    }
    
    /// 全データリセット（Firebase認証のみ）
    func resetAllData() {
        authViewModel.logout()
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        authViewModel.clearError()
    }
    
    // MARK: - Development Helper Methods
    
    #if DEBUG
    func createTestUser() {
        let testUser = DevelopmentHelper.createTestUser()
        authViewModel.login(with: testUser)
    }
    
    func clearAllData() {
        DevelopmentHelper.clearAllFirebaseUserData()
        authViewModel.logout()
    }
    #endif
}
