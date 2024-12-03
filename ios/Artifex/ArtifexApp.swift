//
//  ArtifexApp.swift
//  Artifex
//
//  Created by Jesus Alejandro on 11/30/24.
//

import SwiftUI

@main
struct ArtifexApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
