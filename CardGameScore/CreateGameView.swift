import SwiftUI

/// Sheet to create a new game — enter a name and pick players.
struct CreateGameView: View {

    @ObservedObject var store: GameStore
    @State private var gameName = ""
    @State private var selectedIDs: Set<UUID> = []
    @Environment(\.dismiss) private var dismiss

    private var canCreate: Bool {
        !gameName.trimmingCharacters(in: .whitespaces).isEmpty && selectedIDs.count >= 2
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Game Name") {
                    TextField("e.g. Friday Night Poker", text: $gameName)
                }

                Section("Select Players (\(selectedIDs.count) selected)") {
                    ForEach(store.players) { player in
                        Button {
                            toggleSelection(player.id)
                        } label: {
                            HStack {
                                Image(systemName: selectedIDs.contains(player.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selectedIDs.contains(player.id) ? .blue : .secondary)

                                Text(player.name)
                                    .foregroundStyle(Color.primary)
                            }
                        }
                    }
                }

                if store.players.count < 2 {
                    Section {
                        Text("You need at least 2 players. Go back and add more players first.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("New Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start Game") {
                        _ = store.createGame(
                            name: gameName.trimmingCharacters(in: .whitespaces),
                            playerIDs: store.players.filter { selectedIDs.contains($0.id) }.map(\.id)
                        )
                        dismiss()
                    }
                    .disabled(!canCreate)
                }
            }
        }
    }

    private func toggleSelection(_ id: UUID) {
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
    }
}

#Preview {
    CreateGameView(store: GameStore())
}
