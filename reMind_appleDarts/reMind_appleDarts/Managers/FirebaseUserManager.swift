//
//  FirebaseUserManager.swift
//  reMind_appleDarts
//
//  Created by user on 2025/06/10.
//

import Foundation
import FirebaseFirestore
import Combine


struct FirebaseUser: Codable, Identifiable {
    @DocumentID var documentID: String?
    var id: String
    var name: String
    var email: String
    var password: String
    var profileImg: String
    var created_at: Timestamp?
    var updated_at: Timestamp?
    
    // ローカルUserモデルに変換
    func toLocalUser() -> User {
        return User(
            id: abs(id.hashValue), // idをIntに変換
            name: name,
            email: email,
            password: password, // 開発用: パスワードも保存
            profileImg: profileImg,
            avatars: [] // アバターは別途管理
        )
    }
    
    // ローカルUserから作成
    static func fromLocalUser(_ user: User) -> FirebaseUser {
        return FirebaseUser(
            id: "user_\(user.id)",
            name: user.name,
            email: user.email,
            password: user.password, // 開発用: パスワードも保存
            profileImg: user.profileImg,
            created_at: Timestamp(date: Date()),
            updated_at: Timestamp(date: Date())
        )
    }
}

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
    
    func updateUser(_ updatedUser: User) {
        guard let currentUserId = getUserIdFromUserDefaults() else {
            errorMessage = "ユーザーIDが見つかりません"
            return
        }
        
        isLoading = true
        
        let updateData: [String: Any] = [
            "name": updatedUser.name,
            "email": updatedUser.email,
            "profileImg": updatedUser.profileImg,
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
    
    // MARK: - Single Default Avatar Enforcement
    
    private func enforceSingleDefaultAvatar(_ user: User) -> User {
        // アバター管理は別のFirebaseAvatarManagerで行うため、
        // ここでは基本的なユーザー情報のみ管理
        return user
    }
    
    // MARK: - Helper Methods
    
    func createDummyUser() -> User {
        let dummyUser = User(
            id: Int.random(in: 1000...9999),
            name: "User",
            email: "user@example.com",
            password: "",
            profileImg: "sample_avatar",
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
