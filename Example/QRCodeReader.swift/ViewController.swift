/*
 * QRCodeReader.swift
 *
 * Copyright 2014-present Yannick Loriot.
 * http://yannickloriot.com
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

import AVFoundation
import UIKit

class ViewController: UIViewController, QRCodeReaderViewControllerDelegate {
  @IBOutlet weak var previewView: QRCodeReaderView! {
    didSet {
      previewView.setupComponents(with: QRCodeReaderViewControllerBuilder {
        $0.reader                 = reader
        $0.showTorchButton        = false
        $0.showSwitchCameraButton = false
        $0.showCancelButton       = false
        $0.showOverlayView        = true
        $0.rectOfInterestRelativeWidth = 0.75
      })
      (previewView.overlayView as? ReaderOverlayView)?.overlayOpacity = 0.8
    }
  }
  lazy var reader: QRCodeReader = QRCodeReader()
  lazy var readerVC: QRCodeReaderViewController = {
    let builder = QRCodeReaderViewControllerBuilder {
      $0.reader                  = QRCodeReader(metadataObjectTypes: [.qr], captureDevicePosition: .back)
      $0.showTorchButton         = true
      $0.preferredStatusBarStyle = .lightContent
      $0.showOverlayView         = true
      
      $0.reader.stopScanningWhenCodeIsFound = false
      $0.rectOfInterestRelativeWidth = 0.75
    }
    
    return QRCodeReaderViewController(builder: builder)
  }()

  // MARK: - Actions

  private func checkScanPermissions() -> Bool {
    do {
      return try QRCodeReader.supportsMetadataObjectTypes()
    } catch let error as NSError {
      let alert: UIAlertController

      switch error.code {
      case -11852:
        alert = UIAlertController(title: "Error", message: "This app is not authorized to use Back Camera.", preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Setting", style: .default, handler: { (_) in
          DispatchQueue.main.async {
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
              UIApplication.shared.openURL(settingsURL)
            }
          }
        }))

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
      default:
        alert = UIAlertController(title: "Error", message: "Reader not supported by the current device", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
      }

      present(alert, animated: true, completion: nil)

      return false
    }
  }

  @IBAction func scanInModalAction(_ sender: AnyObject) {
    guard checkScanPermissions() else { return }

    readerVC.modalPresentationStyle = .formSheet
    readerVC.delegate               = self

    readerVC.completionBlock = { (result: QRCodeReaderResult?) in
      if let result = result {
        print("Completion with result: \(result.value) of type \(result.metadataType)")
      }
    }

    present(readerVC, animated: true, completion: nil)
  }

  @IBAction func scanInPreviewAction(_ sender: Any) {
    guard checkScanPermissions(), !reader.isRunning else { return }

    reader.didFindCode = { result in
      print("Completion with result: \(result.value) of type \(result.metadataType)")
    }

    reader.startScanning()
  }

  @IBAction func changeStyleAction(_ sender: Any) {
    // Round-robin trigger
    guard let overlayView = previewView.overlayView as? ReaderOverlayView, let currentCaseIndex = ReaderOverlayState.allCases.firstIndex(of: overlayView.state) else {
      return
    }
    overlayView.state = ReaderOverlayState.allCases[(currentCaseIndex + 1) % ReaderOverlayState.allCases.count]
    overlayView.labelText = String(describing: overlayView.state)
  }

  // MARK: - QRCodeReader Delegate Methods

  func reader(_ reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult) {
    reader.stopScanning()

    dismiss(animated: true) { [weak self] in
      let alert = UIAlertController(
        title: "QRCodeReader",
        message: String (format:"%@ (of type %@)", result.value, result.metadataType),
        preferredStyle: .alert
      )
      alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))

      self?.present(alert, animated: true, completion: nil)
    }
  }

  func readerDidFail(_ reader: QRCodeReaderViewController) {
    print("Reader did fail")
  }

  func reader(_ reader: QRCodeReaderViewController, didSwitchCamera newCaptureDevice: AVCaptureDeviceInput) {
    print("Switching capture to: \(newCaptureDevice.device.localizedName)")
  }

  func readerDidCancel(_ reader: QRCodeReaderViewController) {
    reader.stopScanning()

    dismiss(animated: true, completion: nil)
  }
}
