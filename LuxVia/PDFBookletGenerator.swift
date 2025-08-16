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
                var pageIndex = 0
                let borderInsetX = pageWidth * 0.10
                let borderInsetY = pageHeight * 0.10
                let contentWidth = pageWidth - 2 * borderInsetX
                var y: CGFloat = margin

                // Cover Page
                ctx.beginPage()
                pageIndex += 1

                // Image settings
                let maxImageWidth: CGFloat = pageWidth - 2 * margin
                let maxImageHeight: CGFloat = 180 // You can adjust this as needed

                if let photoData = info.photo, let image = UIImage(data: photoData) {
                    // Calculate aspect ratio and fit image within maxImageWidth and maxImageHeight
                    let aspectRatio = image.size.width > 0 ? image.size.height / image.size.width : 1.0
                    var imageWidth = maxImageWidth
                    var imageHeight = imageWidth * aspectRatio
                    if imageHeight > maxImageHeight {
                        imageHeight = maxImageHeight
                        imageWidth = imageHeight / aspectRatio
                    }
                    // Center horizontally using pageWidth, not margin
                    let imageX = (pageWidth - imageWidth) / 2
                    let imageRect = CGRect(x: imageX, y: y, width: imageWidth, height: imageHeight)
                    image.draw(in: imageRect)
                    y += imageHeight + 20
                } else {
                    // Placeholder image centered
                    let placeholderSize: CGFloat = 100
                    let imageX = (pageWidth - placeholderSize) / 2
                    let rect = CGRect(x: imageX, y: y, width: placeholderSize, height: placeholderSize)
                    let placeholder = UIImage(systemName: "photo") ?? UIImage()
                    placeholder.draw(in: rect)
                    y += placeholderSize + 20
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
                        CGSize(width: contentWidth - 20, height: .greatestFiniteMagnitude),
                        nil
                    )

                    let fits = y + suggestedSize.height <= pageHeight - borderInsetY - 10

                    if !fits {
                        ctx.beginPage()
                        pageIndex += 1
                        // Draw border on all pages except page 1
                        if pageIndex > 1 {
                            let borderRect = CGRect(x: borderInsetX, y: borderInsetY, width: pageWidth - 2 * borderInsetX, height: pageHeight - 2 * borderInsetY)
                            ctx.cgContext.setStrokeColor(UIColor.gray.cgColor)
                            ctx.cgContext.setLineWidth(1)
                            ctx.cgContext.stroke(borderRect)
                            y = borderInsetY + 10
                        } else {
                            y = margin
                        }
                    }

                    let textRect: CGRect
                    if pageIndex > 1 {
                        textRect = CGRect(x: borderInsetX + 10, y: y, width: contentWidth - 20, height: suggestedSize.height)
                    } else {
                        textRect = CGRect(x: margin, y: y, width: pageWidth - 2 * margin, height: suggestedSize.height)
                    }
                    mutableAttr.draw(in: textRect)
                    y += suggestedSize.height + 20
                }

                // --- ADDITION: Final page with other details ---
                ctx.beginPage()
                pageIndex += 1
                // Draw border on all pages except page 1
                if pageIndex > 1 {
                    let borderRect = CGRect(x: borderInsetX, y: borderInsetY, width: pageWidth - 2 * borderInsetX, height: pageHeight - 2 * borderInsetY)
                    ctx.cgContext.setStrokeColor(UIColor.gray.cgColor)
                    ctx.cgContext.setLineWidth(1)
                    ctx.cgContext.stroke(borderRect)
                    y = borderInsetY + 10
                } else {
                    y = margin
                }

                let sectionTitleAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 16),
                    .paragraphStyle: centered()
                ]
                let detailAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 14),
                    .paragraphStyle: centered()
                ]

                // Committal Location
                if let committal = info.committalLocation, !committal.isEmpty {
                    "Committal Location".draw(in: CGRect(x: borderInsetX + 10, y: y, width: contentWidth - 20, height: 20), withAttributes: sectionTitleAttrs)
                    y += 22
                    committal.draw(in: CGRect(x: borderInsetX + 10, y: y, width: contentWidth - 20, height: 18), withAttributes: detailAttrs)
                    y += 26
                }

                // Wake/Reception Location
                if let wake = info.wakeLocation, !wake.isEmpty {
                    "Wake/Reception Location".draw(in: CGRect(x: borderInsetX + 10, y: y, width: contentWidth - 20, height: 20), withAttributes: sectionTitleAttrs)
                    y += 22
                    wake.draw(in: CGRect(x: borderInsetX + 10, y: y, width: contentWidth - 20, height: 18), withAttributes: detailAttrs)
                    y += 26
                }

                // Donation/Flower Instructions
                if let donation = info.donationInfo, !donation.isEmpty {
                    "Donation/Flower Instructions".draw(in: CGRect(x: borderInsetX + 10, y: y, width: contentWidth - 20, height: 20), withAttributes: sectionTitleAttrs)
                    y += 22
                    donation.draw(in: CGRect(x: borderInsetX + 10, y: y, width: contentWidth - 20, height: 40), withAttributes: detailAttrs)
                    y += 48
                }

                // Photographer Name
                if let photographer = info.photographer, !photographer.isEmpty {
                    "Photographer".draw(in: CGRect(x: borderInsetX + 10, y: y, width: contentWidth - 20, height: 20), withAttributes: sectionTitleAttrs)
                    y += 22
                    photographer.draw(in: CGRect(x: borderInsetX + 10, y: y, width: contentWidth - 20, height: 18), withAttributes: detailAttrs)
                    y += 26
                }

                // Pallbearers
                if let pallbearers = info.pallbearers, !pallbearers.isEmpty {
                    "Pallbearers".draw(in: CGRect(x: borderInsetX + 10, y: y, width: contentWidth - 20, height: 20), withAttributes: sectionTitleAttrs)
                    y += 22
                    pallbearers.draw(in: CGRect(x: borderInsetX + 10, y: y, width: contentWidth - 20, height: 18), withAttributes: detailAttrs)
                    y += 26
                }
                // --- END ADDITION ---

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