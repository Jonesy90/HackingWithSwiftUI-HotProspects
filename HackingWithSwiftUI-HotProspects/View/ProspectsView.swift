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

struct ProspectsView: View {
    @Environment(\.modelContext) var modelContext
    @Query(sort: \Prospect.name) var prospects: [Prospect]
    
    @State private var viewModel = ViewModel()
    
    let filter: ProspectsView.ViewModel.FilterType
    
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
            List(prospects, selection: $viewModel.selectedProspects) { prospect in
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
                            viewModel.addNotification(for: prospect)
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
                        viewModel.isShowingScanner = true
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
                
                if viewModel.selectedProspects.isEmpty == false {
                    ToolbarItem(placement: .bottomBar) {
                        Button("Delete Selected") {
                            viewModel.delete(modelContext)
                        }
                    }
                }
            }
            .sheet(isPresented: $viewModel.isShowingScanner) {
                CodeScannerView(
                    codeTypes: [.qr],
                    simulatedData: "Michael Jones\nmichael.jones90@me.com",
                    completion: { result in
                        viewModel.handleScan(result: result, modelContext: modelContext)
                    }
                )
            }
            .onAppear {
                viewModel.selectedProspects = []
            }
        }
    }
    
    init(filter: ProspectsView.ViewModel.FilterType, sort: SortDescriptor<Prospect>) {
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
}

#Preview {
    ProspectsView(filter: ProspectsView.ViewModel.FilterType.none, sort: SortDescriptor(\Prospect.name))
        .modelContainer(for: Prospect.self)
}

