//
//  CameraViewController.swift
//  UnityChallenge
//
//  Created by Travis Chambers on 9/22/17.
//  Copyright © 2017 Travis Chambers. All rights reserved.
//

import UIKit
import AVFoundation
import CoreData

struct KeychainConfiguration {
    static let serviceName = "UnityImages"
    static let accessGroup: String? = nil
}

class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {

    var captureSesssion : AVCaptureSession!
    var cameraOutput : AVCapturePhotoOutput!
    var previewLayer : AVCaptureVideoPreviewLayer!
    @IBOutlet weak var previewView: UIView!
    var imagesTaken:Int = 0
    var timer:Timer? = nil
    var passwordItems: [KeychainPasswordItem] = []
    var images: [Data] = []

    
    override func viewDidLoad() {
        super.viewDidLoad()
        createCameraSession()
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startTimer()
    }
    
    func createCameraSession() {
        captureSesssion = AVCaptureSession()
        captureSesssion.sessionPreset = AVCaptureSessionPresetPhoto
        cameraOutput = AVCapturePhotoOutput()
        let device = AVCaptureDevice.defaultDevice(
            withDeviceType: .builtInWideAngleCamera,
            mediaType: AVMediaTypeVideo,
            position: .front)
        if let input = try? AVCaptureDeviceInput(device: device) {
            if (captureSesssion.canAddInput(input)) {
                captureSesssion.addInput(input)
                if (captureSesssion.canAddOutput(cameraOutput)) {
                    captureSesssion.addOutput(cameraOutput)
                    previewLayer = AVCaptureVideoPreviewLayer(session: captureSesssion)
                    previewLayer.frame = previewView.bounds
                    previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
                    
                    previewView.layer.addSublayer(previewLayer)
                    captureSesssion.startRunning()
                }
            } else {
                print("issue here : captureSesssion.canAddInput")
            }
        } else {
            print("some problem here")
        }
    }
    
    func startTimer() {
        
        timer = Timer.scheduledTimer(timeInterval: 0.5,
                                                       target: self,
                                                       selector:  #selector(self.takePhoto(_:)),
                                                       userInfo: nil,
                                                       repeats: true)
        
    }
    
    func takePhoto(_ timer:Timer){
        if(imagesTaken < 10) {
            let settings = AVCapturePhotoSettings()
            let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
            let previewFormat = [
                kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
                kCVPixelBufferWidthKey as String: 160,
                kCVPixelBufferHeightKey as String: 160
            ]
            settings.previewPhotoFormat = previewFormat
            cameraOutput.capturePhoto(with: settings, delegate: self)
        }
        if(imagesTaken == 10) {
            let alert = UIAlertController(title: "Finsihed", message: "10 Images were taken", preferredStyle: UIAlertControllerStyle.alert)

            alert.addAction(UIAlertAction(title: "Done", style: UIAlertActionStyle.default, handler: nil))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler:nil))
            self.present(alert, animated: true, completion: nil)
        }
    }

    
    // callBack from take picture
    func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        
        if let error = error {
            print("error occure : \(error.localizedDescription)")
        }
        
        if  let sampleBuffer = photoSampleBuffer,
            let previewBuffer = previewPhotoSampleBuffer,
            let dataImage =  AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer:  sampleBuffer, previewPhotoSampleBuffer: previewBuffer) {
            
            let dataProvider = CGDataProvider(data: dataImage as CFData)
            let cgImageRef: CGImage! = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
            let image = UIImage(cgImage: cgImageRef, scale: 1.0, orientation: UIImageOrientation.right)
            imagesTaken = imagesTaken + 1
            let imageData = UIImageJPEGRepresentation(image, 0.0)
            images.append(imageData!)
            self.save(imageData: imageData! as NSData)
            
        } else {
            print("some error here")
        }
    }
    
    func save(imageData: NSData) {
        
        let imgEncoded = imageData.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
        let data = NSKeyedArchiver.archivedData(withRootObject: imgEncoded)
        /// Save Image to keychain here
//        let keychainItem = KeychainItemWrapper(identifier: "com.UnityChallenge", accessGroup: nil)
//        keychainItem["secretKey"] = data as AnyObject

    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
