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
    @State private var selectedTab: Tab = .pacts
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showOnboarding = false
    @State private var navigateToCreatePact = false
    
    enum Tab {
        case pacts
        case settings
    }
    
    var body: some View {
        ZStack {
            // Main app content
            TabView(selection: $selectedTab) {
                // Pacts Tab
                NavigationStack {
                    HomeView()
                        .navigationDestination(isPresented: $navigateToCreatePact) {
                            CreatePactView()
                        }
                }
                .tabItem {
                    Label("Pacts", systemImage: "shield.fill")
                }
                .tag(Tab.pacts)
                
                // Settings Tab
                NavigationStack {
                    SettingsView()
                }
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(Tab.settings)
            }
            .tint(AppColors.gold)
            .environmentObject(pactStore)
            .environmentObject(storeKitManager)
            .preferredColorScheme(.dark)
            .onAppear {
                setupTabBarAppearance()
                
                // Show onboarding if not completed
                if !hasCompletedOnboarding {
                    showOnboarding = true
                }
            }
            .task {
                // Configure StoreKit with PactStore
                storeKitManager.configure(with: pactStore)
                // Check for pending transactions on app launch
                await storeKitManager.checkPendingTransactions()
            }
            
            // Onboarding overlay
            if showOnboarding {
                OnboardingView(isPresented: $showOnboarding)
                    .environmentObject(pactStore)
                    .environmentObject(storeKitManager)
                    .transition(.opacity)
                    .zIndex(1)
                    .onChange(of: showOnboarding) { _, newValue in
                        if !newValue {
                            // Mark onboarding as completed
                            hasCompletedOnboarding = true
                            
                            // Navigate to CreatePactView after short delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                navigateToCreatePact = true
                            }
                        }
                    }
            }
        }
    }
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(AppColors.backgroundElevated)
        
        // Unselected color
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(AppColors.textMuted)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(AppColors.textMuted),
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold)
        ]
        
        // Selected color
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(AppColors.gold)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(AppColors.gold),
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold)
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

#Preview {
    ContentView()
}
