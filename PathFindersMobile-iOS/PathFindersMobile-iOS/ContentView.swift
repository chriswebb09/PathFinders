//
//  ContentView.swift
//  PathFindersMobile-iOS
//
//  Created by Christopher Webb on 7/26/24.
//

import SwiftUI
import ARKit
import RealityKit


struct ContentView : View {
    var body: some View {
        ARViewContainer().edgesIgnoringSafeArea(.all)
    }
}

struct ARViewContainer: UIViewRepresentable {
    
    
    func createFirstEntity(initialDepth: Float = 4.0, initialDistance: Float = 0.5, initialWidth: Float = 0.1) -> (AnchorEntity, ModelEntity) {
        let mesh = MeshResource.generatePlane(width: initialWidth, depth: initialDepth, cornerRadius: 0.05)
        var material = PhysicallyBasedMaterial()
        let uikitColour = UIColor.green
        material.baseColor = .init(tint: .black.withAlphaComponent(uikitColour.cgColor.alpha))
        material.emissiveColor = .init(color: uikitColour)
        material.emissiveIntensity = 2
        
        //impleMaterial(color:.systemMint , roughness: 0.1, isMetallic: false)
        let model = ModelEntity(mesh: mesh, materials: [material])
        model.transform.translation.y = 0.01
        model.transform.translation.z = -1 * (initialDistance)
        // Create horizontal plane anchor for the content
        let anchor = AnchorEntity(.plane(.horizontal, classification: .any, minimumBounds: SIMD2<Float>(0.2, 0.2)))
        anchor.children.append(model)
        return (anchor, model)
    }
    
    
    func createNewEntity(initialWidth: Float, initialDepth: Float, depth2: Float, model: ModelEntity) -> (AnchorEntity, ModelEntity) {
        let mesh2 = MeshResource.generatePlane(width: initialWidth, depth: depth2, cornerRadius: 0.05)
        var material2 = PhysicallyBasedMaterial()
        let uikitColour = UIColor.green
        material2.baseColor = .init(tint: .black.withAlphaComponent(uikitColour.cgColor.alpha))
        material2.emissiveColor = .init(color: uikitColour)
        material2.emissiveIntensity = 2
        let model2 = ModelEntity(mesh: mesh2, materials: [material2])
        model2.setPosition(SIMD3(x: -1 * (depth2 / 2), y: 0, z: -1 * (initialDepth / 2)), relativeTo: model)
        let anchor2 = AnchorEntity(.plane(.horizontal, classification: .any, minimumBounds: SIMD2<Float>(0.2, 0.2)))
        anchor2.children.append(model2)
        return (anchor2, model2)
    }
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        let initialDepth: Float = 24.5
        let initialDistance: Float = 0.7
        let initialWidth: Float = 0.1
        let anchor =  createFirstEntity(initialDepth: initialDepth, initialDistance: initialDistance, initialWidth: initialWidth)
        arView.scene.anchors.append(anchor.0)
        let depth2 = initialDepth + 10
        let anchor2 = createNewEntity(initialWidth: initialWidth, initialDepth: initialDepth, depth2: depth2, model: anchor.1)
        let model2 = anchor2.1
        model2.transform.rotation = simd_quatf(angle: GLKMathDegreesToRadians(90), axis: SIMD3(x: 0, y: 1, z: 0))
        arView.scene.anchors.append(anchor2.0)
        let depth3 = (depth2 / 4)
        let anchor3 = createNewEntity(initialWidth: initialWidth, initialDepth: depth2, depth2: depth3, model: model2)
        let model3 = anchor3.1
        model3.transform.rotation = simd_quatf(angle: GLKMathDegreesToRadians(180), axis: SIMD3(x: 0, y: 1, z: 0))
        let pin = RKPointPin()
        pin.targetEntity = model3
        pin.focusPercentage = 0.55
        arView.addSubview(pin)
        arView.scene.anchors.append(anchor3.0)
        let mapView = CompassMapView()
        let uiView = HostingView(rootView: mapView)
        arView.addSubview(uiView)
        return arView
        
    }
    func updateUIView(_ uiView: ARView, context: Context) {}
}

#Preview {
    ContentView()
}
