//
//  Mantis.swift
//  Mantis
//
//  Created by Yingtao Guo on 11/3/18.
//  Copyright © 2018 Echo Studio. All rights reserved.
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

// MARK: - APIs
public func cropViewController(image: UIImage,
                               config: Mantis.Config = Mantis.Config(),
                               cropToolbar: CropToolbarProtocol = CropToolbar(frame: .zero)) -> CropViewController {
    let cropViewController = CropViewController(config: config)
    setupCropView(for: cropViewController, with: image, and: config.cropViewConfig)
    setupCropToolbar(for: cropViewController, with: cropToolbar)
    return cropViewController
}

public func setupCropViewController(_ cropViewController: CropViewController,
                                    with image: UIImage,
                                    and config: Mantis.Config = Mantis.Config()) {
    cropViewController.config = config
    setupCropView(for: cropViewController, with: image, and: config.cropViewConfig)
    setupCropToolbar(for: cropViewController)
}

public func locateResourceBundle(by hostClass: AnyClass) {
    LocalizedHelper.setBundle(Bundle(for: hostClass))
}

public func crop(image: UIImage, by cropInfo: CropInfo) -> UIImage? {
    return image.crop(by: cropInfo)
}

// MARK: - internal section
var localizationConfig = LocalizationConfig()

// MARK: - private section
private(set) var bundle: Bundle? = {
    return Mantis.Config.bundle
}()

private func setupCropView(for cropViewController: CropViewController,
                           with image: UIImage,
                           and cropViewConfig: CropViewConfig) {
    let imageContainer = ImageContainer(image: image)
    
    let cropView = CropView(image: image,
                            cropViewConfig: cropViewConfig,
                            viewModel: buildCropViewModel(with: cropViewConfig),
                            cropOverlayView: CropOverlayView(),
                            imageContainer: imageContainer,
                            cropScrollView: buildCropScrollView(with: cropViewConfig, and: imageContainer),
                            cropMaskViewManager: buildCropMaskViewManager(with: cropViewConfig))
    
    setupRotationDialIfNeeded(with: cropViewConfig, and: cropView)
    
    cropViewController.cropView = cropView
}

private func setupCropToolbar(for cropViewController: CropViewController,
                              with cropToolbar: CropToolbarProtocol? = nil) {
    cropViewController.cropToolbar = cropToolbar ?? CropToolbar(frame: .zero)
}

private func buildCropViewModel(with cropViewConfig: CropViewConfig) -> CropViewModelProtocol {
    CropViewModel(
        cropViewPadding: cropViewConfig.padding,
        hotAreaUnit: cropViewConfig.cropBoxHotAreaUnit
    )
}

private func buildCropScrollView(with cropViewConfig: CropViewConfig, and imageContainer: ImageContainerProtocol) -> CropScrollViewProtocol {
    CropScrollView(frame: .zero,
                   minimumZoomScale: cropViewConfig.minimumZoomScale,
                   maximumZoomScale: cropViewConfig.maximumZoomScale,
                   imageContainer: imageContainer)
}

private func buildCropMaskViewManager(with cropViewConfig: CropViewConfig) -> CropMaskViewManagerProtocol {
    let dimmingView = CropDimmingView(cropShapeType: cropViewConfig.cropShapeType)
    let visualEffectView = CropMaskVisualEffectView(cropShapeType: cropViewConfig.cropShapeType,
                                                    effectType: cropViewConfig.cropMaskVisualEffectType)
    return CropMaskViewManager(dimmingView: dimmingView, visualEffectView: visualEffectView)
}

private func setupRotationDialIfNeeded(with cropViewConfig: CropViewConfig, and cropView: CropView) {
    if cropViewConfig.showRotationDial {
        let viewModel = RotationDialViewModel()
        cropView.rotationDial = RotationDial(frame: .zero,
                                             dialConfig: cropViewConfig.dialConfig,
                                             viewModel: viewModel)
    }
}
