import Foundation
import FirebaseFirestore
import Combine

// FirestoreAvatar → Avatar に型名変更するだけ
class FirebaseAvatarManager: ObservableObject {
    @Published var avatars: [Avatar] = []  // ✅ FirestoreAvatar → Avatar
    @Published var firestoreAvatars: [Avatar] = []  // ✅ 同じく変更
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    
    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    init() {
        fetchAvatars()
    }
    
    deinit {
        listener?.remove()
    }
    
    // Firebaseからアバターを取得
    func fetchAvatars() {
        isLoading = true
        errorMessage = ""
        
        listener?.remove() // 既存のリスナーを削除
        
        listener = db.collection("avatars")
            .order(by: "created_at", descending: true)
            .limit(to: 50)
            .addSnapshotListener { [weak self] querySnapshot, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        self?.errorMessage = "データの取得に失敗しました: \(error.localizedDescription)"
                        print("❌ Firebase fetch error: \(error)")
                        return
                    }
                    
                    guard let documents = querySnapshot?.documents else {
                        self?.errorMessage = "データが見つかりませんでした"
                        return
                    }
                    
                    let avatars = documents.compactMap { document -> Avatar? in  // ✅ Avatar型
                        do {
                            return try document.data(as: Avatar.self)  // ✅ Avatar型
                        } catch {
                            print("❌ Document parsing error: \(error)")
                            return nil
                        }
                    }
                    
                    self?.firestoreAvatars = avatars
                    self?.avatars = avatars  // ✅ 変換不要！同じ型
                    
                    print("✅ Firebaseから\(self?.avatars.count ?? 0)個のアバターを取得しました")
                }
            }
    }
    
    // 他のメソッドもAvatar型に変更
    func saveAvatar(_ avatar: Avatar) {
        var avatarToSave = avatar
        if avatarToSave.created_at == nil {
            avatarToSave.created_at = Timestamp(date: Date())
        }
        avatarToSave.updated_at = Timestamp(date: Date())
        
        do {
            if let documentID = avatar.documentID {
                try db.collection("avatars").document(documentID).setData(from: avatarToSave)
            } else {
                try db.collection("avatars").addDocument(from: avatarToSave)
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "保存に失敗しました: \(error.localizedDescription)"
            }
        }
    }
    
    func deleteAvatar(_ avatar: Avatar) {  // ✅ Avatar型
        guard let documentID = avatar.documentID else {
            errorMessage = "削除対象のアバターが見つかりません"
            return
        }
        
        db.collection("avatars").document(documentID).delete { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "削除に失敗しました: \(error.localizedDescription)"
                } else {
                    print("✅ アバター削除完了")
                }
            }
        }
    }
    
    // リフレッシュ
    func refresh() {
        fetchAvatars()
    }
    
    // エラーをクリア
    func clearError() {
        errorMessage = ""
    }
}
