import SwiftUI

struct AddRoundView: View {
    let players: [Player]
    let onSave: ([UUID: Int]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var scores: [UUID: String] = [:]
    @FocusState private var focusedPlayer: UUID?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(players) { player in
                        HStack {
                            Text(player.name)
                                .font(.headline)
                            Spacer()
                            TextField("0", text: binding(for: player.id))
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .focused($focusedPlayer, equals: player.id)
                                .font(.system(.body, design: .monospaced))
                        }
                    }
                } header: {
                    Text("Enter Round Scores")
                } footer: {
                    Text("Leave empty for zero.")
                }
            }
            .navigationTitle("New Round")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        save()
                    }
                    .fontWeight(.bold)
                }
            }
            .onAppear {
                focusedPlayer = players.first?.id
            }
        }
    }

    private func binding(for id: UUID) -> Binding<String> {
        Binding(
            get: { scores[id, default: ""] },
            set: { scores[id] = $0 }
        )
    }

    private func save() {
        var finalScores: [UUID: Int] = [:]
        for player in players {
            finalScores[player.id] = Int(scores[player.id] ?? "0") ?? 0
        }
        onSave(finalScores)
        dismiss()
    }
}
