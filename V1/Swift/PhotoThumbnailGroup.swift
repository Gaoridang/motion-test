import SwiftUI

// MARK: - Data

struct PhotoItem: Identifiable, Equatable {
    let id: String
    let label: String
    let startColor: Color
    let endColor: Color
}

private let photos: [PhotoItem] = [
    PhotoItem(id: "a", label: "A", startColor: Color(red: 0.976, green: 0.451, blue: 0.086), endColor: Color(red: 0.918, green: 0.345, blue: 0.047)),
    PhotoItem(id: "b", label: "B", startColor: Color(red: 0.231, green: 0.510, blue: 0.965), endColor: Color(red: 0.114, green: 0.306, blue: 0.847)),
    PhotoItem(id: "c", label: "C", startColor: Color(red: 0.133, green: 0.773, blue: 0.369), endColor: Color(red: 0.082, green: 0.502, blue: 0.239)),
    PhotoItem(id: "d", label: "D", startColor: Color(red: 0.659, green: 0.333, blue: 0.969), endColor: Color(red: 0.494, green: 0.133, blue: 0.808)),
]

// MARK: - Layout constants (match V1 web)

private enum Layout {
    static let thumbSize: CGFloat = 72
    static let stackGap: CGFloat = 10
    static let rowGap: CGFloat = 12
    static let stackStep: CGFloat = thumbSize + stackGap      // 82
    static let slotWidth: CGFloat = thumbSize + rowGap        // 84
    static let cornerRadius: CGFloat = 12
    static let dividerMargin: CGFloat = 16
    static let maxGroupWidth: CGFloat = 360
}

// MARK: - Stack order (must match PhotoThumbnailGroup.tsx)

private func stackOrder(active: Int) -> [Int] {
    let count = photos.count
    let after = (0..<count).filter { $0 > active }.reversed()
    let before = (0..<count).filter { $0 < active }.reversed()
    return Array(after) + Array(before) + [active]
}

private func yOffset(stackPos: Int, count: Int) -> CGFloat {
    -CGFloat(count - 1 - stackPos) * Layout.stackStep
}

// MARK: - Thumbnail

private struct ThumbnailView: View {
    let photo: PhotoItem
    var dimmed = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [photo.startColor, photo.endColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.35), radius: 12, y: 8)

            Text(photo.label)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: Layout.thumbSize, height: Layout.thumbSize)
        .opacity(dimmed ? 0.45 : 1)
        .animation(.easeInOut(duration: 0.2), value: dimmed)
    }
}

// MARK: - Main view

struct PhotoThumbnailGroupView: View {
    @State private var activeIndex: Int? = nil

    private var order: [Int] {
        guard let active = activeIndex else { return [] }
        return stackOrder(active: active)
    }

    private var stackHeight: CGFloat {
        guard activeIndex != nil else { return 0 }
        return Layout.thumbSize + CGFloat(order.count - 1) * Layout.stackStep
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            VStack(spacing: 0) {
                stackZone
                divider
                horizontalRow
            }
            .frame(maxWidth: Layout.maxGroupWidth)
            .padding(.bottom, 32)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.059, green: 0.067, blue: 0.082))
    }

    // MARK: Stack zone

    private var stackZone: some View {
        ZStack(alignment: .bottomLeading) {
            if let active = activeIndex {
                ZStack(alignment: .bottomLeading) {
                    ForEach(Array(order.enumerated()), id: \.element) { stackPos, photoIndex in
                        let photo = photos[photoIndex]
                        let isActive = photoIndex == active
                        let y = yOffset(stackPos: stackPos, count: order.count)

                        ThumbnailView(photo: photo)
                            .scaleEffect(isActive ? 1.05 : 1)
                            .offset(y: y)
                            .zIndex(Double(stackPos))
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.88)),
                                removal: .opacity.combined(with: .scale(scale: 0.88))
                            ))
                            .animation(
                                .spring(response: 0.32, dampingFraction: 0.78)
                                    .delay(Double(stackPos) * 0.04),
                                value: activeIndex
                            )
                    }
                }
                .padding(.leading, CGFloat(active) * Layout.slotWidth)
                .transition(.opacity)
            }
        }
        .frame(height: stackHeight, alignment: .bottomLeading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipped()
        .animation(
            .timingCurve(0.22, 1.0, 0.36, 1.0, duration: 0.35),
            value: stackHeight
        )
    }

    // MARK: Divider

    private var divider: some View {
        LinearGradient(
            colors: [.clear, Color(white: 0.25), Color(white: 0.25), .clear],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(height: 1)
        .padding(.vertical, Layout.dividerMargin)
    }

    // MARK: Horizontal row

    private var horizontalRow: some View {
        HStack(spacing: Layout.rowGap) {
            ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                Button {
                    toggle(index)
                } label: {
                    ThumbnailView(photo: photo, dimmed: activeIndex == index)
                }
                .buttonStyle(ThumbButtonStyle())
                .accessibilityLabel("Spread photo \(photo.label)")
                .accessibilityAddTraits(activeIndex == index ? .isSelected : [])
            }
        }
    }

    // MARK: Actions

    private func toggle(_ index: Int) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
            if activeIndex == index {
                activeIndex = nil
            } else {
                activeIndex = index
            }
        }
    }
}

// MARK: - Button style

private struct ThumbButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - App shell (optional — or use in ContentView)

struct PhotoThumbnailGroupApp: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Photo Thumbnail Group")
                .font(.title3.weight(.semibold))

            Text("Tap a thumbnail to spread. Tap another to switch.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            PhotoThumbnailGroupView()
        }
        .padding(.top, 48)
        .preferredColorScheme(.dark)
    }
}

#Preview("Slots Motion") {
    PhotoThumbnailGroupApp()
}
