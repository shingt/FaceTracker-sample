import UIKit
import AVFoundation
import CoreImage

final class DetectionViewController: UIViewController {
    fileprivate lazy var detector: CIDetector = {
        let context = CIContext()
        let options: [String : Any] = [
            CIDetectorAccuracy: CIDetectorAccuracyHigh,
            CIDetectorTracking: true
        ]
        let detector = CIDetector(ofType: CIDetectorTypeFace, context: context, options: options)!
        return detector
    }()
    fileprivate let featureDetectorOptions: [String : Any] = [
        CIDetectorImageOrientation: 6,   // Assuming portrait in this sample
    ]            
    fileprivate lazy var layersView: LayersView = {
        let view = LayersView(frame: self.view.frame)
        return view
    }()
     
    private lazy var device: AVCaptureDevice? = {
        let device = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .back)
        return device
    }()
    private lazy var deviceInput: AVCaptureDeviceInput? = {
        do {
            return try AVCaptureDeviceInput(device: self.device)
        } catch {
            print("Failed to initialize AVCaptureDeviceInput." ); return nil
        }
    }()    
    private lazy var videoDataOutput: AVCaptureVideoDataOutput = {
        let videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.setSampleBufferDelegate(self, queue: self.sampleBufferQueue)
        return videoDataOutput
    }()
    private lazy var session: AVCaptureSession? = {
        guard let deviceInput = self.deviceInput else { return nil }
        let session = AVCaptureSession()
        session.addInput(deviceInput)
        session.addOutput(self.videoDataOutput)
        return session
    }()    
    private lazy var videoPreviewLayer: AVCaptureVideoPreviewLayer? = {
        let layer = AVCaptureVideoPreviewLayer(session: self.session)
        layer?.frame = self.view.bounds
        layer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        return layer
    }()
    
    private lazy var sampleBufferQueue: DispatchQueue = {
        return DispatchQueue(label: "sample.queue")
    }()        
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        switch AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) {
        case .authorized:
            setup()
        case .notDetermined:
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: { [weak self] granted in
                guard let strongSelf = self else { return }
                guard granted else { print("You need to authorize camera access in this app."); return }
                
                strongSelf.setup()
            })
        default:
            print("You need to authorize camera access in this app."); break
        }
    }
    
    fileprivate func setup() {
        guard let session = session else { print("Failed to prepare session."); return }
        guard let videoPreviewLayer = videoPreviewLayer else { print("Failed to prepare videoPreviewLayer."); return }
        
        view.layer.addSublayer(videoPreviewLayer)
        view.addSubview(layersView)
        session.startRunning()
    }
}

extension DetectionViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ captureOutput: AVCaptureOutput!, didDrop sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        guard let cvImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvPixelBuffer: cvImageBuffer)
        let cvImageHeight = CGFloat(CVPixelBufferGetHeight(cvImageBuffer))
        let ratio = view.frame.width / cvImageHeight

        let faceAreas = detector
            .features(in: ciImage, options: featureDetectorOptions)
            .flatMap { $0 as? CIFaceFeature }
            .map { FaceArea(faceFeature: $0, applyingRatio: ratio) }
        DispatchQueue.main.async {
            self.layersView.update(with: faceAreas)
        }
        
        // Intentionally sleep since face detection is fast.
        Thread.sleep(forTimeInterval: 0.3)
    }
}
