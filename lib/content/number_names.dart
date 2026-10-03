const _ones = [
  '',
  'One',
  'Two',
  'Three',
  'Four',
  'Five',
  'Six',
  'Seven',
  'Eight',
  'Nine',
  'Ten',
  'Eleven',
  'Twelve',
  'Thirteen',
  'Fourteen',
  'Fifteen',
  'Sixteen',
  'Seventeen',
  'Eighteen',
  'Nineteen',
];

const _tens = [
  '',
  '',
  'Twenty',
  'Thirty',
  'Forty',
  'Fifty',
  'Sixty',
  'Seventy',
  'Eighty',
  'Ninety',
];

/// English name of [n] (1–100), as taught in Indian preschools:
/// 1 → "One", 21 → "Twenty-one", 100 → "One Hundred".
String numberNameEn(int n) {
  RangeError.checkValueInInterval(n, 1, 100, 'n');
  if (n == 100) return 'One Hundred';
  if (n < 20) return _ones[n];
  final tens = _tens[n ~/ 10];
  final ones = n % 10;
  return ones == 0 ? tens : '$tens-${_ones[ones].toLowerCase()}';
}

/// Place-value split for the numbers view: 21 → (tens: 2, ones: 1).
({int tens, int ones}) placeValue(int n) {
  RangeError.checkValueInInterval(n, 1, 100, 'n');
  return (tens: n ~/ 10, ones: n % 10);
}
