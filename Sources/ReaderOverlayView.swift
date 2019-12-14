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

import UIKit

/// Overlay over the camera view to display the area (a square) where to scan the code.

public enum ReaderOverlayState: String, CaseIterable, RawRepresentable {
  case ready
  case reading
  case valid
  case invalid
}

public final class ReaderOverlayView: UIView {

  // MARK: - Defaults

  private enum Default {
    static let labelFont = UIFont.boldSystemFont(ofSize: 14.0)
  }

  // MARK: - State Handler

  public var state: ReaderOverlayState = .ready {
    didSet {
      switch state {
      case .ready:
        strokeColor = readyColor
      case .reading:
        strokeColor = readingColor
      case .valid:
        strokeColor = validColor
      case .invalid:
        strokeColor = invalidColor
      }
    }
  }

  // MARK: - UI Variables

  public var readingColor = UIColor(red: 1, green: 204/255, blue: 0, alpha: 1) // marigold
  public var validColor = UIColor(red: 76/255, green: 217/255, blue: 100/255, alpha: 1) // weirdGreen
  public var invalidColor = UIColor(red: 1.0, green: 59/255, blue: 49/255, alpha: 1) // orangeyRed
  public var readyColor = UIColor.white

  private lazy var label = configureLabel()

  private var frameOverlay: CAShapeLayer = {
    let overlay = CAShapeLayer()
    overlay.backgroundColor = UIColor.clear.cgColor
    overlay.fillColor = UIColor.clear.cgColor
    overlay.strokeColor = UIColor.white.cgColor
    overlay.lineCap = .round
    return overlay
  }()

  private var cornerRadius: Double {
    return strokeWidth / 2.0
  }

  private var strokeWidth: Double {
    return min(2.0, Double(min(frame.size.width, frame.size.height)) / 100.0)
  }

  private var cornerWidth: Double {
    return Double(min(frame.size.width, frame.size.height)) / 8.0
  }

  private var dimOverlay: CAShapeLayer = {
    let overlay = CAShapeLayer()
    overlay.fillRule = .evenOdd
    overlay.backgroundColor = UIColor.clear.cgColor
    overlay.fillColor = UIColor.black.cgColor
    return overlay
  }()

  private var gradient: CAGradientLayer = {
    let gradient = CAGradientLayer()
    gradient.startPoint = CGPoint(x: 0, y: 0)
    gradient.endPoint = CGPoint(x: 1, y: 1)
    return gradient
  }()

  private var strokeColor: UIColor = .white {
    didSet {
      label.textColor = strokeColor
      setNeedsDisplay()
    }
  }

  private var brightGradientColor: CGColor {
    return strokeColor.cgColor
  }

  private var dimGradientColor: CGColor {
    return strokeColor.withAlphaComponent(0.0).cgColor
  }

  public var labelText: String = ReaderOverlayState.ready.rawValue {
    didSet {
      DispatchQueue.main.async {
        UIView.animate(withDuration: 0.2, animations: {
          self.label.alpha = 0.0
          self.label.text = self.labelText
          self.label.alpha = 0.8
        })
      }
    }
  }

