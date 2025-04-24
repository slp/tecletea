/*
 * Separador silábico para el Español                                           
 * Autor  : Zenón J. Hernández Figueroa                                         
 *          Gustavo Rodríguez Rodríguez                                         
 *          Francisco Carreras Riudavets                                        
 * Ported to Java by Victor Hugo Borja.
 * Ported to Dart by Sergio Lopez Pascual.
 * Version: 1.1 (Java), 1.0 (Dart)                                              
 * Date   : 12-02-2010 (Java)                                                   
 * Date   : 24-04-2025 (Dart)
 *                                                                              
 *------------------------------------------------------------------------------
 * Copyright (C) 2009 TIP: Text & Information Processing                        
 * (http://tip.dis.ulpgc.es)                                                    
 * All rights reserved.                                                         
 *                                                                              
 * This file is part of SeparatorOfSyllables                                    
 * SeparatorOfSyllables is free software; you can redistribute it and/or        
 * modify it under the terms of the GNU General Public License                  
 * as published by the Free Software Foundation; either version 3               
 * of the License, or (at your option) any later version.                       
 *                                                                              
 * This program is distributed in the hope that it will be useful,              
 * but WITHOUT ANY WARRANTY; without even the implied warranty of               
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                
 * GNU General Public License for more details.                                 
 *                                                                              
 * You should have received a copy of the GNU General Public License            
 * along with this program; if not, write to the Free Software                  
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307,USA.   
 *                                                                              
 * The "GNU General Public License" (GPL) is available at                       
 * http://www.gnu.org/licenses/old-licenses/gpl-2.0.html                        
 *                                                                              
 * When citing this resource, please use the following reference:               
 * Hernández-Figueroa, Z; Rodríguez-Rodríguez, G; Carreras-Riudavets, F (2009). 
 * Separador de sílabas del español - Silabeador TIP.                           
 * Available at http://tip.dis.ulpgc.es                                         
 */

class Syllables {
  final String _word;
  final List<int> _positions;
  final int _wordLength;
  bool _stressedFound;
  int _stressed;
  int _letterAccent;

  Syllables._(String word)
      : _word = word,
        _wordLength = word.length,
        _positions = <int>[],
        _stressedFound = false,
        _stressed = 0,
        _letterAccent = -1;

  String getAccentedCharacter() {
    if (_letterAccent > -1) {
      return _word[_letterAccent];
    }
    return String.fromCharCode(0);
  }

  List<int> getPositions() {
    return _positions;
  }

  int getStressedPosition() {
    return _stressed;
  }

  List<String> getSyllables() {
    List<String> syllabes = <String>[];
    for (int i = 0; i < _positions.length; i++) {
      int start = _positions[i];
      int end = _wordLength;
      if (_positions.length > i + 1) {
        end = _positions[i + 1];
      }
      String seq = _word.substring(start, end);
      syllabes.add(seq);
    }
    return syllabes;
  }

  static Syllables process(String seq) {
    Syllables syllables = Syllables._(seq);
    syllables._process();
    return syllables;
  }

  void _process() {
    int numSyl = 0;

    // Look for syllables in the word
    for (int i = 0; i < _wordLength;) {
      _positions.add(i);
      numSyl++;

      i = _onset(i);
      i = _nucleus(i);
      i = _coda(i);

      if (_stressedFound && _stressed == 0) {
        _stressed = numSyl; // it marks the stressed syllable
      }
    }

    // If the word has not written accent, the stressed syllable is determined
    // according to the stress rules

    if (!_stressedFound) {
      if (numSyl < 2) {
        _stressed = numSyl; // Monosyllables
      } else {
        // Polysyllables
        String endLetter = _toLower(_wordLength - 1);

        if ((!_isConsonant(_wordLength - 1) || (endLetter == 'y')) ||
            (((endLetter == 'n') ||
                (endLetter == 's') && !_isConsonant(_wordLength - 2)))) {
          _stressed = numSyl - 1; // Stressed penultimate syllable
        } else {
          _stressed = numSyl; // Stressed last syllable
        }
      }
    }
  }

  /// Determines the onset of the current syllable whose begins in pos
  /// and pos is changed to the follow position after end of onset.
  ///
  /// @param pos
  /// @return pos
  int _onset(int pos) {
    // Dart doesn't have char, use String for single characters
    String lastConsonant = 'a';

    while (pos < _wordLength && (_isConsonant(pos) && _toLower(pos) != 'y')) {
      lastConsonant = _toLower(pos);
      pos++;
    }

    // (q | g) + u (example: queso, gueto)
    if (pos < _wordLength - 1) {
      if (_toLower(pos) == 'u') {
        if (lastConsonant == 'q') {
          pos++;
        } else if (lastConsonant == 'g') {
          String letter = _toLower(pos + 1);
          if (letter == 'e' ||
              letter == 'é' ||
              letter == 'i' ||
              letter == 'í') {
            pos++;
          }
        }
      } else if (_toLower(pos) == 'ü' && lastConsonant == 'g') {
        // The 'u' with diaeresis is added to the consonant
        pos++;
      }
    }

    return pos;
  }

