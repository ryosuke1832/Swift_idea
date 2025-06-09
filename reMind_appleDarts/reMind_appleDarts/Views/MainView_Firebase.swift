import SwiftUI

struct MainView_Firebase: View {
    @StateObject private var firebaseAvatarManager = FirebaseAvatarManager()
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var refreshTrigger = UUID()
    @State private var showingCreateView = false
    
    let previewUserId: String?
    
    @State private var displayName: String = "User"
    @State private var displayProfileImageURL: String = ""
    @State private var isLoadingUser: Bool = false
    @State private var currentUserId: String? // 🆕 現在のユーザーIDを保持
    
    init(previewUserId: String? = nil) {
        self.previewUserId = previewUserId
    }
    
    var body: some View {
        NavigationView {
            ZStack{
                BackGroundView()
                
                VStack(spacing: 15){
                    UserCard(
                        welcomeText: "Welcome \(displayName)!",
                        descriptionText: avatarCountDescription,
                        profileImageURL: displayProfileImageURL
                    )
                    
                    if isLoadingUser {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Loading user profile...")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.bottom, 10)
                    }
                    
                    Spacer()
                    
                    HStack {
                        Text("Your support circle")
                            .font(.headline)
                        Spacer()
                        
                        HStack(spacing: 12) {
                            NavigationLink(destination: RequestConsentView()
                                .environmentObject(appViewModel)
                                .onDisappear {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        refreshAvatars()
                                    }
                                }
                            ) {
                                Text("Add more +")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            
                            Button(action: {
                                refreshAvatars()
                            }) {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 0)
                    
                    if !firebaseAvatarManager.errorMessage.isEmpty {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                            Text(firebaseAvatarManager.errorMessage)
                                .font(.caption)
                                .foregroundColor(.orange)
                            Button("Dismiss") {
                                firebaseAvatarManager.clearError()
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                    
                    if firebaseAvatarManager.isLoading {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Loading avatars from Firebase...")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding()
                    }
                    
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(sortedAvatars, id: \.id) { avatar in
                                if avatar.status == "ready" {
                                    EnhancedAvatarCard(
                                        avatar: avatar,
                                    )
                                    .transition(.asymmetric(
                                        insertion: .opacity.combined(with: .slide),
                                        removal: .opacity.combined(with: .scale(scale: 0.8))
                                    ))
                                } else {
                                    PendingCard(avatarName: avatar.recipient_name)
                                        .transition(.asymmetric(
                                            insertion: .opacity.combined(with: .slide),
                                            removal: .opacity.combined(with: .scale(scale: 0.8))
                                        ))
                                }
                            }
                            if firebaseAvatarManager.avatars.isEmpty &&
                               !firebaseAvatarManager.isLoading {
                                EmptyAvatarStateView()
                                    .padding(.vertical, 40)
                            }
                        }
                    }
                    .id(refreshTrigger)
                    .refreshable {
                        refreshAvatars()
                    }
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            loadUserData()
            loadAvatars() // 🆕 ユーザーデータロード後にアバターを取得
        }
        .onReceive(firebaseAvatarManager.$avatars) { _ in
            refreshView()
        }
    }
    
    // 🆕 アバターを読み込む
    private func loadAvatars() {
        if let userId = getCurrentUserId() {
            firebaseAvatarManager.fetchAvatarsForUser(userId: userId)
        } else {
            print("⚠️ No user ID available for loading avatars")
        }
    }
    
    // 🆕 アバターをリフレッシュ
    private func refreshAvatars() {
        if let userId = getCurrentUserId() {
            firebaseAvatarManager.refresh(for: userId)
        } else {
            print("⚠️ No user ID available for refreshing avatars")
        }
    }
    
    // 🆕 現在のユーザーIDを取得
    private func getCurrentUserId() -> String? {
        if let previewUserId = previewUserId {
            return previewUserId
        } else if let userId = appViewModel.firebaseUserManager.currentUserId {
            return userId
        } else {
            return currentUserId
        }
    }
    
    private func loadUserData() {
        if let userId = previewUserId {
            loadPreviewUser(userId: userId)
        } else if let user = appViewModel.authViewModel.currentUser {
            displayName = user.name
            displayProfileImageURL = user.profileImageURL
            currentUserId = appViewModel.firebaseUserManager.currentUserId
            print("✅ Loaded user from appViewModel: \(user.name)")
            print("🔑 Current user ID: \(currentUserId ?? "nil")")
        } else {
            print("⚠️ No user found in appViewModel")
        }
    }
    
    private func loadPreviewUser(userId: String) {
        isLoadingUser = true
        currentUserId = userId // 🆕 プレビューユーザーIDを保存
        
        let firebaseUserManager = FirebaseUserManager()
        
        firebaseUserManager.getUserById(userId) { user in
            DispatchQueue.main.async {
                isLoadingUser = false
                
                if let user = user {
                    displayName = user.name
                    displayProfileImageURL = user.profileImageURL
                    
                    appViewModel.authViewModel.currentUser = user
                    appViewModel.authViewModel.isLoggedIn = true
                    
                    print("✅ Preview user loaded: \(user.name)")
                    print("🔑 Preview user ID: \(userId)")
                    
                    // プレビューユーザーのアバターを取得
                    self.loadAvatars()
                } else {
                    displayName = "Test User (\(userId.prefix(8)))"
                    displayProfileImageURL = "https://res.cloudinary.com/dvyjkf3xq/image/upload/v1749361609/initial_profile_zfoxw0.png"
                    print("⚠️ Failed to load user \(userId), using fallback")
                }
            }
        }
    }
    
    private var avatarCountDescription: String {
        let firebaseCount = firebaseAvatarManager.avatars.count
        
        if firebaseCount == 0 {
            return "No support companions yet"
        } else {
            return "You have \(firebaseCount) support companion\(firebaseCount == 1 ? "" : "s")"
        }
    }
    
    private var sortedAvatars: [Avatar] {
        return firebaseAvatarManager.avatars.sorted { first, second in
            if first.isDefault && !second.isDefault {
                return true
            } else if !first.isDefault && second.isDefault {
                return false
            } else {
                return first.name < second.name
            }
        }
    }
    
    private func refreshView() {
        withAnimation(.easeInOut(duration: 0.3)) {
            refreshTrigger = UUID()
        }
    }
}

#Preview("With Specific User") {
    MainView_Firebase(previewUserId: "BKkzo8JLqoCNQq4jo3yw")
        .environmentObject(AppViewModel())
}