  var rectOfInterest: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1) {
    didSet {
      setNeedsDisplay()
    }
  }

  var overlayOpacity: Float = 0.0 {
      didSet {
          dimOverlay.opacity = overlayOpacity
      }
  }

  // MARK: - Initialzers

  override init(frame: CGRect) {
    super.init(frame: frame)

    setupViews()
  }

  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)

    setupViews()
  }

  // MARK: - Drawing method

  public override func draw(_ rect: CGRect) {
    frameOverlay.removeAllAnimations()

    let innerRect = CGRect(
      x: rect.width * rectOfInterest.minX,
      y: rect.height * rectOfInterest.minY,
      width: rect.width * rectOfInterest.width,
      height: rect.height * rectOfInterest.height
    )

    let dimOverlayPath = UIBezierPath(roundedRect: rect, cornerRadius: 0.0)
    dimOverlayPath.append(UIBezierPath(roundedRect: innerRect, cornerRadius: CGFloat(cornerRadius)))
    dimOverlayPath.usesEvenOddFillRule = true
    dimOverlay.path = dimOverlayPath.cgPath

    let labelOffset = CGFloat(40.0)
    label.frame = CGRect(x: innerRect.origin.x, y: innerRect.origin.y - labelOffset, width: innerRect.width, height: labelOffset)

    let path = UIBezierPath()
    path.append(createTopLeft(innerRect))
    path.append(createTopRight(innerRect))
    path.append(createBottomRight(innerRect))
    path.append(createBottomLeft(innerRect))
    frameOverlay.path = path.cgPath
    frameOverlay.lineWidth = CGFloat(strokeWidth)

    // Gradient colors animation inteferes with rotating gradient direction enimation
    CATransaction.begin()
    CATransaction.setValue(true, forKey: kCATransactionDisableActions)
    gradient.colors = [brightGradientColor, dimGradientColor]
    gradient.mask = frameOverlay
    gradient.frame = rect
    CATransaction.commit()

//    setupGradientAnimation()
  }

}

// MARK: - Animations

extension ReaderOverlayView {

  private func setupGradientAnimation() {
    let animationGroup = CAAnimationGroup()
    animationGroup.repeatCount = .infinity
    animationGroup.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
    animationGroup.duration = 4.0
    animationGroup.autoreverses = true
    animationGroup.animations = []

    let startCorners = [[0, 0], [1, 0], [1, 1], [0, 1]]
    for cornerIdx in 0..<startCorners.count {
      let gradientStartPointAnimation = CABasicAnimation(keyPath: "startPoint")
      gradientStartPointAnimation.fromValue = startCorners[cornerIdx]
      gradientStartPointAnimation.toValue = startCorners[(cornerIdx + 1) % startCorners.count]
      gradientStartPointAnimation.beginTime = Double(cornerIdx)
      gradientStartPointAnimation.duration = 1.0
      animationGroup.animations?.append(gradientStartPointAnimation)
    }

    let endCorners = [[1, 1], [0, 1], [0, 0], [1, 0]]
    for cornerIdx in 0..<endCorners.count {
      let gradientEndPointAnimation = CABasicAnimation(keyPath: "endPoint")
      gradientEndPointAnimation.fromValue = endCorners[cornerIdx]
      gradientEndPointAnimation.toValue = endCorners[(cornerIdx + 1) % endCorners.count]
      gradientEndPointAnimation.beginTime = Double(cornerIdx)
      gradientEndPointAnimation.duration = 1.0
      animationGroup.animations?.append(gradientEndPointAnimation)
    }

    gradient.add(animationGroup, forKey: nil)
  }

}

// MARK: - UI Helpers

extension ReaderOverlayView {

  private func setupViews() {
    layer.addSublayer(frameOverlay)
    layer.addSublayer(dimOverlay)
    layer.addSublayer(gradient)

    addSubview(label)
  }

  private func configureLabel() -> UILabel {
    let label = UILabel()
    label.textAlignment = .center
    label.font = Default.labelFont
    label.textColor = strokeColor
    label.text = labelText
    label.alpha = 0.8
    return label
  }

  //  ⌜  ⌝
  //  ⌞  ⌟

  private func createTopLeft(_ frame: CGRect) -> UIBezierPath {
      let topLeft = UIBezierPath()
      topLeft.move(to: CGPoint(x: Double(frame.origin.x) - strokeWidth/2, y: Double(frame.origin.y) + cornerRadius + cornerWidth))
      topLeft.addLine(to: CGPoint(x: Double(frame.origin.x) - strokeWidth/2, y: Double(frame.origin.y) + cornerRadius))
      topLeft.addQuadCurve(to: CGPoint(x: Double(frame.origin.x) + cornerRadius, y: Double(frame.origin.y) - strokeWidth/2), controlPoint: CGPoint(x: Double(frame.origin.x) - strokeWidth/2, y: Double(frame.origin.y) - strokeWidth/2))
      topLeft.addLine(to: CGPoint(x: Double(frame.origin.x) + cornerRadius + cornerWidth, y: Double(frame.origin.y) - strokeWidth/2))
      return topLeft
   }

