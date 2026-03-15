//
//  ContentView.swift
//  MacFog
//
//  Created by Dennis Stewart Jr. on 4/3/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        if #available(macOS 11.0, *) {
            StorageVisualizationView()
                .background(.ultraThinMaterial)
                .glassEffectConditional()
                .shadow(color: .black.opacity(0.1), radius: 30, x: 0, y: 15)
        } else {
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.orange)
                
                Text("DiskOptimizer Pro requires macOS 11.0 or later")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text("Please upgrade your macOS version to use this application")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(40)
            .background(.regularMaterial)
            .glassEffectConditional()
            .shadow(color: .orange.opacity(0.3), radius: 20, x: 0, y: 10)
        }
    }
}

#Preview {
    ContentView()
}
wwr
