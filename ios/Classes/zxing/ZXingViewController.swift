//
//  ZXingViewController.swift
//  QRCodeReader
//
//  Created by kazuhiro_nanko on 2022/09/21.
//

import UIKit
import ZXingObjC

protocol ZXingViewControllerDelegate {
    func metadataOutput(qrcode: QRCode)
}

class ZXingViewController: UIViewController {
    
    // MARK: Properties
    
    fileprivate var capture: ZXCapture?
    
    fileprivate var isScanning: Bool?
    fileprivate var isFirstApplyOrientation: Bool?
    fileprivate var captureSizeTransform: CGAffineTransform?
    
    var delegate: ZXingViewControllerDelegate?
    
    
    // MARK: Life Circles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if isFirstApplyOrientation == true { return }
        isFirstApplyOrientation = true
        applyOrientation()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { (context) in
            // do nothing
        }) { [weak self] (context) in
            guard let weakSelf = self else { return }
            weakSelf.applyOrientation()
        }
    }
}

// MARK: Helpers
extension ZXingViewController {
    func setup() {
        isScanning = false
        isFirstApplyOrientation = false
        
        capture = ZXCapture()
        guard let _capture = capture else { return }
        _capture.camera = _capture.back()
        _capture.focusMode = .continuousAutoFocus
        _capture.delegate = self
        
        view.backgroundColor = .black
        
        self.view.layer.addSublayer(_capture.layer)
    }
    
    func applyOrientation() {
        let orientation = UIApplication.shared.statusBarOrientation
        var captureRotation: Double
        var scanRectRotation: Double
        
        switch orientation {
            case .portrait:
                captureRotation = 0
                scanRectRotation = 90
                break
            
            case .landscapeLeft:
                captureRotation = 90
                scanRectRotation = 180
                break
            
            case .landscapeRight:
                captureRotation = 270
                scanRectRotation = 0
                break
            
            case .portraitUpsideDown:
                captureRotation = 180
                scanRectRotation = 270
                break
            
            default:
                captureRotation = 0
                scanRectRotation = 90
                break
        }
        
        
        let angleRadius = captureRotation / 180.0 * Double.pi
        let captureTranform = CGAffineTransform(rotationAngle: CGFloat(angleRadius))
        
        capture?.transform = captureTranform
        capture?.rotation = CGFloat(scanRectRotation)
        capture?.layer.frame = view.frame
    }
    
    func adjustScanRect() {
        guard let captureLayer = capture?.layer as? AVCaptureVideoPreviewLayer else { return }
        // 読み取り可能エリアのサイズを定義
        // おくすり連絡帳アプリ側で実装している定義しているエリアサイズ算出ロジックに合わせる
        //https://github.com/kkhs/pocket-musubi-native/blob/develop/lib/components/qr_code_reader/qr_code_reader.dart/#L213
        // TODO: scanAreaSizeはflutter側から渡されるargsから知ることも可能なので今後必要に応じて修正する
        let scanAreaSize: CGFloat = (view.bounds.width < 400 || view.bounds.height < 400) ? 225.0 : 300.0
        let marginX = (view.bounds.width - scanAreaSize) * 0.5
        let marginY = (view.bounds.height - scanAreaSize) * 0.5
        let scanRect = CGRect(x: marginX, y: marginY, width: scanAreaSize, height: scanAreaSize)
        
        // 参考: https://github.com/zxingify/zxingify-objc/blob/master/examples/BarcodeScannerSwift/BarcodeScannerSwift/ViewController.swift#L139
        let metadataOutputRect = captureLayer.metadataOutputRectConverted(fromLayerRect: scanRect)
        let rectOfInterest = capture!.output.outputRectConverted(fromMetadataOutputRect: metadataOutputRect)
        capture?.scanRect = rectOfInterest
    }
}

// MARK: ZXCaptureDelegate
extension ZXingViewController: ZXCaptureDelegate {
    func captureCameraIsReady(_ capture: ZXCapture?) {
        isScanning = true
        
        adjustScanRect()
    }
    
    func captureResult(_ capture: ZXCapture?, result: ZXResult?) {
        guard let _result = result, let rawBytes = _result.rawBytes, isScanning == true else { return }

        capture?.stop()
        isScanning = false
        
        let text = _result.text ?? "Unknow"
                
        delegate?.metadataOutput(qrcode: .init(rawValue: text, data: NSData(bytes: rawBytes.array, length: Int(rawBytes.length))))
        
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.isScanning = true
            weakSelf.capture?.start()
        }
    }
}

