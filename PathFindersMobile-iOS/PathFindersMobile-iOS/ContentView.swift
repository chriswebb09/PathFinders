//
//  ContentView.swift
//  PathFindersMobile-iOS
//
//  Created by Christopher Webb on 7/26/24.
//

import SwiftUI
import RealityKit

struct ContentView : View {
    var body: some View {
        ARViewContainer().edgesIgnoringSafeArea(.all)
    }
}

struct ARViewContainer: UIViewRepresentable {
    
    func makeUIView(context: Context) -> ARView {
        
        let arView = ARView(frame: .zero)
        var result: Float = 0
        for i in 0..<800 {
            // Create a cube model
            let mesh = MeshResource.generatePlane(width: 0.1, depth: 0.1)
            //MeshResource.generateBox(size: 0.1, cornerRadius: 0.005)
            let material = SimpleMaterial(color: .gray, roughness: 0.15, isMetallic: true)
            let model = ModelEntity(mesh: mesh, materials: [material])
            model.transform.translation.y = 0.05
            
            if i < 10 {
                result = -0.05 * Float(i)
                model.transform.translation.z = result
                model.transform.translation.x = 0
            } else {
                model.transform.translation.z = result
                model.transform.translation.x = -0.008 * Float(i)
            }
            
            if i == 10 {
                let rkPin = RKPointPin()
                arView.addSubview(rkPin)
                rkPin.autoHideOnFocused = true
                rkPin.focusPercentage = 0.35
                rkPin.targetEntity = model
            }
            
            
            // Create horizontal plane anchor for the content
            let anchor = AnchorEntity(.plane(.horizontal, classification: .any, minimumBounds: SIMD2<Float>(0.2, 0.2)))
            anchor.children.append(model)
            
            // Add the horizontal plane anchor to the scene
            arView.scene.anchors.append(anchor)
        }
        
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

