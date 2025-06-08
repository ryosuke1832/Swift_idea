//
//  Untitled.swift
//  reMind_appleDarts
//
//  Created by user on 2025/06/03.
//
import Foundation
import SwiftUI
import Combine

/// Firebase専用のアプリケーションビューモデル
class AppViewModel: ObservableObject {
    @Published var authViewModel: AuthenticationViewModel
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.authViewModel = AuthenticationViewModel()
        setupUserObserver()
    }
    
    // MARK: - Setup
    
    private func setupUserObserver() {
        authViewModel.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                print("🔄 User changed: \(user?.name ?? "None")")
            }
            .store(in: &cancellables)
        
        authViewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { loading in
                print("🔄 Auth loading: \(loading)")
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Convenience Properties
    
    var userDisplayName: String {
        return authViewModel.userDisplayName
    }
    
    // 🆕 Firebase画像URLを返す
    var userProfileImageURL: String {
        return authViewModel.userProfileImageURL
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
        let user = User(
            id: Int.random(in: 1000...9999),
            name: "User",
            email: email,
            password: password,
            profileImageURL: "",  // 🆕 空文字で初期化
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
            profileImageURL: "",  // 🆕 空文字で初期化
            avatars: []
        )
        authViewModel.login(with: user)
    }
    
    func logout() {
        authViewModel.logout()
    }
    
    // 🆕 プロフィール更新メソッド（Firebase URLのみ）
    func updateProfile(name: String? = nil, email: String? = nil, profileImageURL: String? = nil, password: String? = nil) {
        authViewModel.updateUserProfile(
            name: name,
            email: email,
            profileImageURL: profileImageURL,
            password: password
        )
    }
    
    // 🆕 プロフィール画像URLのみを更新する便利メソッド
    func updateProfileImageURL(_ url: String) {
        authViewModel.updateUserProfile(profileImageURL: url)
    }
    
    // MARK: - Initialization Methods
    
    func initializeApp() {
        if !authViewModel.hasUser {
            print("ℹ️ ユーザーが見つかりません - 新規ユーザーを作成")
            authViewModel.createDummyUser()
        } else {
            print("✅ 既存ユーザーを読み込み完了")
        }
    }
    
    func resetAllData() {
        authViewModel.logout()
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        authViewModel.clearError()
    }
    
}
