enum RepeatMode {
  off,
  single,
  all;

  RepeatMode next() {
    final values = RepeatMode.values;
    final nextIndex = (index + 1) % values.length;
    return values[nextIndex];
  }
}