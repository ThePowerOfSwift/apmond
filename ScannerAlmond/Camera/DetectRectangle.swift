

import Foundation
import AVFoundation
import Vision

class DetectRectangle{
    
    private var isAutoCaptureOn: Bool = true
    
    func getState()->Bool{
        return isAutoCaptureOn
    }
    func setState(state: Bool){
        isAutoCaptureOn = state
    }
}
