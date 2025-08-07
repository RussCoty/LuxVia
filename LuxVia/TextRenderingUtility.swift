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
            .replacingOccurrences(of: "\u{E2}\u{80}\u{99}", with: "'")
            .replacingOccurrences(of: "\u{E2}\u{80}\u{9C}", with: "\"")
            .replacingOccurrences(of: "\u{E2}\u{80}\u{9D}", with: "\"")
            .replacingOccurrences(of: "\u{E2}\u{80}\u{98}", with: "'")
            .replacingOccurrences(of: "\u{E2}\u{80}\u{93}", with: "–")
            .replacingOccurrences(of: "\u{E2}\u{80}\u{94}", with: "—")
            .replacingOccurrences(of: "\u{E2}\u{80}\u{A6}", with: "…")
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
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
        paragraphStyle.paragraphSpacing = 16  // Consistent with plain text
        paragraphStyle.lineSpacing = 6        // Consistent with plain text
        
        let range = NSRange(location: 0, length: attributedString.length)
        attributedString.addAttributes([
            .font: UIFont.systemFont(ofSize: fontSize, weight: .regular),
            .paragraphStyle: paragraphStyle,
            .foregroundColor: UIColor.label  // Ensures proper color in dark/light mode
        ], range: range)
        
        return attributedString
    }
    
    private static func renderAsPlainText(_ plainText: String, fontSize: CGFloat, alignment: NSTextAlignment) -> NSAttributedString {
        // Normalize line breaks and spacing for better readability
        let normalizedText = normalizeLineBreaks(plainText)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        paragraphStyle.paragraphSpacing = 16  // Increased for better visual separation
        paragraphStyle.lineSpacing = 6       // Increased for better readability
        paragraphStyle.firstLineHeadIndent = 0
        paragraphStyle.headIndent = 0
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: fontSize, weight: .regular),
            .paragraphStyle: paragraphStyle,
            .foregroundColor: UIColor.label  // Ensures proper color in dark/light mode
        ]
        
        return NSAttributedString(string: normalizedText, attributes: attributes)
    }
    
    private static func normalizeLineBreaks(_ text: String) -> String {
        // Remove excessive whitespace while preserving intentional formatting
        var normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Replace carriage returns and mixed line endings with standard newlines
        normalized = normalized
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        
        // Replace multiple consecutive spaces with single spaces (except at line start)
        normalized = normalized.replacingOccurrences(of: " +", with: " ", options: .regularExpression)
        
        // Normalize excessive newlines to at most double newlines for paragraph spacing
        normalized = normalized.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
        
        // Clean up trailing whitespace on each line while preserving line breaks
        let lines = normalized.components(separatedBy: "\n")
        let cleanedLines = lines.map { line in
            line.trimmingCharacters(in: .whitespaces)
        }
        
        // Filter out completely empty lines except for intentional paragraph breaks
        var result: [String] = []
        var lastWasEmpty = false
        
        for line in cleanedLines {
            if line.isEmpty {
                if !lastWasEmpty && !result.isEmpty {
                    result.append(line) // Keep one empty line for paragraph spacing
                }
                lastWasEmpty = true
            } else {
                result.append(line)
                lastWasEmpty = false
            }
        }
        
        return result.joined(separator: "\n")
    }
}