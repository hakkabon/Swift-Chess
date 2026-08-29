import Testing

struct Test {

    @Test func test_function_name() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
/*
        let game = ChessGame()
        try! game.loadFen(fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
        let state = game.getState()
        print("Turn:", state.turn, "Checkmate:", state.isCheckmate, "Eval:", state.evaluationCp)
        let moves = game.legalMoves()
        print("Legal moves from startpos:", moves.count)

        // Apply the first legal move via makeMove and confirm the board changes.
        let m0 = moves[0]
        let before = game.getCells()
        _ = try! game.makeMove(fromSquare: m0.fromSquare, toSquare: m0.toSquare, promotion: m0.promotion)
        let after = game.getCells()
        print("Applied \(m0.san); cells changed:", before != after)
        print("Legal moves now:", game.legalMoves().count)

        // aiMove applies the move internally and returns it; verify it was legal
        // against the position it was searched from.
        let legalBefore = game.legalMoves()
        let mv = try! game.aiMove(depth: 3)
        let playedLegal = legalBefore.contains {
            $0.fromSquare == mv.fromSquare &&
            $0.toSquare == mv.toSquare &&
            $0.promotion == mv.promotion
        }
        print("Engine move:", mv.san, "was legal:", playedLegal)

        // Play several AI moves from a fresh game to exercise search stability.
        let g2 = ChessGame()
        for _ in 0..<4 {
            let legalB = g2.legalMoves()
            let m = try! g2.aiMove(depth: 3)
            let ok = legalB.contains {
                $0.fromSquare == m.fromSquare &&
                $0.toSquare == m.toSquare &&
                $0.promotion == m.promotion
            }
            let s = g2.getState()
            print("Played", m.san, "legal?", ok, "checkmate?", s.isCheckmate)
        }

        print("SMOKE TEST OK")
*/
    }
}
