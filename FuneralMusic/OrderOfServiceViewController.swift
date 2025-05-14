import UIKit
import WebKit
import QuickLook

class OrderOfServiceViewController: UIViewController, WKNavigationDelegate, QLPreviewControllerDataSource {

    private var webView: WKWebView!
    private let pdfFilename = "order.pdf"

    private let infoBar = UIView()
    private let infoLabel = UILabel()
    private let shareButton = UIButton(type: .system)
    private let previewButton = UIButton(type: .system)
    private let toastLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Order of Service"
        view.backgroundColor = .white

        setupWebView()
        setupInfoBar()
        setupToast()
        layoutViews()

        loadOrderForm()
        updateInfoBar()
    }

    // MARK: - Setup

    private func setupWebView() {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
    }

    private func loadOrderForm() {
        if let url = URL(string: "https://funeralmusic.co.uk/order-of-service-creator-127/") {
            webView.load(URLRequest(url: url))
        }
    }

    private func setupInfoBar() {
        infoBar.translatesAutoresizingMaskIntoConstraints = false
        infoBar.backgroundColor = UIColor(white: 0.95, alpha: 1.0)

        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        infoLabel.font = .systemFont(ofSize: 13, weight: .medium)

        shareButton.setTitle("Share", for: .normal)
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        shareButton.addTarget(self, action: #selector(sharePDF), for: .touchUpInside)
        shareButton.setTitleColor(.systemBlue, for: .normal)
        shareButton.setTitleColor(.gray, for: .disabled)

        previewButton.setTitle("Preview", for: .normal)
        previewButton.translatesAutoresizingMaskIntoConstraints = false
        previewButton.addTarget(self, action: #selector(previewPDF), for: .touchUpInside)
        previewButton.setTitleColor(.systemBlue, for: .normal)
        previewButton.setTitleColor(.gray, for: .disabled)

        infoBar.addSubview(infoLabel)
        infoBar.addSubview(shareButton)
        infoBar.addSubview(previewButton)
        view.addSubview(infoBar)
    }

    private func setupToast() {
        toastLabel.translatesAutoresizingMaskIntoConstraints = false
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        toastLabel.textColor = .white
        toastLabel.textAlignment = .center
        toastLabel.font = .systemFont(ofSize: 13, weight: .medium)
        toastLabel.layer.cornerRadius = 8
        toastLabel.clipsToBounds = true
        toastLabel.alpha = 0
        view.addSubview(toastLabel)
    }

    private func layoutViews() {
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: infoBar.topAnchor),

            infoBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            infoBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            infoBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            infoBar.heightAnchor.constraint(equalToConstant: 48),

            infoLabel.leadingAnchor.constraint(equalTo: infoBar.leadingAnchor, constant: 16),
            infoLabel.centerYAnchor.constraint(equalTo: infoBar.centerYAnchor),

            previewButton.trailingAnchor.constraint(equalTo: shareButton.leadingAnchor, constant: -12),
            previewButton.centerYAnchor.constraint(equalTo: infoBar.centerYAnchor),

            shareButton.trailingAnchor.constraint(equalTo: infoBar.trailingAnchor, constant: -16),
            shareButton.centerYAnchor.constraint(equalTo: infoBar.centerYAnchor),

            toastLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toastLabel.bottomAnchor.constraint(equalTo: infoBar.topAnchor, constant: -8),
            toastLabel.heightAnchor.constraint(equalToConstant: 32),
            toastLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 180)
        ])
    }

    // MARK: - PDF Logic

    private func pdfLocalURL() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(pdfFilename)
    }

    private func updateInfoBar() {
        let exists = FileManager.default.fileExists(atPath: pdfLocalURL().path)
        infoLabel.text = exists ? "Saved: \(pdfFilename)" : "No PDF saved"
        shareButton.isEnabled = exists
        previewButton.isEnabled = exists
    }

    @objc private func sharePDF() {
        let url = pdfLocalURL()
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        present(vc, animated: true)
    }

    @objc private func previewPDF() {
        let preview = QLPreviewController()
        preview.dataSource = self
        present(preview, animated: true)
    }

    private func manuallyDownloadPDF(from url: URL) {
        let dest = pdfLocalURL()

        let task = URLSession.shared.downloadTask(with: url) { tempURL, _, error in
            guard let tempURL = tempURL, error == nil else {
                print("❌ PDF download failed: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            do {
                try? FileManager.default.removeItem(at: dest)
                try FileManager.default.moveItem(at: tempURL, to: dest)
                print("✅ PDF saved to: \(dest.lastPathComponent)")

                DispatchQueue.main.async {
                    self.updateInfoBar()
                    self.showToast("✅ PDF saved successfully")
                }
            } catch {
                print("❌ Save error: \(error)")
            }
        }

        task.resume()
    }

    // MARK: - Toast

    private func showToast(_ message: String) {
        toastLabel.text = message
        toastLabel.alpha = 0
        UIView.animate(withDuration: 0.3) {
            self.toastLabel.alpha = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            UIView.animate(withDuration: 0.3) {
                self.toastLabel.alpha = 0
            }
        }
    }

    // MARK: - WebView Navigation

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        if let url = navigationAction.request.url,
           url.absoluteString.contains("e2pdf-download") {
            print("📥 Intercepting dynamic PDF link: \(url)")
            decisionHandler(.cancel)
            manuallyDownloadPDF(from: url)
            return
        }

        decisionHandler(.allow)
    }

    // MARK: - QLPreviewController

    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return pdfLocalURL() as QLPreviewItem
    }
}
