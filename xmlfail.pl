#!/bin/perl
use File::Basename;
use warnings;
use Data::Dumper;
use XML::Simple;

$ENV{'PERL_PERTURB_KEYS'} = 0;

exit 0 if( not $ARGV[0] );

binmode( STDOUT, ":utf8");
binmode( STDIN, ":utf8");

$out = "/tmp/".basename($ARGV[0])."/";
unlink $out if -e $out;
print("Extracting ODF: ");
system("unzip -qqo \"".$ARGV[0]."\" -d \"$out\"");
print("done\n");
# tie my @array, 'Tie::File', $out."content.xml" or die $!;
# print("Done\n");

$tilde = 0;
$erre = 0;
$underline = 0;
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
    $erre +=  $in =~ s/([r])\_/$1\x{0304}/g; #305 is larger
    $underline += $in =~ s/([aeiou])\_/$1\x{0333}/g;
    $diptongos += $in =~ s/([ui])\^/$1\x{032f}/g; #^ => i/u with curvy line under
    $ches += $in =~ s/([t])\|/$1\x{222B}/g;
    #.. => umlout
    #= => double underline
    
    #^ => y with v
    push @file, $in;
}
close($fh);
#After the basics, move on to the t's/d's

$xml = new XML::Simple;
$fin = join("\n", @file);
$xmldr = $xml->XMLin($fin);
%xmld = %$xmldr;
#print( Dumper \%xmld );

if( ref($xmld{'office:body'}{'office:text'}{'table:table'}) eq "ARRAY" )
{
  @tables = @{$xmld{'office:body'}{'office:text'}{'table:table'}};
  
  for $tabler (@tables)
  {
    %table = %$tabler;
    @rows = @{$table{'table:table-row'}};
    for $rowr (@rows)
    {
      rowhandle($rowr)
    }
  }
}
else
{
    @rows = @{$xmld{'office:body'}{'office:text'}{'table:table'}{'table:table-row'}};
    
    for $rowr (@rows)
    {
      rowhandle($rowr);
    }
}
#print Dumper \%xmld;
$xmlstrout = $xml->XMLout(\%xmld, noindent => 1);

@file = split("\n", $xmlstrout);

open($fh, ">", $out."content.xml");
binmode( $fh, ":utf8");
for my $line (@file)
{
  print $fh $line."\n";
}

print("Found/Replaced ~: $tilde\n");
print("Found/Replaced _: ".($erre+$underline)."\n");
print("Found/Replaced ^: $diptongos\n");
print("Found/Replaced |: $ches\n");
print("Teeth (d/t): $dete\n");

print("Recreating ODF: ");
unlink "/tmp/temp.new.odt" if( -e "/tmp/temp.new.odt" );
unlink "/tmp/temp.new.pdf" if( -e "/tmp/temp.new.pdf" );
system("cd $out && zip -q9pr \"/tmp/temp.new.odt\" *");
print(-e "/tmp/temp.new.odt" ? "done" : "failed", "\nCreating PDF: ");
system("libreoffice --headless --invisible --convert-to pdf /tmp/temp.new.odt --outdir /tmp/");
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

sub rowhandle
{
    $trowr = shift;
    for $trowr (@rows)
    {
        %trow = %$trowr;
        #print Dumper \%trow;
        for $cellr (@{$trow{'table:table-cell'}})
        {
            #Each Individual Cell
  
#             tyle-name' => 'P6',
#                                 'text:span' => {
#                                                 'text:style-name' => 'T24',
#                                                 'content' => '/sanao_rias/'
#                                             }
#                             },
#                     'office:value-type' => 'string'
#                 },
#                 {
#                     'table:style-name' => 'Table2.A1',
#                     'text:p' => {
#                                 'text:style-name' => 'P4',
#                                 'content' => "[sa-na-\x{f3}-ryas]"
#                             },
#                     'office:value-type' => 'string'
#                 },
#                 {
#                     'table:style-name' => 'Table2.A1',
#                     'text:p' => {
#                                 'text:style-name' => 'P4',
#                                 'content' => "[sa-na\x{330}\x{f3}-ryas]"
#                             },
#                     'office:value-type' => 'string'
#                 }
#                 ]
#             },
#             {
#             'table:table-cell' => [
#                 {
#                     'table:style-name' => 'Table2.A1',
#                     'text:p' => {
#                                 'text:style-name' => 'P4',
#                                 'content' => 'creemos'
#                             },
#                     'office:value-type' => 'string'
#                 },
#                 {
#                     'table:style-name' => 'Table2.A1',
#                     'text:p' => {
#                                 'text:style-name' => 'P6',
#                                 'text:span' => {
#                                                 'text:style-name' => 'T24',
#                                                 'content' => '/kree_mos/'
#                                             }
#                             },
#                     'office:value-type' => 'string'
#                 },
#                 {
#                     'table:style-name' => 'Table2.A1',
#                     'text:p' => {
#                                 'text:style-name' => 'P4',
#                                 'content' => "[kre-\x{e9}-mos]"
#                             },
#                     'office:value-type' => 'string'
#                 },
#                 {
#                             
    
            next if( not defined $cellr );
            if( ref($cellr) ne "HASH" )
            {
                print("Improperly formatted cell, not a hash.\n");
                print Dumper $cellr;
                next;
            }
            
            %cell = %$cellr;
            next if( not defined $cell{'text:p'} or ref($cell{'text:p'}) ne "HASH");
            #print Dumper \%cell;
            
            #Get the content ref and drop it in here.
            $content = "";
            if( defined $cell{'text:p'}{'content'} && ref($cell{'text:p'}{'content'}) eq "" )
            {
                $content = \$cell{'text:p'}{'content'};
            }
            elsif( defined $cell{'text:p'}{'text:span'} )
            {
                if( ref($cell{'text:p'}{'text:span'}) eq "HASH" && defined $cell{'text:p'}{'text:span'}
                    && defined $cell{'text:p'}{'text:span'}{'content'} && (ref($cell{'text:p'}{'text:span'}{'content'}) eq "SCALAR" || not ref($cell{'text:p'}{'text:span'}{'content'}) ) )
                {
                    $content = \$cell{'text:p'}{'text:span'}{'content'};
                }
                else
                {
                    print("Improperly formed cell, this doesn't appear to be a hash or content isn't a string.\n");
                    print Dumper $cell{'text:p'}{'text:span'};
                    print( "ISHASH: ", ref($cell{'text:p'}{'text:span'}), "\n", "IS REF?: ", 
                            ref($cell{'text:p'}{'text:span'}) eq "HASH" ? ref($cell{'text:p'}{'text:span'}{'content'}) : "UNKNOWN", "\n");
                    next;
                }
            }
            else
            {
                print("Bad cell?:\n");
                print Dumper $cellr;
                next;
            }
            
            $dete += ${$content} =~ s/(d|t)[^\\]?/$1\x{032A}/g;
        }
    }
}