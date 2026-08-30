import SwiftUI
import SwiftChess

enum GameMode: String, CaseIterable, Identifiable {
    case humanVsAI = "Human vs AI"
    case humanVsHuman = "Human vs Human"
    case computerVsComputer = "Computer vs Computer"
    var id: String { rawValue }
}

enum BoardSize: String, CaseIterable, Identifiable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"
    var id: String { rawValue }
    var cell: CGFloat {
        switch self {
        case .small: return 40
        case .medium: return 52
        case .large: return 68
        }
    }
    var font: CGFloat {
        switch self {
        case .small: return 26
        case .medium: return 34
        case .large: return 44
        }
    }
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
    @Published var boardSize: BoardSize = .medium
    @Published var showCoordinates: Bool = true

    // Transient state while a piece is being dragged.
    @Published var dragPiece: (Side, PieceKind)?
    @Published var dragPoint: CGPoint = .zero

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
        if mode == .computerVsComputer { return }

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
        if mode == .computerVsComputer { return true }
        return state?.turn != humanColor
    }

    // MARK: - Drag & drop

    /// Whether the given side's piece may be picked up and dragged by the user.
    func canDrag(_ side: Side) -> Bool {
        guard !thinking, !gameOver, let s = state else { return false }
        if mode == .computerVsComputer { return false }
        if mode == .humanVsAI, s.turn != humanColor { return false }
        return side == s.turn
    }

    func beginDrag(from: UInt8, piece: (Side, PieceKind), at point: CGPoint) {
        guard canDrag(piece.0) else { return }
        selected = from
        legalTargets = []
        dragPiece = piece
        dragPoint = point
    }

    func endDrag(to: UInt8) {
        let from = selected
        dragPiece = nil
        selected = nil
        legalTargets = []
        guard let from = from else { return }
        if to != from {
            tryMove(from: from, to: to)
        }
    }

    /// Attempt a move from `from` to `to` (used by drag & drop). Illegal or
    /// non-feasible moves are ignored; promotions surface the chooser.
    func tryMove(from: UInt8, to: UInt8) {
        guard !thinking, !gameOver else { return }
        guard let s = state else { return }
        if mode == .computerVsComputer { return }
        if mode == .humanVsAI, s.turn != humanColor { return }
        guard let piece = board[from], piece.0 == s.turn else { return }
        guard let target = game.legalMoves()
            .first(where: { $0.fromSquare == from && $0.toSquare == to })
        else { return }

        selected = nil
        legalTargets = []
        if target.promotion != nil {
            // Defer to the promotion sheet for the destination square.
            selected = from
            legalTargets = game.legalMoves()
                .filter { $0.fromSquare == from && $0.toSquare == to }
        } else {
            performMove(target)
        }
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
        switch mode {
        case .humanVsHuman:
            aiToMove = force
        case .humanVsAI:
            aiToMove = s.turn != humanColor
        case .computerVsComputer:
            aiToMove = true
        }
        guard aiToMove else { return }

        thinking = true
        let game = self.game
        let depth = self.depth
        let isCvC = (mode == .computerVsComputer)
        Task.detached(priority: .userInitiated) { [game, depth, isCvC] in
            // In Computer vs Computer give the viewer a beat between plies.
            if isCvC {
                try? await Task.sleep(nanoseconds: 350_000_000)
            }
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
}
