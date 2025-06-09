import Foundation
import FirebaseFirestore
import Combine

class FirebaseAvatarManager: ObservableObject {
    @Published var avatars: [Avatar] = []
    @Published var firestoreAvatars: [Avatar] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    
    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    init() {
        // 初期化時は何もしない
    }
    
    deinit {
        listener?.remove()
    }
    
    // 🆕 ユーザーIDを指定してそのユーザーのアバターを取得
    func fetchAvatarsForUser(userId: String) {
        print("🔍 Fetching avatars for user: \(userId)")
        
        isLoading = true
        errorMessage = ""
        
        // まずユーザードキュメントからavatar_idsを取得
        db.collection("users")
            .document(userId)
            .getDocument { [weak self] documentSnapshot, error in
                if let error = error {
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        self?.errorMessage = "ユーザー情報の取得に失敗: \(error.localizedDescription)"
                        print("❌ Error fetching user: \(error)")
                    }
                    return
                }
                
                guard let document = documentSnapshot,
                      document.exists,
                      let data = document.data() else {
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        self?.avatars = []
                        self?.firestoreAvatars = []
                        print("⚠️ User document not found or no data")
                    }
                    return
                }
                
                // avatar_idsを取得
                let avatarIds = data["avatar_ids"] as? [String] ?? []
                print("✅ Found avatar_ids: \(avatarIds)")
                
                if avatarIds.isEmpty {
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        self?.avatars = []
                        self?.firestoreAvatars = []
                        print("⚠️ No avatar IDs found for user")
                    }
                    return
                }
                
                // アバターIDを使ってアバターデータを取得
                self?.fetchAvatarsByIds(avatarIds)
            }
    }
    
    // アバターIDの配列からアバターデータを取得
    private func fetchAvatarsByIds(_ avatarIds: [String]) {
        print("🔍 Fetching avatars by IDs: \(avatarIds)")
        
        guard !avatarIds.isEmpty else {
            DispatchQueue.main.async {
                self.isLoading = false
                self.avatars = []
                self.firestoreAvatars = []
            }
            return
        }
        
        // Firestoreの'in'クエリを使用（最大10個まで）
        let chunks = avatarIds.chunked(into: 10)
        var allAvatars: [Avatar] = []
        let group = DispatchGroup()
        
        for chunk in chunks {
            group.enter()
            
            db.collection("avatars")
                .whereField("id", in: chunk)
                .getDocuments { [weak self] querySnapshot, error in
                    defer { group.leave() }
                    
                    if let error = error {
                        print("❌ Firebase fetch error: \(error)")
                        DispatchQueue.main.async {
                            self?.errorMessage = "アバターデータの取得に失敗: \(error.localizedDescription)"
                        }
                        return
                    }
                    
                    guard let documents = querySnapshot?.documents else {
                        print("⚠️ No documents found for chunk: \(chunk)")
                        return
                    }
                    
                    let avatars = documents.compactMap { document -> Avatar? in
                        do {
                            return try document.data(as: Avatar.self)
                        } catch {
                            print("❌ Document parsing error: \(error)")
                            return nil
                        }
                    }
                    
                    allAvatars.append(contentsOf: avatars)
                    print("✅ Fetched \(avatars.count) avatars from chunk")
                }
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.isLoading = false
            
            // IDの順序を保持してソート
            let sortedAvatars = avatarIds.compactMap { id in
                allAvatars.first { $0.id == id }
            }
            
            self?.firestoreAvatars = sortedAvatars
            self?.avatars = sortedAvatars
            
            print("✅ Total avatars loaded: \(sortedAvatars.count)")
            print("✅ Avatar names: \(sortedAvatars.map { $0.name })")
        }
    }
    
    // リフレッシュ用（userIdを外部から渡す必要がある）
    func refresh(for userId: String) {
        fetchAvatarsForUser(userId: userId)
    }
    
    func clearError() {
        errorMessage = ""
    }
    
    func clearAvatars() {
        listener?.remove()
        avatars = []
        firestoreAvatars = []
        print("🗑️ Avatars cleared")
    }
}

// 配列を指定サイズに分割するヘルパー
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
