import SwiftUI

/// Home screen — lists all games, with toolbar buttons for "New Game" and "Manage Players".
struct ContentView: View {

    @StateObject private var store = GameStore()
    @State private var showCreateGame = false
    @State private var showPlayers = false

    var body: some View {
        NavigationStack {
            Group {
                if store.games.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("No Games Yet")
                            .font(.title2.bold())
                        Text("Create a game to get started.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    List {
                        ForEach(store.games) { game in
                            NavigationLink(value: game.id) {
                                HStack(spacing: 16) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(game.name)
                                            .font(.headline)
                                        
                                        let playerNames = game.playerIDs.compactMap { store.player(for: $0)?.name }
                                        Text(playerNames.joined(separator: ", "))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                        
                                        HStack(spacing: 12) {
                                            Label("\(game.rounds.count)", systemImage: "numbers.rectangle")
                                            Label("\(game.totalScore)", systemImage: "sum")
                                        }
                                        .font(.caption2.bold())
                                        .foregroundStyle(.blue)
                                    }
                                    
                                    Spacer()
                                    
                                    if let leaderID = game.leader, let leaderName = store.player(for: leaderID)?.name, !game.rounds.isEmpty {
                                        VStack(alignment: .trailing, spacing: 4) {
                                            Text("LEADER")
                                                .font(.system(size: 8, weight: .black))
                                                .foregroundStyle(.yellow)
                                            Text(leaderName)
                                                .font(.caption2.bold())
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        .onDelete { offsets in
                            store.deleteGames(at: offsets)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Card Game Score")
            .navigationDestination(for: UUID.self) { gameID in
                if let idx = store.games.firstIndex(where: { $0.id == gameID }) {
                    GameDetailView(game: $store.games[idx], store: store)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showPlayers = true
                    } label: {
                        Label("Players", systemImage: "person.2.fill")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreateGame = true
                    } label: {
                        Label("New Game", systemImage: "plus.circle.fill")
                    }
                    .disabled(store.players.count < 2)
                }
            }
            .sheet(isPresented: $showPlayers) {
                PlayersView(store: store)
            }
            .sheet(isPresented: $showCreateGame) {
                CreateGameView(store: store)
            }
        }
    }
}

#Preview {
    ContentView()
}