  /// Determines the nucleus of current syllable whose onset ending on pos - 1
  /// and changes pos to the follow position behind of nucleus
  int _nucleus(int pos) {
    // Saves the type of previous vowel when two vowels together exists
    int previous = 0;
    // 0 = open
    // 1 = close with written accent (Not explicitly used like this in logic, but comment kept)
    // 2 = close

    if (pos >= _wordLength) return pos; // ¡¿Doesn't it have nucleus?!

    // Jumps a letter 'y' to the starting of nucleus, it is as consonant
    if (_toLower(pos) == 'y') pos++;

    // First vowel
    if (pos < _wordLength) {
      // Dart switch statement works on Strings
      switch (_toLower(pos)) {
        // Open-vowel or close-vowel with written accent
        case 'á':
        case 'à':
        case 'é':
        case 'è':
        case 'ó':
        case 'ò':
          _letterAccent = pos;
          _stressedFound = true;
          previous = 0;
          pos++;
          break;
        // Open-vowel
        case 'a':
        case 'e':
        case 'o':
          previous = 0;
          pos++;
          break;
        // Close-vowel with written accent breaks some possible diphthong
        case 'í':
        case 'ì':
        case 'ú':
        case 'ù':
        case 'ü':
          _letterAccent = pos;
          pos++;
          _stressedFound = true;
          return pos;
        // Close-vowel
        case 'i': // case 'I': Dart toLowerCase handles this
        case 'u': // case 'U': Dart toLowerCase handles this
          previous = 2;
          pos++;
          break;
      }
    }

    // If 'h' has been inserted in the nucleus then it doesn't determine diphthong neither hiatus

    bool aitch = false;
    if (pos < _wordLength) {
      if (_toLower(pos) == 'h') {
        pos++;
        aitch = true;
      }
    }

    // Second vowel

    if (pos < _wordLength) {
      switch (_toLower(pos)) {
        // Open-vowel with written accent
        case 'á':
        case 'à':
        case 'é':
        case 'è':
        case 'ó':
        case 'ò':
          _letterAccent = pos;
          if (previous == 0) {
            // Two open-vowels don't form syllable
            if (aitch) pos--;
            return pos;
          } else {
            _stressedFound = true;
          }

          break;

        // Open-vowel
        case 'a':
        case 'e':
        case 'o':
          if (previous == 0) {
            // Two open-vowels don't form syllable
            if (aitch) pos--;
            return pos;
          } else {
            pos++;
          }

          break;

        // Close-vowel with written accent, can't be a triphthong, but would be a diphthong
        case 'í':
        case 'ì':
        case 'ú':
        case 'ù':
          _letterAccent = pos;

          if (previous != 0) {
            // Diphthong
            _stressedFound = true;
            pos++;
          } else if (aitch) {
            pos--;
          }

          return pos;
        // Close-vowel
        case 'i':
        case 'u':
        case 'ü':
          if (pos < _wordLength - 1) {
            // ¿Is there a third vowel?
            if (!_isConsonant(pos + 1)) {
              // Check previous character safely
              if (pos > 0 && _toLower(pos - 1) == 'h') pos--;
              return pos;
            }
          }

          // Two equals close-vowels don't form diphthong
          if (pos > 0 && _toLower(pos) != _toLower(pos - 1)) pos++;

          int firstVowelPos = aitch ? pos - 2 : pos - 1;
          if (firstVowelPos >= 0 && _toLower(pos) != _toLower(firstVowelPos)) {
            pos++;
          } else if (firstVowelPos < 0) {
            if (pos > 0 && _toLower(pos) != _toLower(pos - 1)) {
              pos++;
            }
          }

          return pos; // It is a descendent diphthong
      }
    }

    // Third vowel?

    if (pos < _wordLength) {
      // Check third vowel (close vowel)
      String lowerPos = _toLower(pos);
      if ((lowerPos == 'i') || (lowerPos == 'u')) {
        // Close-vowel
        pos++;
        return pos; // It is a triphthong
      }
    }

    return pos;
  }

