import SwiftUI

struct MainView_ryosuke_ver: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var editingAvatar: Avatar?
    
    var body: some View {
        ZStack{
            // Background
            BackGroundView()
            
            NavigationView {
                VStack(spacing: 15){
                    // User card with dynamic data
                    UserCard(
                        welcomeText: "Welcome \(appViewModel.userDisplayName)!",
                        descriptionText: appViewModel.avatarCountDescription,
                        avatarImageName: appViewModel.userProfileImage
                    )
                    
                    // Add button and heading of List
                    HStack {
                        Text("Your support circle")
                            .font(.headline)
                        Spacer()
                        
                        HStack(spacing: 12) {
                            // Add avatar button - NavigationLink
                            NavigationLink(destination: CreateAvatarView().environmentObject(appViewModel)) {
                                Text("Add more +")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding()
                    
                    // List for supporter
                    ScrollView {
                        VStack(spacing: 12) {
                            if appViewModel.hasAvatars {
                                // Display actual user avatars
                                ForEach(Array(appViewModel.avatarManager.avatars.enumerated()), id: \.element.id) { index, avatar in
                                    EnhancedAvatarCard(
                                        avatar: avatar,
                                        onStartSession: {
                                            print("\(avatar.name) session started!")
                                        },
                                        onEdit: {
                                            editingAvatar = avatar
                                        },
                                        onDelete: {
                                            appViewModel.avatarManager.deleteAvatar(withId: avatar.id)
                                        }
                                    )
                                }
                                
                            } else {
                                // Empty state with call to action
                                EmptyAvatarStateView()
                            }
                        }
                    }
                    
                    Spacer()
                }
            }
        }
        .sheet(item: $editingAvatar) { avatar in
            EditAvatarView(avatar: avatar)
                .environmentObject(appViewModel)
        }
        .onAppear {
            // Initialize app when view appears
            appViewModel.initializeApp()
        }
    }
}

// MARK: - Empty State View
struct EmptyAvatarStateView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No Support Companions Yet")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primaryText)
                
                Text("Create your first avatar to begin your personalized support journey")
                    .font(.subheadline)
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            // Create Avatar CTA Button
            NavigationLink(destination: CreateAvatarView().environmentObject(appViewModel)) {
                Text("Create Your First Avatar")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.primaryGreen)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            
            // Demo Data Button (for development)
            Button(action: {
                appViewModel.createDemoData()
            }) {
                Text("Load Demo Avatars")
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 40)
    }
}

// Enhanced AvatarCard with edit and delete buttons
struct EnhancedAvatarCard: View {
    let avatar: Avatar
    let onStartSession: () -> Void
    let onEdit: (() -> Void)?
    let onDelete: (() -> Void)?
    
    @State private var showingDeleteAlert = false
    
    init(
        avatar: Avatar,
        onStartSession: @escaping () -> Void,
        onEdit: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil
    ) {
        self.avatar = avatar
        self.onStartSession = onStartSession
        self.onEdit = onEdit
        self.onDelete = onDelete
    }
    
    var body: some View {
        ZStack{
            // border rectangle
            Rectangle()
                .fill(Color.white)
                .opacity(0.1)
                .frame(width: 380, height: 120)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(avatar.isDefault ? Color.primaryGreen.opacity(0.6) : Color.gray, lineWidth: avatar.isDefault ? 2 : 1)
                        .opacity(avatar.isDefault ? 1.0 : 0.5)
                )
            
            HStack{
                // image
                Image(avatar.profileImg)
                    .resizable()
                    .frame(width: 100, height: 100)
                    .cornerRadius(100)
                    .overlay(
                        Circle()
                            .stroke(avatar.isDefault ? Color.primaryGreen.opacity(0.4) : Color.clear, lineWidth: 3)
                    )
                
                // text
                VStack(alignment: .leading, spacing: 4){
                    HStack{
                        Text(avatar.name)
                            .font(.headline)
                            .foregroundColor(.primaryText)
                        
                        if avatar.isDefault {
                            ZStack{
                                Rectangle()
                                    .foregroundColor(avatar.tagColor)
                                    .frame(width: 60, height: 30)
                                    .cornerRadius(10)
                                Text("default")
                                    .font(.caption)
                                    .foregroundColor(.black)
                            }
                        }
                    }
                    
                    Text(avatar.displayDescription)
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                    
                    Text(avatar.theme)
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                }
                
                Spacer()
                
                VStack(spacing: 6) {
                    // start session button
                    NavigationLink(destination: SessionView()) {
                        ZStack{
                            Rectangle()
                                .foregroundColor(Color.primaryGreen)
                                .frame(width: 90, height: 32)
                                .cornerRadius(8)
                            Text("start session")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.black)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    HStack(spacing: 4) {
                        // edit button
                        Button(action: {
                            onEdit?()
                        }) {
                            ZStack{
                                Rectangle()
                                    .foregroundColor(Color.blue.opacity(0.1))
                                    .frame(width: 42, height: 28)
                                    .cornerRadius(6)
                                Image(systemName: "pencil")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // delete button
                        Button(action: {
                            showingDeleteAlert = true
                        }) {
                            ZStack{
                                Rectangle()
                                    .foregroundColor(Color.red.opacity(0.1))
                                    .frame(width: 42, height: 28)
                                    .cornerRadius(6)
                                Image(systemName: "trash")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .alert("Delete Avatar", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                onDelete?()
            }
        } message: {
            Text("Are you sure you want to delete '\(avatar.name)'? This action cannot be undone.")
        }
    }
}

#Preview {
    MainView_ryosuke_ver()
        .environmentObject(AppViewModel())
}
