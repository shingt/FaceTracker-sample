import UIKit
import CoreImage

struct FaceArea {
    let trackingID: Int32
    let bounds: CGRect
    
    init (faceFeature: CIFaceFeature, applyingRatio ratio: CGFloat) {
        let bounds = CGRect(
            x: faceFeature.bounds.origin.y * ratio,
            y: faceFeature.bounds.origin.x * ratio,
            width: faceFeature.bounds.size.height * ratio,
            height: faceFeature.bounds.size.width * ratio
        )
        self.trackingID = faceFeature.trackingID
        self.bounds = bounds
    }    
}
