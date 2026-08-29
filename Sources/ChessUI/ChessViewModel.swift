import SwiftUI
import SwiftChess

enum GameMode: String, CaseIterable, Identifiable {
    case humanVsAI = "Human vs AI"
    case humanVsHuman = "Human vs Human"
    var id: String { rawValue }
}

@MainActor
class ChessViewModel: ObservableObject {
    @Published var board: [UInt8: (Side, PieceKind)] = [:]
    @Published var state: GameState?
    @Published var selected: UInt8?
    @Published var legalTargets: [MoveData] = []
    @Published var moveHistory: [String] = []
    @Published var statusText: String = ""
    @Published var thinking: Bool = false
    @Published var gameOver: Bool = false
    @Published var lastFrom: UInt8?
    @Published var lastTo: UInt8?

    @Published var mode: GameMode = .humanVsAI
    @Published var humanColor: Side = .white
    @Published var depth: UInt8 = 3

    // Squares in top-left -> bottom-right display order.
    let displayOrder: [UInt8]

    private let game = ChessGame()

    init() {
        var order: [UInt8] = []
        for r in 0..<8 {
            let rank = 7 - r
            for c in 0..<8 {
                order.append(UInt8(rank * 8 + c))
            }
        }
        displayOrder = order
        reload()
    }

    // MARK: - Game lifecycle

    func reload() {
        game.reset()
        selected = nil
        legalTargets = []
        moveHistory.removeAll()
        lastFrom = nil
        lastTo = nil
        thinking = false
        refresh()
        maybeAIMove()
    }

    func loadFen(_ fen: String) {
        try? game.loadFen(fen: fen)
        selected = nil
        legalTargets = []
        moveHistory.removeAll()
        lastFrom = nil
        lastTo = nil
        refresh()
        maybeAIMove()
    }

    private func refresh() {
        var map: [UInt8: (Side, PieceKind)] = [:]
        for cell in game.getCells() {
            if let side = cell.side, let kind = cell.kind {
                map[cell.square] = (side, kind)
            }
        }
        board = map
        state = game.getState()
        updateStatus()
    }

    private func updateStatus() {
        guard let s = state else { return }
        if s.isCheckmate {
            statusText = "Checkmate — \(s.turn == .white ? "Black" : "White") wins"
            gameOver = true
        } else if s.isStalemate {
            statusText = "Stalemate — draw"
            gameOver = true
        } else if s.isDraw {
            statusText = "Draw"
            gameOver = true
        } else if s.isInCheck {
            statusText = "\(s.turn == .white ? "White" : "Black") to move — CHECK"
            gameOver = false
        } else {
            statusText = "\(s.turn == .white ? "White" : "Black") to move"
            gameOver = false
        }
    }

    // MARK: - Interaction

    func squareTapped(_ sq: UInt8) {
        guard !thinking, !gameOver else { return }
        if mode == .humanVsAI, state?.turn != humanColor { return }

        if let sel = selected {
            if sel == sq {
                selected = nil
                legalTargets = []
                return
            }
            if let target = legalTargets.first(where: { $0.toSquare == sq }) {
                if target.promotion != nil {
                    // Promotion: surface a chooser with all promotion options.
                    legalTargets = legalTargets.filter { $0.toSquare == sq }
                    return
                }
                performMove(target)
                return
            }
            selectIfOwn(sq)
        } else {
            selectIfOwn(sq)
        }
    }

    private func selectIfOwn(_ sq: UInt8) {
        let moves = game.legalMoves()
        if moves.contains(where: { $0.fromSquare == sq }) {
            selected = sq
            legalTargets = moves.filter { $0.fromSquare == sq }
        } else {
            selected = nil
            legalTargets = []
        }
    }

    func choosePromotion(_ kind: PieceKind) {
        guard let target = legalTargets.first(where: { $0.promotion == kind }) else { return }
        performMove(target)
    }

    func cancelPromotion() {
        selected = nil
        legalTargets = []
    }

    var isPromoting: Bool {
        !legalTargets.isEmpty && legalTargets.allSatisfy { $0.promotion != nil }
    }

    var canRequestAI: Bool {
        if gameOver { return false }
        if mode == .humanVsHuman { return true }
        return state?.turn != humanColor
    }

    private func performMove(_ move: MoveData) {
        do {
            _ = try game.makeMove(
                fromSquare: move.fromSquare,
                toSquare: move.toSquare,
                promotion: move.promotion
            )
            moveHistory.append(move.san)
            lastFrom = move.fromSquare
            lastTo = move.toSquare
            selected = nil
            legalTargets = []
            refresh()
            maybeAIMove()
        } catch {
            // Move was illegal; ignore.
        }
    }

    // MARK: - AI

    func requestAIMove() {
        maybeAIMove(force: true)
    }

    private func maybeAIMove(force: Bool = false) {
        guard !gameOver else { return }
        if mode == .humanVsHuman, !force { return }
        guard let s = state else { return }
        let aiToMove: Bool
        if mode == .humanVsHuman {
            aiToMove = force
        } else {
            aiToMove = s.turn != humanColor
        }
        guard aiToMove else { return }

        thinking = true
        let game = self.game
        let depth = self.depth
        Task.detached(priority: .userInitiated) { [game, depth] in
            let mv = try? game.aiMove(depth: depth)
            await MainActor.run {
                self.thinking = false
                if let mv = mv {
                    self.moveHistory.append(mv.san)
                    self.lastFrom = mv.fromSquare
                    self.lastTo = mv.toSquare
                    self.refresh()
                    self.maybeAIMove()
                }
            }
        }
    }

    // MARK: - Display helpers

    func evalText() -> String {
        guard let s = state else { return "0.00" }
        let cp = s.evaluationCp
        let pawns = Double(cp) / 100.0
        if cp >= 0 {
            return String(format: "+%.2f", pawns)
        } else {
            return String(format: "%.2f", pawns)
        }
    }

    func glyph(for side: Side, _ kind: PieceKind) -> String {
        let white = ["♙", "♘", "♗", "♖", "♕", "♔"]
        let black = ["♟", "♞", "♝", "♜", "♛", "♚"]
        let idx = kindIndex(kind)
        return side == .white ? white[idx] : black[idx]
    }

    private func kindIndex(_ kind: PieceKind) -> Int {
        switch kind {
        case .pawn: return 0
        case .knight: return 1
        case .bishop: return 2
        case .rook: return 3
        case .queen: return 4
        case .king: return 5
        }
    }
}
