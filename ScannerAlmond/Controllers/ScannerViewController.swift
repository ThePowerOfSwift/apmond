//
//  ScannerViewController.swift
//  ScannerAlmond
//
//  Created by apple on 13.02.2018.
//  Copyright © 2018 apple. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class ScannerViewController: UIViewController {
    
    @IBOutlet weak var photoCollection: UIImageView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var takePhotoButton: UIButton!
    
    @IBOutlet weak var countPhotoInSessionLabel: UILabel!
    @IBOutlet weak var circleForCountPhotoImageView: UIImageView!
    @IBOutlet weak var flashButtonOutlet: UIButton!
    @IBOutlet weak var autoCaptureZoneOutlet: UIImageView!
    @IBOutlet weak var autoCaptureTextOutlet: UIButton!
    
    
    var session = AVCaptureSession()
    var requests = [VNRequest]()
    var photoOutput: AVCapturePhotoOutput?
    
    var stateFlash = Flash()
    var detectRectangle = DetectRectangle()
    
    var photoImage: UIImage?
    var arrayOfPhotoInMemory = [UIImage] ()
    
    private var rectangleLayer: CAShapeLayer?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        startLiveVideo()
        startRectDetection()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        countPhotoInSessionLabel.text = "\(arrayOfPhotoInMemory.count)"
    }
    override func viewDidAppear(_ animated: Bool) {

    }
    
    
    
    override func viewDidLayoutSubviews() {
        imageView.layer.sublayers?[0].frame = imageView.bounds
    }
    
    
    //MARK: - Buttons

    @IBAction func takePhotoActionButton(_ sender: Any) {
        
        let settings = AVCapturePhotoSettings()
        var state = stateFlash.getFlashState()
        settings.flashMode = state
        photoOutput?.capturePhoto(with: settings, delegate: self)
    }
    
    
    @IBAction func changeFlash(_ sender: Any) {
        
        
        if stateFlash.getFlashState() == .off {
            flashButtonOutlet.setImage(UIImage(named:"automaticFlash.png"), for: UIControlState.normal)
            stateFlash.setFlashState(state: .auto)
        } else {
            flashButtonOutlet.setImage(UIImage(named:"automaticFlashOff.png"), for: UIControlState.normal)
            stateFlash.setFlashState(state: .off)
        }
    }
    
    
    @IBAction func changeAutoCapture(_ sender: Any) {
        if autoCaptureTextOutlet.title(for: .normal) == "Auto-Capture On"{
            autoCaptureZoneOutlet.image = UIImage(named: "AutoCapture2.png")
            autoCaptureTextOutlet.setTitle("Auto-Capture Off", for: UIControlState.normal)
            detectRectangle.setState(state: false)
        } else {
            autoCaptureZoneOutlet.image = UIImage(named: "AutoCapture.png")
            autoCaptureTextOutlet.setTitle("Auto-Capture On", for: UIControlState.normal)
            detectRectangle.setState(state: true)
        }
    }
    
    @IBAction func cancle(_ sender: Any) {
    }
    
    @IBAction func goToGallery(_ sender: Any) {
    }
    
    
    
    
    
    
}

//MARK: - Work with camera
extension ScannerViewController: AVCaptureVideoDataOutputSampleBufferDelegate, AVCapturePhotoCaptureDelegate {
    
