import SwiftUI
import ChessEngineKit

/// A chess piece rendered as a fully opaque, solid glyph. The fill is pure
/// white or black; a thin contrasting outline keeps white pieces legible on
/// light squares and black pieces on dark squares.
struct PieceSymbol: View {
    let glyph: String
    let side: Side
    let size: CGFloat

    var body: some View {
        let isWhite = side == .white
        ZStack {
            Text(glyph)
                .font(.system(size: size * 1.12))
                .foregroundColor(isWhite ? .black : .white)
            Text(glyph)
                .font(.system(size: size))
                .foregroundColor(isWhite ? .white : .black)
        }
    }
}

struct BoardView: View {
    @ObservedObject var vm: ChessViewModel

    var body: some View {
        VStack(spacing: 2) {
            ForEach(0..<8, id: \.self) { row in
                HStack(spacing: 2) {
                    ForEach(0..<8, id: \.self) { col in
                        let index = row * 8 + col
                        let sq = vm.displayOrder[index]
                        CellView(vm: vm, sq: sq)
                    }
                }
            }
        }
        .padding(8)
        .background(Color.black.opacity(0.85))
        .cornerRadius(10)
    }
}

struct CellView: View {
    @ObservedObject var vm: ChessViewModel
    let sq: UInt8

    var body: some View {
        let isLight = ((Int(sq) / 8) + (Int(sq) % 8)) % 2 == 1
        let base = isLight
            ? Color(red: 0.93, green: 0.87, blue: 0.73)
            : Color(red: 0.45, green: 0.32, blue: 0.22)
        let isSelected = vm.selected == sq
        let isLast = vm.lastFrom == sq || vm.lastTo == sq
        let isTarget = vm.legalTargets.contains { $0.toSquare == sq }
        let piece = vm.board[sq]
        let file = Int(sq) % 8
        let rank = Int(sq) / 8

        return Button(action: { vm.squareTapped(sq) }) {
            ZStack {
                Rectangle()
                    .fill(isSelected
                          ? Color.yellow.opacity(0.7)
                          : (isLast ? Color.blue.opacity(0.45) : base))
                if let (side, kind) = piece {
                    PieceSymbol(
                        glyph: vm.glyph(for: side, kind),
                        side: side,
                        size: vm.boardSize.font
                    )
                }
                if isTarget {
                    Circle()
                        .fill(Color.green.opacity(0.6))
                        .frame(width: 16, height: 16)
                }
                if vm.showCoordinates {
                    if rank == 0 {
                        Text(String(UnicodeScalar(97 + file)!))
                            .font(.system(size: 10))
                            .foregroundColor(isLight ? .black.opacity(0.6) : .white.opacity(0.75))
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                            .padding(3)
                    }
                    if file == 0 {
                        Text(String(rank + 1))
                            .font(.system(size: 10))
                            .foregroundColor(isLight ? .black.opacity(0.6) : .white.opacity(0.75))
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            .padding(3)
                    }
                }
            }
            .frame(width: vm.boardSize.cell, height: vm.boardSize.cell)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
