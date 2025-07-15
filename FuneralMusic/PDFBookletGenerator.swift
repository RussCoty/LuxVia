import UIKit
import CoreText

final class PDFBookletGenerator {

    static func generate(from info: BookletInfo, items: [ServiceItem]) -> URL? {
        let pdfMetaData: [String: Any] = [
            kCGPDFContextCreator as String: "Funeral Service App",
            kCGPDFContextAuthor as String: info.userName
        ]

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData

        let pageWidth: CGFloat = 420     // A5
        let pageHeight: CGFloat = 595
        let margin: CGFloat = 30

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), format: format)
        let fileName = "OrderOfService_\(UUID().uuidString.prefix(8)).pdf"
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try renderer.writePDF(to: outputURL, withActions: { ctx in
                var y: CGFloat = margin

                // Cover Page
                ctx.beginPage()

                if let photoData = info.photo, let image = UIImage(data: photoData) {
                    let maxWidth: CGFloat = pageWidth - 2 * margin
                    let aspectRatio = image.size.height / image.size.width
                    let imageHeight: CGFloat = maxWidth * aspectRatio
                    let imageRect = CGRect(x: margin, y: y, width: maxWidth, height: imageHeight)
                    image.draw(in: imageRect)
                    y += imageHeight + 20
                } else {
                    let placeholder = UIImage(systemName: "photo") ?? UIImage()
                    let rect = CGRect(x: (pageWidth - 100)/2, y: y, width: 100, height: 100)
                    placeholder.draw(in: rect)
                    y += 120
                }

                let titleAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 18), .paragraphStyle: centered()]
                "In Loving Memory of".draw(in: CGRect(x: margin, y: y, width: pageWidth - 2*margin, height: 24), withAttributes: titleAttrs)
                y += 30

                let nameAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 20, weight: .semibold), .paragraphStyle: centered()]
                info.deceasedName.draw(in: CGRect(x: margin, y: y, width: pageWidth - 2*margin, height: 26), withAttributes: nameAttrs)
                y += 28

                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                let dob = dateFormatter.string(from: info.dateOfBirth)
                let dop = dateFormatter.string(from: info.dateOfPassing)
                "\(dob) - \(dop)".draw(in: CGRect(x: margin, y: y, width: pageWidth - 2*margin, height: 20), withAttributes: centeredAttrs())
                y += 30

                info.location.draw(in: CGRect(x: margin, y: y, width: pageWidth - 2*margin, height: 20), withAttributes: centeredAttrs())
                y += 40

                // Service Items
                for item in items {
                    guard let htmlText = item.customText else { continue }

                    // Fix broken character encodings
                    let fixedString = htmlText
                        .replacingOccurrences(of: "â€™", with: "’")
                        .replacingOccurrences(of: "â€œ", with: "“")
                        .replacingOccurrences(of: "â€", with: "”")
                        .replacingOccurrences(of: "â€˜", with: "‘")
                        .replacingOccurrences(of: "â€“", with: "–")
                        .replacingOccurrences(of: "â€”", with: "—")
                        .replacingOccurrences(of: "â€¦", with: "…")

                    guard let data = fixedString.data(using: .utf8),
                          let attr = try? NSAttributedString(
                              data: data,
                              options: [.documentType: NSAttributedString.DocumentType.html],
                              documentAttributes: nil
                          ) else { continue }

                    let centeredStyle = NSMutableParagraphStyle()
                    centeredStyle.alignment = .center

                    let mutableAttr = NSMutableAttributedString(attributedString: attr)
                    mutableAttr.addAttribute(.paragraphStyle, value: centeredStyle, range: NSRange(location: 0, length: mutableAttr.length))

                    let framesetter = CTFramesetterCreateWithAttributedString(mutableAttr as CFAttributedString)
                    let suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(
                        framesetter,
                        CFRangeMake(0, mutableAttr.length),
                        nil,
                        CGSize(width: pageWidth - 2 * margin, height: .greatestFiniteMagnitude),
                        nil
                    )

                    let fits = y + suggestedSize.height <= pageHeight - margin

                    if !fits {
                        ctx.beginPage()

                        // Center vertically only if item takes whole page
                        let contentHeight = suggestedSize.height
                        let availableHeight = pageHeight - 2 * margin
                        y = (availableHeight - contentHeight) / 2 + margin
                    }


                    let textRect = CGRect(x: margin, y: y, width: pageWidth - 2 * margin, height: suggestedSize.height)
                    mutableAttr.draw(in: textRect)
                    y += suggestedSize.height + 20
                }

            })

            return outputURL
        } catch {
            print("❌ Failed to generate PDF: \(error)")
            return nil
        }
    }

    private static func centered() -> NSMutableParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        return style
    }

    private static func centeredAttrs() -> [NSAttributedString.Key: Any] {
        return [.font: UIFont.systemFont(ofSize: 16), .paragraphStyle: centered()]
    }
}
