//
//  ContentView.swift
//  Cravr Fidgetable Demo
//
//  Created by Ezra Akresh on 10/13/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            Color.cravrDarkBackground.ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                JoystickDiskView()
                    .tag(0)
                    .background(Color.cravrDarkBackground)
                
                FourDotGridView()
                    .tag(1)

                SixDotGridView()
                    .tag(2)

                ThreeDotGridView()
                    .tag(3)

                BallOnRingView()
                    .tag(4)

                BallBalancerView()
                    .tag(5)

                PhoneShakeView()
                    .tag(6)

                RotationalPhoneView()
                    .tag(7)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
        }
    }
}

#Preview {
    ContentView()
}
