//
//  EditProspectView.swift
//  HackingWithSwiftUI-HotProspects
//
//  Created by Michael Jones on 26/07/2026.
//

import SwiftUI

struct EditProspectView: View {
    @Bindable var prospect: Prospect
    
    var body: some View {
        Form {
            TextField("Name", text: $prospect.name)
            TextField("Email", text: $prospect.email)
            Toggle("Contacted", isOn: $prospect.isContacted)
        }
        .navigationTitle("Edit Prospect")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    EditProspectView(prospect: Prospect(name: "Michael", email: "test", isContacted: false))
}
