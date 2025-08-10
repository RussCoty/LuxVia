//
//  TextRenderingUtility.swift
//  LuxVia
//
//  Created by AI Assistant on 07/08/2025.
//

import UIKit

final class TextRenderingUtility {
    
    static func renderText(_ text: String, fontSize: CGFloat = 18, alignment: NSTextAlignment = .center) -> NSAttributedString {
        let cleanText = cleanupText(text)
        
        // First try to detect if this is valid HTML
        if isValidHTML(cleanText) {
            return renderAsHTML(cleanText, fontSize: fontSize, alignment: alignment)
        } else {
            return renderAsPlainText(cleanText, fontSize: fontSize, alignment: alignment)
        }
    }
    
    private static func cleanupText(_ text: String) -> String {
        // Fix common HTML encoding issues
        let cleaned = text
            .replacingOccurrences(of: "â€™", with: "'")
            .replacingOccurrences(of: "â€œ", with: "\"")
            .replacingOccurrences(of: "â€\u{9C}", with: "\"") // closing quote
            .replacingOccurrences(of: "â€˜", with: "'")
            .replacingOccurrences(of: "â€“", with: "–") // en dash
            .replacingOccurrences(of: "â€”", with: "—") // em dash
            .replacingOccurrences(of: "â€¦", with: "…")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Fix malformed HTML tags
        let fixedHTML = cleaned
            .replacingOccurrences(of: "strong>", with: "<strong>")
            .replacingOccurrences(of: "em>", with: "<em>")
            .replacingOccurrences(of: "p>", with: "<p>")
        
        return fixedHTML
    }

    
    private static func isValidHTML(_ text: String) -> Bool {
        // Simple heuristic: check if text contains properly formed HTML tags
        let htmlPattern = "<\\s*\\w+[^>]*>"
        let regex = try? NSRegularExpression(pattern: htmlPattern)
        let range = NSRange(location: 0, length: text.utf16.count)
        return regex?.firstMatch(in: text, range: range) != nil
    }
    
    private static func renderAsHTML(_ htmlText: String, fontSize: CGFloat, alignment: NSTextAlignment) -> NSAttributedString {
        guard let data = htmlText.data(using: .utf8) else {
            return renderAsPlainText(htmlText, fontSize: fontSize, alignment: alignment)
        }
        
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        
        guard let attributedString = try? NSMutableAttributedString(data: data, options: options, documentAttributes: nil) else {
            return renderAsPlainText(htmlText, fontSize: fontSize, alignment: alignment)
        }
        
        // Apply consistent styling
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        paragraphStyle.paragraphSpacing = 8
        paragraphStyle.lineSpacing = 2
        
        let range = NSRange(location: 0, length: attributedString.length)
        attributedString.addAttributes([
            .font: UIFont.systemFont(ofSize: fontSize),
            .paragraphStyle: paragraphStyle
        ], range: range)
        
        return attributedString
    }
    
    private static func renderAsPlainText(_ plainText: String, fontSize: CGFloat, alignment: NSTextAlignment) -> NSAttributedString {
        // Normalize line breaks and spacing for better readability
        let normalizedText = normalizeLineBreaks(plainText)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        paragraphStyle.paragraphSpacing = 12
        paragraphStyle.lineSpacing = 4
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: fontSize),
            .paragraphStyle: paragraphStyle
        ]
        
        return NSAttributedString(string: normalizedText, attributes: attributes)
    }
    
    private static func normalizeLineBreaks(_ text: String) -> String {
        // Replace multiple consecutive newlines with double newlines for paragraph spacing
        let singleSpaced = text.replacingOccurrences(of: "\n+", with: "\n", options: .regularExpression)
        
        // Convert sequences of 3+ newlines to double newlines
        let doubleSpaced = singleSpaced.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
        
        // Ensure proper paragraph spacing
        return doubleSpaced
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
    }
}
