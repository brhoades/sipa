sipa

Spanish IPA Tool

====
Synopsis

When text inside square brackets [...] or two forward slashes /.../ is found, this script will perform
various substitutions to the characters contained. The only accepted format is the open document format.
**The text should never break into a new font or be underlined for the substituions to occur.**
An evenly spaced font (MONO) is recommended. The document will be output, with the new characters, 
at <inputfilename>.new.odt in the same directory.
 
| Type          | Found | Replaced |
|:-------------:|:-----:|:--------:|
| ch            | tbar  | tʃ       |
| d             | d     | d̪        |
| t             | t     | t̪        |
| ll, y         | y^    | y̌        |
| rr            | r_    | r̅        |
| diaeresis     | a..   | ä        |
| semivowel     | a~    | a̰        |
| stress        | a_    | a̲        |
| 2xstress      | a=    | a̳        |
| strikethrough | (bdg)_| bg̶d̶̶      |

tbar is equivalent to t|


====

Usage

perl sipa.pl <document>

ie:
perl sipa.pl /home/brhoades/spanish/0.2.1.odt