   private func createTopRight(_ frame: CGRect) -> UIBezierPath {
     let topRight = UIBezierPath()
     topRight.move(to: CGPoint(x: Double(frame.origin.x) + Double(frame.width) - cornerRadius - cornerWidth, y: Double(frame.origin.y) - strokeWidth/2))
     topRight.addLine(to: CGPoint(x: Double(frame.origin.x) + Double(frame.width) - cornerRadius + strokeWidth/2, y: Double(frame.origin.y) - strokeWidth/2))
     topRight.addQuadCurve(to: CGPoint(x: Double(frame.origin.x) + Double(frame.width) + strokeWidth/2, y: Double(frame.origin.y) + cornerRadius), controlPoint: CGPoint(x: Double(frame.origin.x) + Double(frame.width) + strokeWidth/2, y: Double(frame.origin.y) - strokeWidth/2))
     topRight.addLine(to: CGPoint(x: Double(frame.origin.x) + Double(frame.width) + strokeWidth/2, y: Double(frame.origin.y) + cornerRadius + cornerWidth - strokeWidth/2))
     return topRight
   }

   private func createBottomRight(_ frame: CGRect) -> UIBezierPath {
     let bottomRight = UIBezierPath()
     bottomRight.move(to: CGPoint(x: Double(frame.origin.x) + Double(frame.width) + strokeWidth/2, y: Double(frame.origin.y) + Double(frame.height) - cornerRadius - cornerWidth))
     bottomRight.addLine(to: CGPoint(x: Double(frame.origin.x) + Double(frame.width) + strokeWidth/2, y: Double(frame.origin.y) + Double(frame.height) - cornerRadius))
     bottomRight.addQuadCurve(to: CGPoint(x: Double(frame.origin.x) + Double(frame.width) - cornerRadius, y: Double(frame.origin.y) + Double(frame.height) + strokeWidth/2), controlPoint: CGPoint(x: Double(frame.origin.x) + Double(frame.width) + strokeWidth/2, y: Double(frame.origin.y) + Double(frame.height) + strokeWidth/2))
     bottomRight.addLine(to: CGPoint(x: Double(frame.origin.x) + Double(frame.width) - cornerRadius - cornerWidth, y: Double(frame.origin.y) + Double(frame.height) + strokeWidth/2))
     return bottomRight
   }

   private func createBottomLeft(_ frame: CGRect) -> UIBezierPath {
     let bottomLeft = UIBezierPath()
     bottomLeft.move(to: CGPoint(x: Double(frame.origin.x) + cornerRadius + cornerWidth, y: Double(frame.origin.y) + Double(frame.width) + strokeWidth/2))
     bottomLeft.addLine(to: CGPoint(x: Double(frame.origin.x) + cornerRadius, y: Double(frame.origin.y) + Double(frame.height) + strokeWidth/2))
     bottomLeft.addQuadCurve(to: CGPoint(x: Double(frame.origin.x) - strokeWidth/2, y: Double(frame.origin.y) + Double(frame.height) - cornerRadius), controlPoint: CGPoint(x: Double(frame.origin.x) - strokeWidth/2, y: Double(frame.origin.y) + Double(frame.height) + strokeWidth/2))
     bottomLeft.addLine(to: CGPoint(x: Double(frame.origin.x) - strokeWidth/2, y: Double(frame.origin.y) + Double(frame.height) - cornerRadius - cornerWidth))
     return bottomLeft
   }

}
