/// Determine behaviour of FaceBoxCamera running the callback.
/// if [FaceBoxCameraMode.continuous], the function would running continously as the face detected per frame.
/// Otherwise, [FaceBoxCameraMode.block] the image stream would be block and would waiting until the processed
/// frame is finished first
enum FaceBoxCameraMode { continuous, block }
