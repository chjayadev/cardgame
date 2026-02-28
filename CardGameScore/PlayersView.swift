import SwiftUI

/// Manage the global player pool — add and delete players.
struct PlayersView: View {

    @ObservedObject var store: GameStore
    @State private var newName = ""
    @FocusState private var isFocused: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Add player bar
                HStack(spacing: 12) {
                    TextField("Player name", text: $newName)
                        .textFieldStyle(.roundedBorder)
                        .focused($isFocused)
                        .submitLabel(.done)
                        .onSubmit { addPlayer() }

                    Button {
                        addPlayer()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                    .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding()

                Divider()

                if store.players.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "person.fill.questionmark")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("No Players")
                            .font(.title2.bold())
                        Text("Add at least 2 players to create a game.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                } else {
                    List {
                        ForEach(store.players) { player in
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .foregroundStyle(.blue)
                                Text(player.name)
                                    .font(.body)
                            }
                        }
                        .onDelete { offsets in
                            store.deletePlayers(at: offsets)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Players")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func addPlayer() {
        store.addPlayer(name: newName)
        newName = ""
        isFocused = true
    }
}

#Preview {
    PlayersView(store: GameStore())
}
