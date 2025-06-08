//
//  AuthenticationViewModel.swift
//  reMind_appleDarts
//
//  Created by user on 2025/06/03.
//
//
import Foundation
import Combine

class AuthenticationViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoggedIn: Bool = false
    @Published var isLoading: Bool = false
    
    private var firebaseUserManager = FirebaseUserManager()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupUserObserver()
        loadStoredUser()
    }
    
    private func setupUserObserver() {
        firebaseUserManager.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.currentUser = user
                self?.isLoggedIn = user != nil
            }
            .store(in: &cancellables)
        
        firebaseUserManager.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                self?.isLoading = loading
            }
            .store(in: &cancellables)
    }
    
    // MARK: - User Authentication
    
    func login(with user: User) {
        firebaseUserManager.saveUser(user)
    }
    
    func logout() {
        firebaseUserManager.clearUser()
        self.currentUser = nil
        self.isLoggedIn = false
    }
    
    func createDummyUser() {
        let dummyUser = firebaseUserManager.createDummyUser()
        self.currentUser = dummyUser
        self.isLoggedIn = true
    }
    
    private func loadStoredUser() {
        if let storedUser = firebaseUserManager.loadUser() {
            self.currentUser = storedUser
            self.isLoggedIn = true
        }
    }
    
    // MARK: - User Profile Management
    
    // 🆕 Firebase URL専用のプロフィール更新メソッド
    func updateUserProfile(name: String? = nil, email: String? = nil, profileImageURL: String? = nil, password: String? = nil) {
        guard var user = currentUser else { return }
        
        if let name = name {
            user.name = name
        }
        if let email = email {
            user.email = email
        }
        if let profileImageURL = profileImageURL {
            user.profileImageURL = profileImageURL  // 🆕 Firebase URLのみ
        }
        if let password = password {
            user.password = password
        }
        
        firebaseUserManager.updateUser(user)
    }
    
    // MARK: - User Data Access
    
    var userDisplayName: String {
        return currentUser?.displayName ?? "User"
    }
    
    // 🆕 Firebase画像URLを返す
    var userProfileImageURL: String {
        return currentUser?.displayProfileImageURL ?? ""
    }
    
    var userEmail: String {
        return currentUser?.email ?? ""
    }
    
    var hasUser: Bool {
        return currentUser != nil
    }
    
    // 🆕 有効なプロフィール画像があるかどうか
    var hasValidProfileImage: Bool {
        return currentUser?.hasValidProfileImage ?? false
    }
    
    // MARK: - Error Handling
    
    var errorMessage: String {
        return firebaseUserManager.errorMessage
    }
    
    func clearError() {
        firebaseUserManager.clearError()
    }
}
