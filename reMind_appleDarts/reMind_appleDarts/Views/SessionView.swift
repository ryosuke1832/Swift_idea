import SwiftUI
import AVKit

struct TagView: View {
    let tags: [String]
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat
    let onRemove: (String) -> Void

    init(tags: [String],
         horizontalSpacing: CGFloat = 8,
         verticalSpacing: CGFloat = 8,
         onRemove: @escaping (String) -> Void) {
        self.tags = tags
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
        self.onRemove = onRemove
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: horizontalSpacing) {
                ForEach(tags, id: \.self) { tag in
                    tagView(for: tag)
                }
            }
            .padding(.horizontal, 8)
        }
        .frame(height: 50)
    }

    private func tagView(for text: String) -> some View {
        HStack(spacing: 4) {
            Text(text)
                .foregroundColor(Color(red: 100 / 255, green: 116 / 255, blue: 139 / 255))

            Button(action: {
                onRemove(text)
            }) {
                Image(systemName: "xmark")
                    .resizable()
                    .frame(width: 10, height: 10)
                    .foregroundColor(Color(red: 100 / 255, green: 116 / 255, blue: 139 / 255))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.white)
        .clipShape(Capsule())
    }
}

struct SessionView: View {
    @State private var currentStep: Int = 0
    @State private var recorded: Bool = false
    @State private var navigateToBreak = false
    @State private var isKeyboardMode: Bool = false
    @State private var inputText: String = ""
    @State private var tags: [String] = []

    private var progress: Float {
        switch currentStep {
        case 0: return 0.0
        case 1: return 0.2
        case 2: return 0.2
        case 3: return 0.4
        case 4: return 0.6
        case 5: return 0.8
        case 6: return 1.0
        default: return 1.0
        }
    }

    let prompts = [
        "Its OKAY, I Got U",
        "Now, What are 5 things you can SEE?",
        "Now, Tell me 4 things you can TOUCH?",
        "You are doing GREAT!!",
        "Now, Tell me 3 things you HEAR?",
        "Focus on 2 things you can SMELL?",
        "Now, Tell me 1 thing you can TASTE?"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                VideoView()
                    .ignoresSafeArea()

                LinearGradient(
                    gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.2)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack {
                    HStack(spacing: 6) {
                        ForEach(0..<5) { index in
                            Capsule()
                                .frame(height: 4)
                                .foregroundColor(Float(index) < progress * 5 ? .white : .white.opacity(0.3))
                        }
                    }
                    .padding(.top, 12)
                    .padding(.horizontal, 20)

                    Spacer()
                }
                .frame(maxHeight: .infinity, alignment: .top)

                VStack(spacing: 16) {
                    Spacer().frame(height: isKeyboardMode ? 400 : 500)

                    Text(prompts[currentStep])
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .frame(width: 346, height: 64)
                        .background(.black.opacity(0.4))
//                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        .multilineTextAlignment(.center)

                    if isKeyboardMode {
                        TextField("Type Here...", text: $inputText, onCommit: {
                            if !inputText.isEmpty && tags.count < 5 {
                                tags.insert(inputText, at: 0)
                                DispatchQueue.main.async {
                                            inputText = ""
                                        }
                            }
                        })
                        .padding()
                        .frame(width: 346, height: 64)
                        .background(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.5), lineWidth: 1))
                        .foregroundColor(.black)
                        
                    }

                    Spacer()
                }
                .frame(maxHeight: .infinity, alignment: .top)

                if isKeyboardMode {
                    VStack {
                        Spacer().frame(height: 570)

                        TagView(tags: tags, onRemove: { tag in
                            tags.removeAll { $0 == tag }
                        })
                        .frame(width: 346, height: 50)
                        .padding(.horizontal, 24)

                        Spacer()
                    }
                }

                VStack {
                    Spacer()

                    ZStack {
                        if isKeyboardMode {
                            Button(action: {}) {
                                Image(systemName: "keyboard")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 40, height: 40)
                                    .foregroundColor(Color(red: 220 / 255, green: 236 / 255, blue: 125 / 255))
                                    .padding(.horizontal, 40)
                                    .padding(.vertical, 26.66667)
                                    .frame(width: 100, height: 100)
                                    .background(Color.black.opacity(0.4))
//                                    .background(.ultraThinMaterial)
                                    .cornerRadius(100)
                            }
                        } else {
                            RecordButton(recorded: $recorded)
                        }

                        HStack {
                            Button(action: {
                                isKeyboardMode.toggle()
                                recorded = false
                                inputText = ""
                                tags.removeAll()
                            }) {
                                Image(systemName: isKeyboardMode ? "mic.fill" : "keyboard")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                                    .padding(15)
                                    .foregroundColor(.white.opacity(0.8))
                                    .background(Color.black.opacity(0.3))
                                    .clipShape(Circle())
                                    .padding(.leading, 20)
                            }

                            Spacer()

                            HStack(spacing: 30) {
                                Button(action: {
                                    recorded = false
                                    inputText = ""
                                    tags.removeAll()
                                }) {
                                    Image(systemName: "xmark")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 12, height: 12)
                                        .padding(10)
                                        .background(Color.black.opacity(0.3))
                                        .clipShape(Circle())
                                        .foregroundColor(.white)
                                }

                                Button(action: {
                                    if currentStep < prompts.count - 1 {
                                        currentStep += 1
                                        recorded = false
                                        inputText = ""
                                        tags.removeAll()
                                    } else {
                                        navigateToBreak = true
                                    }
                                }) {
                                    Image(systemName: "checkmark")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 12, height: 12)
                                        .foregroundColor(.black)
                                        .padding(8)
                                        .background(Color(red: 220 / 255, green: 236 / 255, blue: 125 / 255))
                                        .clipShape(Circle())
                                }
                            }
                        }
                        .padding(.horizontal, 30)
                    }
                    .padding(.bottom, 24)
                }
                

                NavigationLink(destination: Break(), isActive: $navigateToBreak) {
                    EmptyView()
                }
                
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct SessionView_Previews: PreviewProvider {
    static var previews: some View {
        SessionView()
    }
}
