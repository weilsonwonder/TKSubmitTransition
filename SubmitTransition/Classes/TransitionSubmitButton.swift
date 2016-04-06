import Foundation
import UIKit

@IBDesignable
public class TKTransitionSubmitButton : UIButton, UIViewControllerTransitioningDelegate {
    
    lazy var spiner: SpinerLayer! = {
        let s = SpinerLayer(frame: self.frame)
        self.layer.addSublayer(s)
        return s
    }()
    
    @IBInspectable public var spinnerColor: UIColor = UIColor.whiteColor() {
        didSet {
            spiner.spinnerColor = spinnerColor
        }
    }
    
    public var didEndFinishAnimation : (()->())? = nil

    let springGoEase = CAMediaTimingFunction(controlPoints: 0.45, -0.36, 0.44, 0.92)
    let shrinkCurve = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
    let expandCurve = CAMediaTimingFunction(controlPoints: 0.95, 0.02, 1, 0.05)
    let shrinkDuration: CFTimeInterval  = 0.1
    var originalWidth: CGFloat = 0
    var originalCornerRadius: CGFloat = 0
    @IBInspectable public var normalCornerRadius:CGFloat? = 0.0{
        didSet {
            self.layer.cornerRadius = normalCornerRadius!
        }
    }

    var cachedTitle: String?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }

    public required init!(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        self.setup()
    }

    func setup() {
        self.originalWidth = frame.width
        self.clipsToBounds = true
        spiner.spinnerColor = spinnerColor
    }
    
    public func startLoadingAnimation(completion: (Void -> Void)?) {
        self.cachedTitle = titleForState(.Normal)
        self.setTitle("", forState: .Normal)
        self.originalCornerRadius = self.layer.cornerRadius
        UIView.animateWithDuration(0.1, animations: {
            self.layer.cornerRadius = self.frame.height / 2
            }) { (done) -> Void in
                self.shrink()
                NSTimer.schedule(delay: self.shrinkDuration - 0.25) { timer in
                    
                    self.spiner.animation()
                }
                completion?()
        }
    }
    
    public func stopLoadingAnimation(completion: (Void -> Void)?) {
        setTitle(self.cachedTitle, forState: UIControlState.Normal)
        UIView.animateWithDuration(0.1, animations: {
            self.layer.cornerRadius = self.originalCornerRadius
            }) { (done) -> Void in
                self.revertShrink()
                self.spiner.stopAnimation()
                completion?()
        }
    }

    public func startFinishAnimation(completion: (Void -> Void)?) {
        self.didEndFinishAnimation = completion
        self.expand()
        self.spiner.stopAnimation()
    }

    public func animate(duration: NSTimeInterval, completion:(()->())?) {
        startLoadingAnimation(nil)
        startFinishAnimation(completion)
    }

    public func setOriginalState() {
        self.returnToOriginalState()
        self.spiner.stopAnimation()
    }
    
    public override func animationDidStop(anim: CAAnimation, finished flag: Bool) {
        let a = anim as! CABasicAnimation
        if a.keyPath == "transform.scale" {
            didEndFinishAnimation?()
            NSTimer.schedule(delay: 1) { timer in
                self.returnToOriginalState()
            }
        }
    }
    
    public func returnToOriginalState() {
        
        self.layer.removeAllAnimations()
        self.setTitle(self.cachedTitle, forState: .Normal)
        self.spiner.stopAnimation()
    }
    
    func revertShrink() {
        let revertShrinkAnim = CABasicAnimation(keyPath: "bounds.size.width")
        revertShrinkAnim.fromValue = frame.height
        revertShrinkAnim.toValue = self.originalWidth
        revertShrinkAnim.duration = shrinkDuration
        revertShrinkAnim.timingFunction = shrinkCurve
        revertShrinkAnim.fillMode = kCAFillModeForwards
        revertShrinkAnim.removedOnCompletion = false
        layer.addAnimation(revertShrinkAnim, forKey: revertShrinkAnim.keyPath)
    }
    
    func shrink() {
        let shrinkAnim = CABasicAnimation(keyPath: "bounds.size.width")
        shrinkAnim.fromValue = frame.width
        shrinkAnim.toValue = frame.height
        shrinkAnim.duration = shrinkDuration
        shrinkAnim.timingFunction = shrinkCurve
        shrinkAnim.fillMode = kCAFillModeForwards
        shrinkAnim.removedOnCompletion = false
        layer.addAnimation(shrinkAnim, forKey: shrinkAnim.keyPath)
    }
    
    func expand() {
        let expandAnim = CABasicAnimation(keyPath: "transform.scale")
        expandAnim.fromValue = 1.0
        expandAnim.toValue = 26.0
        expandAnim.timingFunction = expandCurve
        expandAnim.duration = 0.3
        expandAnim.delegate = self
        expandAnim.fillMode = kCAFillModeForwards
        expandAnim.removedOnCompletion = false
        layer.addAnimation(expandAnim, forKey: expandAnim.keyPath)
    }
    
}
