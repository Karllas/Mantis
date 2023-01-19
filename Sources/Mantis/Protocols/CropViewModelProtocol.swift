//
//  CropViewModelProtocol.swift
//  Mantis
//
//  Created by yingtguo on 12/15/22.
//

import Foundation

protocol CropViewModelProtocol: AnyObject {
    var cropBoxFrameChanged: (_ frame: CGRect) -> Void { get set }
    var cropBoxFrame: CGRect { get set }
    var cropBoxOriginFrame: CGRect { get set }
    func resetCropFrame(by frame: CGRect)
    func getNewCropBoxFrame(with point: CGPoint, and contentFrame: CGRect, aspectRatioLockEnabled: Bool) -> CGRect
    func setCropBoxFrame(by refCropBox: CGRect, and imageRationH: Double)

    var statusChanged: (_ status: CropViewStatus) -> Void { get set }
    var viewStatus: CropViewStatus { get set }
    var panOriginPoint: CGPoint { get set }
    var tappedEdge: CropViewOverlayEdge { get set }
    var degrees: CGFloat { get set }
    var radians: CGFloat { get }
    var rotationType: ImageRotationType { get set }
    var aspectRatio: CGFloat { get set }
    var cropLeftTopOnImage: CGPoint { get set }
    var cropRightBottomOnImage: CGPoint { get set }
    var horizontallyFlip: Bool { get set }
    var verticallyFlip: Bool { get set }
    
    func reset(forceFixedRatio: Bool)
    func rotateBy90(withRotateType type: RotateBy90DegreeType)
    func getTotalRadians() -> CGFloat
    func getRatioType(byImageIsOriginalHorizontal isHorizontal: Bool) -> RatioType
    func isUpOrUpsideDown() -> Bool
    func prepareForCrop(byTouchPoint point: CGPoint)
    
    func needCrop() -> Bool
    
    // MARK: - Handle view status changes
    func setInitialStatus()
    func setRotatingStatus(by angle: CGAngle)
    func setDegree90RotatingStatus()
    func setTouchImageStatus()
    func setTouchRotationBoardStatus()
    func setTouchCropboxHandleStatus()
    func setBetweenOperationStatus()
}

extension CropViewModelProtocol {
    func setInitialStatus() {
        viewStatus = .initial
    }
    
    func setRotatingStatus(by angle: CGAngle) {
        viewStatus = .rotating(angle: angle)
    }
    
    func setDegree90RotatingStatus() {
        viewStatus = .degree90Rotating
    }
    
    func setTouchImageStatus() {
        viewStatus = .touchImage
    }

    func setTouchRotationBoardStatus() {
        viewStatus = .touchRotationBoard
    }

    func setTouchCropboxHandleStatus() {
        viewStatus = .touchCropboxHandle(tappedEdge: tappedEdge)
    }
    
    func setBetweenOperationStatus() {
        viewStatus = .betweenOperation
    }
}
