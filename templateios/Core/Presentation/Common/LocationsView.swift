import SwiftUI
import MultipeerConnectivity

// Custom implementation of location sharing with native MultipeerConnectivity
class NativeLocationSharingService: NSObject, ObservableObject {
    @Published var nearbyUsers: [String] = []
    @Published var receivedLocations: [String: String] = [:]
    @Published var discoveredPeers: [MCPeerID] = []
    @Published var peerConnectionStates: [MCPeerID: MCSessionState] = [:]
    @Published var receivedImages: [String: UIImage] = [:]
    
    private let serviceType = "rm-locations"
    private let myPeerId = MCPeerID(displayName: UIDevice.current.name)
    private var serviceAdvertiser: MCNearbyServiceAdvertiser?
    private var serviceBrowser: MCNearbyServiceBrowser?
    private var session: MCSession?
    
    override init() {
        super.init()
        print("MPC: Initializing service")
        setupMultipeer()
    }
    
    private func setupMultipeer() {
        print("MPC: Setting up with service type: \(serviceType)")
        print("MPC: My device name: \(myPeerId.displayName)")
        
        session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .required)
        session?.delegate = self
        
        serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: serviceType)
        serviceAdvertiser?.delegate = self
        serviceAdvertiser?.startAdvertisingPeer()
        print("MPC: Started advertising")
        
        serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)
        serviceBrowser?.delegate = self
        serviceBrowser?.startBrowsingForPeers()
        print("MPC: Started browsing for peers")
    }
    
    func shareLocation(_ locationName: String) {
        guard let session = session, !session.connectedPeers.isEmpty else { return }
        
        guard let prefixData = "LOCATION:".data(using: .utf8),
              let locationData = locationName.data(using: .utf8) else {
            print("MPC: Error converting location text to data")
            return
        }
        
        let dataToSend = prefixData + locationData
        do {
            try session.send(dataToSend, toPeers: session.connectedPeers, with: .reliable)
            print("MPC: Location shared: \(locationName)")
        } catch {
            print("Error sending location: \(error.localizedDescription)")
        }
    }
    
    func shareImage(_ image: UIImage) {
        guard let session = session, !session.connectedPeers.isEmpty else { 
            print("MPC: No connected peers to share image with")
            return 
        }
        
        if let imageData = image.jpegData(compressionQuality: 0.7) {
            do {
                // We'll prefix data with a type identifier
                let dataToSend = "IMAGE:".data(using: .utf8)! + imageData
                try session.send(dataToSend, toPeers: session.connectedPeers, with: .reliable)
                print("MPC: Sending image, size: \(imageData.count) bytes")
            } catch {
                print("Error sending image: \(error.localizedDescription)")
            }
        }
    }
    
    func connectToPeer(_ peerID: MCPeerID) {
        print("MPC: Attempting to connect to peer: \(peerID.displayName)")
        serviceBrowser?.invitePeer(peerID, to: session!, withContext: nil, timeout: 30)
    }
    
    deinit {
        serviceAdvertiser?.stopAdvertisingPeer()
        serviceBrowser?.stopBrowsingForPeers()
    }
}

