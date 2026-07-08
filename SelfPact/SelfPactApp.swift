//
//  SelfPactApp.swift
//  SelfPact
//
//  Created by Ayush Kumar Agarwal on 02/03/26.
//

import SwiftUI

@main
struct SelfPactApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                // The product currently ships with a deliberately light-only palette.
                // Keep SwiftUI presentations and native controls in the same appearance.
                .preferredColorScheme(.light)
        }
    }
}
