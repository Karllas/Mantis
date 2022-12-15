//
//  CropViewController.swift
//  Mantis
//
//  Created by Echo on 10/30/18.
//  Copyright © 2018 Echo. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
//  IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import UIKit

public protocol CropViewControllerDelegate: AnyObject {
    func cropViewControllerDidCrop(_ cropViewController: CropViewController,
                                   cropped: UIImage,
                                   transformation: Transformation,
                                   cropInfo: CropInfo)
    func cropViewControllerDidFailToCrop(_ cropViewController: CropViewController, original: UIImage)
    func cropViewControllerDidCancel(_ cropViewController: CropViewController, original: UIImage)
    
    func cropViewControllerDidBeginResize(_ cropViewController: CropViewController)
    func cropViewControllerDidEndResize(_ cropViewController: CropViewController, original: UIImage, cropInfo: CropInfo)
    func cropViewControllerDidImageTransformed(_ cropViewController: CropViewController)
}

public extension CropViewControllerDelegate where Self: UIViewController {
    func cropViewControllerDidFailToCrop(_ cropViewController: CropViewController, original: UIImage) {}
    func cropViewControllerDidBeginResize(_ cropViewController: CropViewController) {}
    func cropViewControllerDidEndResize(_ cropViewController: CropViewController, original: UIImage, cropInfo: CropInfo) {}
    func cropViewControllerDidImageTransformed(_ cropViewController: CropViewController) {}
}

public class CropViewController: UIViewController {
    public weak var delegate: CropViewControllerDelegate?
    public var config = Mantis.Config()
    
    private var orientation: UIInterfaceOrientation = .unknown

    var cropView: CropViewProtocol!
    var cropToolbar: CropToolbarProtocol!
    
    private var ratioPresenter: RatioPresenter?
    private var ratioSelector: RatioSelector?
    private var stackView: UIStackView?
    private var cropStackView: UIStackView!
    private var initialLayout = false
    private var disableRotation = false
    
    deinit {
        print("CropViewController deinit.")
    }
    
    init(config: Mantis.Config = Mantis.Config()) {
        self.config = config

        switch config.cropViewConfig.cropShapeType {
        case .circle, .square, .heart:
            self.config.presetFixedRatioType = .alwaysUsingOnePresetFixedRatio(ratio: 1)
        default:
            ()
        }        
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    fileprivate func createRatioSelector() {
        let fixedRatioManager = getFixedRatioManager()
        ratioSelector = RatioSelector(type: fixedRatioManager.type,
                                      originalRatioH: fixedRatioManager.originalRatioH,
                                      ratios: fixedRatioManager.ratios)
        ratioSelector?.didGetRatio = { [weak self] ratio in
            self?.setFixedRatio(ratio)
        }
    }
    
    fileprivate func createCropToolbar() {
        cropToolbar.cropToolbarDelegate = self
        
        switch config.presetFixedRatioType {
        case .alwaysUsingOnePresetFixedRatio(let ratio):
                config.cropToolbarConfig.includeFixedRatiosSettingButton = false
                                
            if case .none = config.cropViewConfig.presetTransformationType {
                    setFixedRatio(ratio)
                }
                
        case .canUseMultiplePresetFixedRatio(let defaultRatio):
                if defaultRatio > 0 {
                    setFixedRatio(defaultRatio)
                    cropView.aspectRatioLockEnabled = true
                    config.cropToolbarConfig.presetRatiosButtonSelected = true
                }
                
                config.cropToolbarConfig.includeFixedRatiosSettingButton = true
        }
        
        cropToolbar.createToolbarUI(config: config.cropToolbarConfig)                
    }
    
    private func getRatioType() -> RatioType {
        switch config.cropToolbarConfig.fixedRatiosShowType {
        case .adaptive:
            return cropView.getRatioType(byImageIsOriginalisHorizontal: cropView.image.isHorizontal())
        case .horizontal:
            return .horizontal
        case .vertical:
            return .vertical
        }
    }
    
    fileprivate func getFixedRatioManager() -> FixedRatioManager {
        let type: RatioType = getRatioType()
        
        let ratio = cropView.getImageRatioH()
        
        return FixedRatioManager(type: type,
                                 originalRatioH: ratio,
                                 ratioOptions: config.ratioOptions,
                                 customRatios: config.getCustomRatioItems())
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()

#if targetEnvironment(macCatalyst)
        modalPresentationStyle = .fullScreen
        navigationController?.modalPresentationStyle = .fullScreen
#endif
        view.backgroundColor = .black
        
        cropView.initialSetup(delegate: self, alwaysUsingOnePresetFixedRatio: isAlwaysUsingOnePresetFixedRatio())
        createCropToolbar()
        if config.cropToolbarConfig.ratioCandidatesShowType == .alwaysShowRatioList
            && config.cropToolbarConfig.includeFixedRatiosSettingButton {
            createRatioSelector()
        }
        initLayout()
        updateLayout()        
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if initialLayout == false {
            initialLayout = true
            view.layoutIfNeeded()
            cropView.adaptForCropBox()
        }
    }
    
    public override var prefersStatusBarHidden: Bool {
        return true
    }
    
    public override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        return [.top, .bottom]
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        cropView.prepareForDeviceRotation()
        handleDeviceRotated()
    }    
    
