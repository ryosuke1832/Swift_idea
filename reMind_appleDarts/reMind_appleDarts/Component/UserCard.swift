//
//  UserCard.swift
//  reMind_appleDarts
//
//  Created by ryosuke on 2/6/2025.
//

import SwiftUI

struct UserCard: View {
    
    let welcomeText: String
    let descriptionText: String
    let profileImageURL: String
    
    init(welcomeText: String = "Welcome, User!",
         descriptionText: String = "Feel grounded with your loved one",
         profileImageURL: String = "") {
        self.welcomeText = welcomeText
        self.descriptionText = descriptionText
        self.profileImageURL = profileImageURL
    }
    
    var body: some View {
        HStack{
            AsyncImage(url: URL(string: profileImageURL.isEmpty ? defaultProfileImageURL : profileImageURL)) { image in
                 image
                     .resizable()
                     .aspectRatio(contentMode: .fill)
             } placeholder: {
                 ZStack {
                     Circle()
                         .fill(Color.gray.opacity(0.3))
                     
                     Image(systemName: "person.fill")
                         .font(.system(size: 40))
                         .foregroundColor(.gray)
                 }
             }
             .frame(width: 100, height: 100)
             .clipShape(Circle())
             .padding()
            VStack(alignment: .leading){
                Text(welcomeText)
                    .font(.title)
                Text(descriptionText)
                    .font(.caption)
                    .foregroundColor(Color.gray)
            }
            Spacer()
            
        }
    }
    private var defaultProfileImageURL: String {
        return "https://res.cloudinary.com/dvyjkf3xq/image/upload/v1749361609/initial_profile_zfoxw0.png"
    }
}

#Preview {
    VStack(spacing: 20) {
        // デフォルト画像URLのテスト
        UserCard(welcomeText: "Welcome User!",
                descriptionText: "Feel grounded with your loved one",
                profileImageURL: "")
        
        // Firebase URLのテスト
        UserCard(welcomeText: "Welcome Firebase User!",
                descriptionText: "Using Firebase profile image",
                profileImageURL: "https://res.cloudinary.com/dvyjkf3xq/image/upload/v1749361609/initial_profile_zfoxw0.png")
    }
}
