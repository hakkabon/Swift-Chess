import SwiftUI
import ChessEngineKit

/// A chess piece rendered from the vector asset catalog (`Assets.xcassets`).
/// Uses pre-colored PDFs (white/black) — no runtime tinting.
struct PieceSymbol: View {
    let kind: PieceKind
    let side: Side
    let size: CGFloat

    private var asset: String {
        let base: String
        switch kind {
        case .pawn: base = "piece_pawn"
        case .knight: base = "piece_knight"
        case .bishop: base = "piece_bishop"
        case .rook: base = "piece_rook"
        case .queen: base = "piece_queen"
        case .king: base = "piece_king"
        }
        // Expect separate image sets per color, e.g. "piece_pawn_white", "piece_pawn_black"
        let suffix = side == .white ? "_white" : "_black"
        return base + suffix
    }

    var body: some View {
        Image(asset, bundle: .module)
            .resizable()
            .interpolation(.high)
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
    }
}

struct BoardView: View {
    @ObservedObject var vm: ChessViewModel

    var body: some View {
        let cell = vm.boardSize.cell
        let step = cell + 2 // cell + inter-cell spacing

        return VStack(spacing: 0) {
            // Top spacer for alignment with left rank labels
            HStack(spacing: 0) {
                rankLabelsColumn(cell: cell, step: step)
                    .padding(.leading, 8) // match board's left padding
                boardGrid(cell: cell, step: step)
                    .padding(8)
                    .background(Color.black.opacity(0.85))
                    .cornerRadius(10)
            }
            // Bottom file labels
            fileLabelsRow(cell: cell, step: step)
                .padding(.leading, 8 + labelColumnWidth(cell)) // align with board
        }
        .overlay(
            // Floating piece that follows the finger during a drag.
            Group {
                if let drag = vm.dragPiece {
                    PieceSymbol(kind: drag.1, side: drag.0, size: cell * 0.75)
                        .position(x: vm.dragPoint.x + labelColumnWidth(cell) + 8,
                                  y: vm.dragPoint.y + 8)
                }
            }
        )
    }

    private func labelColumnWidth(_ cell: CGFloat) -> CGFloat {
        20 // fixed width for rank labels
    }

    @ViewBuilder
    private func rankLabelsColumn(cell: CGFloat, step: CGFloat) -> some View {
        VStack(spacing: 2) {
            ForEach(0..<8, id: \.self) { row in
                // displayOrder: row 0 = rank 8 (top), row 7 = rank 1 (bottom)
                let rank = 8 - row
                Text("\(rank)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary.opacity(0.7))
                    .frame(width: labelColumnWidth(cell), height: cell, alignment: .center)
            }
        }
    }

    @ViewBuilder
    private func fileLabelsRow(cell: CGFloat, step: CGFloat) -> some View {
        HStack(spacing: 2) {
            ForEach(0..<8, id: \.self) { col in
                let file = String(UnicodeScalar(97 + col)!)
                Text(file)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary.opacity(0.7))
                    .frame(width: cell, height: 20, alignment: .center)
            }
        }
    }

    @ViewBuilder
    private func boardGrid(cell: CGFloat, step: CGFloat) -> some View {
        VStack(spacing: 2) {
            ForEach(0..<8, id: \.self) { row in
                HStack(spacing: 2) {
                    ForEach(0..<8, id: \.self) { col in
                        let index = row * 8 + col
                        let sq = vm.displayOrder[index]
                        CellView(vm: vm, sq: sq, cell: cell, step: step, row: row, col: col)
                    }
                }
            }
        }
    }
}

struct CellView: View {
    @ObservedObject var vm: ChessViewModel
    let sq: UInt8
    let cell: CGFloat
    let step: CGFloat
    let row: Int
    let col: Int

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

        let drag = DragGesture(minimumDistance: 4)
            .onChanged { value in
                guard let p = piece, vm.canDrag(p.0) else { return }
                vm.beginDrag(
                    from: sq,
                    piece: p,
                    at: CGPoint(x: CGFloat(col) * step + value.location.x,
                                y: CGFloat(row) * step + value.location.y)
                )
            }
            .onEnded { value in
                guard let p = piece, vm.canDrag(p.0) else { return }
                let gx = CGFloat(col) * step + value.location.x
                let gy = CGFloat(row) * step + value.location.y
                let dc = min(max(Int((gx / step).rounded(.down)), 0), 7)
                let dr = min(max(Int((gy / step).rounded(.down)), 0), 7)
                let to = vm.displayOrder[dr * 8 + dc]
                vm.endDrag(to: to)
            }

        return ZStack {
            Rectangle()
                .fill(isSelected
                      ? Color.yellow.opacity(0.7)
                      : (isLast ? Color.blue.opacity(0.45) : base))
            if let (side, kind) = piece {
                PieceSymbol(kind: kind, side: side, size: cell * 0.75)
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
        .frame(width: cell, height: cell)
        .contentShape(Rectangle())
        .onTapGesture { vm.squareTapped(sq) }
        .gesture(drag)
    }
}