  int _coda(int pos) {
    if (pos >= _wordLength || !_isConsonant(pos)) {
      return pos; // Syllable hasn't coda
    } else if (pos == _wordLength - 1) {
      // End of word
      pos++;
      return pos;
    }

    // If there is only a consonant between vowels, it belongs to the following syllable
    if (!_isConsonant(pos + 1)) return pos;

    String c1 = _toLower(pos);
    String c2 = _toLower(pos + 1);

    // Has the syllable a third consecutive consonant?

    if (pos < _wordLength - 2) {
      String c3 = _toLower(pos + 2);

      if (!_isConsonant(pos + 2)) {
        // There isn't third consonant
        // The groups ll, ch and rr begin a syllable

        if ((c1 == 'l') && (c2 == 'l')) return pos;
        if ((c1 == 'c') && (c2 == 'h')) return pos;
        if ((c1 == 'r') && (c2 == 'r')) return pos;

        // A consonant + 'h' begins a syllable, except for groups sh and rh
        if ((c1 != 's') && (c1 != 'r') && (c2 == 'h')) return pos;

        // If the letter 'y' is preceded by the some
        //      letter 's', 'l', 'r', 'n' or 'c' then
        //      a new syllable begins in the previous consonant
        // else it begins in the letter 'y'

        if ((c2 == 'y')) {
          if ((c1 == 's') ||
              (c1 == 'l') ||
              (c1 == 'r') ||
              (c1 == 'n') ||
              (c1 == 'c')) {
            return pos;
          }

          pos++;
          return pos;
        }

        // groups: gl - kl - bl - vl - pl - fl - tl

        if ((((c1 == 'b') ||
                (c1 == 'v') ||
                (c1 == 'c') ||
                (c1 == 'k') ||
                (c1 == 'f') ||
                (c1 == 'g') ||
                (c1 == 'p') ||
                (c1 == 't')) &&
            (c2 == 'l'))) {
          return pos;
        }

        // groups: gr - kr - dr - tr - br - vr - pr - fr

        if ((((c1 == 'b') ||
                (c1 == 'v') ||
                (c1 == 'c') ||
                (c1 == 'd') ||
                (c1 == 'k') ||
                (c1 == 'f') ||
                (c1 == 'g') ||
                (c1 == 'p') ||
                (c1 == 't')) &&
            (c2 == 'r'))) {
          return pos;
        }

        pos++;
        return pos;
      } else {
        // There is a third consonant
        if ((pos + 3) == _wordLength) {
          // Three consonants to the end, foreign words?
          if ((c2 == 'y')) {
            // 'y' as vowel
            if ((c1 == 's') ||
                (c1 == 'l') ||
                (c1 == 'r') ||
                (c1 == 'n') ||
                (c1 == 'c')) {
              return pos;
            }
          }

          if (c3 == 'y') {
            // 'y' at the end as vowel with c2
            pos++;
          } else {
            // Three consonants to the end, foreign words?
            pos += 3;
          }
          return pos;
        }

        if ((c2 == 'y')) {
          // 'y' as vowel
          if ((c1 == 's') ||
              (c1 == 'l') ||
              (c1 == 'r') ||
              (c1 == 'n') ||
              (c1 == 'c')) {
            return pos;
          }

          pos++;
          return pos;
        }

        // The groups pt, ct, cn, ps, mn, gn, ft, pn, cz, tz and ts begin a syllable
        // when preceded by other consonant

        if ((c2 == 'p') && (c3 == 't') ||
            (c2 == 'c') && (c3 == 't') ||
            (c2 == 'c') && (c3 == 'n') ||
            (c2 == 'p') && (c3 == 's') ||
            (c2 == 'm') && (c3 == 'n') ||
            (c2 == 'g') && (c3 == 'n') ||
            (c2 == 'f') && (c3 == 't') ||
            (c2 == 'p') && (c3 == 'n') ||
            (c2 == 'c') && (c3 == 'z') ||
            (c2 == 't') && (c3 == 's')) {
          pos++;
          return pos;
        }

        if ((c3 == 'l') ||
            (c3 == 'r') || // The consonantal groups formed by a consonant
            // following the letter 'l' or 'r' cann't be
            // separated and they always begin syllable
            ((c2 == 'c') && (c3 == 'h')) || // 'ch'
            (c3 == 'y')) {
          // 'y' as vowel
          pos++; // Following syllable begins in c2
        } else {
          pos += 2; // c3 begins the following syllable
        }
      }
    } else {
      // This block handles the case where pos == _wordLength - 2
      // We already know there's a consonant at pos+1 (c2)
      if ((c2 == 'y')) {
        return pos; // If the last char is 'y', it doesn't belong to coda
      }

      pos += 2; // The word ends with two consonants, both belong to the coda
    }

    return pos;
  }

  // Helper method to get lowercase character as String
  String _toLower(int pos) {
    if (pos < 0 || pos >= _wordLength) {
      throw Exception('pos out of range');
    }
    return _word[pos].toLowerCase();
  }

  // Helper method to check if character at pos is a consonant
  bool _isConsonant(int pos) {
    if (pos < 0 || pos >= _wordLength) {
      throw Exception('pos out of range');
    }

    // Get character at pos - case is handled by the switch
    String c = _word[pos];
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
}
