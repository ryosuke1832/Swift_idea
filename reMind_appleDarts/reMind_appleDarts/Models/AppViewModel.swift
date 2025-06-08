import Foundation
import SwiftUI
import Combine

class AppViewModel: ObservableObject {
    @Published var authViewModel: AuthenticationViewModel
    
    // 🔴 共有FirebaseUserManagerインスタンス
    @Published var firebaseUserManager = FirebaseUserManager()
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.authViewModel = AuthenticationViewModel()
        
        // 🔴 AuthenticationViewModelに共有インスタンスを設定
        self.authViewModel.setFirebaseUserManager(firebaseUserManager)
        
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
            profileImageURL: "",
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
            profileImageURL: "",
            avatars: []
        )
        authViewModel.login(with: user)
    }
    
    func logout() {
        authViewModel.logout()
    }
    
    func updateProfile(name: String? = nil, email: String? = nil, profileImageURL: String? = nil, password: String? = nil) {
        authViewModel.updateUserProfile(
            name: name,
            email: email,
            profileImageURL: profileImageURL,
            password: password
        )
    }
    
    func updateProfileImageURL(_ url: String) {
        authViewModel.updateUserProfile(profileImageURL: url)
    }
    
    // 🔴 共有FirebaseUserManagerへの直接アクセスメソッド
    func loadAndSetCurrentUser(userId: String, completion: @escaping (User?) -> Void) {
        firebaseUserManager.loadAndSetCurrentUser(userId: userId) { [weak self] user in
            DispatchQueue.main.async {
                if let user = user {
                    self?.authViewModel.currentUser = user
                    self?.authViewModel.isLoggedIn = true
                }
                completion(user)
            }
        }
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        authViewModel.clearError()
    }
}
