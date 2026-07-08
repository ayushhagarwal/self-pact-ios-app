//
//  ContentView.swift
//  SelfPact
//
//  Created by Ayush Kumar Agarwal on 02/03/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var pactStore = PactStore()
    @StateObject private var storeKitManager = StoreKitManager()
    @State private var selectedTab: Tab = .today
    @State private var showSettings = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showOnboarding = false
    
    enum Tab {
        case today
        case goals
    }
    
    var body: some View {
        ZStack {
            // Main app content
            TabView(selection: $selectedTab) {
                NavigationStack {
                    HomeView()
                        .toolbar {
                            profileToolbarButton
                        }
                }
                .tabItem {
                    Label("Today", systemImage: "checkmark.circle.fill")
                }
                .tag(Tab.today)
                
                NavigationStack {
                    GoalsView()
                        .toolbar {
                            profileToolbarButton
                        }
                }
                .tabItem {
                    Label("Goals", systemImage: "list.bullet.rectangle")
                }
                .tag(Tab.goals)
            }
            .tint(AppColors.accent)
            .environmentObject(pactStore)
            .environmentObject(storeKitManager)
            .sheet(isPresented: $showSettings) {
                NavigationStack {
                    SettingsView()
                }
                .environmentObject(pactStore)
                .environmentObject(storeKitManager)
            }
            .onAppear {
                setupTabBarAppearance()
                
                // Show onboarding if not completed
                if !hasCompletedOnboarding {
                    showOnboarding = true
                }
            }
            .task {
                storeKitManager.configure(with: pactStore)
                await storeKitManager.prepareStore()
            }
            
            // Onboarding overlay
            if showOnboarding {
                OnboardingView(isPresented: $showOnboarding)
                    .environmentObject(pactStore)
                    .environmentObject(storeKitManager)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .onChange(of: showOnboarding) { _, newValue in
            if !newValue {
                hasCompletedOnboarding = true
            }
        }
        .background(KeyboardDismissalLayer())
    }

    private var profileToolbarButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            ToolbarSymbolButton(
                systemName: "person.crop.circle",
                accessibilityLabel: "Open settings"
            ) {
                showSettings = true
            }
        }
    }
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(AppColors.background)
        appearance.shadowColor = UIColor(AppColors.border)
        
        // Unselected color
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(AppColors.textSecondary)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(AppColors.textSecondary),
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold)
        ]
        
        // Selected color
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(AppColors.accent)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(AppColors.accent),
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold)
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

#Preview {
    ContentView()
}
