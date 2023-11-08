//
//  ZXingSwiftUIView.swift
//  QRCodeReader
//
//  Created by kazuhiro_nanko on 2022/09/21.
//

import SwiftUI
import UIKit

struct ZXingSwiftUIView: UIViewControllerRepresentable {
    typealias UIViewControllerType = ZXingViewController
    
    let controller = ZXingViewController()
    let zxingDelegate = ZXingDelegate()

    func makeUIViewController(context: Context) -> UIViewControllerType {
        controller.delegate = zxingDelegate
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        print(uiViewController)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {

    }
}

// MARK: - fluent interface

extension ZXingSwiftUIView {

    func found(completion: @escaping (QRCode) -> Void) -> ZXingSwiftUIView {
        self.zxingDelegate.onResult = completion
        return self
    }

    func error(completion: @escaping (Error) -> Void) -> ZXingSwiftUIView {
        self.zxingDelegate.onError = completion
        return self
    }
}


class ZXingDelegate: ZXingViewControllerDelegate {
    
    var onResult: (QRCode) -> Void = { _  in }
    var onError: (Error) -> Void = { _  in }
    
    func metadataOutput(qrcode: QRCode) {
        onResult(qrcode)
    }
}
