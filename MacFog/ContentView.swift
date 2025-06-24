//
//  ContentView.swift
//  MacFog
//
//  Created by Dennis Stewart Jr. on 4/3/25.
//

import SwiftUI
import CoreData
@_exported import struct StorageVisualizationView

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        if #available(macOS 11.0, *) {
            StorageVisualizationView()
        } else {
            Text("DiskOptimizer Pro requires macOS 11.0 or later")
                .padding()
        }
    }
}

#Preview {
    ContentView()
}
