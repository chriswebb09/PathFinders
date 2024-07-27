//
//  CompassMapViewModel.swift
//  PathFindersMobile-iOS
//
//  Created by Christopher Webb on 7/26/24.
//

import ArcGIS
import CoreLocation
import SwiftUI



@MainActor
class CompassMapViewModel: ObservableObject {
    /// Map of Esri Campus indoors.
    let map = Map(url: .indoorsMap)!
    
    /// A indoors location data source based on sensor data, including but not
    /// limited to radio, GPS, motion sensors.
    private var indoorsLocationDataSource: IndoorsLocationDataSource?
    
    /// The map's location display.
    private(set) var locationDisplay = LocationDisplay(dataSource: SystemLocationDataSource())
    
    /// The location manager which handles the location data.
    private let locationManager = CLLocationManager()
    
    /// Represents loading state of indoors data, blocks interaction until loaded.
    @Published var isLoading = false
    
    /// Kicks off the logic loading the data for the indoors map and indoors location.
    func loadIndoorData() async throws {
        isLoading = true
        try await map.load()
        try await requestLocationServicesAuthorizationIfNecessary()
        try await setIndoorDatasource()
    }
    
    /// Stops the location data source.
    func stopLocationDataSource() {
        Task {
            await locationDisplay.dataSource.stop()
        }
    }
    
    /// A function that attempts to load an indoor definition attached to the map
    /// and returns a boolean value based whether it is loaded.
    /// - Parameter map: The map that contains the IndoorDefinition.
    /// - Returns: A boolean value for whether the IndoorDefinition is loaded.
    private func indoorDefinitionIsLoaded(map: Map) async throws -> Bool {
        guard map.indoorPositioningDefinition?.loadStatus != .loaded else { return true }
        try await map.indoorPositioningDefinition?.load()
        return map.indoorPositioningDefinition?.loadStatus == .loaded
    }
    
    /// Sets the indoor datasource on the location display depending on
    /// whether the map contains an IndoorDefinition.
    private func setIndoorDatasource() async throws {
        try await map.floorManager?.load()
        // If an indoor definition exists in the map, it gets loaded and sets the IndoorsDataSource to pull information
        // from the definition.
        if try await indoorDefinitionIsLoaded(map: map),
           let indoorPositioningDefinition = map.indoorPositioningDefinition {
            indoorsLocationDataSource = IndoorsLocationDataSource(definition: indoorPositioningDefinition)
            // Otherwise the IndoorsDataSource attempts to create itself using IPS table information.
        } else {
            indoorsLocationDataSource = try await createIndoorLocationDataSourceFromTables(map: map)
        }
        // This ensures that the details of the inside of the building, like room layouts are displayed.
        for featLayer in map.operationalLayers {
            if featLayer.name == "Transitions" || featLayer.name == "Details" {
                featLayer.isVisible = true
            }
        }
        // The indoorsLocationDataSource should always be there. Since the createIndoorLocationDataSourceFromTables returns an optional value
        // it cannot be guaranteed. Best option if you get to this point without a datasource is to return
        // (ideally an error would have been thrown before this point and the flow broken.)
        guard let dataSource = indoorsLocationDataSource else { return }
        
        locationDisplay.dataSource = dataSource
        locationDisplay.autoPanMode = .compassNavigation
        // Start the location display to zoom to the user's current location.
        guard locationDisplay.dataSource.status != .started else { return }
        try await locationDisplay.dataSource.start()
    }
    
    /// Creates an indoor location datasource from the maps tables if there is no indoors definition.
    /// - Parameter map: The map which contains the tables from which the data source is constructed.
    /// - Returns: Returns a configured IndoorsLocationDataSource created from the IPS position table.
    private func createIndoorLocationDataSourceFromTables(map: Map) async throws -> IndoorsLocationDataSource? {
        // Gets the positioning table from the map.
        guard let positioningTable = map.tables.first(where: { $0.displayName == "IPS_Positioning" }) else { return nil }
        // Creates and configures the query parameters.
        let queryParameters = QueryParameters()
        queryParameters.maxFeatures = 1
        queryParameters.whereClause = "1 = 1"
        // Queries positioning table to get the positioning ID.
        let queryResult = try await positioningTable.queryFeatures(using: queryParameters)
        guard let feature = queryResult.features().makeIterator().next() else { return nil }
        let serviceFeatureTable = positioningTable as! ServiceFeatureTable
        let positioningID = feature.attributes[serviceFeatureTable.globalIDField] as? UUID
        
        // Gets the pathways layer (optional for creating the IndoorsLocationDataSource).
        let pathwaysLayer = map.operationalLayers.first(where: { $0.name == "Pathways" }) as! FeatureLayer
        // Gets the levels layer (optional for creating the IndoorsLocationDataSource).
        let levelsLayer = map.operationalLayers.first(where: { $0.name == "Levels" }) as! FeatureLayer
        
        // Setting up IndoorsLocationDataSource with positioning, pathways tables and positioning ID.
        // positioningTable - the "IPS_Positioning" feature table from an IPS-aware map.
        // pathwaysTable - An ArcGISFeatureTable that contains pathways as per the ArcGIS Indoors Information Model.
        // Setting this property enables path snapping of locations provided by the IndoorsLocationDataSource.
        // levelsTable - An ArcGISFeatureTable that contains floor levels in accordance with the ArcGIS Indoors Information Model.
        // Providing this table enables the retrieval of a location's floor level ID.
        // positioningID - an ID which identifies a specific row in the positioningTable that should be used for setting up IPS.
        return IndoorsLocationDataSource(
            positioningTable: positioningTable,
            pathwaysTable: pathwaysLayer.featureTable as? ArcGISFeatureTable,
            levelsTable: levelsLayer.featureTable as? ArcGISFeatureTable,
            positioningID: positioningID
        )
    }
    
    /// The method that updates the location when the indoors location datasource is triggered.
    func updateDisplayOnLocationChange(proxy: MapViewProxy) async throws {
        for try await _ in locationDisplay.dataSource.locations {
            if isLoading {
                Task {
                    await proxy.setViewpointScale(550)
                    locationDisplay.autoPanMode = .compassNavigation
                }
            }
            isLoading = false
        }
    }
    
    /// Starts the location display to show user's location on the map.
    func requestLocationServicesAuthorizationIfNecessary() async throws {
        // Requests location permission if it has not yet been determined.
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
    }
}
private extension URL {
    static var indoorsMap: URL {
        URL(string: "https://www.arcgis.com/home/item.html?id=8fa941613b4b4b2b8a34ad4cdc3e4bba")!
    }
}


