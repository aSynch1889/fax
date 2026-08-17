import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

public final class ImageFilterUtility {
    private static let context = CIContext(options: nil)
    
    public static func apply(filter: FilterType, to image: UIImage) -> UIImage {
        guard filter != .original else { return image }
        guard let ciImage = CIImage(image: image) else { return image }
        
        var outputImage: CIImage?
        
        switch filter {
        case .original:
            return image
        case .grayscale:
            let filter = CIFilter.photoEffectNoir()
            filter.inputImage = ciImage
            outputImage = filter.outputImage
        case .blackAndWhite:
            let noir = CIFilter.photoEffectNoir()
            noir.inputImage = ciImage
            if let noirOut = noir.outputImage {
                let controls = CIFilter.colorControls()
                controls.inputImage = noirOut
                controls.contrast = 2.2
                controls.brightness = 0.1
                outputImage = controls.outputImage
            }
        case .enhancedDoc:
            let controls = CIFilter.colorControls()
            controls.inputImage = ciImage
            controls.contrast = 1.4
            controls.brightness = 0.05
            controls.saturation = 0.6
            
            if let intermediate = controls.outputImage {
                let unsharp = CIFilter.unsharpMask()
                unsharp.inputImage = intermediate
                unsharp.radius = 2.5
                unsharp.intensity = 0.8
                outputImage = unsharp.outputImage
            }
        }
        
        guard let finalCI = outputImage,
              let cgImage = context.createCGImage(finalCI, from: finalCI.extent) else {
            return image
        }
        
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
}
