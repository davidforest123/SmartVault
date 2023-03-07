bool isNumeric(String s) {
  if (s == '') {
    return false;
  }
  return double.tryParse(s) != null;
}
