import Foundation
import SwiftUI
import Combine

class AppViewModel: ObservableObject {
    @Published var authViewModel: AuthenticationViewModel
    
    // 🔴 共有FirebaseUserManagerインスタンス
    @Published var firebaseUserManager = FirebaseUserManager()
    
    // 🆕 チュートリアル状態管理
    @Published var hasCompletedTutorial: Bool = UserDefaults.standard.bool(forKey: "hasCompletedTutorial")
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.authViewModel = AuthenticationViewModel()
        
        // 🔴 AuthenticationViewModelに共有インスタンスを設定
        self.authViewModel.setFirebaseUserManager(firebaseUserManager)
        
        setupUserObserver()
        
        // 🆕 チュートリアル状態の変更を監視
        setupTutorialObserver()
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
    
    // 🆕 チュートリアル状態の監視
    private func setupTutorialObserver() {
        $hasCompletedTutorial
            .sink { completed in
                print("🎓 Tutorial status changed: \(completed)")
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
    
    // 🆕 アプリの初期表示状態を判定
    var shouldShowOnboarding: Bool {
        return !isLoggedIn
    }
    
    var shouldShowTutorial: Bool {
        return isLoggedIn && !hasCompletedTutorial
    }
    
    var shouldShowMainApp: Bool {
        return isLoggedIn && hasCompletedTutorial
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
        // 🆕 ログアウト時はチュートリアルをリセットしない（ユーザー固有の情報として保持）
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
    
    // MARK: - 🆕 Tutorial Management Methods
    
    func markTutorialCompleted() {
        UserDefaults.standard.set(true, forKey: "hasCompletedTutorial")
        DispatchQueue.main.async {
            self.hasCompletedTutorial = true
        }
        print("✅ Tutorial marked as completed")
    }
    
    func resetTutorial() {
        UserDefaults.standard.set(false, forKey: "hasCompletedTutorial")
        DispatchQueue.main.async {
            self.hasCompletedTutorial = false
        }
        print("🔄 Tutorial reset")
    }
    
    func checkTutorialStatus() {
        let completed = UserDefaults.standard.bool(forKey: "hasCompletedTutorial")
        DispatchQueue.main.async {
            self.hasCompletedTutorial = completed
        }
        print("🔍 Tutorial status checked: \(completed)")
    }
    
    // MARK: - 🆕 Auto Login Methods
    
    func checkAutoLogin() {
        print("🔍 Checking auto login...")
        
        guard firebaseUserManager.hasValidSession() else {
            print("⚠️ No valid session found")
            return
        }
        
        firebaseUserManager.checkAutoLogin()
    }
    
    func hasValidSession() -> Bool {
        return firebaseUserManager.hasValidSession()
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        authViewModel.clearError()
    }
}