    @objc func handleDeviceRotated() {
        let currentOrientation = Orientation.interfaceOrientation
        
        guard currentOrientation != .unknown else { return }
        guard currentOrientation != orientation else { return }
        
        orientation = currentOrientation
        
        if UIDevice.current.userInterfaceIdiom == .phone
            && currentOrientation == .portraitUpsideDown {
            return
        }
        
        updateLayout()
        view.layoutIfNeeded()
        
        // When it is embedded in a container, the timing of viewDidLayoutSubviews
        // is different with the normal mode.
        // So delay the execution to make sure handleRotate runs after the final
        // viewDidLayoutSubviews
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.cropView.handleDeviceRotated()
        }
    }    
    
    private func setFixedRatio(_ ratio: Double, zoom: Bool = true) {
        cropToolbar.handleFixedRatioSetted(ratio: ratio)
        cropView.setFixedRatio(ratio, zoom: zoom, alwaysUsingOnePresetFixedRatio: isAlwaysUsingOnePresetFixedRatio())
    }
    
    private func isAlwaysUsingOnePresetFixedRatio() -> Bool {
        if case .alwaysUsingOnePresetFixedRatio = config.presetFixedRatioType {
            return true
        }
        
        return false
    }
        
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        cropView.processPresetTransformation { [weak self] transformation in
            guard let self = self else { return }
            if case .alwaysUsingOnePresetFixedRatio(let ratio) = self.config.presetFixedRatioType {
                self.cropToolbar.handleFixedRatioSetted(ratio: ratio)
                self.cropView.handlePresetFixedRatio(ratio, transformation: transformation)
            }
        }
    }
    
    private func handleCancel() {
        delegate?.cropViewControllerDidCancel(self, original: cropView.image)
    }
    
    private func resetRatioButton() {
        cropView.aspectRatioLockEnabled = false
        cropToolbar.handleFixedRatioUnSetted()
    }
    
    @objc private func handleSetRatio() {
        if cropView.aspectRatioLockEnabled {
            resetRatioButton()
            return
        }
        
        guard let presentSourceView = cropToolbar.getRatioListPresentSourceView() else {
            return
        }
        
        let fixedRatioManager = getFixedRatioManager()
        
        guard !fixedRatioManager.ratios.isEmpty else { return }
        
        if fixedRatioManager.ratios.count == 1 {
            let ratioItem = fixedRatioManager.ratios[0]
            let ratioValue = (fixedRatioManager.type == .horizontal) ? ratioItem.ratioH : ratioItem.ratioV
            setFixedRatio(ratioValue)
            return
        }
        
        ratioPresenter = RatioPresenter(type: fixedRatioManager.type,
                                        originalRatioH: fixedRatioManager.originalRatioH,
                                        ratios: fixedRatioManager.ratios,
                                        fixRatiosShowType: config.cropToolbarConfig.fixedRatiosShowType)
        ratioPresenter?.didGetRatio = {[weak self] ratio in
            self?.setFixedRatio(ratio, zoom: false)
        }
        ratioPresenter?.present(by: self, in: presentSourceView)
    }
    
    private func handleReset() {
        resetRatioButton()
        cropView.reset()
        ratioSelector?.reset()
        ratioSelector?.update(fixedRatioManager: getFixedRatioManager())
    }
    
    private func handleRotate(rotateAngle: CGFloat) {
        if !disableRotation {
            disableRotation = true
            cropView.rotateBy90(rotateAngle: rotateAngle) { [weak self] in
                self?.disableRotation = false
                self?.ratioSelector?.update(fixedRatioManager: self?.getFixedRatioManager())
            }
        }
        
    }
    
    private func handleAlterCropper90Degree() {
        cropView.handleAlterCropper90Degree()
    }
    
    private func handleHorizontallyFlip() {
        cropView.horizontallyFlip()
    }
    
    private func handleVerticallyFlip() {
        cropView.verticallyFlip()
    }
    
    private func handleCrop() {
        crop()
    }
}

