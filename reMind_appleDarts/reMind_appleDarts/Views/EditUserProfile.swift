import SwiftUI
import FirebaseFirestore

struct EditUserView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var profileImage: String = "sample_avatar"
    
    private var isPreviewMode: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
    
    private let previewUserId = "BKkzo8JLqoCNQq4jo3yw"
    
    @State private var navigateToMain = false
    @State private var isUpdating = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
    private var db = Firestore.firestore()

    var body: some View {
        NavigationStack {
            ZStack {
                BackGroundView()

                VStack(spacing: 24) {
                    Spacer()

                    if isLoading {
                        ProgressView("Loading user data...")
                            .font(.title)
                            .bold()
                    } else {
                        Text(name)
                            .font(.title)
                            .bold()
                    }

                    Image(profileImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 16) {
                        LabeledEditableTextField(label: "Name", text: $name)
                        LabeledEditableTextField(label: "Email", text: $email)
                        LabeledEditableTextField(label: "Password", text: $password, isSecure: true)
                    }
                    .padding(.horizontal, 30)

                    Spacer()

                    Button(action: {
                        handleSave()
                    }) {
                        HStack {
                            if isUpdating {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.black)
                            }
                            Text(isUpdating ? "Saving..." : "Save")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.primaryGreen)
                        .foregroundColor(.black)
                        .cornerRadius(15)
                        .font(.headline)
                    }
                    .padding(.horizontal, 30)
                    .disabled(isUpdating || isLoading)

                    NavigationLink(destination: getDestinationView(), isActive: $navigateToMain) {
                        EmptyView()
                    }

                    Spacer(minLength: 10)
                }
            }
        }
        .onAppear {
            loadUserData()
        }
        .alert("Profile", isPresented: $showAlert) {
            Button("OK") {
                if alertMessage.contains("Success") {
                    navigateToMain = true
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Firebase
    
    private func loadUserData() {
        isLoading = true
        
        let documentId: String
        
        if isPreviewMode {
            documentId = previewUserId
            print("🔍 Preview mode: Loading user data for ID: \(documentId)")
        } else {
            guard let currentUser = appViewModel.authViewModel.currentUser else {
                print("❌ No current user found")
                isLoading = false
                return
            }
            documentId = "user_\(currentUser.id)"
            print("🔍 App mode: Loading user data for ID: \(documentId)")
        }
        
        db.collection("users").document(documentId).getDocument { [self] document, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    print("❌ Error loading user data: \(error)")
                    alertMessage = "fail"
                    showAlert = true
                    return
                }
                
                guard let document = document, document.exists else {
                    print("❌ User document not found: \(documentId)")
                    alertMessage = "fail"
                    showAlert = true
                    return
                }
                
                do {
                    let userData = try document.data(as: FirebaseUser.self)
                    print("✅ User data loaded: \(userData.name)")
                    
                    name = userData.name
                    email = userData.email
                    password = userData.password
                    profileImage = userData.profileImg
                    
                } catch {
                    print("❌ Error parsing user data: \(error)")
                    alertMessage = "fail"
                    showAlert = true
                }
            }
        }
    }
    
    private func handleSave() {
        let documentId: String
        
        if isPreviewMode {
            documentId = previewUserId
            print("🔍 Preview mode: Saving user data for ID: \(documentId)")
        } else {
            guard let currentUser = appViewModel.authViewModel.currentUser else {
                alertMessage = "can't find user data"
                showAlert = true
                return
            }
            documentId = "user_\(currentUser.id)"
            print("🔍 App mode: Saving user data for ID: \(documentId)")
        }
        
        isUpdating = true

        let updateData: [String: Any] = [
            "name": name.trimmingCharacters(in: .whitespacesAndNewlines),
            "email": email.trimmingCharacters(in: .whitespacesAndNewlines),
            "password": password,
            "profileImg": profileImage,
            "updated_at": Timestamp(date: Date())
        ]
        

        db.collection("users").document(documentId).updateData(updateData) { [self] error in
            DispatchQueue.main.async {
                isUpdating = false
                
                if let error = error {
                    print("❌ Profile update error: \(error)")
                    alertMessage = "Failed to update: \(error.localizedDescription)"
                    showAlert = true
                } else {
                    print("✅ Profile updated successfully for \(documentId)")
                    
                    if !isPreviewMode {
                        if var currentUser = appViewModel.authViewModel.currentUser {
                            currentUser.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
                            currentUser.email = email.trimmingCharacters(in: .whitespacesAndNewlines)
                            currentUser.password = password
                            currentUser.profileImg = profileImage
                            appViewModel.authViewModel.currentUser = currentUser
                        }
                    }
                    
                    alertMessage = "Modified correctly"
                    showAlert = true
                }
            }
        }
    }
    

    private func getDestinationView() -> some View {
        if isPreviewMode {
            return AnyView(
                VStack {
                    Text("Preview Mode")
                        .font(.title)
                    Text("Profile Updated Successfully")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding()
            )
        } else {
            return AnyView(MainTabView())
        }
    }
}


struct LabeledEditableTextField: View {
    let label: String
    @Binding var text: String
    var isSecure: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.gray)

            if isSecure {
                SecureField("", text: $text)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
            } else {
                TextField("", text: $text)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
            }
        }
    }
}


struct LabeledTextField: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.gray)

            TextField("", text: .constant(value))
                .disabled(true)
                .padding()
                .background(Color.white)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
        }
    }
}

#Preview {
    EditUserView()
        .environmentObject(AppViewModel())
}
