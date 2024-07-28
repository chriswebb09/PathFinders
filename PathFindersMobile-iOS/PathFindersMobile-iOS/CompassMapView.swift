//
//  CompassMapView.swift
//  PathFindersMobile-iOS
//
//  Created by Christopher Webb on 7/26/24.
//
import ArcGIS
import CoreLocation
import SwiftUI

struct CompassMapView: View {
    /// The data model for the sample.
    @StateObject private var model = CompassMapViewModel()
    
    @StateObject public var graphicsOverlayModel = Model()
    
    /// The error shown in the error alert.
    @State private var error: Error?
    
    var body: some View {
        MapViewReader { proxy in
            MapView(map: model.map, graphicsOverlays: [graphicsOverlayModel.graphicsOverlay])
                .locationDisplay(model.locationDisplay)
                .clipShape(Circle())
                .overlay {
                    Circle().stroke(.gray, lineWidth: 4)
                }
                .frame(width: 190, height: 190)
                .offset(y: 150)
                .offset(x: 280)
                .opacity(/*@START_MENU_TOKEN@*/0.8/*@END_MENU_TOKEN@*/)
                .task {
                    do {
                        model.isLoading = true
                        try await model.loadIndoorData()
                        try await model.updateDisplayOnLocationChange(proxy: proxy)
                    } catch {
                        self.error = error
                    }
                }
                .onDisappear {
                    model.stopLocationDataSource()
                }
        }
    }
}

#Preview {
    CompassMapView()
}
