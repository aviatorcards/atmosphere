import AppKit
import Foundation
import SwiftMark
import WebKit

@MainActor
class ExportManager {
    static let shared = ExportManager()

    private init() {}

    // MARK: - HTML Export

    func exportToHTML(entry: JournalEntry) -> String {
        let processor = MarkdownProcessor()
        let htmlContent = processor.process(content: entry.content)

        let title = entry.title ?? "Untitled"
        let date = DateFormatter.localizedString(
            from: entry.date, dateStyle: .medium, timeStyle: .short)

        return """
            <!DOCTYPE html>
            <html lang="en">
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>\(title)</title>
                <style>
                    body {
                        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
                        line-height: 1.6;
                        color: #333;
                        max-width: 800px;
                        margin: 0 auto;
                        padding: 40px 20px;
                    }
                    header {
                        margin-bottom: 40px;
                        border-bottom: 1px solid #eee;
                        padding-bottom: 20px;
                    }
                    h1 {
                        margin: 0 0 10px 0;
                        font-size: 2.5em;
                    }
                    .meta {
                        color: #666;
                        font-size: 0.9em;
                    }
                    img {
                        max-width: 100%;
                        height: auto;
                        border-radius: 8px;
                    }
                    pre {
                        background: #f5f5f5;
                        padding: 15px;
                        border-radius: 5px;
                        overflow-x: auto;
                    }
                    code {
                        font-family: Menlo, Monaco, Consolas, "Courier New", monospace;
                        font-size: 0.9em;
                    }
                    blockquote {
                        margin: 0;
                        padding-left: 20px;
                        border-left: 4px solid #ddd;
                        color: #555;
                    }
                    @media (prefers-color-scheme: dark) {
                        body {
                            background-color: #1a1a1a;
                            color: #ddd;
                        }
                        header {
                            border-bottom-color: #333;
                        }
                        .meta {
                            color: #aaa;
                        }
                        pre {
                            background: #2a2a2a;
                        }
                        blockquote {
                            border-left-color: #444;
                            color: #bbb;
                        }
                    }
                </style>
            </head>
            <body>
                <header>
                    <h1>\(title)</h1>
                    <div class="meta">
                        <p>\(date)</p>
                        \(entry.tags.isEmpty ? "" : "<p>Tags: \(entry.tags.joined(separator: ", "))</p>")
                    </div>
                </header>
                <article>
                    \(htmlContent)
                </article>
            </body>
            </html>
            """
    }

    // MARK: - PDF Export

    func exportToPDF(entry: JournalEntry, completion: @escaping (Result<Data, Error>) -> Void) {
        let html = exportToHTML(entry: entry)
        let webView = WKWebView()

        // Load HTML into WebView
        webView.loadHTMLString(html, baseURL: nil)

        // Wait for navigation to finish using a delegate helper would be ideal,
        // but for simplicity in this context we'll use a delayed check or simple observation.
        // A robust way without a delegate is difficult in a pure logic class,
        // so we'll use a simple delegate wrapper.

        let delegate = WebViewPrintDelegate(completion: completion)
        webView.navigationDelegate = delegate

        // Keep a strong reference to the delegate and webView during the process
        // In a real app, this might need more robust lifecycle management.
        objc_setAssociatedObject(webView, "printDelegate", delegate, .OBJC_ASSOCIATION_RETAIN)
    }
}

private class WebViewPrintDelegate: NSObject, WKNavigationDelegate {
    let completion: (Result<Data, Error>) -> Void

    init(completion: @escaping (Result<Data, Error>) -> Void) {
        self.completion = completion
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let printInfo = NSPrintInfo.shared
        printInfo.horizontalPagination = .automatic
        printInfo.verticalPagination = .automatic
        printInfo.topMargin = 50
        printInfo.leftMargin = 50
        printInfo.rightMargin = 50
        printInfo.bottomMargin = 50

        // Create print operation
        let operation = webView.printOperation(with: printInfo)
        operation.showsPrintPanel = false
        operation.showsProgressPanel = false

        // Export to PDF
        // let data = NSMutableData()
        operation.runModal(for: NSWindow(), delegate: nil, didRun: nil, contextInfo: nil)

        // Since runModal is blocking/synchronous for local print operations usually,
        // we might not get the data directly from it easily without a file path.
        // Alternative: Use createPDF

        let pdfConfiguration = WKPDFConfiguration()

        if #available(macOS 11.0, *) {
            webView.createPDF(configuration: pdfConfiguration) { result in
                switch result {
                case .success(let data):
                    self.completion(.success(data))
                case .failure(let error):
                    self.completion(.failure(error))
                }
            }
        } else {
            // Fallback or error for older macOS
            self.completion(
                .failure(
                    NSError(
                        domain: "ExportManager", code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "PDF export requires macOS 11.0+"])))
        }
    }
}
