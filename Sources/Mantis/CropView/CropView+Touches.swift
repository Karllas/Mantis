//
//  CropView+Touches.swift
//  Mantis
//
//  Created by Echo on 5/24/19.
//

import Foundation
import UIKit

extension CropView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let newPoint = convert(point, to: self)
        
        if let rotationDial = rotationDial, rotationDial.frame.contains(newPoint) {
            return rotationDial
        }
        
        if isHitGridOverlayView(by: newPoint) {
            return self
        }
        
        if bounds.contains(newPoint) {
            return scrollView
        }
        
        return nil
    }
    
    private func isHitGridOverlayView(by touchPoint: CGPoint) -> Bool {
        let hotAreaUnit = cropViewConfig.cropBoxHotAreaUnit
        
        return cropOverlayView.frame.insetBy(dx: -hotAreaUnit/2, dy: -hotAreaUnit/2).contains(touchPoint)
        && !cropOverlayView.frame.insetBy(dx: hotAreaUnit/2, dy: hotAreaUnit/2).contains(touchPoint)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        guard touches.count == 1, let touch = touches.first else {
            return
        }
        
        // A resize event has begun by grabbing the crop UI, so notify delegate
        delegate?.cropViewDidBeginResize(self)
        
        if touch.view is RotationDial {
            viewModel.setTouchRotationBoardStatus()
            return
        }
        
        let point = touch.location(in: self)
        viewModel.prepareForCrop(byTouchPoint: point)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        
        guard touches.count == 1, let touch = touches.first else {
            return
        }
        
        if touch.view is RotationDial {
            return
        }
        
        let point = touch.location(in: self)
        updateCropBoxFrame(with: point)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        if viewModel.needCrop() {
            cropOverlayView.handleEdgeUntouched()
            let contentRect = getContentBounds()
            adjustUIForNewCrop(contentRect: contentRect) {[weak self] in
                self?.delegate?.cropViewDidEndResize(self!)
                self?.viewModel.setBetweenOperationStatus()
                self?.scrollView.updateMinZoomScale()
            }
        } else {
            delegate?.cropViewDidEndResize(self)
            viewModel.setBetweenOperationStatus()
        }
    }
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UIPanGestureRecognizer {
            return false
        }
        
        return true
    }
}
