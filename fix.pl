#!/bin/perl
use File::Basename;
use warnings;
use Data::Dumper;
use File::Path;
use OpenOffice::OODoc::Text;

binmode( STDOUT, ":utf8");
binmode( STDIN, ":utf8");

$ENV{'PERL_PERTURB_KEYS'} = 0;

print("Missing second argument\n") and exit 0 if( not $ARGV[0] );

$out = "/tmp/".basename($ARGV[0])."/";

#Crashed?
rmtree($out) if -e $out;

print("Extracting ODF: ");
system("unzip -qqo \"".$ARGV[0]."\" -d \"$out\"");

print( ( -e $out ? "Done" : "Failed!" )."\n" );

my ($tilde, $erre, $ches, $dete, $diaeresis, $underline, $double) = 0;

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
}

##Status report
print("Trill <rr>:\t $erre\n");
print("<y> <ll>:\t $lla\n");
print("<ch>:\t\t $ches\n");
print("Diaresis:\t $diaeresis\n");
print("Semivowels:\t $tilde\n");
print("Teeth (d/t):\t $dete\n");
print("Underline:\t $underline\n");
print("Double underline $double\n");
print("\n\n");

##Create the ODF
print("Recreating ODF: ");
unlink "/tmp/temp.odt" if( -e "/tmp/temp.odt" );

#Zip it
system("cd $out && zip -q9pr \"/tmp/temp.odt\" *");

#Delete the old contents
rmtree($out);

print(-e "/tmp/temp.odt" ? "Done" : "Failed");

##find our new name
$newbname = basename($ARGV[0]);
$oldbname = $newbname;
$newbname =~ s/\.odt/.new/i;
$newbname .= ".odt" if( !($newbname =~ m/\.odt$/) );
$newname = $ARGV[0];
$newname =~ s/$oldbname/$newbname/;

print("\nMoving ODT (give me a sec): ");
unlink $newname and sleep(2) if( -e $newname );

##Move!
system("mv /tmp/temp.odt $newname");
print(-e $newname ? "Done" : "Failed", "\n");
