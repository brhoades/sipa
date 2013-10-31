sipa

Spanish IPA Tool

====

Synopsis

In my Spanish Phonetics course there are a lot of complex symbols that need to be used
in our typed homework. These symbols, not found on a traditional keyboard,
are tedius to look up and available tools are clunky. In order to save time, I 
wrote this script to allow the use of quick shortcuts in a text document with unique symbols. 
All d's and t's will automatically have dental marks placed under them if they aren't
followed by something used in a different pattern. Everything else 
requires a trailing symbol. This script will output a new document with .new before the
extension in the same directory. This new document has the shortcuts translated 
to the actual symbols.

====

Usage

perl sipa.pl <source document>

ie:
perl sipa.pl /home/brhoades/spanish/0.2.1.odt

This script will only function on odt files. These files can be saved with Word 2007+ and 
natively with any version of Open/Libre Office, but
the script must be ran on cygwin or Linux. Please also note that combining symbols work best
with certain fonts. Cambria has worked best on both Windows and Ubuntu. Additionally, due to
limitations of the open document format **do not switch fonts, sizes, or use italics/bold/underline
inside transcriptions**. This script will ignore the entry if this is done to preserve
integrity of non-phonemic test. If you are attempting to remove formatting
from a document, you will need to completely retype the text in most cases to remove the 
special formatting from the internals of your document.

Below you will find the list of shortcuts to be typed before converting. These should be in your
"source document." If you make any future changes, make sure you make them to the source document 
and rerun the script. 
 
| Description   | Pattern  | Replacement |
|:-------------:|:--------:|:-----------:|
| d (automatic) | d        | d̪           |
| t (automatic) | t        | t̪           |
| ch            | t + VB*  | tʃ          |
| ll, y         | y + ^    | y̌           |
| rr            | r + _    | r̅           |
| diaeresis     | V + . + .| v	̈          |
| semivowel     | V + ~    | v̰           |
| stress        | V + _    | v̲           |
| 2xstress      | V + =    | v̳           |
| beta          | b + _    | β           |
| gamma         | g + _    | ɣ           |
| delta         | d + _    | ẟ           |

* VB is equivalent to |
* V denotes any vowel

Here is some text in an example document, example.odt:

> /atla_ntiko/   [ad_-lán-ti-ko]

Here is the output after running the script on the file. The output is in example.new.odt 
in the same directory.

> /at̪la̲nt̪iko   /  [aẟ-lán-t̪i-ko]
