//import SwiftUI
//
//struct DetailsView: View {
//    let item: WallpaperItem
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            infoRow("Title", item.title)
//            infoRow("FileName", item.fileUrl.lastPathComponent)
//            infoRow("Resolution", item.resolution)
//            infoRow("File Size", String(format: "%.2f MB", Double(item.fileSize) / 1024 / 1024))
//            infoRow("Codec", item.codec)
//            infoRow("Duration", String(format: "%.2f s", item.duration))
//            infoRow("Created At", item.creationDate.formatted())
//        }
//        .padding()
//    }
//    
//    @ViewBuilder
//    private func infoRow(_ label: String, _ value: String) -> some View {
//        HStack {
//            Text("\(NSLocalizedString(label, comment: "")):").bold()
//            Text(value)
//        }
//    }
//}
//
//#Preview {
//    DetailsView(item: WallpaperItem(
//        id: UUID(),
//        title: "Sample Video",
//        fileUrl: URL(fileURLWithPath: "/test/test.mp4"),
//        resolution: "1920x1080",
//        fileSize: 123456,
//        codec: "H.264",
//        duration: 60.0,
//        creationDate: Date(),
//    ))
//    .frame(width:400, height: 260)
//}
