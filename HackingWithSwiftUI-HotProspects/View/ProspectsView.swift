//
//  ProspectsView.swift
//  HackingWithSwiftUI-HotProspects
//
//  Created by Michael Jones on 23/07/2026.
//

import AVFoundation
import CodeScanner
import SwiftData
import SwiftUI
import UserNotifications

struct ProspectsView: View {
    @Environment(\.modelContext) var modelContext
    @Query(sort: \Prospect.name) var prospects: [Prospect]
    
    @State private var isShowingScanner: Bool = false
    @State private var selectedProspects = Set<Prospect>()
    
    enum FilterType {
        case none, contacted, uncontacted
    }
    
    let filter: FilterType
    
    var title: String {
        switch filter {
        case .none:
            "Everyone"
        case .contacted:
            "Contacted"
        case .uncontacted:
            "Uncontacted"
        }
    }
    
    var body: some View {
        NavigationStack {
            List(prospects, selection: $selectedProspects) { prospect in
                NavigationLink {
                    EditProspectView(prospect: prospect)
                } label: {
                    VStack(alignment: .leading) {
                        Text(prospect.name)
                            .font(.headline)
                        Text(prospect.email)
                            .foregroundStyle(.secondary)
                    }
                    
                    if filter == .none && prospect.isContacted {
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                    }
                }
                .swipeActions {
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        modelContext.delete(prospect)
                    }
                    
                    switch prospect.isContacted {
                    case true:
                        Button("Mark Uncontacted", systemImage: "person.crop.circle.badge.xmark") {
                            prospect.isContacted = false
                        }
                        .tint(.blue)
                        
                    case false:
                        Button("Mark Contacted", systemImage: "person.crop.circle.fill.badge.checkmark") {
                            prospect.isContacted = true
                        }
                        .tint(.green)
                        
                        Button("Remind Me", systemImage: "bell" ) {
                            addNotification(for: prospect)
                        }
                        .tint(.orange)
                    }
                }
                .tag(prospect)
            }
            .navigationTitle(title)
            .toolbar {
                 ToolbarItem(placement: .topBarTrailing) {
                    Button("Scan", systemImage: "qrcode.viewfinder") {
                        isShowingScanner = true
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
                
                if selectedProspects.isEmpty == false {
                    ToolbarItem(placement: .bottomBar) {
                        Button("Delete Selected", action: delete)
                    }
                }
            }
            .sheet(isPresented: $isShowingScanner) {
                CodeScannerView(
                    codeTypes: [.qr],
                    simulatedData: "Michael Jones\nmichael.jones90@me.com",
                    completion: handleScan
                )
            }
            .onAppear {
                selectedProspects = []
            }
        }
    }
    
    init(filter: FilterType, sort: SortDescriptor<Prospect>) {
        self.filter = filter
        
        if filter != .none {
            let showContactOnly = filter == .contacted
            
            _prospects = Query(filter: #Predicate {
                $0.isContacted == showContactOnly
            }, sort: [SortDescriptor(\Prospect.name)])
        } else {
            _prospects = Query(sort: [sort])
        }
    }
    
    /// A callback handler for the QR code scanner sheet (CodeScannerView). When a QR code is scanned, this function processes the result.
    func handleScan(result: Result<ScanResult, ScanError>) {
        isShowingScanner = false
        
        switch result {
        case .success(let result):
            let details = result.string.components(separatedBy: "\n")
            guard details.count == 2 else { return }
            
            let person = Prospect(name: details[0], email: details[1], isContacted: false)
            modelContext.insert(person)
        case .failure(let error):
            print("Scanning failed: \(error.localizedDescription)")
        }
    }
    
    /// Deletes all the currently selected prospects from the data model.
    func delete() {
        for prospect in selectedProspects {
            modelContext.delete(prospect)
        }
    }
    
    /// Schedules a local notification to remind the user to contact a specific Prospect.
    func addNotification(for prospect: Prospect) {
        /// Fetches the shared notification centre for scheduling and managing notifications.
        let centre = UNUserNotificationCenter.current()
        
        /// Prepares and schedules the notification.
        let addRequest = {
            /// Sets the notification content (title, subtitle and sound).
            let content = UNMutableNotificationContent()
            content.title = "Contact \(prospect.name)"
            content.subtitle = prospect.email
            content.sound = UNNotificationSound.default
            
            /// Creates a trigger that is scheduled for 9am.
            var dateComponents = DateComponents()
            dateComponents.hour = 9
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            
            /// Creates a new request and adds it to the notification center.
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            centre.add(request)
        }
        
        /// Checks if the app is already authorised to show notifications.
        centre.getNotificationSettings { settings in
            /// Schedules the notification.
            if settings.authorizationStatus == .authorized {
                addRequest()
            } else {
                /// Requests permission from the user. If granted, schedules the notification, if not, prints an error.
                centre.requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
                    if success {
                        addRequest()
                    } else if let error {
                        print(error.localizedDescription)
                    }
                }
            }
        }
    }
}

#Preview {
    ProspectsView(filter: .none, sort: SortDescriptor(\Prospect.name))
        .modelContainer(for: Prospect.self)
}
