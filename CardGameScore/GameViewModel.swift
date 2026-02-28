import Foundation
import SwiftUI

// MARK: - Data Models

struct Player: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}

struct Round: Identifiable, Codable, Hashable {
    let id: UUID
    /// Maps player ID → score for that round
    var scores: [UUID: Int]
    let timestamp: Date

    init(id: UUID = UUID(), scores: [UUID: Int], timestamp: Date = Date()) {
        self.id = id
        self.scores = scores
        self.timestamp = timestamp
    }
}

struct Ranking: Hashable {
    let playerID: UUID
    let total: Int
}

struct Game: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var playerIDs: [UUID]
    var rounds: [Round]
    let createdAt: Date

    init(id: UUID = UUID(), name: String, playerIDs: [UUID], rounds: [Round] = [], createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.playerIDs = playerIDs
        self.rounds = rounds
        self.createdAt = createdAt
    }

    // MARK: - Computed Properties

    func totalScore(for playerID: UUID) -> Int {
        rounds.reduce(0) { $0 + ($1.scores[playerID] ?? 0) }
    }

    var totalScore: Int {
        rounds.reduce(0) { total, round in
            total + round.scores.values.reduce(0, +)
        }
    }

    var rankings: [Ranking] {
        playerIDs.map { Ranking(playerID: $0, total: totalScore(for: $0)) }
            .sorted { $0.total > $1.total }
    }

    var leader: UUID? {
        rankings.first?.playerID
    }
}

// MARK: - Game Store (ViewModel)

@MainActor
final class GameStore: ObservableObject {

    // MARK: Storage Keys
    private static let playersKey = "savedPlayers_v2"
    private static let gamesKey   = "savedGames_v2"

    // MARK: Published State

    @Published var players: [Player] = [] {
        didSet { persistPlayers() }
    }

    @Published var games: [Game] = [] {
        didSet { persistGames() }
    }

    // MARK: Init

    init() {
        loadPlayers()
        loadGames()
    }

    // MARK: - Player Actions

    func addPlayer(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        // Prevent duplicate names
        if !players.contains(where: { $0.name.lowercased() == trimmed.lowercased() }) {
            players.append(Player(name: trimmed))
        }
    }

    func deletePlayers(at offsets: IndexSet) {
        players.remove(atOffsets: offsets)
    }

    func player(for id: UUID) -> Player? {
        players.first { $0.id == id }
    }

    // MARK: - Game Actions

    func createGame(name: String, playerIDs: [UUID]) -> Game {
        let game = Game(name: name, playerIDs: playerIDs)
        games.append(game)
        return game
    }

    func deleteGames(at offsets: IndexSet) {
        games.remove(atOffsets: offsets)
    }

    func updateGame(_ updatedGame: Game) {
        if let index = games.firstIndex(where: { $0.id == updatedGame.id }) {
            games[index] = updatedGame
        }
    }

    // MARK: - Round Actions

    func addRound(to gameID: UUID, scores: [UUID: Int]) {
        guard let idx = games.firstIndex(where: { $0.id == gameID }) else { return }
        withAnimation {
            games[idx].rounds.append(Round(scores: scores))
        }
    }

    func deleteRounds(from gameID: UUID, at offsets: IndexSet) {
        guard let idx = games.firstIndex(where: { $0.id == gameID }) else { return }
        games[idx].rounds.remove(atOffsets: offsets)
    }

    func resetGame(_ gameID: UUID) {
        guard let idx = games.firstIndex(where: { $0.id == gameID }) else { return }
        games[idx].rounds.removeAll()
    }

    // MARK: - Persistence

    private func persistPlayers() {
        do {
            let data = try JSONEncoder().encode(players)
            UserDefaults.standard.set(data, forKey: Self.playersKey)
        } catch {
            print("Failed to encode players: \(error)")
        }
    }

    private func persistGames() {
        do {
            let data = try JSONEncoder().encode(games)
            UserDefaults.standard.set(data, forKey: Self.gamesKey)
        } catch {
            print("Failed to encode games: \(error)")
        }
    }

    private func loadPlayers() {
        guard
            let data = UserDefaults.standard.data(forKey: Self.playersKey),
            let decoded = try? JSONDecoder().decode([Player].self, from: data)
        else { return }
        players = decoded
    }

    private func loadGames() {
        guard
            let data = UserDefaults.standard.data(forKey: Self.gamesKey),
            let decoded = try? JSONDecoder().decode([Game].self, from: data)
        else { return }
        games = decoded
    }
}
