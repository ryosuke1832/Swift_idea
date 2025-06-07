import Foundation
import FirebaseFirestore
import Combine

// Firestore用のAvatarモデル（ローカルAvatar互換フィールド追加）
struct FirestoreAvatar: Codable, Identifiable {
    @DocumentID var documentID: String?
    var id: String
    
    // ローカルAvatar互換フィールド
    var name: String            // creator_nameと同じ値
    var isDefault: Bool         // デフォルトアバターかどうか
    var language: String        // 言語設定
    var theme: String          // テーマ設定
    var voiceTone: String      // 声のトーン
    var profileImg: String     // プロフィール画像（ローカル用、image_urlsが空の場合のフォールバック）
    var deepfakeReady: Bool    // status == "ready"と同じ
    
    // Firebase固有フィールド
    var recipient_name: String
    var creator_name: String
    var image_urls: [String]
    var audio_url: String
    var image_count: Int
    var audio_size_mb: String
    var storage_provider: String
    var status: String
    var created_at: Timestamp?
    var updated_at: Timestamp?
    var deepfake_video_urls: [String]
    
    // ローカルAvatarモデルに変換
    func toLocalAvatar() -> Avatar {
        return Avatar(
            id: abs(id.hashValue), // idをIntに変換（正の値にする）
            name: name,
            isDefault: isDefault,
            language: language,
            theme: theme,
            voiceTone: voiceTone,
            profileImg: image_urls.first ?? profileImg, // Firebase画像URLを優先、なければローカル画像
            deepfakeReady: deepfakeReady
        )
    }
}

// Firebase Avatarマネージャー
class FirebaseAvatarManager: ObservableObject {
    @Published var avatars: [Avatar] = []
    @Published var firestoreAvatars: [FirestoreAvatar] = []
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
                    
                    let firestoreAvatars = documents.compactMap { document -> FirestoreAvatar? in
                        do {
                            return try document.data(as: FirestoreAvatar.self)
                        } catch {
                            print("❌ Document parsing error: \(error)")
                            return nil
                        }
                    }
                    
                    self?.firestoreAvatars = firestoreAvatars
                    self?.avatars = firestoreAvatars.map { $0.toLocalAvatar() }
                    
                    print("✅ Firebaseから\(self?.avatars.count ?? 0)個のアバターを取得しました")
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

// MARK: - Extensions

extension FirestoreAvatar {
    var formattedCreatedAt: String {
        guard let timestamp = created_at else { return "Unknown" }
        let date = timestamp.dateValue()
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var hasImages: Bool {
        return !image_urls.isEmpty
    }
    
    var hasAudio: Bool {
        return !audio_url.isEmpty
    }
    
    // ローカルAvatarと同じdisplayDescription
    var displayDescription: String {
        return "\(language) / \(voiceTone)"
    }
}
