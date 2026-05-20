//
//  QRCode.swift
//  CorePresentation
//
//  Created by Nicolas Bouème on 20/05/2026.
//

import CoreImage.CIFilterBuiltins
import SwiftUI
import UIKit

public struct QRCode: View {
    private let content: String
    private let size: CGFloat

    public init(from content: String, size: CGFloat = 200) {
        self.content = content
        self.size = size
    }

    public var body: some View {
        if let image = Self.makeImage(from: content) {
            image
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .padding(12)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private static func makeImage(from string: String) -> Image? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        guard
            let outputImage = filter.outputImage,
            let cgImage = context.createCGImage(outputImage, from: outputImage.extent)
        else { return nil }
        return Image(uiImage: UIImage(cgImage: cgImage))
    }
}

#Preview {
    VStack(spacing: 16) {
        QRCode(from: "7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU")
        QRCode(from: "DezXAZ8z7PnrnRJjz3wXBoRgixCa6xjnB7YaB1pPB263", size: 120)
    }
    .padding()
    .background(Color.deepIndigo)
}
