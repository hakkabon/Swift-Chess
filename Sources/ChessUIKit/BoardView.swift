import SwiftUI
import ChessEngineKit

/// A chess piece rendered from the vector asset catalog (`Assets.xcassets`).
/// The artwork is a single-color silhouette; we tint it pure white or black and
/// draw a thin contrasting outline so pieces stay legible on both square colors
/// and remain fully opaque (no transparency).
struct PieceSymbol: View {
    let kind: PieceKind
    let side: Side
    let size: CGFloat

    private var asset: String {
        switch kind {
        case .pawn: return "piece_pawn"
        case .knight: return "piece_knight"
        case .bishop: return "piece_bishop"
        case .rook: return "piece_rook"
        case .queen: return "piece_queen"
        case .king: return "piece_king"
        }
    }

    var body: some View {
        let isWhite = side == .white
        ZStack {
            Image(asset, bundle: .module)
                .renderingMode(.template)
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
                .frame(width: size * 1.12, height: size * 1.12)
                .foregroundColor(isWhite ? .black : .white)
            Image(asset, bundle: .module)
                .renderingMode(.template)
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .foregroundColor(isWhite ? .white : .black)
        }
    }
}

struct BoardView: View {
    @ObservedObject var vm: ChessViewModel

    var body: some View {
        let cell = vm.boardSize.cell
        let step = cell + 2 // cell + inter-cell spacing

        return VStack(spacing: 2) {
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
        .padding(8)
        .background(Color.black.opacity(0.85))
        .cornerRadius(10)
        .overlay(
            // Floating piece that follows the finger during a drag.
            Group {
                if let drag = vm.dragPiece {
                    PieceSymbol(kind: drag.1, side: drag.0, size: cell * 0.75)
                        .position(x: vm.dragPoint.x, y: vm.dragPoint.y)
                }
            }
        )
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
