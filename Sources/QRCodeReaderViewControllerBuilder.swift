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

import Foundation
import UIKit

/**
 The QRCodeViewControllerBuilder aims to create a simple configuration object for
 the QRCode view controller.
 */
public final class QRCodeReaderViewControllerBuilder {
  // MARK: - Configuring the QRCodeViewController Objects

  /**
   The builder block.
   The block gives a reference of builder you can configure.
   */
  public typealias QRCodeReaderViewControllerBuilderBlock = (QRCodeReaderViewControllerBuilder) -> Void

  /**
   The title to use for the cancel button.
   */
  public var cancelButtonTitle = "Cancel"

  /**
   The code reader object used to scan the bar code.
   */
  public var reader = QRCodeReader()

  /**
   The reader container view used to display the video capture and the UI components.
   */
  public var readerView = QRCodeReaderContainer(displayable: QRCodeReaderView())

  /**
   Flag to know whether the view controller start scanning the codes when the view will appear.
   */
  public var startScanningAtLoad = true

  /**
   Flag to display the cancel button.
   */
  public var showCancelButton = true

  /**
   Flag to display the switch camera button.
   */
  public var showSwitchCameraButton: Bool {
    get {
      return _showSwitchCameraButton && reader.hasFrontDevice
    }
    set {
      _showSwitchCameraButton = newValue
    }
  }
  private var _showSwitchCameraButton: Bool = true

  /**
   Flag to display the toggle torch button. If the value is true and there is no torch the button will not be displayed.
   */
  public var showTorchButton: Bool {
    get {
      return _showTorchButton && reader.isTorchAvailable
    }
    set {
      _showTorchButton = newValue
    }
  }
  private var _showTorchButton = true

  /**
   Flag to display the guide view.
   */
  public var showOverlayView = false

  /**
    Flag to display the guide view.
  */
  public var handleOrientationChange = true

  /**
   A UIStatusBarStyle key indicating your preferred status bar style for the view controller.
   Nil by default. It means it'll use the current context status bar style.
  */
  public var preferredStatusBarStyle: UIStatusBarStyle? = nil

  /**
   Specifies a rectangle of interest for limiting the search area for visual metadata.

   The value of this property is a CGFloat that determines the receiver's rectangle of interest relative width for each frame of video. Specifying a rectOfInterestRelativeWidth may improve detection performance for certain types of metadata. Metadata objects whose bounds do not intersect with the reactangle of interest will not be returned.
  */
  public var rectOfInterestRelativeWidth: CGFloat = 0.5 {
    didSet {
      guard let overlayView = readerView.displayable.overlayView else { return }
      reader.metadataOutput.rectOfInterest = CGRect(
        x: min(max(overlayView.bounds.origin.x, 0), 1),
        y: min(max(overlayView.bounds.origin.y, 0), 1),
        width: min(max(overlayView.bounds.width, 0), 1),
        height: min(max(overlayView.bounds.height, 0), 1)
      )
    }
  }

  public var overlayOpacity: Float = 0.0 {
    didSet {
      (readerView.displayable.overlayView as? ReaderOverlayView)?.overlayOpacity = overlayOpacity
    }
  }

  // MARK: - Initializing a Flap View

  /**
   Initialize a QRCodeViewController builder with default values.
   */
  public init() {}

  /**
   Initialize a QRCodeReaderViewController builder with default values.

   - parameter buildBlock: A QRCodeReaderViewController builder block to configure itself.
   */
  public init(buildBlock: QRCodeReaderViewControllerBuilderBlock) {
    buildBlock(self)
  }
}
