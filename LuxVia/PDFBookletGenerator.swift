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

                // Calculate total height of cover content
                let maxImageWidth: CGFloat = pageWidth - 2 * margin
                let maxImageHeight: CGFloat = 180
                var imageHeight: CGFloat = 0
                var imageWidth: CGFloat = 0
                var imageBlockHeight: CGFloat = 0
                if let photoData = info.photo, let image = UIImage(data: photoData) {
                    let aspectRatio = image.size.width > 0 ? image.size.height / image.size.width : 1.0
                    imageWidth = maxImageWidth
                    imageHeight = imageWidth * aspectRatio
                    if imageHeight > maxImageHeight {
                        imageHeight = maxImageHeight
                        imageWidth = imageHeight / aspectRatio
                    }
                    imageBlockHeight = imageHeight + 20
                } else {
                    imageBlockHeight = 100 + 20
                }
                let titleBlockHeight: CGFloat = 24 + 30
                let nameBlockHeight: CGFloat = 26 + 28
                let dateBlockHeight: CGFloat = 20 + 30
                let locationBlockHeight: CGFloat = 20 + 40
                let totalCoverHeight = imageBlockHeight + titleBlockHeight + nameBlockHeight + dateBlockHeight + locationBlockHeight
                let startY = (pageHeight - totalCoverHeight) / 2
                y = startY

                // Draw image
                if let photoData = info.photo, let image = UIImage(data: photoData) {
                    let aspectRatio = image.size.width > 0 ? image.size.height / image.size.width : 1.0
                    imageWidth = maxImageWidth
                    imageHeight = imageWidth * aspectRatio
                    if imageHeight > maxImageHeight {
                        imageHeight = maxImageHeight
                        imageWidth = imageHeight / aspectRatio
                    }
                    let imageX = (pageWidth - imageWidth) / 2
                    let imageRect = CGRect(x: imageX, y: y, width: imageWidth, height: imageHeight)
                    image.draw(in: imageRect)
                    y += imageHeight + 20
                } else {
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

                // Service Items: Always start readings/lyrics on page 2
                // Prepare attributed strings for all readings/lyrics
                var readingAttrs: [NSAttributedString] = []
                for item in items {
                    guard let htmlText = item.customText else { continue }
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
                    readingAttrs.append(mutableAttr)
                }

                // Paginate readings/lyrics (never on page 1)
                var pageContents: [[NSAttributedString]] = []
                var pageHeights: [CGFloat] = []
                var currentPage: [NSAttributedString] = []
                var currentHeight: CGFloat = 0
                let maxContentHeight = pageHeight - 2 * borderInsetY - 20
                for mutableAttr in readingAttrs {
                    let framesetter = CTFramesetterCreateWithAttributedString(mutableAttr as CFAttributedString)
                    let suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(
                        framesetter,
                        CFRangeMake(0, mutableAttr.length),
                        nil,
                        CGSize(width: contentWidth - 20, height: .greatestFiniteMagnitude),
                        nil
                    )
                    let itemHeight = suggestedSize.height + 20
                    if currentHeight + itemHeight > maxContentHeight && currentHeight > 0 {
                        pageHeights.append(currentHeight)
                        pageContents.append(currentPage)
                        currentPage = []
                        currentHeight = 0
                    }
                    currentPage.append(mutableAttr)
                    currentHeight += itemHeight
                }
                if !currentPage.isEmpty {
                    pageHeights.append(currentHeight)
                    pageContents.append(currentPage)
                }

                // Render each readings/lyrics page (starting at page 2)
                for i in 0..<pageContents.count {
                    ctx.beginPage()
                    pageIndex += 1
                    // Draw border on all pages except page 1
                    if pageIndex > 1 {
                        let borderRect = CGRect(x: borderInsetX, y: borderInsetY, width: pageWidth - 2 * borderInsetX, height: pageHeight - 2 * borderInsetY)
                        ctx.cgContext.setStrokeColor(UIColor.gray.cgColor)
                        ctx.cgContext.setLineWidth(1)
                        ctx.cgContext.stroke(borderRect)
                    }
                    let pageContent = pageContents[i]
                    let totalHeight = pageHeights[i]
                    let startY: CGFloat = (pageIndex > 1)
                        ? borderInsetY + 10 + (maxContentHeight - totalHeight) / 2
                        : margin
                    var y = startY
                    for mutableAttr in pageContent {
                        let framesetter = CTFramesetterCreateWithAttributedString(mutableAttr as CFAttributedString)
                        let suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(
                            framesetter,
                            CFRangeMake(0, mutableAttr.length),
                            nil,
                            CGSize(width: contentWidth - 20, height: .greatestFiniteMagnitude),
                            nil
                        )
                        let textRect: CGRect
                        if pageIndex > 1 {
                            textRect = CGRect(x: borderInsetX + 10, y: y, width: contentWidth - 20, height: suggestedSize.height)
                        } else {
                            textRect = CGRect(x: margin, y: y, width: pageWidth - 2 * margin, height: suggestedSize.height)
                        }
                        mutableAttr.draw(in: textRect)
                        y += suggestedSize.height + 20
                    }
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
                }

                let sectionTitleAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 16),
                    .paragraphStyle: centered()
                ]
                let detailAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 14),
                    .paragraphStyle: centered()
                ]

                // Collect all last page content and measure total height
                var lastPageBlocks: [(String, CGRect, [NSAttributedString.Key: Any], CGFloat)] = []
                var lastPageHeight: CGFloat = 0
                let blockWidth = contentWidth - 20
                if let committal = info.committalLocation, !committal.isEmpty {
                    lastPageBlocks.append(("Committal Location", CGRect.zero, sectionTitleAttrs, 20))
                    lastPageBlocks.append((committal, CGRect.zero, detailAttrs, 18))
                }
                if let wake = info.wakeLocation, !wake.isEmpty {
                    lastPageBlocks.append(("Wake/Reception Location", CGRect.zero, sectionTitleAttrs, 20))
                    lastPageBlocks.append((wake, CGRect.zero, detailAttrs, 18))
                }
                if let donation = info.donationInfo, !donation.isEmpty {
                    lastPageBlocks.append(("Donation/Flower Instructions", CGRect.zero, sectionTitleAttrs, 20))
                    lastPageBlocks.append((donation, CGRect.zero, detailAttrs, 40))
                }
                if let photographer = info.photographer, !photographer.isEmpty {
                    lastPageBlocks.append(("Photographer", CGRect.zero, sectionTitleAttrs, 20))
                    lastPageBlocks.append((photographer, CGRect.zero, detailAttrs, 18))
                }
                if let pallbearers = info.pallbearers, !pallbearers.isEmpty {
                    lastPageBlocks.append(("Pallbearers", CGRect.zero, sectionTitleAttrs, 20))
                    lastPageBlocks.append((pallbearers, CGRect.zero, detailAttrs, 18))
                }
                // Calculate total height
                for (_, _, _, h) in lastPageBlocks {
                    lastPageHeight += h + 6 // 6pt spacing between blocks
                }
                if lastPageHeight > 0 { lastPageHeight -= 6 } // Remove last spacing
                let lastPageStartY = borderInsetY + 10 + ((pageHeight - 2 * borderInsetY - 20) - lastPageHeight) / 2
                y = lastPageStartY
                for (text, _, attrs, h) in lastPageBlocks {
                    let rect = CGRect(x: borderInsetX + 10, y: y, width: blockWidth, height: h)
                    (text as NSString).draw(in: rect, withAttributes: attrs)
                    y += h + 6
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