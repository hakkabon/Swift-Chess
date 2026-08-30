import SwiftUI
import ChessEngineKit
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// A chess piece rendered from the matching black or white PDF in
/// `Assets.xcassets`. The artwork supplies its own colors, so it must be loaded
/// using original rendering rather than being converted into a tinted template.
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
        // Image set names in the catalog: pawn-white, pawn-black, etc.
        return base + (side == .white ? "-white" : "-black")
    }

    private var pdfURL: URL? {
        let directory = "Assets.xcassets/\(asset).imageset"
        guard let resourceURL = Bundle.module.resourceURL,
              let files = try? FileManager.default.contentsOfDirectory(
                  at: resourceURL.appendingPathComponent(directory),
                  includingPropertiesForKeys: nil
              )
        else { return nil }
        return files.first { $0.pathExtension.lowercased() == "pdf" }
    }

    @ViewBuilder
    var body: some View {
        pieceImage
            .renderingMode(.original)
            .resizable()
            .interpolation(.high)
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
    }

    private var pieceImage: Image {
#if os(macOS)
        if let image = Bundle.module.image(forResource: NSImage.Name(asset)) {
            return Image(nsImage: image)
        }
        if let pdfURL, let image = NSImage(contentsOf: pdfURL) {
            return Image(nsImage: image)
        }
#else
        if let image = UIImage(named: asset, in: .module, compatibleWith: nil) {
            return Image(uiImage: image)
        }
        if let pdfURL, let image = UIImage(contentsOfFile: pdfURL.path) {
            return Image(uiImage: image)
        }
#endif
        // This also provides a useful missing-asset indicator in development.
        return Image(systemName: "questionmark.square.dashed")
    }
}

#if DEBUG
/// Preview-friendly piece symbol that falls back to Unicode glyphs when
/// `Bundle.module` is unavailable (e.g., in SwiftUI previews).
struct PreviewPieceSymbol: View {
    let kind: PieceKind
    let side: Side
    let size: CGFloat

    private var glyph: String {
        let solid = ["♟", "♞", "♝", "♜", "♛", "♚"]
        let idx: Int
        switch kind {
        case .pawn: idx = 0
        case .knight: idx = 1
        case .bishop: idx = 2
        case .rook: idx = 3
        case .queen: idx = 4
        case .king: idx = 5
        }
        return solid[idx]
    }

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
#endif

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
                rankLabelsColumn(cell: cell, step: step, labelWidth: labelWidth, labelFont: labelFont)
                    .padding(.leading, 8)
                    .opacity(vm.showCoordinates ? 1 : 0)
                    .frame(width: labelWidth, alignment: .center)
                boardGrid(cell: cell, step: step)
                    .padding(8)
                    .background(Color.black.opacity(0.85))
                    .cornerRadius(10)
            }
            // Bottom file labels
            fileLabelsRow(cell: cell, step: step, labelWidth: labelWidth, labelFont: labelFont, fileLabelHeight: fileLabelHeight)
                .padding(.leading, 8 + labelWidth)
                .opacity(vm.showCoordinates ? 1 : 0)
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
