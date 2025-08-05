import UIKit
import SafariServices

class NativeLoginViewController: UIViewController {

    private let logoImageView: UIImageView = {
        let image = UIImage(named: "LuxViaLogo") ?? UIImage()
        let iv = UIImageView(image: image)
        iv.contentMode = .scaleAspectFit
        iv.alpha = 0.0
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let usernameField = UITextField()
    private let passwordField = UITextField()
    private let loginButton = UIButton(type: .system)
    private let guestButton = UIButton(type: .system)
    private let registerButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
        animateLogo()
    }

    private func setupUI() {
        usernameField.placeholder = "Username or Email"
        usernameField.borderStyle = .roundedRect

        passwordField.placeholder = "Password"
        passwordField.isSecureTextEntry = true
        passwordField.borderStyle = .roundedRect

        loginButton.setTitle("Login", for: .normal)
        loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)

        guestButton.setTitle("Try as Guest", for: .normal)
        guestButton.addTarget(self, action: #selector(guestTapped), for: .touchUpInside)

        registerButton.setTitle("Register", for: .normal)
        registerButton.addTarget(self, action: #selector(registerTapped), for: .touchUpInside)

        let formStack = UIStackView(arrangedSubviews: [usernameField, passwordField, loginButton, guestButton, registerButton])
        formStack.axis = .vertical
        formStack.spacing = 12
        formStack.translatesAutoresizingMaskIntoConstraints = false

        let logoContainer = UIView()
        logoContainer.translatesAutoresizingMaskIntoConstraints = false
        logoContainer.addSubview(logoImageView)

        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: logoContainer.centerXAnchor),
            logoImageView.topAnchor.constraint(equalTo: logoContainer.topAnchor),
            logoImageView.heightAnchor.constraint(equalToConstant: 120),
            logoImageView.widthAnchor.constraint(equalToConstant: 120),
            logoImageView.bottomAnchor.constraint(equalTo: logoContainer.bottomAnchor)
        ])

        let fullStack = UIStackView(arrangedSubviews: [logoContainer, formStack])
        fullStack.axis = .vertical
        fullStack.spacing = 32
        fullStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(fullStack)

        NSLayoutConstraint.activate([
            fullStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            fullStack.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 40), // 👈 pushes it down
            fullStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            fullStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
    }


    private func animateLogo() {
        // Start: hidden, moved up slightly, and scaled down
        logoImageView.alpha = 0.0
        logoImageView.transform = CGAffineTransform(translationX: 0, y: -40).scaledBy(x: 0.8, y: 0.8)

        UIView.animate(withDuration: 2.5,
                       delay: 0.2,
                       usingSpringWithDamping: 0.6,
                       initialSpringVelocity: 1.0,
                       options: [.curveEaseOut],
                       animations: {
            self.logoImageView.alpha = 1.0
            self.logoImageView.transform = .identity
        })
    }


    @objc private func loginTapped() {
        guard let username = usernameField.text, !username.isEmpty,
              let password = passwordField.text, !password.isEmpty else {
            showAlert(message: "Please enter both username and password.")
            return
        }

        let url = URL(string: "https://funeralmusic.co.uk/wp-json/jwt-auth/v1/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = ["username": username, "password": password]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.showAlert(message: "Error: \(error.localizedDescription)")
                }
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                DispatchQueue.main.async {
                    self.showAlert(message: "Invalid response from server.")
                }
                return
            }

            if let token = json["token"] as? String {
                if let tokenData = token.data(using: .utf8) {
                    KeychainHelper.standard.save(tokenData, service: "jwt", account: "funeralmusic")
                }

                UserDefaults.standard.set(true, forKey: "isLoggedIn")
                UserDefaults.standard.set(true, forKey: "isMember")
                UserDefaults.standard.set(false, forKey: "guestMode")

                DispatchQueue.main.async {
                    if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
                        sceneDelegate.showMainApp()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    let message = json["message"] as? String ?? "Login failed"
                    self.showAlert(message: message)
                }
            }
        }

        task.resume()
    }

    @objc private func guestTapped() {
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
        UserDefaults.standard.set(false, forKey: "isMember")
        UserDefaults.standard.set(true, forKey: "guestMode")

        if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
            sceneDelegate.showMainApp()
        }
    }

    @objc private func registerTapped() {
        if let url = URL(string: "https://funeralmusic.co.uk/wp-login.php?action=register") {
            let safariVC = SFSafariViewController(url: url)
            present(safariVC, animated: true)
        }
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Login", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