// MARK: - MCSessionDelegate
extension NativeLocationSharingService: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        print("MPC: Peer \(peerID.displayName) changed state to: \(state)")
        DispatchQueue.main.async {
            self.peerConnectionStates[peerID] = state
            
            switch state {
            case .connected:
                print("MPC: Connected to \(peerID.displayName)")
                if !self.nearbyUsers.contains(peerID.displayName) {
                    self.nearbyUsers.append(peerID.displayName)
                }
            case .notConnected:
                print("MPC: Disconnected from \(peerID.displayName)")
                if let index = self.nearbyUsers.firstIndex(of: peerID.displayName) {
                    self.nearbyUsers.remove(at: index)
                }
                self.receivedLocations.removeValue(forKey: peerID.displayName)
                self.receivedImages.removeValue(forKey: peerID.displayName)
            case .connecting:
                print("MPC: Connecting to \(peerID.displayName)")
            @unknown default:
                break
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        // Check if it's an image
        if data.count > 6, 
           let prefixString = String(data: data.prefix(6), encoding: .utf8),
           prefixString == "IMAGE:" {
            
            let imageData = data.dropFirst(6)
            if let image = UIImage(data: imageData) {
                print("MPC: Received image from \(peerID.displayName), size: \(imageData.count) bytes")
                DispatchQueue.main.async {
                    self.receivedImages[peerID.displayName] = image
                }
            }
            return
        }
        
        // Check if it's a location
        if data.count > 9,
           let prefixString = String(data: data.prefix(9), encoding: .utf8),
           prefixString == "LOCATION:" {
            
            let locationData = data.dropFirst(9)
            if let locationString = String(data: locationData, encoding: .utf8) {
                print("MPC: Received location from \(peerID.displayName): \(locationString)")
                DispatchQueue.main.async {
                    self.receivedLocations[peerID.displayName] = locationString
                }
            }
            return
        }
        
        // Default to legacy behavior for backward compatibility
        if let locationString = String(data: data, encoding: .utf8) {
            print("MPC: Received legacy text data from \(peerID.displayName)")
            DispatchQueue.main.async {
                self.receivedLocations[peerID.displayName] = locationString
            }
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension NativeLocationSharingService: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // Auto-accept invitations
        print("MPC: Received invitation from \(peerID.displayName)")
        invitationHandler(true, session)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("MPC: Failed to start advertising: \(error.localizedDescription)")
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension NativeLocationSharingService: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        print("MPC: Found peer: \(peerID.displayName)")
        DispatchQueue.main.async {
            if !self.discoveredPeers.contains(peerID) {
                self.discoveredPeers.append(peerID)
                self.peerConnectionStates[peerID] = .notConnected
            }
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("MPC: Lost peer: \(peerID.displayName)")
        DispatchQueue.main.async {
            if let index = self.discoveredPeers.firstIndex(of: peerID) {
                self.discoveredPeers.remove(at: index)
                self.peerConnectionStates.removeValue(forKey: peerID)
            }
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("MPC: Failed to start browsing: \(error.localizedDescription)")
    }
}

struct LocationsView: View {
    @StateObject private var sharingService = NativeLocationSharingService()
    @State private var locationToShare = ""
    @State private var showingShareSheet = false
    @State private var selectedTab = 0
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    
    var body: some View {
        NavigationView {
            VStack {
                // Tabbed interface
                Picker("Feature", selection: $selectedTab) {
                    Text("Devices").tag(0)
                    Text("Locations").tag(1)
                    Text("Images").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Tab content
                if selectedTab == 0 {
                    // DEVICES TAB
                    deviceTabContent
                } else if selectedTab == 1 {
                    // LOCATIONS TAB
                    locationTabContent
                } else {
                    // IMAGES TAB - completely refactored
                    imageTabContent
                }
            }
            .navigationTitle("Rick & Morty Connect")
            .navigationBarItems(trailing: selectedTab == 0 ? refreshButton : nil)
            .onAppear {
                print("DEBUG: View appeared")
            }
        }
        // Image picker presentation integrated directly
        .sheet(isPresented: $showingImagePicker, onDismiss: {
            print("DEBUG: ImagePicker dismissed")
        }) {
            ImagePickerView(selectedImage: $selectedImage)
        }
    }
    
    // Image picker integrated directly into LocationsView
    struct ImagePickerView: UIViewControllerRepresentable {
        @Binding var selectedImage: UIImage?
        @Environment(\.presentationMode) private var presentationMode
        
        func makeUIViewController(context: Context) -> UIImagePickerController {
            let picker = UIImagePickerController()
            picker.delegate = context.coordinator
            picker.sourceType = .photoLibrary
            picker.allowsEditing = false
            return picker
        }
        
        func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
        
        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }
        
        class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
            let parent: ImagePickerView
            
            init(_ parent: ImagePickerView) {
                self.parent = parent
            }
            
            func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
                if let image = info[.originalImage] as? UIImage {
                    // Create a copy of the image to prevent metadata issues
                    let imageSize = image.size
                    UIGraphicsBeginImageContextWithOptions(imageSize, false, image.scale)
                    image.draw(in: CGRect(origin: .zero, size: imageSize))
                    if let copyImage = UIGraphicsGetImageFromCurrentImageContext() {
                        parent.selectedImage = copyImage
                    } else {
                        parent.selectedImage = image
                    }
                    UIGraphicsEndImageContext()
                }
                parent.presentationMode.wrappedValue.dismiss()
            }
            
            func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
                parent.presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    // MARK: - Device Tab Content
    private var deviceTabContent: some View {
        List {
            Section("Discovered Devices") {
                if sharingService.discoveredPeers.isEmpty {
                    HStack {
                        Text("Searching for devices...")
                            .foregroundColor(.secondary)
                        Spacer()
                        ProgressView()
                    }
                } else {
                    ForEach(sharingService.discoveredPeers, id: \.self) { peer in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(peer.displayName)
                                    .font(.headline)
                                
                                Text(connectionStateText(for: peer))
                                    .font(.caption)
                                    .foregroundColor(connectionStateColor(for: peer))
                            }
                            
                            Spacer()
                            
                            if sharingService.peerConnectionStates[peer] != .connected {
                                Button(action: {
                                    sharingService.connectToPeer(peer)
                                }) {
                                    Text("Connect")
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.green)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            
            Section("Connection Status") {
                if sharingService.nearbyUsers.isEmpty {
                    Text("Not connected to any devices")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(sharingService.nearbyUsers, id: \.self) { user in
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(.green)
                            Text(user)
                            Spacer()
                            Text("Connected")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Location Tab Content
    private var locationTabContent: some View {
        List {
            Section(header: Text("Share a Location")) {
                VStack(spacing: 12) {
                    TextField("Enter location name from Rick & Morty", text: $locationToShare)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.vertical, 4)
                    
                    Button(action: {
                        if !locationToShare.isEmpty {
                            sharingService.shareLocation(locationToShare)
                            locationToShare = ""
                        }
                    }) {
                        HStack {
                            Image(systemName: "paperplane.fill")
                            Text("Share Location")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(locationToShare.isEmpty ? Color.gray : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(locationToShare.isEmpty || sharingService.nearbyUsers.isEmpty)
                }
                .padding(.vertical, 4)
            }
            
            if !sharingService.receivedLocations.isEmpty {
                Section(header: Text("Received Locations")) {
                    ForEach(Array(sharingService.receivedLocations.keys), id: \.self) { user in
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Image(systemName: "person.circle")
                                    .foregroundColor(.blue)
                                Text(user)
                                    .font(.headline)
                                Spacer()
                                Text("Shared location")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Image(systemName: "mappin.and.ellipse")
                                    .foregroundColor(.red)
                                Text(sharingService.receivedLocations[user] ?? "")
                                    .font(.subheadline)
                                    .padding(.leading, 4)
                            }
                            .padding(.top, 2)
                            .padding(.leading, 8)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
        }
    }
    
    // MARK: - Image Tab Content
    private var imageTabContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // SECTION 1: Selected image display
                if let image = selectedImage {
                    Text("Selected Image")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
                
                // SECTION 2: Action buttons (completely separate)
                Text("Actions")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                // Select Image Button (ONLY opens picker, does NOT share)
                Button(action: {
                    // *ONLY* open the image picker, nothing else
                    print("DEBUG: Select Image button pressed")
                    showingImagePicker = true
                }) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                        Text(selectedImage == nil ? "Select Image" : "Change Image")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // Share Image Button (ONLY shares, does NOT open picker)
                if selectedImage != nil {
                    Button(action: {
                        // *ONLY* share the image, nothing else
                        print("DEBUG: Share Image button pressed")
                        if let image = selectedImage {
                            sharingService.shareImage(image)
                            
                            // Feedback
                            let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
                            feedbackGenerator.impactOccurred()
                        }
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Image")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(sharingService.nearbyUsers.isEmpty ? Color.gray : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .disabled(sharingService.nearbyUsers.isEmpty)
                }
                
                // SECTION 3: Received images
                if !sharingService.receivedImages.isEmpty {
                    Text("Received Images")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    ForEach(Array(sharingService.receivedImages.keys), id: \.self) { user in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "person.circle")
                                    .foregroundColor(.blue)
                                Text(user)
                                    .font(.headline)
                                Spacer()
                                Text("Shared image")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            if let image = sharingService.receivedImages[user] {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 200)
                                    .cornerRadius(8)
                                    .padding(.top, 4)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 6)
                    }
                }
            }
            .padding(.vertical)
        }
    }
    
    // MARK: - Button Components
    private var refreshButton: some View {
        Button(action: {
            sharingService.discoveredPeers = []
        }) {
            Image(systemName: "arrow.triangle.2.circlepath")
        }
    }
    
    private func connectionStateText(for peer: MCPeerID) -> String {
        let state = sharingService.peerConnectionStates[peer] ?? .notConnected
        
        switch state {
        case .connected:
            return "Connected"
        case .connecting:
            return "Connecting..."
        case .notConnected:
            return "Not Connected"
        @unknown default:
            return "Unknown"
        }
    }
    
    private func connectionStateColor(for peer: MCPeerID) -> Color {
        let state = sharingService.peerConnectionStates[peer] ?? .notConnected
        
        switch state {
        case .connected:
            return .green
        case .connecting:
            return .orange
        case .notConnected:
            return .red
        @unknown default:
            return .gray
        }
    }
    
    @ViewBuilder
    private func connectionStateView(for peer: MCPeerID) -> some View {
        let state = sharingService.peerConnectionStates[peer] ?? .notConnected
        
        switch state {
        case .connected:
            Circle()
                .fill(Color.green)
                .frame(width: 10, height: 10)
        case .connecting:
            Circle()
                .fill(Color.orange)
                .frame(width: 10, height: 10)
        case .notConnected:
            Circle()
                .fill(Color.red)
                .frame(width: 10, height: 10)
        @unknown default:
            Circle()
                .fill(Color.gray)
                .frame(width: 10, height: 10)
        }
    }
} 