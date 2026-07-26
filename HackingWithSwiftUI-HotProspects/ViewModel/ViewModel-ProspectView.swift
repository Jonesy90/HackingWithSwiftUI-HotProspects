//
//  ViewModel-ProspectView.swift
//  HackingWithSwiftUI-HotProspects
//
//  Created by Michael Jones on 26/07/2026.
//

import CodeScanner
import SwiftData
import Foundation
import UserNotifications

extension ProspectsView {
    @Observable
    class ViewModel {
        enum FilterType {
            case none, contacted, uncontacted
        }
        
        var isShowingScanner: Bool = false
        var selectedProspects = Set<Prospect>()
        
        
        
        /// Deletes all the currently selected prospects from the data model.
        func delete(_ modelContext: ModelContext) {
            for prospect in selectedProspects {
                modelContext.delete(prospect)
            }
        }
        
        func handleScan(result: Result<ScanResult, ScanError>, modelContext: ModelContext) {
            self.isShowingScanner = false
            
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
}
