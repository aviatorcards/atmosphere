// Theme.swift
// Centralized access to brand colors and gradients

import SwiftUI

enum Theme {
    static let primary = Color("BrandPrimary")
    static let secondary = Color("BrandSecondary")

    static var brandGradient: LinearGradient {
        LinearGradient(colors: [primary, secondary], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

#if DEBUG
#Preview("Theme Colors") {
    VStack(spacing: 24) {
        Text("Primary").padding().frame(maxWidth: .infinity).background(Theme.primary).foregroundStyle(.white)
        Text("Secondary").padding().frame(maxWidth: .infinity).background(Theme.secondary).foregroundStyle(.black)
        RoundedRectangle(cornerRadius: 20)
            .fill(Theme.brandGradient)
            .frame(height: 120)
            .overlay(Text("Brand Gradient").foregroundStyle(.white))
    }
    .padding()
    .frame(width: 320)
}
#endif
