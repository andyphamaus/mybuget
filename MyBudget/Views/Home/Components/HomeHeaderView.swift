import SwiftUI

struct HomeHeaderView: View {
    let user: LocalUser?
    let selectedTab: Int
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:
            return "Good Morning"
        default:
            return "Good Afternoon"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Home")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(greeting)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
}

struct HomeTabSelector: View {
    @Binding var selectedTab: Int
    
    private let tabs = ["Dashboard", "Activity"]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    selectedTab = index
                }) {
                    Text(tabs[index])
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(selectedTab == index ? .white : .white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            selectedTab == index ? 
                            Color.white.opacity(0.2) : 
                            Color.clear
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(Color.clear)
        .cornerRadius(10)
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
}