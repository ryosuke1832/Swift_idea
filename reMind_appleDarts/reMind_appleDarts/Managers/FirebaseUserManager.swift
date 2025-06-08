//
//  FirebaseUserManager.swift
//  reMind_appleDarts
//
//  Created by user on 2025/06/10.
//
import Foundation
import FirebaseFirestore
import Combine

class FirebaseUserManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    
    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private let userCollectionPath = "users"
    
    init() {
        loadStoredUser()
    }
    
    deinit {
        listener?.remove()
    }
    
    // MARK: - User Authentication & Management
    
    func saveUser(_ user: User) {
        isLoading = true
        errorMessage = ""
        
        let firebaseUser = FirebaseUser.fromLocalUser(user)
        
        do {
            try db.collection(userCollectionPath)
                .document(firebaseUser.id)
                .setData(from: firebaseUser) { [weak self] error in
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        
                        if let error = error {
                            self?.errorMessage = "ユーザー保存に失敗: \(error.localizedDescription)"
                            print("❌ Firebase user save error: \(error)")
                        } else {
                            print("✅ User saved to Firebase: \(firebaseUser.id)")
                            self?.currentUser = user
                            self?.saveUserIdToUserDefaults(firebaseUser.id)
                        }
                    }
                }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "ユーザーデータの変換に失敗: \(error.localizedDescription)"
            }
        }
    }
    
    func loadUser() -> User? {
        guard let userId = getUserIdFromUserDefaults() else {
            print("ℹ️ No user ID found in UserDefaults")
            return nil
        }
        
        loadUserFromFirebase(userId: userId)
        return currentUser
    }
    
    private func loadUserFromFirebase(userId: String) {
        isLoading = true
        
        listener?.remove()
        listener = db.collection(userCollectionPath)
            .document(userId)
            .addSnapshotListener { [weak self] documentSnapshot, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        self?.errorMessage = "ユーザー読み込みに失敗: \(error.localizedDescription)"
                        print("❌ Firebase user load error: \(error)")
                        return
                    }
                    
                    guard let document = documentSnapshot,
                          document.exists else {
                        print("⚠️ User document not found: \(userId)")
                        self?.clearUser()
                        return
                    }
                    
                    do {
                        let firebaseUser = try document.data(as: FirebaseUser.self)
                        self?.currentUser = firebaseUser.toLocalUser()
                        print("✅ User loaded from Firebase: \(firebaseUser.name)")
                        print("🖼️ Profile image URL: \(firebaseUser.profileImageURL)")
                    } catch {
                        self?.errorMessage = "ユーザーデータの解析に失敗: \(error.localizedDescription)"
                        print("❌ User parsing error: \(error)")
                    }
                }
            }
    }
    
    private func loadStoredUser() {
        if let user = loadUser() {
            print("✅ Stored user loaded: \(user.name)")
        }
    }
    
    func clearUser() {
        listener?.remove()
        currentUser = nil
        clearUserIdFromUserDefaults()
        print("🗑️ User data cleared")
    }
    
    // 🆕 Firebase URL専用のupdateUserメソッド
    func updateUser(_ updatedUser: User) {
        guard let currentUserId = getUserIdFromUserDefaults() else {
            errorMessage = "ユーザーIDが見つかりません"
            return
        }
        
        isLoading = true
        
        let updateData: [String: Any] = [
            "name": updatedUser.name,
            "email": updatedUser.email,
            "profileImageURL": updatedUser.profileImageURL,  // 🆕 Firebase URLのみ
            "updated_at": Timestamp(date: Date())
        ]
        
        db.collection(userCollectionPath)
            .document(currentUserId)
            .updateData(updateData) { [weak self] error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        self?.errorMessage = "ユーザー更新に失敗: \(error.localizedDescription)"
                        print("❌ Firebase user update error: \(error)")
                    } else {
                        print("✅ User updated in Firebase")
                        print("🖼️ New profile image URL: \(updatedUser.profileImageURL)")
                        self?.currentUser = updatedUser
                    }
                }
            }
    }
    
    // MARK: - UserDefaults Helper (Firebase ID管理用)
    
    private func saveUserIdToUserDefaults(_ userId: String) {
        UserDefaults.standard.set(userId, forKey: "firebase_user_id")
    }
    
    private func getUserIdFromUserDefaults() -> String? {
        return UserDefaults.standard.string(forKey: "firebase_user_id")
    }
    
    private func clearUserIdFromUserDefaults() {
        UserDefaults.standard.removeObject(forKey: "firebase_user_id")
    }
    
    // MARK: - Helper Methods
    
    // 🆕 Firebase URL対応のダミーユーザー作成
    func createDummyUser() -> User {
        let dummyUser = User(
            id: Int.random(in: 1000...9999),
            name: "User",
            email: "user@example.com",
            password: "",
            profileImageURL: "https://picsum.photos/150/150?random=\(Int.random(in: 1...100))",  // 🆕 ランダムな画像URL
            avatars: []
        )
        saveUser(dummyUser)
        return dummyUser
    }
    
    func getUserById(_ userId: String, completion: @escaping (User?) -> Void) {
        db.collection(userCollectionPath)
            .document(userId)
            .getDocument { documentSnapshot, error in
                if let error = error {
                    print("❌ Get user by ID error: \(error)")
                    completion(nil)
                    return
                }
                
                guard let document = documentSnapshot,
                      document.exists else {
                    completion(nil)
                    return
                }
                
                do {
                    let firebaseUser = try document.data(as: FirebaseUser.self)
                    completion(firebaseUser.toLocalUser())
                } catch {
                    print("❌ User parsing error: \(error)")
                    completion(nil)
                }
            }
    }
    
    func clearError() {
        errorMessage = ""
    }
}
