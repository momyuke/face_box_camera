/// Determine behaviour of FaceBoxCamera running the image stream callback.
/// if [FaceBoxCameraMode.continuous], the image stream callback would running continously as the face detected per frame.
/// Otherwise, [FaceBoxCameraMode.block] the image stream callback would be block and would waiting until the processed
/// frame is finished first
enum FaceBoxCameraMode { continuous, block }