    //MARK: - Stream
    func startLiveVideo() {
        //1
        session.sessionPreset = AVCaptureSession.Preset.photo
        let captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
        
        //2
        let deviceInput = try! AVCaptureDeviceInput(device: captureDevice!)
        let deviceOutput = AVCaptureVideoDataOutput()
        deviceOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        deviceOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.default))
        session.addInput(deviceInput)
        session.addOutput(deviceOutput)
        
        //4
        photoOutput = AVCapturePhotoOutput()
        session.addOutput(photoOutput!)
        
        //3
        let imageLayer = AVCaptureVideoPreviewLayer(session: session)
        imageLayer.frame = imageView.bounds
        imageView.layer.addSublayer(imageLayer)
        session.startRunning()
    }
    
    //MARK: - Detect object
    func startRectDetection() {
        var rectangleBoxRequest = VNDetectRectanglesRequest(completionHandler:self.detectRectangles)
        self.requests = [rectangleBoxRequest]
    }
    
    private func detectRectangles(request: VNRequest, error: Error?) {
        
        // contain the result of request
        guard let observations = request.results else {
            print("no result")
            return
        }
        
        // and then transform result to VNRectObserv
        let result = observations.map({$0 as? VNRectangleObservation})
        
        if detectRectangle.getState(){
            DispatchQueue.main.async() {
                self.imageView.layer.sublayers?.removeSubrange(1...)
                for region in result {
                    guard let rg = region else {
                        continue
                    }
                    self.highlightObject(box: rg)
                }
            }
        } else {
            DispatchQueue.main.async() {
                self.imageView.layer.sublayers?.removeSubrange(1...)
            }
            
        }
    }
    
    private func highlightObject(box: VNRectangleObservation) {
        
        let points = [box.bottomLeft, box.topLeft, box.topRight, box.bottomRight]
        let convertedPoints = points.map { self.convertFromCamera($0) }
        self.rectangleLayer = self.drawBoundingBox(convertedPoints, color: #colorLiteral(red: 0.3328347607, green: 0.236689759, blue: 1, alpha: 1))
        imageView.layer.addSublayer(self.rectangleLayer!)
    }
    
    private func convertFromCamera(_ point: CGPoint) -> CGPoint {
        
        let orientation = UIApplication.shared.statusBarOrientation
        
        switch orientation {
        case .portrait, .unknown:
            return CGPoint(x: point.y * self.imageView.frame.width, y: point.x * self.imageView.frame.height)
        case .landscapeLeft:
            return CGPoint(x: (1 - point.x) * self.imageView.frame.width, y: point.y * self.imageView.frame.height)
        case .landscapeRight:
            return CGPoint(x: point.x * self.imageView.frame.width, y: (1 - point.y) * self.imageView.frame.height)
        case .portraitUpsideDown:
            return CGPoint(x: (1 - point.y) * self.imageView.frame.width, y: (1 - point.x) * self.imageView.frame.height)
        }
        
    }
    
    private func drawBoundingBox(_ points: [CGPoint], color: CGColor) -> CAShapeLayer {
        let layer = CAShapeLayer()
        layer.fillColor = #colorLiteral(red: 0.4506933627, green: 0.5190293554, blue: 0.9686274529, alpha: 0.2050513699)
        layer.strokeColor = color
        layer.lineWidth = 2
        let path = UIBezierPath()
        path.move(to: points.last!)
        points.forEach { point in
            path.addLine(to: point)
        }
        layer.path = path.cgPath
        return layer
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        var requestOptions:[VNImageOption : Any] = [:]
        
        if let camData = CMGetAttachment(sampleBuffer, kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, nil) {
            requestOptions = [.cameraIntrinsics:camData]
        }
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: requestOptions)
        
        do {
            try imageRequestHandler.perform(self.requests)
        } catch {
            print(error)
        }
    }

    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
    
        if let imageData = photo.fileDataRepresentation(){
            print(imageData)
            photoImage = UIImage(data: imageData)
            arrayOfPhotoInMemory.append(photoImage!)
            photoCollection.backgroundColor = UIColor.clear
            photoCollection.image = self.photoImage
            countPhotoInSessionLabel.text = "\(arrayOfPhotoInMemory.count)"

        }
    }
    
    // flash
    func toggleFlash() -> Bool {

        var isOn: Bool = false
        let device = AVCaptureDevice.default(for: AVMediaType.video)
        if (device?.hasTorch)! == false {
            do {
                try device?.lockForConfiguration()
                if (device?.torchMode == AVCaptureDevice.TorchMode.auto) {
                    device?.torchMode = AVCaptureDevice.TorchMode.off
                    isOn = false
                } else {
                    do {
                        try device?.setTorchModeOn(level: 1.0)
                        isOn = true
                    } catch {
                        print(error)
                    }
                }
                device?.unlockForConfiguration()
            } catch {
                print(error)
            }
        }
        return isOn
    }
    
    
    
}









