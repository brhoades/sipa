#!/bin/perl
use File::Basename;
use warnings;
use Data::Dumper;
use OpenOffice::OODoc::Text;

$ENV{'PERL_PERTURB_KEYS'} = 0;

exit 0 if( not $ARGV[0] );

binmode( STDOUT, ":utf8");
binmode( STDIN, ":utf8");

$out = "/tmp/".basename($ARGV[0])."/";
unlink $out if -e $out;
print("Extracting ODF: ");
system("unzip -qqo \"".$ARGV[0]."\" -d \"$out\"");

# tie my @array, 'Tie::File', $out."content.xml" or die $!;
# print("Done\n");

$tilde = 0;
$erre = 0;
$diptongos = 0;
$ches = 0;
$dete = 0;
@matches = [];
my @file;
my $fh;
open($fh, "<", $out."content.xml");
binmode( $fh, ":utf8");
$| = 1;

while($in = <$fh>)
{
    $text = $in =~ /\<text/g;
    if( $text < 1 )
    {
        if( defined $in )
        {
            push @file, $in;
        }
        next;
    }
    
    push @matches, $in =~ /([aeiou]~)/ig;
    $tilde +=  $in =~ s/([aeiou])~/$1\x{0330}/g;
    $erre +=  $in =~ s/([r])_/$1\x{0304}/g; #305 is larger
    $diptongos += $in =~ s/([ui])\^/$1\x{032f}/g; #^ => i/u with curvy line under
    $ches += $in =~ s/([t])\|/$1\x{03A3}/g;
    #.. => umlout
    #= => double underline
    #^ => y with v
    
    push @file, $in;
}
close($fh);
#After the basics, move on to the t's/d's

open($fh, ">", $out."content.xml");
binmode( $fh, ":utf8");
for my $line (@file)
{
  print $fh $line."\n";
  #print $line."\n";
}


print("Found/Replaced ~: $tilde\n");
print("Found/Replaced _: $erre\n");
print("Found/Replaced ^: $diptongos\n");
print("Found/Replaced |: $ches\n");
print("Teeth (d/t): $dete\n");

print("Recreating ODF: ");
unlink "/tmp/temp.new.odt" if( -e "/tmp/temp.new.odt" );
unlink "/tmp/temp.new.pdf" if( -e "/tmp/temp.new.pdf" );
system("cd $out && zip -q9pr \"/tmp/temp.new.odt\" *");
print(-e "/tmp/temp.new.odt" ? "done" : "failed", "\nCreating PDF: ");
system("libreoffice --headless --invisible --convert-to pdf /tmp/temp.new.odt --outdir /tmp/");

my $doc = OpenOffice::OODoc::Text->new(file => '/tmp/temp.new.odt');
$doc->selectTextContent( qr/[A-Za-z\p{C}\p{M}\p{L}\-]+/, \&parse );

sub parse
{
    my ($d, $element, $value) = @_;
    #print 
    #print $element."\n";
}

my ($row, $col ) = $doc->getTable(0);
print $row."\n", $col."\n";
$table = $doc->normalizeSheet($doc->getTable(0),$row,$col);
print $doc->getCellValue($doc->getTable(0),5,3);
print $cell."\n";

$newbname = basename($ARGV[0]);
$oldbname = $newbname;
$newbname =~ s/\.odt/\.pdf/i;
$newbname .= ".pdf" if( !($newbname =~ m/\.pdf$/) );
$newname = $ARGV[0];
$newname =~ s/$oldbname/$newbname/;
print(-e "/tmp/temp.new.pdf" ? "done" : "failed", "\nMoving PDF: ");
unlink $newname if( -e $newname );
sleep 2;
system("cp /tmp/temp.new.pdf $newname");
print(-e $newname ? "done" : "failed", "\n");