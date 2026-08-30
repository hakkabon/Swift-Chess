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
        case .pawn: base = "pawn"
        case .knight: base = "knight"
        case .bishop: base = "bishop"
        case .rook: base = "rook"
        case .queen: base = "queen"
        case .king: base = "king"
        }
        // Expect separate image sets per color, e.g. "pawn_white", "pawn_black"
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
        let labelWidth = max(20, cell * 0.3) // scales with board size
        let labelFont = max(10, cell * 0.18)
        let fileLabelHeight = max(16, cell * 0.25)

        return VStack(spacing: 0) {
            // Top spacer for alignment with left rank labels
            HStack(spacing: 0) {
                if vm.showCoordinates {
                    rankLabelsColumn(cell: cell, step: step, labelWidth: labelWidth, labelFont: labelFont)
                        .padding(.leading, 8)
                }
                boardGrid(cell: cell, step: step)
                    .padding(8)
                    .background(Color.black.opacity(0.85))
                    .cornerRadius(10)
            }
            // Bottom file labels
            if vm.showCoordinates {
                fileLabelsRow(cell: cell, step: step, labelWidth: labelWidth, labelFont: labelFont, fileLabelHeight: fileLabelHeight)
                    .padding(.leading, 8 + labelWidth)
            }
        }
        .overlay(
            // Floating piece that follows the finger during a drag.
            Group {
                if let drag = vm.dragPiece {
                    PieceSymbol(kind: drag.1, side: drag.0, size: cell * 0.75)
                        .position(x: vm.dragPoint.x + (vm.showCoordinates ? labelWidth + 8 : 8),
                                  y: vm.dragPoint.y + 8)
                }
            }
        )
    }

    private func labelColumnWidth(_ cell: CGFloat) -> CGFloat {
        max(20, cell * 0.3)
    }

    @ViewBuilder
    private func rankLabelsColumn(cell: CGFloat, step: CGFloat, labelWidth: CGFloat, labelFont: CGFloat) -> some View {
        VStack(spacing: 2) {
            ForEach(0..<8, id: \.self) { row in
                let rank = 8 - row
                Text("\(rank)")
                    .font(.system(size: labelFont, weight: .medium))
                    .foregroundColor(.primary.opacity(0.7))
                    .frame(width: labelWidth, height: cell, alignment: .center)
            }
        }
    }

    @ViewBuilder
    private func fileLabelsRow(cell: CGFloat, step: CGFloat, labelWidth: CGFloat, labelFont: CGFloat, fileLabelHeight: CGFloat) -> some View {
        HStack(spacing: 2) {
            ForEach(0..<8, id: \.self) { col in
                let file = String(UnicodeScalar(97 + col)!)
                Text(file)
                    .font(.system(size: labelFont, weight: .medium))
                    .foregroundColor(.primary.opacity(0.7))
                    .frame(width: cell, height: fileLabelHeight, alignment: .center)
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
        }
        .frame(width: cell, height: cell)
        .contentShape(Rectangle())
        .onTapGesture { vm.squareTapped(sq) }
        .gesture(drag)
    }
}
