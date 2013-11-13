#!/bin/perl
#Spanish IPA Tool
#By Billy Rhoades

use File::Basename;
use File::Path;

use warnings;

binmode( STDOUT, ":utf8");
binmode( STDIN, ":utf8");

#Don't scramble keys, libreoffice will scream if stuff is out of order
$ENV{'PERL_PERTURB_KEYS'} = 0;

print("Missing second argument\n") and exit 0 if( not $ARGV[0] );

$out = "/tmp/".basename($ARGV[0])."/";

#Crashed?
rmtree($out) if -e $out;

print("Extracting ODF: ");
system("unzip -qqo \"".$ARGV[0]."\" -d \"$out\"");

print( ( -e $out ? "Done" : "Failed!" )."\n" );

#Counters
my ($tilde, $erre, $ches, $dete, $diaeresis, $underline, $double, $ktp, $ntd, $mnwifhook) = 0;

my @file;
my $fh;
open($fh, "<", $out."content.xml");
binmode( $fh, ":utf8");

#Slurp mode
$| = 1;

#Replace loop
while($in = <$fh>)
{
    #odts usually have only one line that has what we want
    $text = $in =~ m/\<text/g;
    if( $text < 1 )
    {
        push @file, $in if( defined $in );
        next;
    }

    #find [..] and /../
    my @subs;    
    while( $in =~ m/(\/|\[|\>)([a-z\~\^\_\.\,\|\-\p{Letter}\p{Mark}\s]+)(\/|\])/gi )
    {
        next if( not defined $2 );
        $match = $2;
        $original = $2;
        $start = $1;
        $end = $3;
	check($end, $match);
		
	#d / t => d/t w/ dental        
        $dete += $match =~ s/(d|t)([^\|\_])/$1\x{032A}$2/g; #For some reason we need to match this second character

	#t| => t w/ baby sigma
        $ches += $match =~ s/t\|/t\x{0283}/g;

	#b,g,d_ => beta, gamma, delta respectively. Lowercase.
        $ktp += $match =~ s/b\_/\x{03B2}/g;
        $ktp += $match =~ s/g\_/\x{0263}/g;
        $ktp += $match =~ s/d\_/\x{03B4}/g;
        
	#a,e,i,o,u~ => a,e,i,o,u w/ tilde below
        $tilde += $match =~ s/([aeiou])\~/$1\x{0330}/g;

	#r_ => r with line on top
        $erre += $match =~ s/([r])_/$1\x{0304}/g; #305 is larger

	#a,e,i,o,u_ => a,e,i,o,u w/ line below (stress)
        $underline += $match =~ s/([aeiou])\_/$1\x{0332}/g;
	#a,e,i,o,u= => a,e,i,o,u w/ double line below (stress)
        $double += $match =~ s/([aeiou])\=/$1\x{0333}/g;

	#a-z.. => a-z w/ diaeresis (umlaut) on top
        $diaeresis += $match =~ s/([a-z])\.\./$1\x{0308}/g;

	#y^ => y with upside down ^ above
        $lla += $match =~ s/(y)\^/$1\x{030C}/g;
        
        #n + t / d => nd / nt w/ dental on n
        $ntd += $match =~ s/(n)-(t|d)/$1\x{032A}-$2/g;

        #n, / m, => n / m with curly right side
        $mnwifhook += $match =~ s/m[,]/\x{0271}/g;
        $mnwifhook += $match =~ s/n[,]/\x{014B}/g;
        
        push @subs, [$original, $match, $start, $end ] if( $match ne $original );
    }
    
    #substitute out, perl doesn't like it if we sub on the fly
    for $sub (@subs)
    {
        ($orig, $match, $start, $end) = @$sub;
        
        if( defined $start )
        {
            $in =~ s/\Q$start$orig$end\E/$start$match$end/;
        }
        else
        {
            $in =~ s/\Q$orig$end\E/$match$end/;
        }
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
print("Trill <rr>:\t\t $erre\n");
print("<y> <ll>:\t\t $lla\n");
print("<ch>:\t\t\t $ches\n");
print("Diaresis:\t\t $diaeresis\n");
print("Semivowels:\t\t $tilde\n");
print("Teeth (d/t):\t\t $dete\n");
print("(b,t,k) allophones:\t $ktp\n");
print("Underline:\t\t $underline\n");
print("Double underline:\t $double\n");
print("Dental N:\t\t $ntd\n");
print("N / M velar:\t\t $mnwifhook\n");
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

####END OF MAIN

sub checkInternals
{
  my ($inside, $type) = @_;

}

sub check
{
  my ($type, $match) = @_;
    
  if( $type eq "/" )
  {
    if( $match =~ m/(w|[nm]\,|[aeiou]\~|h|q|c|ü|[áéíóú])/ )
    {
      print("Warning: $match contains $1 in phonemic\n");
    }
    elsif( $match !~ m/(_)/ && $match =~ m/[aeiou].*[aeiou].*[aeiou]/ )
    {
      print("Warning: $match lacks a stressed character\n");
    }
  }
}
