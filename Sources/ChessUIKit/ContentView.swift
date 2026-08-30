import SwiftUI
import ChessEngineKit

public struct ContentView: View {
    @StateObject private var vm = ChessViewModel()

    public init() {}

    public var body: some View {
        HStack(alignment: .top, spacing: 16) {
            BoardView(vm: vm)
            SidePanel(vm: vm)
        }
        .padding()
        .frame(minWidth: 720, minHeight: 600)
        .sheet(
            isPresented: Binding(
                get: { vm.isPromoting },
                set: { if !$0 { vm.cancelPromotion() } }
            )
        ) {
            PromotionChooser(vm: vm)
        }
    }
}

struct SidePanel: View {
    @ObservedObject var vm: ChessViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(vm.statusText)
                .font(.headline)
                .lineLimit(2)

            HStack {
                Text("Eval:").font(.subheadline)
                Text(vm.evalText())
                    .font(.system(.body, design: .monospaced))
            }

            Divider()

            Picker("Mode", selection: $vm.mode) {
                ForEach(GameMode.allCases) { m in
                    Text(m.rawValue).tag(m)
                }
            }
            .onChange(of: vm.mode) { _ in vm.reload() }

            if vm.mode == .humanVsAI {
                Picker("Play as", selection: $vm.humanColor) {
                    Text("White").tag(Side.white)
                    Text("Black").tag(Side.black)
                }
                .onChange(of: vm.humanColor) { _ in vm.reload() }
            }

            VStack(alignment: .leading) {
                Text("Depth: \(vm.depth)").font(.subheadline)
                Slider(
                    value: Binding(
                        get: { Double(vm.depth) },
                        set: { vm.depth = UInt8($0) }
                    ),
                    in: 1...6,
                    step: 1
                )
            }

            Divider()

            Picker("Board size", selection: $vm.boardSize) {
                ForEach(BoardSize.allCases) { s in
                    Text(s.rawValue).tag(s)
                }
            }

            Toggle("Show coordinates", isOn: $vm.showCoordinates)

            HStack {
                Button("New Game") { vm.reload() }
                Button(vm.thinking ? "Thinking…" : "AI Move") {
                    vm.requestAIMove()
                }
                .disabled(vm.thinking || !vm.canRequestAI)
            }

            Divider()

            Text("Moves").font(.subheadline)
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(vm.moveHistory.enumerated()), id: \.offset) { i, san in
                        Text("\(i + 1). \(san)")
                            .font(.system(.caption, design: .monospaced))
                    }
                }
            }
            .frame(maxHeight: 240)

            if vm.thinking {
                ProgressView()
            }
        }
        .frame(width: 260)
    }
}

struct PromotionChooser: View {
    @ObservedObject var vm: ChessViewModel

    var body: some View {
        VStack(spacing: 16) {
            Text("Promote to").font(.headline)
            HStack(spacing: 24) {
                PromotionButton(vm: vm, kind: .queen)
                PromotionButton(vm: vm, kind: .rook)
                PromotionButton(vm: vm, kind: .bishop)
                PromotionButton(vm: vm, kind: .knight)
            }
            Button("Cancel", action: vm.cancelPromotion)
        }
        .padding(24)
    }
}

struct PromotionButton: View {
    @ObservedObject var vm: ChessViewModel
    let kind: PieceKind

    var body: some View {
            Button(action: { vm.choosePromotion(kind) }) {
                let side = vm.state?.turn ?? .white
                PieceSymbol(kind: kind, side: side, size: 44)
            }
        .buttonStyle(PlainButtonStyle())
    }
}
