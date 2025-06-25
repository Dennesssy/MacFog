//: # Liquid Glass UI Demo
//: SwiftUI playground with glass-like material effects

import SwiftUI
import PlaygroundSupport

struct ContentView: View {
    @State private var isExpanded = false
    @State private var hoverButton = false
    
    var body: some View {
        VStack(spacing: 30) {
            // Title with glass effect
            Text("Hello, Liquid Glass!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
                .background(.regularMaterial)
                .clipShape(Capsule())
            
            // Interactive cards
            HStack(spacing: 20) {
                // Card 1 - Expandable
                VStack {
                    Image(systemName: "sparkles")
                        .font(.system(size: 30))
                        .foregroundColor(.blue)
                    Text("Tap Me")
                        .font(.headline)
                    
                    if isExpanded {
                        Text("Expanded!")
                            .font(.caption)
                            .transition(.scale)
                    }
                }
                .padding()
                .frame(width: isExpanded ? 150 : 100, height: 100)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .onTapGesture {
                    withAnimation(.spring()) {
                        isExpanded.toggle()
                    }
                }
                
                // Card 2 - Static
                VStack {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 30))
                        .foregroundColor(.purple)
                    Text("Glass")
                        .font(.headline)
                }
                .padding()
                .frame(width: 100, height: 100)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            
            // Interactive button
            Button("Animate") {
                withAnimation(.bouncy) {
                    isExpanded.toggle()
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .scaleEffect(hoverButton ? 1.1 : 1.0)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    hoverButton = hovering
                }
            }
        }
        .padding(40)
        .frame(width: 400, height: 500)
        .background(
            LinearGradient(
                colors: [.blue.opacity(0.3), .purple.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

// Present the view
PlaygroundPage.current.setLiveView(ContentView())