// Auto layout
extension CropViewController {
    fileprivate func initLayout() {
        cropStackView = UIStackView()
        cropStackView.axis = .vertical
        cropStackView.addArrangedSubview(cropView)
        
        if let ratioSelector = ratioSelector {
            cropStackView.addArrangedSubview(ratioSelector)
        }
        
        stackView = UIStackView()
        view.addSubview(stackView!)
        
        cropStackView?.translatesAutoresizingMaskIntoConstraints = false
        stackView?.translatesAutoresizingMaskIntoConstraints = false
        cropToolbar.translatesAutoresizingMaskIntoConstraints = false
        
        stackView?.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        stackView?.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        stackView?.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
        stackView?.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
    }
    
    fileprivate func setStackViewAxis() {
        if Orientation.isPortrait {
            stackView?.axis = .vertical
        } else if Orientation.isLandscape {
            stackView?.axis = .horizontal
        }
    }
    
    fileprivate func changeStackViewOrder() {
        guard config.showAttachedCropToolbar else {
            stackView?.removeArrangedSubview(cropStackView)
            stackView?.addArrangedSubview(cropStackView)
            return
        }
        
        stackView?.removeArrangedSubview(cropStackView)
        stackView?.removeArrangedSubview(cropToolbar)
        
        if Orientation.isPortrait || Orientation.isLandscapeRight {
            stackView?.addArrangedSubview(cropStackView)
            stackView?.addArrangedSubview(cropToolbar)
        } else if Orientation.isLandscapeLeft {
            stackView?.addArrangedSubview(cropToolbar)
            stackView?.addArrangedSubview(cropStackView)
        }
    }
            
    fileprivate func updateLayout() {
        setStackViewAxis()
        cropToolbar.respondToOrientationChange()
        changeStackViewOrder()
    }
}

extension CropViewController: CropViewDelegate {    
    func cropViewDidBecomeResettable(_ cropView: CropView) {
        cropToolbar.handleCropViewDidBecomeResettable()
        delegate?.cropViewControllerDidImageTransformed(self)
    }
    
    func cropViewDidBecomeUnResettable(_ cropView: CropView) {
        cropToolbar.handleCropViewDidBecomeUnResettable()
    }
    
    func cropViewDidBeginResize(_ cropView: CropView) {
        delegate?.cropViewControllerDidBeginResize(self)
    }
    
    func cropViewDidEndResize(_ cropView: CropView) {
        delegate?.cropViewControllerDidEndResize(self, original: cropView.image, cropInfo: cropView.getCropInfo())
    }
}

extension CropViewController: CropToolbarDelegate {
    public func didSelectHorizontallyFlip(_ cropToolbar: CropToolbarProtocol) {
        handleHorizontallyFlip()
    }
    
    public func didSelectVerticallyFlip(_ cropToolbar: CropToolbarProtocol) {
        handleVerticallyFlip()
    }
    
    public func didSelectCancel(_ cropToolbar: CropToolbarProtocol) {
        handleCancel()
    }
    
    public func didSelectCrop(_ cropToolbar: CropToolbarProtocol) {
        handleCrop()
    }
    
    public func didSelectCounterClockwiseRotate(_ cropToolbar: CropToolbarProtocol) {
        handleRotate(rotateAngle: -CGFloat.pi / 2)
    }
    
    public func didSelectClockwiseRotate(_ cropToolbar: CropToolbarProtocol) {
        handleRotate(rotateAngle: CGFloat.pi / 2)
    }
    
    public func didSelectReset(_ cropToolbar: CropToolbarProtocol) {
        handleReset()
    }
    
    public func didSelectSetRatio(_ cropToolbar: CropToolbarProtocol) {
        handleSetRatio()
    }
    
    public func didSelectRatio(_ cropToolbar: CropToolbarProtocol, ratio: Double) {
        setFixedRatio(ratio)
    }
    
    public func didSelectAlterCropper90Degree(_ cropToolbar: CropToolbarProtocol) {
        handleAlterCropper90Degree()
    }    
}

// API
extension CropViewController {
    public func crop() {
        switch config.cropMode {
        case .sync:
            let cropOutput = cropView.crop()
            handleCropOutput(cropOutput)
        case .async:
            cropView.asyncCrop(completion: handleCropOutput)
        }
        
        func handleCropOutput(_ cropOutput: CropOutput) {
            guard let image = cropOutput.croppedImage else {
                delegate?.cropViewControllerDidFailToCrop(self, original: cropView.image)
                return
            }
            
            delegate?.cropViewControllerDidCrop(self,
                                                cropped: image,
                                                transformation: cropOutput.transformation,
                                                cropInfo: cropOutput.cropInfo)
        }
    }
    
    public func process(_ image: UIImage) -> UIImage? {
        return cropView.crop(image).croppedImage
    }
    
    public func getExpectedCropImageSize() -> CGSize {
        cropView.getExpectedCropImageSize()
    }

}
