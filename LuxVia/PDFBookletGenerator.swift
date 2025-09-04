import UIKit
import CoreText

final class PDFBookletGenerator {

    // MARK: - Types (defined at file scope to help compiler)
    private enum BlockKind { case image, text, gap }
    private struct Block { let kind: BlockKind; let height: CGFloat; let text: String?; let attrs: [NSAttributedString.Key: Any]? }
    private struct CoverLayout {
        let blocks: [Block]
        let image: UIImage?
        let imageSize: CGSize
        let totalHeight: CGFloat
    }

    // MARK: - Public API
    static func generate(from info: BookletInfo, items: [ServiceItem]) -> URL? {
        // Keep these simple to avoid heavy type inference
        let pdfMetaData: [String: Any] = [
            kCGPDFContextCreator as String: "Funeral Service App",
            kCGPDFContextAuthor as String: info.userName
        ]
        let format = UIGraphicsPDFRendererFormat(); format.documentInfo = pdfMetaData

        let pageWidth: CGFloat = 420     // A5
        let pageHeight: CGFloat = 595
        let margin: CGFloat = 30

        let rendererBounds = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: rendererBounds, format: format)

        let fileName = "OrderOfService_\(UUID().uuidString.prefix(8)).pdf"
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try renderer.writePDF(to: outputURL, withActions: { ctx in
                var pageIndex = 0
                let borderInsetX = pageWidth * 0.10
                let borderInsetY = pageHeight * 0.10

                // Page 1 — Cover
                ctx.beginPage(); pageIndex += 1
                Self.drawCover(ctx: ctx, info: info, pageWidth: pageWidth, pageHeight: pageHeight, margin: margin)

                // Readings/Lyrics pages
                let readings = Self.prepareReadingAttributedStrings(from: items)
                let pagination = Self.paginate(readings: readings, pageWidth: pageWidth, pageHeight: pageHeight, borderInsetX: borderInsetX, borderInsetY: borderInsetY)
                Self.drawReadingPages(ctx: ctx,
                                      pages: pagination.pages,
                                      heights: pagination.heights,
                                      pageWidth: pageWidth,
                                      pageHeight: pageHeight,
                                      borderInsetX: borderInsetX,
                                      borderInsetY: borderInsetY,
                                      startPageIndex: &pageIndex)

                // Final details page
                Self.drawFinalDetailsPage(ctx: ctx,
                                          info: info,
                                          pageWidth: pageWidth,
                                          pageHeight: pageHeight,
                                          borderInsetX: borderInsetX,
                                          borderInsetY: borderInsetY,
                                          startPageIndex: &pageIndex)
            })
            return outputURL
        } catch {
            print("❌ Failed to generate PDF: \(error)")
            return nil
        }
    }

    // MARK: - Cover
    private static func drawCover(ctx: UIGraphicsPDFRendererContext, info: BookletInfo, pageWidth: CGFloat, pageHeight: CGFloat, margin: CGFloat) {
        let titleAttrs = attrs(font: .boldSystemFont(ofSize: 18))
        let nameAttrs  = attrs(font: .systemFont(ofSize: 20, weight: .semibold))
        let bodyAttrs  = attrs(font: .systemFont(ofSize: 16))

        // Derived strings
        let dateFmt = DateFormatter(); dateFmt.dateStyle = .medium
        let dob = dateFmt.string(from: info.dateOfBirth)
        let dop = dateFmt.string(from: info.dateOfPassing)
        let dateRange = "\(dob) - \(dop)"
        let serviceDateStr = dateFmt.string(from: info.dateOfService)
        var comps = DateComponents(); comps.hour = info.timeHour; comps.minute = info.timeMinute
        let timeFmt = DateFormatter(); timeFmt.timeStyle = .short
        let timeDate = Calendar.current.date(from: comps) ?? info.dateOfService
        let serviceLine = "\(serviceDateStr) at \(timeFmt.string(from: timeDate))"
        let hasCelebrant = !info.celebrantName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        // Make layout (measured)
        let cover = makeCoverLayout(
            imageData: info.photo,
            pageWidth: pageWidth,
            pageHeight: pageHeight,
            margin: margin,
            title: "In Loving Memory of",
            titleAttrs: titleAttrs,
            name: info.deceasedName,
            nameAttrs: nameAttrs,
            dateRange: dateRange,
            bodyAttrs: bodyAttrs,
            location: info.location,
            serviceLine: serviceLine,
            celebrant: hasCelebrant ? "Officiant: \(info.celebrantName)" : nil
        )

        // Start Y (clamped to margin)
        var y = max(margin, (pageHeight - cover.totalHeight) / 2)

        // Draw blocks in order
        for b in cover.blocks {
            switch b.kind {
            case .gap:
                y += b.height
            case .text:
                let rect = CGRect(x: margin, y: y, width: pageWidth - 2*margin, height: b.height)
                (b.text! as NSString).draw(in: rect, withAttributes: b.attrs)
                y += b.height
            case .image:
                if let img = cover.image {
                    let x = (pageWidth - cover.imageSize.width) / 2
                    let rect = CGRect(x: x, y: y, width: cover.imageSize.width, height: cover.imageSize.height)
                    img.draw(in: rect)
                } else {
                    let size = min(cover.imageSize.width, cover.imageSize.height)
                    let x = (pageWidth - size) / 2
                    let rect = CGRect(x: x, y: y, width: size, height: size)
                    (UIImage(systemName: "photo") ?? UIImage()).draw(in: rect)
                }
                y += b.height
            }
        }
    }

    private static func makeCoverLayout(
        imageData: Data?,
        pageWidth: CGFloat,
        pageHeight: CGFloat,
        margin: CGFloat,
        title: String,
        titleAttrs: [NSAttributedString.Key: Any],
        name: String,
        nameAttrs: [NSAttributedString.Key: Any],
        dateRange: String,
        bodyAttrs: [NSAttributedString.Key: Any],
        location: String,
        serviceLine: String,
        celebrant: String?
    ) -> CoverLayout {
        // Image sizing
        let maxImageWidth: CGFloat = pageWidth - 2 * margin
        let maxImageHeight: CGFloat = 180
        var coverImage: UIImage? = nil
        var imageSize = CGSize(width: 100, height: 100) // placeholder default
        if let data = imageData, let img = UIImage(data: data) {
            coverImage = img
            let aspect = img.size.width > 0 ? img.size.height / img.size.width : 1
            var w = maxImageWidth
            var h = w * aspect
            if h > maxImageHeight { h = maxImageHeight; w = h / aspect }
            imageSize = CGSize(width: w, height: h)
        }

        // Spacing constants
        let sAfterImage: CGFloat = 20
        let sAfterTitle: CGFloat = 30
        let sAfterName: CGFloat = 28
        let sAfterDates: CGFloat = 30
        let sAboveLocation: CGFloat = 28
        let sAfterLocation: CGFloat = 24
        let sAfterService: CGFloat = 22

        // Measurements
        let textWidth = pageWidth - 2*margin
        let titleH = measuredHeight(for: title, attrs: titleAttrs, width: textWidth)
        let nameH  = measuredHeight(for: name, attrs: nameAttrs, width: textWidth)
        let datesH = measuredHeight(for: dateRange, attrs: bodyAttrs, width: textWidth)
        let locH   = measuredHeight(for: location, attrs: bodyAttrs, width: textWidth)
        let svcH   = measuredHeight(for: serviceLine, attrs: bodyAttrs, width: textWidth)
        let celH   = celebrant != nil ? measuredHeight(for: celebrant!, attrs: bodyAttrs, width: textWidth) : 0

        // Build blocks (explicit types to help compiler)
        var blocks: [Block] = []
        blocks.append(Block(kind: .image, height: imageSize.height, text: nil, attrs: nil))
        blocks.append(Block(kind: .gap, height: sAfterImage, text: nil, attrs: nil))

        blocks.append(Block(kind: .text, height: titleH, text: title, attrs: titleAttrs))
        blocks.append(Block(kind: .gap, height: sAfterTitle, text: nil, attrs: nil))

        blocks.append(Block(kind: .text, height: nameH, text: name, attrs: nameAttrs))
        blocks.append(Block(kind: .gap, height: sAfterName, text: nil, attrs: nil))

        blocks.append(Block(kind: .text, height: datesH, text: dateRange, attrs: bodyAttrs))
        blocks.append(Block(kind: .gap, height: sAfterDates, text: nil, attrs: nil))

        blocks.append(Block(kind: .gap, height: sAboveLocation, text: nil, attrs: nil))
        blocks.append(Block(kind: .text, height: locH, text: location, attrs: bodyAttrs))
        blocks.append(Block(kind: .gap, height: sAfterLocation, text: nil, attrs: nil))

        blocks.append(Block(kind: .text, height: svcH, text: serviceLine, attrs: bodyAttrs))
        if let cel = celebrant {
            blocks.append(Block(kind: .gap, height: sAfterService, text: nil, attrs: nil))
            blocks.append(Block(kind: .text, height: celH, text: cel, attrs: bodyAttrs))
        }

        // Sum heights without using reduce (keeps type-checker happy)
        var total: CGFloat = 0
        for b in blocks { total += b.height }

        return CoverLayout(blocks: blocks, image: coverImage, imageSize: imageSize, totalHeight: total)
    }

    // MARK: - Readings preparation & pagination
    private static func prepareReadingAttributedStrings(from items: [ServiceItem]) -> [NSAttributedString] {
        var result: [(title: NSAttributedString, content: NSAttributedString)] = []
        for item in items {
            let title = item.title.trimmingCharacters(in: .whitespacesAndNewlines)
            var titleString: NSAttributedString? = nil
            if !title.isEmpty {
                let titleAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 13),
                    .paragraphStyle: centeredParagraphStyle()
                ]
                titleString = NSAttributedString(string: title + "\n", attributes: titleAttrs)
            }

            guard let htmlText = item.customText else { continue }
            let fixed = htmlText
                .replacingOccurrences(of: "â€™", with: "’")
                .replacingOccurrences(of: "â€œ", with: "“")
                .replacingOccurrences(of: "â€", with: "”")
                .replacingOccurrences(of: "â€˜", with: "‘")
                .replacingOccurrences(of: "â€“", with: "–")
                .replacingOccurrences(of: "â€”", with: "—")
                .replacingOccurrences(of: "â€¦", with: "…")
            guard let data = fixed.data(using: .utf8) else { continue }
            if let attr = try? NSAttributedString(
                data: data,
                options: [.documentType: NSAttributedString.DocumentType.html],
                documentAttributes: nil
            ) {
                let style = NSMutableParagraphStyle(); style.alignment = .center
                let mutable = NSMutableAttributedString(attributedString: attr)
                mutable.addAttribute(.paragraphStyle, value: style, range: NSRange(location: 0, length: mutable.length))
                if let titleString = titleString {
                    result.append((title: titleString, content: mutable))
                } else {
                    result.append((title: NSAttributedString(string: ""), content: mutable))
                }
            }
        }
        // Flatten to array of NSAttributedString, each pair is (title, content)
        var flat: [NSAttributedString] = []
        for pair in result {
            flat.append(pair.title)
            flat.append(pair.content)
        }
        return flat
    }

    private static func paginate(readings: [NSAttributedString], pageWidth: CGFloat, pageHeight: CGFloat, borderInsetX: CGFloat, borderInsetY: CGFloat) -> (pages: [[NSAttributedString]], heights: [CGFloat]) {
        var pages: [[NSAttributedString]] = []
        var heights: [CGFloat] = []
        var current: [NSAttributedString] = []
        var currentHeight: CGFloat = 0
        let contentWidth = pageWidth - 2 * borderInsetX
        let maxContentHeight = pageHeight - 2 * borderInsetY - 20

        var i = 0
        while i < readings.count {
            // Always treat (title, content) as a pair
            if i + 1 < readings.count {
                let titleAttr = readings[i]
                let contentAttr = readings[i+1]
                let titleFramesetter = CTFramesetterCreateWithAttributedString(titleAttr as CFAttributedString)
                let titleSize = CTFramesetterSuggestFrameSizeWithConstraints(titleFramesetter, CFRange(location: 0, length: titleAttr.length), nil, CGSize(width: contentWidth - 20, height: .greatestFiniteMagnitude), nil)
                let titleHeight = titleSize.height + 10
                let contentFramesetter = CTFramesetterCreateWithAttributedString(contentAttr as CFAttributedString)
                let contentSize = CTFramesetterSuggestFrameSizeWithConstraints(contentFramesetter, CFRange(location: 0, length: contentAttr.length), nil, CGSize(width: contentWidth - 20, height: .greatestFiniteMagnitude), nil)
                let contentHeight = contentSize.height + 20
                let blockHeight = titleHeight + contentHeight
                if currentHeight + blockHeight > maxContentHeight && currentHeight > 0 {
                    pages.append(current); heights.append(currentHeight)
                    current = []; currentHeight = 0
                }
                current.append(titleAttr)
                current.append(contentAttr)
                currentHeight += blockHeight
                i += 2
            } else {
                // If odd, just add the last one
                let attr = readings[i]
                let framesetter = CTFramesetterCreateWithAttributedString(attr as CFAttributedString)
                let size = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRange(location: 0, length: attr.length), nil, CGSize(width: contentWidth - 20, height: .greatestFiniteMagnitude), nil)
                let itemHeight = size.height + 20
                if currentHeight + itemHeight > maxContentHeight && currentHeight > 0 {
                    pages.append(current); heights.append(currentHeight)
                    current = []; currentHeight = 0
                }
                current.append(attr); currentHeight += itemHeight
                i += 1
            }
        }
        if !current.isEmpty { pages.append(current); heights.append(currentHeight) }
        return (pages, heights)
    }

    private static func drawReadingPages(ctx: UIGraphicsPDFRendererContext,
                                         pages: [[NSAttributedString]],
                                         heights: [CGFloat],
                                         pageWidth: CGFloat,
                                         pageHeight: CGFloat,
                                         borderInsetX: CGFloat,
                                         borderInsetY: CGFloat,
                                         startPageIndex: inout Int) {
        let contentWidth = pageWidth - 2 * borderInsetX
        let maxContentHeight = pageHeight - 2 * borderInsetY - 20
        for (i, page) in pages.enumerated() {
            ctx.beginPage(); startPageIndex += 1
            if startPageIndex > 1 {
                let borderRect = CGRect(x: borderInsetX, y: borderInsetY, width: pageWidth - 2 * borderInsetX, height: pageHeight - 2 * borderInsetY)
                ctx.cgContext.setStrokeColor(UIColor.gray.cgColor)
                ctx.cgContext.setLineWidth(1)
                ctx.cgContext.stroke(borderRect)
            }
            let totalH = heights[i]
            var y = max(borderInsetY + 20, borderInsetY + 10 + (maxContentHeight - totalH) / 2)
            for attr in page {
                let framesetter = CTFramesetterCreateWithAttributedString(attr as CFAttributedString)
                let size = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRange(location: 0, length: attr.length), nil, CGSize(width: contentWidth - 20, height: .greatestFiniteMagnitude), nil)
                let rect = CGRect(x: borderInsetX + 10, y: y, width: contentWidth - 20, height: size.height)
                attr.draw(in: rect)
                y += size.height + 20
            }
        }
    }

    // MARK: - Final Details Page
    private static func drawFinalDetailsPage(ctx: UIGraphicsPDFRendererContext,
                                             info: BookletInfo,
                                             pageWidth: CGFloat,
                                             pageHeight: CGFloat,
                                             borderInsetX: CGFloat,
                                             borderInsetY: CGFloat,
                                             startPageIndex: inout Int) {
        ctx.beginPage(); startPageIndex += 1
        if startPageIndex > 1 {
            let borderRect = CGRect(x: borderInsetX, y: borderInsetY, width: pageWidth - 2 * borderInsetX, height: pageHeight - 2 * borderInsetY)
            ctx.cgContext.setStrokeColor(UIColor.gray.cgColor)
            ctx.cgContext.setLineWidth(1)
            ctx.cgContext.stroke(borderRect)
        }

        let sectionTitleAttrs: [NSAttributedString.Key: Any] = [ .font: UIFont.boldSystemFont(ofSize: 16), .paragraphStyle: centeredParagraphStyle() ]
        let detailAttrs: [NSAttributedString.Key: Any] = [ .font: UIFont.systemFont(ofSize: 14), .paragraphStyle: centeredParagraphStyle() ]

        var blocks: [(text: String, height: CGFloat, attrs: [NSAttributedString.Key: Any])] = []
        if let committal = info.committalLocation, !committal.isEmpty {
            blocks.append(("Committal Location", 20, sectionTitleAttrs))
            blocks.append((committal, 18, detailAttrs))
        }
        if let wake = info.wakeLocation, !wake.isEmpty {
            blocks.append(("Wake/Reception Location", 20, sectionTitleAttrs))
            blocks.append((wake, 18, detailAttrs))
        }
        if let donation = info.donationInfo, !donation.isEmpty {
            blocks.append(("Donation/Flower Instructions", 20, sectionTitleAttrs))
            blocks.append((donation, 40, detailAttrs))
        }
        if let photographer = info.photographer, !photographer.isEmpty {
            blocks.append(("Photographer", 20, sectionTitleAttrs))
            blocks.append((photographer, 18, detailAttrs))
        }
        if let pallbearers = info.pallbearers, !pallbearers.isEmpty {
            blocks.append(("Pallbearers", 20, sectionTitleAttrs))
            blocks.append((pallbearers, 18, detailAttrs))
        }

        var totalH: CGFloat = 0
        for b in blocks { totalH += b.height }
        totalH += CGFloat(max(0, blocks.count - 1)) * 6

        let contentWidth = pageWidth - 2 * borderInsetX
        let blockWidth = contentWidth - 20
        var y = borderInsetY + 10 + ((pageHeight - 2 * borderInsetY - 20) - totalH) / 2
        for b in blocks {
            let rect = CGRect(x: borderInsetX + 10, y: y, width: blockWidth, height: b.height)
            (b.text as NSString).draw(in: rect, withAttributes: b.attrs)
            y += b.height + 6
        }
    }

    // MARK: - Utilities
    private static func centeredParagraphStyle() -> NSMutableParagraphStyle { let s = NSMutableParagraphStyle(); s.alignment = .center; return s }
    private static func attrs(font: UIFont) -> [NSAttributedString.Key: Any] { [.font: font, .paragraphStyle: centeredParagraphStyle()] }
    private static func measuredHeight(for text: String, attrs: [NSAttributedString.Key: Any], width: CGFloat) -> CGFloat {
        let rect = (text as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attrs,
            context: nil
        )
        return ceil(rect.height)
    }
}
