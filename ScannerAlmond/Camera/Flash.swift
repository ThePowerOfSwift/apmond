

import AVFoundation


class Flash{
    
    private var flashState: AVCaptureDevice.FlashMode = .off
    
    func getFlashState()->AVCaptureDevice.FlashMode{
        return flashState
    }
    func setFlashState(state: AVCaptureDevice.FlashMode){
        flashState = state
    }
    
}
