import SwiftUI

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

        return Button(action: { vm.squareTapped(sq) }) {
            ZStack {
                Rectangle()
                    .fill(isSelected
                          ? Color.yellow.opacity(0.7)
                          : (isLast ? Color.blue.opacity(0.45) : base))
                if let (side, kind) = piece {
                    Text(vm.glyph(for: side, kind))
                        .font(.system(size: 34))
                        .foregroundColor(side == .white ? .white : .black)
                        .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
                }
                if isTarget {
                    Circle()
                        .fill(Color.green.opacity(0.6))
                        .frame(width: 16, height: 16)
                }
            }
            .frame(width: 52, height: 52)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
