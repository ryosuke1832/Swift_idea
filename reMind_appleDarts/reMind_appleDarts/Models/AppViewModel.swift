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
        // 認証のみを管理
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
                // 必要に応じて他の処理を追加
                print("🔄 User changed: \(user?.name ?? "None")")
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
    
    // MARK: - Initialization Methods
    
    /// アプリ開始時にユーザーが存在することを確認
    func initializeApp() {
        if !authViewModel.hasUser {
            authViewModel.createDummyUser()
        }
    }
    
    /// 全データリセット（認証のみ）
    func resetAllData() {
        authViewModel.logout()
    }
}
