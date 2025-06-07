import SwiftUI

struct EnhancedAvatarCard: View {
    let firestoreAvatar: FirestoreAvatar // Firebase データのみ使用
    let onStartSession: () -> Void
    let onEdit: (() -> Void)?
    
    @State private var showingEditView = false
    
    init(
        firestoreAvatar: FirestoreAvatar,
        onStartSession: @escaping () -> Void,
        onEdit: (() -> Void)? = nil,
    ) {
        self.firestoreAvatar = firestoreAvatar
        self.onStartSession = onStartSession
        self.onEdit = onEdit
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.white.opacity(0.5)) // Background
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.black.opacity(0.3), lineWidth: 0.5) // Stroke
            )
            .frame(width: 380, height: 120)
            .overlay(
                HStack(spacing: 20) { // Increased spacing between image and text
                    // Avatar image - Firebaseの画像URLを使用
                    if let imageUrl = firestoreAvatar.image_urls.first, !imageUrl.isEmpty {
                        AsyncImage(url: URL(string: imageUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Image("sample_avatar")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        }
                        .frame(width: 68, height: 72)
                        .clipShape(Circle())
                    } else {
                        Image("sample_avatar")
                            .resizable()
                            .frame(width: 68, height: 72)
                            .clipShape(Circle())
                    }
                    
                    // Text content
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(firestoreAvatar.name)
                                .font(.system(size: 20, weight: .semibold)) // Apple standard size
                                .foregroundColor(.primaryText)
                            if firestoreAvatar.isDefault {
                                Text("Default")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color(red: 52/255, green: 211/255, blue: 153/255).opacity(0.8))
                                    .cornerRadius(150)
                            }
                        }
                        
                        // 元のローカルアバターと同じdisplayDescription形式
                        Text(firestoreAvatar.displayDescription)
                            .font(.system(size: 13)) // Apple standard for subtext
                            .foregroundColor(Color(red: 0.39, green: 0.45, blue: 0.55))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    VStack {
                        Button(action: {
                            if let onEdit = onEdit {
                                onEdit()
                            } else {
                                showingEditView = true
                            }
                        }) {
                            Label("Edit", systemImage: "pencil")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(PlainButtonStyle())

                        Spacer()
                    }
                    .frame(maxHeight: .infinity)

                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            )
            .sheet(isPresented: $showingEditView) {
                EditAvatarView(firestoreAvatar: firestoreAvatar)
                    .environmentObject(AppViewModel()) // 
            }
    }
    
}

struct EnhancedAvatarCard_Previews: PreviewProvider {
    static var previews: some View {
        // Firebase データのサンプル（すべてのフィールドを含む）
        let sampleFirestoreAvatar = FirestoreAvatar(
            id: "avatar_12345",
            // ローカルAvatar互換フィールド
            name: "Bob",
            isDefault: true,
            language: "English",
            theme: "Calm",
            voiceTone: "Ghibli",
            profileImg: "sample_avatar",
            deepfakeReady: true,
            // Firebase固有フィールド
            recipient_name: "Alice",
            creator_name: "Bob",
            image_urls: ["https://example.com/avatar.jpg"],
            audio_url: "https://example.com/audio.mp3",
            image_count: 3,
            audio_size_mb: "2.5",
            storage_provider: "cloudinary",
            status: "ready",
            created_at: nil,
            updated_at: nil,
            deepfake_video_urls: []
        )
        
        EnhancedAvatarCard(
            firestoreAvatar: sampleFirestoreAvatar,
            onStartSession: { print("Start session tapped") },
            onEdit: { print("Edit tapped") },
        )
        .previewLayout(.sizeThatFits)
        .padding()
        .background(Color.white)
    }
}
