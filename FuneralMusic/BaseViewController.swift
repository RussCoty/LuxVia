//
//  BaseViewController.swift
//  FuneralMusic
//
//  Created by Russell Cottier on 17/05/2025.
//
import UIKit

extension UIViewController {
    @discardableResult
    func addWhiteHeader(height: CGFloat = 48) -> UIView {
        let header = UIView()
        header.translatesAutoresizingMaskIntoConstraints = false
        header.backgroundColor = .white
        view.addSubview(header)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            header.heightAnchor.constraint(equalToConstant: height)
        ])

        return header
    }
}
