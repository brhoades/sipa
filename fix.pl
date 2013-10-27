#!/bin/perl
use File::Basename;
use warnings;
use Data::Dumper;
use File::Path;
use OpenOffice::OODoc::Text;

$ENV{'PERL_PERTURB_KEYS'} = 0;

exit 0 if( not $ARGV[0] );

binmode( STDOUT, ":utf8");
binmode( STDIN, ":utf8");

$out = "/tmp/".basename($ARGV[0])."/";
rmtree($out) if -e $out;
print("Extracting ODF: ");
system("unzip -qqo \"".$ARGV[0]."\" -d \"$out\"");
print( ( -e $out ? "Done" : "Failed!" )."\n" );

# tie my @array, 'Tie::File', $out."content.xml" or die $!;
# print("Done\n");

$tilde = 0;

$erre = 0;
$ches = 0;
$dete = 0;
$diaeresis = 0;
$underline = 0;
$double = 0;

my @file;
my $fh;
open($fh, "<", $out."content.xml");
binmode( $fh, ":utf8");
$| = 1;

while($in = <$fh>)
{
    $text = $in =~ m/\<text/g;
    if( $text < 1 )
    {
        push @file, $in if( defined $in );
        next;
    }
    my @subs;
    
    while( $in =~ m/(\/|\[)([a-z\~\^\_\.\|\-\p{Letter}\p{Mark}\s]+)(\/|\])/gi )
    {
        next if( not defined $2 );
        $match = $2;
        $original = $2;
        $start = $1;
        $end = $3;
        
        $ches += $match =~ s/([t])\|/$1\x{222B}/g;
        $dete += $match =~ s/(d|t)([^\\]?)/$1\x{032A}$2/g;
        $tilde +=  $match =~ s/([aeiou])~/$1\x{0330}/g;
        $erre +=  $match =~ s/([r])_/$1\x{0304}/g; #305 is larger
        $underline += $match =~ s/([aeiou])\_/$1\x{0332}/g;
        $double += $match =~ s/([aeiou])\=/$1\x{0333}/g;
        $diaeresis += $match =~ s/([a-z])\.\./$1\x{0308}/g;
        $lla += $match =~ s/([y])\^/$1\x{}/g;

        #$in =~ s/$original/$match/;
        
        push @subs, [$original, $match, $start, $end ] if( $match ne $original );
    }
    
    for $sub (@subs)
    {
        ($orig, $match, $start, $end) = @$sub;
                
        #print($start,$orig,$end, " ===> ", $start,$match,$end, "\n");
        $in =~ s/\Q$start\E$orig\Q$end\E/$start$match$end/;
    }
 
    push @file, $in;
}
close($fh);

#Prepare to write
unlink($out."content.xml");
open($fh, ">", $out."content.xml");
binmode( $fh, ":utf8");
for my $line (@file)
{
  print $fh $line."\n";
  #print $line."\n";
}


print("Trill <rr>:\t $erre\n");
print("<y> <ll>:\t $lla\n");
print("<ch>:\t\t $ches\n");
print("Diaresis:\t $diaeresis\n");
print("Semivowels:\t $tilde\n");
print("Teeth (d/t):\t $dete\n");
print("Underline:\t $underline\n");
print("Double underline $double\n");
print("\n\n");

print("Recreating ODF: ");
unlink "/tmp/temp.new.odt" if( -e "/tmp/temp.new.odt" );
unlink "/tmp/temp.new.pdf" if( -e "/tmp/temp.new.pdf" );
system("cd $out && zip -q9pr \"/tmp/temp.new.odt\" *");
print(-e "/tmp/temp.new.odt" ? "done" : "failed", "\nCreating PDF: ");
system("libreoffice --headless --invisible --convert-to pdf /tmp/temp.new.odt --outdir /tmp/");

=pod
my $doc = OpenOffice::OODoc::Text->new(file => $ARGV[0]);
$doc->selectTextContent( qr/[A-Za-z\p{C}\p{M}\p{L}\-]+/, \&parse );
sub parse
{
    my ($d, $element, $value) = @_;
    #print 
    #print $element."\n";
}

open($fh2, ">", "/home/aaron/look");
binmode( $fh, ":utf8");
my ($row, $col ) = $doc->getTable(0);
$table = $doc->normalizeSheet(0, 'full');
for(my $i=0; $i<$row; $i++)
{
    for(my $j=0; $j<$col; $j++)
    {
        $cell = $doc->getCell($table, $i, $j);
        $text = $doc->getFlatText($cell);
        print Dumper $cell;
        print "\n\n";
        #print $fh2 $text;
    }
}
close($fh2);
=cut

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
