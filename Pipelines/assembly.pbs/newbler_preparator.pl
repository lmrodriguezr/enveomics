#!/usr/bin/perl


my ($in, $out) = @ARGV;
($in and $out) or die "
Usage: $0 input.fa output.fa
";

open IN, "<", $in  or die "Cannot read file: $in: $!\n";
open OUT,">", $out or die "Cannot create file: $out: $!\n";

%reads=();
@reads=();
while(<IN>){
  chomp;
  if(/^\>/){
	$tag=$_;
	$reads{$tag}='';
	push(@reads,$tag);
  }else{
	$reads{$tag}.=$_;
  }
}
close(IN);

for(0..$#reads){
  $tag=$reads[$_];
  $read=$reads{$tag};
  $l=length $read;
  if($l<100){
	next;
  }else{
	if($l<1500){
	  print OUT "$tag\n$read\n";
	}else{
	  $r=int($l/1500)+1;
	  $start=0;
	  $i=1;
	  while($start<$l-100){
		$tag_new=$tag.':r'.$i;
		$i++;
		$read_new=substr($read,$start,1500);
		$start+=200;
		print OUT "$tag_new\n$read_new\n";
	  }
	}
  }
}
close(OUT);
