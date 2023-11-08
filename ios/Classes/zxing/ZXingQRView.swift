import Foundation
import UIKit
import SwiftUI

struct QRCode {
    let rawValue: String
    let data: NSData
}

public class ZXingQRView: NSObject, FlutterPlatformView {
    var registrar: FlutterPluginRegistrar
    var channel: FlutterMethodChannel
    var previewView: UIView!
    var qrView: ZXingSwiftUIView!
    
    public init(withFrame frame: CGRect, withRegistrar registrar: FlutterPluginRegistrar, withId id: Int64, params: Dictionary<String, Any>){
        self.registrar = registrar

        // NOTE: 問題が起きているiOSは17系なのでiOS13以下になりえない。
        if #available(iOS 13.0, *) {
            qrView = ZXingSwiftUIView()
            let childViewController = UIHostingController(rootView: qrView)
            childViewController.view.translatesAutoresizingMaskIntoConstraints = false
            previewView = childViewController.view
        } else {
            fatalError()
        }    
        
        channel = FlutterMethodChannel(name: "net.touchcapture.qr.flutterqr/qrview_\(id)", binaryMessenger: registrar.messenger())
    }
    
    deinit {

    }
    
    public func view() -> UIView {        
        channel.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in

            // NOTE: 必須のもの以外は削除
            switch(call.method){
                case "startScan":
                    self?.startScan(call.arguments as! Array<Int>, result)
            default:
                break
            }
        })
        return previewView
    }

    func startScan(_ arguments: Array<Int>, _ result: @escaping FlutterResult) {
        qrView.found(
            completion: { [weak self] r in self?.channel.invokeMethod("onRecognizeQR", arguments: ["code": r.rawValue, "type": "QR_CODE", "rawBytes": r.data])
        }).error(completion: { error in
            let scanError = FlutterError(code: "unknown-error", message: "Unable to start scanning", details: error)
            result(scanError)
        })
    }
}
