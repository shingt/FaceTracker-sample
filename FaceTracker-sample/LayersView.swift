import UIKit

struct FaceLayer {
    let layer: CAShapeLayer
    let area: FaceArea
}

final class LayersView: UIView {
    private let layerColor = UIColor(colorLiteralRed: 0.78, green: 0.13, blue: 0.16, alpha: 0.5)
    private var drawnFaceLayers = [FaceLayer]()
   
    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = UIColor.clear
        isUserInteractionEnabled = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(with areas: [FaceArea]) {
        let drawnAreas = drawnFaceLayers.map { $0.area }
        let drawnTrackingIDs: Set<Int32> = Set(drawnAreas.map { $0.trackingID })
        let newTrackingIDs: Set<Int32> = Set(areas.map { $0.trackingID })

        let trackingIDsToBeAdded: Set<Int32> = newTrackingIDs.subtracting(drawnTrackingIDs)
        let trackingIDsToBeMoved: Set<Int32> = drawnTrackingIDs.intersection(newTrackingIDs)
        let trackingIDsToBeRemoved: Set<Int32> = drawnTrackingIDs.subtracting(newTrackingIDs)
        
        let areasToBeAdded: [FaceArea] = trackingIDsToBeAdded.flatMap { trackingID in
            areas.first { $0.trackingID == trackingID }
        }
        let areasToBeMoved: [FaceArea] = trackingIDsToBeMoved.flatMap { trackingID in
            areas.first { $0.trackingID == trackingID }
        }

        drawCircles(of: areasToBeAdded)
        moveCircles(of: areasToBeMoved)
        removeCircles(of: Array(trackingIDsToBeRemoved))
    }
    
    private func moveCircles(of areas: [FaceArea]) {
        areas.forEach { moveCircle(of: $0) }
    }
    
    private func moveCircle(of area: FaceArea) {
        guard let drawnLayerIndex = (drawnFaceLayers.index { $0.area.trackingID == area.trackingID }) else {
            return
        }
        let drawnLayer = drawnFaceLayers[drawnLayerIndex]
        let fromCentroid = drawnLayer.layer.position
        let toCentroid = area.bounds.center
        let moveAnimation = CABasicAnimation(keyPath: "position")
        moveAnimation.fromValue = NSValue(cgPoint: fromCentroid)
        moveAnimation.toValue = NSValue(cgPoint: toCentroid)
        moveAnimation.duration = 0.3
        moveAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        drawnLayer.layer.position = toCentroid
        drawnLayer.layer.add(moveAnimation, forKey: "position")
    }

    private func drawCircles(of areas: [FaceArea]) {
        areas.forEach { drawCircle(of: $0) }
    }
    
    private func drawCircle(of area: FaceArea) {
        let bounds = area.bounds
        let radius: CGFloat = (bounds.maxX - bounds.minX) / 2.0
        let circleLayer = CAShapeLayer.circle(radius: radius)
        circleLayer.frame = CGRect(x: 0, y: 0, width: radius * 2, height: radius * 2)
        circleLayer.position = bounds.center
        circleLayer.fillColor = layerColor.cgColor
        layer.addSublayer(circleLayer)
        drawnFaceLayers.append(FaceLayer(layer: circleLayer, area: area))
    }
    
    private func removeCircles(of indexes: [Int32]) {
        indexes.forEach { index in
            guard let drawnLayer = (drawnFaceLayers.first { $0.area.trackingID == index }) else { return }
            drawnLayer.layer.removeFromSuperlayer()
            drawnFaceLayers = drawnFaceLayers.filter { $0.area.trackingID != index }
        }
    }
}
