import 'dart:math';

bool isConsonant(String c) {
  if (c.length != 1) {
    throw Exception("isConsonant with length != 1");
  }
  switch (c) {
    // Open-vowel or close-vowel with written accent
    // Added uppercase variants explicitly as Dart switch is case-sensitive
    case 'a':
    case 'á':
    case 'A':
    case 'Á':
    case 'à':
    case 'À':
    case 'e':
    case 'é':
    case 'E':
    case 'É':
    case 'è':
    case 'È':
    case 'í':
    case 'Í':
    case 'ì':
    case 'Ì':
    case 'o':
    case 'ó':
    case 'O':
    case 'Ó':
    case 'ò':
    case 'Ò':
    case 'ú':
    case 'Ú':
    case 'ù':
    case 'Ù':
    // Close-vowel
    case 'i':
    case 'I':
    case 'u':
    case 'U':
    case 'ü':
    case 'Ü':
      return false; // It's a vowel
  }
  return true; // It's a consonant
}

String getRandomLetter(String c, Random random) {
  const consonants = 'BCDFGHJKLMNÑPQRSTVWXYZ';
  const vowels = 'AEIOU';
  String chars;

  if (isConsonant(c)) {
    chars = consonants;
  } else {
    chars = vowels;
  }

  String toreturn;
  while (true) {
    toreturn = chars[random.nextInt(chars.length - 1)];
    if (toreturn != c) {
      print(c);
      print(toreturn);
      return toreturn;
    }
  }
}
