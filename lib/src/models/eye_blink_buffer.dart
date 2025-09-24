class EyeBlinkBuffer {
  final int maxLength;
  final List<double> leftEyeBuffer = [];
  final List<double> rightEyeBuffer = [];

  EyeBlinkBuffer({this.maxLength = 3});

  void add(double leftEyeProbability, double rightEyeProbability) {
    if (leftEyeBuffer.length >= maxLength) leftEyeBuffer.removeAt(0);
    if (rightEyeBuffer.length >= maxLength) rightEyeBuffer.removeAt(0);

    leftEyeBuffer.add(leftEyeProbability);
    rightEyeBuffer.add(rightEyeProbability);
  }

  bool isBlinking() {
    const closedThreshold = 0.3;
    const openThreshold = 0.6;

    if (leftEyeBuffer.length < maxLength || rightEyeBuffer.length < maxLength) {
      return false;
    }

    bool wasOpen =
        leftEyeBuffer.first > openThreshold &&
        rightEyeBuffer.first > openThreshold;
    bool isClosed =
        leftEyeBuffer[maxLength ~/ 2] < closedThreshold &&
        rightEyeBuffer[maxLength ~/ 2] < closedThreshold;
    bool isOpenAgain =
        leftEyeBuffer.last > openThreshold &&
        rightEyeBuffer.last > openThreshold;

    return wasOpen && isClosed && isOpenAgain;
  }

  void clear() {
    leftEyeBuffer.clear();
    rightEyeBuffer.clear();
  }
}
