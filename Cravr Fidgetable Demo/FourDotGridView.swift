//
//  FourDotGridView.swift
//  Cravr Fidgetable Demo
//
//  Created by Ezra Akresh on 10/13/25.
//

import SwiftUI

struct FourDotGridView: View {
    @State private var dotStates: [[Bool]] = Array(repeating: Array(repeating: false, count: 6), count: 6)
    
    var body: some View {
        ZStack {
            Color.green.ignoresSafeArea()
            
            VStack(spacing: 40) {
                ZStack {
                    /*
                    want to 2x2 grid that has 4 dots in it, each dot is a gray circle
                    each dot is 80x80
                    the grid is 200x200
                    the dots are spaced 20 pixels apart
                    the grid is centered in the view
                    the grid is 200x200
                    the dots are spaced 20 pixels apart
                    the grid is centered in the view
                    the grid is 200x200

                    each dot can be dragged within its zone
                    it should use a similar drag logic to the joystick disk view (feel free to refactor and use the exact same logic)
                    the dots should each have a distinct haptic feedback when dragged
                    they should not be the same
                    description of feedbacks:
                    top left: super light and very frequent
                    top right: medium and frequent
                    bottom left: super full and frequent (these vibrations should be super deep and they feel like a bubble pop)
                    bottom right: light and very frequent

                    each vibration should occur it its distinct area of the phone the dot was dragged from (you may want to refactor from joystick disk view)
                    */
                }
            }
        }
        .onAppear {
            Haptics.shared.prepareAll()
        }
    }
}

#Preview {
    FourDotGridView()
}
