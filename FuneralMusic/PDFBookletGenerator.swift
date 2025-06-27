// File: Utils/PDFBookletGenerator.swift

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
                y += 20
                dateFormatter.timeStyle = .short
                let timeStr = String(format: "%02d:%02d", info.timeHour, info.timeMinute)
                "\(dateFormatter.string(from: info.dateOfService)) at \(timeStr)".draw(in: CGRect(x: margin, y: y, width: pageWidth - 2*margin, height: 20), withAttributes: centeredAttrs())
                y += 20

                "Conducted by \(info.celebrantName)".draw(in: CGRect(x: margin, y: y, width: pageWidth - 2*margin, height: 20), withAttributes: centeredAttrs())

                // Service Items
                ctx.beginPage()
                y = margin

                for item in items {
                    let header = "• \(item.title) (\(item.type.rawValue.capitalized))"
                    let headerHeight: CGFloat = 20
                    let topPadding: CGFloat = 12
                    let bottomPadding: CGFloat = 20

                    if let htmlText = item.customText,
                       let data = htmlText.data(using: .utf8),
                       let attr = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil) {

                        let centeredStyle = NSMutableParagraphStyle()
                        centeredStyle.alignment = .center
                        let mutableAttr = NSMutableAttributedString(attributedString: attr)
                        mutableAttr.addAttribute(.paragraphStyle, value: centeredStyle, range: NSRange(location: 0, length: mutableAttr.length))

                        let framesetter = CTFramesetterCreateWithAttributedString(mutableAttr as CFAttributedString)
                        let suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, mutableAttr.length), nil, CGSize(width: pageWidth - 2*margin, height: .greatestFiniteMagnitude), nil)

                        if y + headerHeight + topPadding + suggestedSize.height > pageHeight - margin {
                            ctx.beginPage()
                            y = margin
                        }

                        header.draw(in: CGRect(x: margin, y: y, width: pageWidth - 2*margin, height: headerHeight), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 14), .paragraphStyle: centered()])
                        y += headerHeight + topPadding

                        var currentRange = CFRange(location: 0, length: 0)
                        while currentRange.location < mutableAttr.length {
                            let remaining = CFRange(location: currentRange.location, length: mutableAttr.length - currentRange.location)
                            let suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, remaining, nil, CGSize(width: pageWidth - 2*margin, height: pageHeight - y - margin), nil)

                            if y + suggestedSize.height > pageHeight - margin {
                                ctx.beginPage()
                                y = margin
                            }

                            let frameRect = CGRect(x: margin, y: y, width: pageWidth - 2*margin, height: suggestedSize.height)
                            let path = CGMutablePath()
                            path.addRect(frameRect)
                            let frame = CTFramesetterCreateFrame(framesetter, remaining, path, nil)

                            let ctxRef = UIGraphicsGetCurrentContext()!
                            ctxRef.saveGState()
                            ctxRef.textMatrix = .identity
                            ctxRef.translateBy(x: 0, y: pageHeight)
                            ctxRef.scaleBy(x: 1.0, y: -1.0)
                            CTFrameDraw(frame, ctxRef)
                            ctxRef.restoreGState()

                            let visibleRange = CTFrameGetVisibleStringRange(frame)
                            currentRange.location += visibleRange.length
                            y += suggestedSize.height + bottomPadding
                        }
                    }
                }

                // Wake & Donations
                ctx.beginPage()
                y = margin

                if let w = info.wakeLocation {
                    "You are invited to a reception at".draw(in: CGRect(x: margin, y: y, width: pageWidth - 2*margin, height: 20), withAttributes: paragraphAttrs())
                    y += 24
                    w.draw(in: CGRect(x: margin, y: y, width: pageWidth - 2*margin, height: 40), withAttributes: paragraphAttrs())
                    y += 50
                }

                if let d = info.donationInfo {
                    "Flowers or Donations can be sent to".draw(in: CGRect(x: margin, y: y, width: pageWidth - 2*margin, height: 20), withAttributes: paragraphAttrs())
                    y += 24
                    d.draw(in: CGRect(x: margin, y: y, width: pageWidth - 2*margin, height: 40), withAttributes: paragraphAttrs())
                }
            })

            return outputURL
        } catch {
            print("❌ Failed to generate PDF: \(error)")
            return nil
        }
    }

    private static func centered() -> NSMutableParagraphStyle {
        let p = NSMutableParagraphStyle()
        p.alignment = .center
        return p
    }

    private static func centeredAttrs() -> [NSAttributedString.Key: Any] {
        [.font: UIFont.systemFont(ofSize: 14), .paragraphStyle: centered()]
    }

    private static func paragraphAttrs() -> [NSAttributedString.Key: Any] {
        [.font: UIFont.systemFont(ofSize: 14), .paragraphStyle: centered()]
    }
}
