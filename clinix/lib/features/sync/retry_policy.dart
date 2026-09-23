class RetryPolicy {
  static const List<Duration> delays = [
    Duration(seconds: 2),
    Duration(seconds: 5),
    Duration(seconds: 10),
    Duration(seconds: 30),
    Duration(seconds: 60),
  ];

  static Duration getDelay(int retryCount) {
    if (retryCount < 0) {
      return delays.first;
    }

    if (retryCount >= delays.length) {
      return delays.last;
    }

    return delays[retryCount];
  }

  static bool canRetry(int retryCount) {
    return retryCount < delays.length;
  }
}