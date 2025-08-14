//
//  DetailsView.swift
//  CodeLume
//
//  Created by lyke on 2025/5/28.
//

import SwiftUI

struct DetailsView: View {
    let item: WallpaperItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            infoRow("Title", item.title)
            infoRow("File URL", item.fileUrl.path())
            infoRow("Resolution", item.resolution)
            infoRow("File Size", String(format: "%.2f MB", Double(item.fileSize) / 1024 / 1024))
            infoRow("Codec", item.codec)
            infoRow("Duration", String(format: "%.2f s", item.duration))
            infoRow("Created At", item.creationDate.formatted())
        }
        .padding()
    }
    
    @ViewBuilder
    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text("\(NSLocalizedString(label, comment: "")):").bold()
            Text(value)
        }
    }
}

//#Preview {
//    DetailsView(item: WallpaperItem(
//        id: UUID(),
//        title: "Sample Video",
//        filePath: "video/sample.mp4",
//        category: "Scenery",
//        resolution: "1920x1080",
//        fileSize: 123456,
//        codec: "H.264",
//        duration: 60.0,
//        creationDate: Date(),
//        tags: ["scenery", "HD"]
//    ))
//    .frame(width:400, height: 260)
//}
