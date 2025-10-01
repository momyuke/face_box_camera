class EyeBlinkBuffer {
  final List<double> leftEyeProbs = [];
  final List<double> rightEyeProbs = [];
  final int windowSize;

  EyeBlinkBuffer({this.windowSize = 30});

  void addFrame(double leftProb, double rightProb) {
    leftEyeProbs.add(leftProb);
    rightEyeProbs.add(rightProb);

    if (leftEyeProbs.length > windowSize) leftEyeProbs.removeAt(0);
    if (rightEyeProbs.length > windowSize) rightEyeProbs.removeAt(0);
  }

  bool isBlinking() {
    if (leftEyeProbs.length < 5 || rightEyeProbs.length < 5) return false;

    // 1. Check variance
    double leftVar = _variance(leftEyeProbs);
    double rightVar = _variance(rightEyeProbs);

    const double minVariance = 0.01; // too flat = spoof
    if (leftVar < minVariance && rightVar < minVariance) {
      return false;
    }

    // 2. Check blink cycle
    bool leftBlink = _detectBlink(leftEyeProbs);
    bool rightBlink = _detectBlink(rightEyeProbs);

    return leftBlink && rightBlink;
  }

  bool _detectBlink(List<double> probs) {
    const openThresh = 0.8;
    const closeThresh = 0.2;
    bool sawOpen = false;
    bool sawClose = false;

    for (double p in probs) {
      if (p > openThresh) sawOpen = true;
      if (p < closeThresh) sawClose = true;

      // Require both open and close seen in the sequence
      if (sawOpen && sawClose) {
        return true;
      }
    }
    return false;
  }

  double _variance(List<double> values) {
    double mean = values.reduce((a, b) => a + b) / values.length;
    double sumSq = values
        .map((v) => (v - mean) * (v - mean))
        .reduce((a, b) => a + b);
    return sumSq / values.length;
  }

  void clear() {
    leftEyeProbs.clear();
    rightEyeProbs.clear();
  }
}
