import SwiftMark
import SwiftUI

@main
struct AtmosphereApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var store = JournalStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Essential for command-line binaries to show UI
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows.first?.makeKeyAndOrderFront(nil)
        print("Atmosphere launched!")
    }
}

struct ContentView: View {
    @EnvironmentObject var store: JournalStore
    @State private var selectedJournal: Journal? = Journal.all
    @State private var selectedEntry: JournalEntry?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(selectedJournal: $selectedJournal)
        } content: {
            EntryListView(journal: selectedJournal, selectedEntry: $selectedEntry)
        } detail: {
            EditorView(entry: $selectedEntry)
        }
        .navigationTitle(selectedEntry?.displayTitle ?? "Atmosphere")
    }
}
