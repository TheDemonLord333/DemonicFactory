//
//  ParticleTextureFactory.swift
//  DemonicFactory
//
//  Generates small soft-circle textures at runtime so SKEmitterNodes don't
//  depend on bundled art assets.
//

import SpriteKit
import UIKit

enum ParticleTextureFactory {
    private static var cache: [String: SKTexture] = [:]

    static func softCircle(diameter: CGFloat = 24) -> SKTexture {
        let key = "circle_\(diameter)"
        if let cached = cache[key] { return cached }

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: diameter, height: diameter))
        let image = renderer.image { context in
            let cg = context.cgContext
            let colors = [UIColor.white.withAlphaComponent(1).cgColor,
                          UIColor.white.withAlphaComponent(0).cgColor] as CFArray
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) else { return }
            let center = CGPoint(x: diameter / 2, y: diameter / 2)
            cg.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: diameter / 2, options: [])
        }
        let texture = SKTexture(image: image)
        cache[key] = texture
        return texture
    }
}
