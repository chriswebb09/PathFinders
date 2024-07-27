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

        // Create a cube model
        let mesh = MeshResource.generateBox(size: 0.1, cornerRadius: 0.005)
        let material = SimpleMaterial(color: .gray, roughness: 0.15, isMetallic: true)
        let model = ModelEntity(mesh: mesh, materials: [material])
        model.transform.translation.y = 0.05

        // Create horizontal plane anchor for the content
        let anchor = AnchorEntity(.plane(.horizontal, classification: .any, minimumBounds: SIMD2<Float>(0.2, 0.2)))
        anchor.children.append(model)

        // Add the horizontal plane anchor to the scene
        arView.scene.anchors.append(anchor)
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

import SwiftUI
import UIKit

class HostingView<T: View>: UIView {
    
    private(set) var hostingController: UIHostingController<T>
    
    var rootView: T {
        get { hostingController.rootView }
        set { hostingController.rootView = newValue }
    }
    
    init(rootView: T, frame: CGRect = .zero) {
        hostingController = UIHostingController(rootView: rootView)
        super.init(frame: frame)
        backgroundColor = .clear
        hostingController.view.backgroundColor = backgroundColor
        hostingController.view.frame = self.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        addSubview(hostingController.view)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
