//
//  GameSceneContainer.swift
//  DemonicFactory
//
//  Hosts the FactoryScene inside SwiftUI and wires up the two gestures
//  SpriteKit's own touch handling doesn't cover: two-finger pinch-to-zoom and
//  long-press (build menu / move mode).
//

import SwiftUI
import SpriteKit
import UIKit

struct GameSceneContainer: UIViewRepresentable {
    let scene: FactoryScene

    func makeUIView(context: Context) -> SKView {
        let view = SKView(frame: .zero)
        view.ignoresSiblingOrder = true
        view.showsFPS = false
        view.showsNodeCount = false
        view.preferredFramesPerSecond = 60
        view.presentScene(scene)

        let pinch = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        view.addGestureRecognizer(pinch)

        let longPress = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLongPress(_:)))
        longPress.minimumPressDuration = 0.4
        view.addGestureRecognizer(longPress)

        context.coordinator.scene = scene
        return view
    }

    func updateUIView(_ uiView: SKView, context: Context) {
        context.coordinator.scene = scene
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject {
        var scene: FactoryScene?

        @objc func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
            guard recognizer.state == .changed else { return }
            scene?.handlePinch(incrementalScale: recognizer.scale)
            recognizer.scale = 1
        }

        @objc func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
            guard let view = recognizer.view as? SKView, let scene else { return }
            let location = recognizer.location(in: view)
            let scenePoint = scene.convertPoint(fromView: location)

            switch recognizer.state {
            case .began:
                scene.handleLongPressBegan(at: scenePoint)
            case .changed:
                scene.handleLongPressChanged(at: scenePoint)
            case .ended:
                scene.handleLongPressEnded(at: scenePoint)
            case .cancelled, .failed:
                scene.handleLongPressCancelled()
            default:
                break
            }
        }
    }
}
