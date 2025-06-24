//
//  MacFogApp.swift
//  MacFog
//
//  Created by Dennis Stewart Jr. on 4/3/25.
//

import SwiftUI

@main
struct MacFogApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
