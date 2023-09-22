#!/usr/bin/perl 
# Meng Liu and Hong-Yu Ou on April-24-2018
# School of Life Sciences & Biotechnology, Shanghai Jiao Tong University

###########################################################
#blastn against RDP database 
#and generate a .gram as the tag of a gram positive bacteria 
##########################################################

use strict;
use File::Path;

die "usage: perl script_name.pl <job_id>" if @ARGV != 1;
my $job_id = shift;
my $blastprogram = "blastn";
my $cds_class = "all";

my $blast_path = "./tools/";
my $job_temp_path = "./tmp/$job_id";
my $query = "$job_temp_path/$job_id.fna";
my $subject = "./data/release11_3_Bacteria_unaligned.fa";
my $outputfile = "$job_temp_path/".$job_id."_".$cds_class."_".$blastprogram."_vs_RDP.txt";
my $blastparsename = $job_id."_".$cds_class."_".$blastprogram."_vs_RDP_parsed.txt";
my $blastparse = "$job_temp_path/".$blastparsename;
my $Evalue_cutoff = 0.0001;
my $blastHitNo=3;


##############################
# blastp search
##############################
system("$blast_path/$blastprogram -query $query -db $subject -outfmt 0 -num_alignments 3 -evalue 0.0001 -num_threads 10 -out $outputfile");
ParseBlastnSearch($blastHitNo, $outputfile, $blastparse);
	
if (-e $blastparse){
#output the blast result
 outputresult($blastparse, $blastprogram, $cds_class, $blastHitNo);
}

sub ParseBlastnSearch{
#####################################################	
# Parse the blast result and calculate the H values
#####################################################
	my($myblastHitNo, $myinFile, $myoutFile) = @_;
	use strict;
	use Bio::SearchIO;
	my $querynum=0;
	my $blast_report = new Bio::SearchIO ('-format' => 'blast', '-file'   => $myinFile);
	open(OUTFILE, ">$myoutFile")|| die "Cannot open $myoutFile!\n";		             
	while(my $result = $blast_report->next_result){
	  $querynum++;	    
	  my $Evalue="-";
	  my $score = 0.0;
	  my $hvalue=0.0;
	  my $identity=0.0;
	  my $positive=0.0;
	  my $matchingLen=0;
	  my $hitcount= $result->num_hits;
	  my $hitname= "-";#"No significant homology found"
	  my $hitdescription = "-";
	  my $mycount=0;
	  while( my $hit = $result->next_hit ) {
	  	if(++$mycount > $myblastHitNo) {last;}  		  	 
	  	my $hsp = $hit->next_hsp();
	  	$Evalue=$hsp->evalue;
	  	$score = $hsp->score;
	  	$hvalue=(($hsp->length('total')*$hsp->frac_identical())/$result->query_length);
	  	$hvalue=round($hvalue, 4);
	  	$identity=int ($hsp->frac_identical()*100);
	  	$positive=int ($hsp->frac_conserved ()*100);
	  	$matchingLen = int($hsp->length('total')/$result->query_length*100);
	  	$hitname=$hit->name;
	  	$hitdescription=trimwhitespace($hit->description);  
  	  my $queryname=$result->query_name();
	    if ($blastprogram  eq "blastp" ) {$queryname=trimqueryname($queryname);}

		print OUTFILE $queryname,"\t";
	  print OUTFILE $hitname,"\t";
	  print OUTFILE $Evalue,"\t";
	  print OUTFILE $score,"\t";
	  print OUTFILE $identity,"\t";
	  print OUTFILE $hitdescription;
	  print OUTFILE "\n";	  
	  	  }
	}
   close(OUTFILE);
}

sub trimqueryname($){
################################################################	
# Remove word "_1" from the query gene name generated by EMOSS transeq
################################################################
	my $string = shift;
	my $substring="";
	$substring=substr($string, 0,(length($string)-2));
	return $substring;
}

sub round {
    my $val = shift;
    my $col = shift;
    my $r = 10 ** $col;
    my $a = ($val > 0) ? 0.5 : -0.5;
    return int($val * $r + $a) / $r;
}

sub outputresult {
##########################################################
#Output the blast result as html
##########################################################
my($filename, $myprogram, $mycds_class, $myblastHitNo) = @_;
		 my $queryno=0;            		
     my $hitno=0;                 
     my @queryname;               
     my $querynamedisplay="";     
     my $formername="";           
		 open(INPUT,"<".$filename)  or die "Unable open input file ".$filename." .\n";
		 my $k=0;
		 while ( my $infileline = <INPUT>)           # retrieve file, line by line
		 {
		 	my @fields=split(/\t/,$infileline);
		 	if($fields[3]>0){#score >0
		 	     $queryname[$hitno]=$fields[0];
		 	     $querynamedisplay=$fields[0];
		 	     for (my $i=1; $i<$myblastHitNo; $i++){
		 	     		if($hitno-$i<0){
		 	     			$formername="FIRSTHIT";
		 	     		}else{
		 	     			$formername=$queryname[$hitno-$i];
		 	     		}
		 	     		if($querynamedisplay eq $formername){
		 	     			$querynamedisplay="";
		 	     			last;
		 	     		}
						}
		 	    $hitno++;
			    $queryno++; 	     
				  my @querynamedisplay1=split /\ /,$querynamedisplay;
				  my $queryname1 = $querynamedisplay1[0]; 
				  my $fieldcount = 3;
    			while ($fieldcount <= @fields) {
   					 $fieldcount++;
    			}     
         if($fields[5] =~ /Numidum|Anaerobium|Deinococcus|Streptomyces|Clostridium|Clostridioides|Corynebacterium|Rhodococcus|Bacillus|Staphylococcus|Promicromonospora|Moorella|Curtobacterium|Psychrobacillus|Cellulosimicrobium|Myxosarcina|Ruminococcaceae|Melissococcus|Flavihumibacter|Anoxybacillus|Thermoactinomyces|Williamsia|Sedimentibacter|Prauserella|Lentzea|Lechevalieria|Kutzneria|Kibdelosporangium|Goodfellowiella|Alkalitalea|Cryobacterium|Bifidobacterium|Micromonospora|Desulfotomaculum|Nonomuraea|Acidaminobacter|Tepidimicrobium|Proteiniborus|Fructobacillus|Natronincola|Alkaliphilus|Caldanaerovirga|Anaerobranca|Weissella|Streptococcus|Paucisalibacillus|Listeria|Lactobacillus|Entomoplasma|Dermacoccus|Geobacillus|Amycolatopsis|Terribacillus|Candidatus|Frankia|Crossiella|Thermoanaerobacter|Lachnobacterium|Leuconostoc|Exiguobacterium|Actinobaculum|Planomonospora|Pilibacter|Eubacterium|Acetoanaerobium|Thermosporothrix|Methanobrevibacter|Tomitella|Gracilibacillus|Nesterenkonia|Mycobacterium|Paenibacillus|Micrococcus|Kocuria|Enterococcus|Brevibacterium|Dermabacter|Xylanimicrobium|Nocardiopsis|Nocardioides|Microbacterium|Lactococcus|Sulfuritalea|Trueperella|Sporosarcina|Saccharopolyspora|Actinomadura|Streptacidiphilus|Kitasatospora|Pontibacillus|Knoellia|Mycoplasma|Lysinibacillus|Cellulomonas|Blautia|Kandleria|Carnobacterium|Sharpea|Tetrasphaera|Alicyclobacillus|Leifsonia|Gemella|Flavobacterium|Syntrophomonas|Anaerosalibacter|Streptoalloteichus|Aneurinibacillus|Oerskovia|Pontimonas|Propionibacterium|Actinoplanes|Aerococcus|Isoptericola|Ilumatobacter|Peptoniphilus|Kallipyga|Enterobacter|Methylobacterium|Butyrivibrio|Ruminococcus|Pediococcus|Dietzia|Leucobacter|Gulosibacter|Oribacterium|Actinomyces|Microlunatus|Lachnospiraceae|Nocardia|Cryocola|Terracoccus|Arthrobacter|Jeotgalicoccus|Brevibacillus|Ornithinibacillus|Brochothrix|Vagococcus|Mycetocola|Facklamia|Alkalibacterium|Luteococcus|Agrococcus|Marinilactibacillus|Saccharothrix|Patulibacter|Listeriaceae|Gordonia|Rothia|Macrococcus|Peptostreptococcus|Lachnoanaerobaculum|Finegoldia|Eggerthella|Arcanobacterium|Clostridiales|Aeromonas|Dehalobacter|Nosocomiicoccus|Gardnerella|Salinispora|Enterorhabdus|Collinsella|Brachybacterium|Tsukamurella|Pseudonocardia|Rathayibacter|Pasteuria|Clavibacter|Solibacillus|Modestobacter|Blastococcus|Sporolactobacillus|Scardovia|Mogibacterium|Coprococcus|Caldalkalibacillus|Peptococcus|Alkalibacillus|Paenisporosarcina|Viridibacillus|Virgibacillus|Ureibacillus|Salinibacterium|Planococcus|Zimmermannella|Devriesea|Conexibacter|Salinactinospora|Flexivirga|Jiangella|Thermasporomyces|Cohnella|Actinophytocola|Planosporangium|Methanosphaera|Agitococcus|Spinactinospora|Tessaracoccus|Yaniella|Chryseomicrobium|Demequina|Sinomonas|Actinoalloteichus|Catenuloplanes|Auraticoccus|Microaerobacter|Marisediminicola|Arsenicicoccus|Actinopolyspora|Branchiibius|Fontibacillus|Caldanaerobacter|Streptosporangium|Salimicrobium|Pseudoclavibacter|Aciditerrimonas|Herbiconiux|Actinomycetospora|Actinoallomurus|Thermosyntropha|Carboxydothermus|Agromyces|Angustibacter|Citricoccus|Tepidibacter|Sphaerisporangium|Serinicoccus|Pseudokineococcus|Natronovirga|Natranaerobius|Dactylosporangium|Haloactinopolyspora|Actinopolymorpha|Flindersiella|Thalassobacillus|Oceanobacillus|Pisciglobus|Alkalibaculum|Anaerostipes|Murinocardiopsis|Allocatelliglobosispora|Marmoricola|Carboxydocella|Virgisporangium|Thermogemmatispora|Lentibacillus|Georgenia|Frondihabitans|Phytomonospora|Kroppenstedtia|Halobacillus|Lapillicoccus|Aquipuribacter|Glycomyces|Proteiniclasticum|Hydrogenoanaerobacterium|Natronobacillus|Streptomonospora|Bhargavaea|Tetragenococcus|Anaerobacillus|Schumannella|Salirhabdus|Deinobacterium|Paraliobacillus|Terrabacter|Salinicoccus|Phycicola|Salsuginibacillus|Sporosalibacterium|Jishengella|Kineococcus|Aeromicrobium|Kribbella|Verrucosispora|Calidifontibacter|Actinocatenispora|Murdochiella|Planomicrobium|Labedella|Sulfobacillus|Marihabitans|Trichococcus|Kineosporia|Falsibacillus|Catenulispora|Solirubrobacter|Calditerricola|Pseudosporangium|Microterricola|Humibacillus|Humihabitans|Anaerococcus|Phycicoccus|Fodinicola|Sediminibacillus|Planotetraspora|Aquisalibacillus|Adlercreutzia|Ammonifex|Rugosimonospora|Serinibacter|Zhihengliuella|Fodinibacter|Natribacillus|Thermobifida|Halolactibacillus|Sanguibacter|Phytohabitans|Desulfitispora|Ornithinibacter|Streptohalobacillus|Luteimicrobium|Longispora|Hoyosella|Olsenella|Thermoanaerobacterium|Amnibacterium|Kytococcus|Yuhushiella|Yimella|Actinokineospora|Intrasporangium|Laceyella|Slackia|Luteipulveratus|Alteribacillus|Plantactinospora|Herbidospora|Microbispora|Asanoa|Actinaurispora|Thermaerobacter|Myceligenerans|Friedmanniella|Jeotgalibacillus|Propioniciclava|Haloactinospora|Howardella|Microtetraspora|Chainia|Streptoverticillium|Kitasatoa|Marinococcus|Sarcina|Tissierella|Saccharococcus|Roseburia|Spirilliplanes|Actinosynnema|Filifactor|Planobispora|Micropolyspora|Lachnospira|Propioniferax|Oxobacter|Rarobacter|Caseobacter|Acrocarpospora|Kurthia|Acetivibrio|Methanothermus|Mesoplasma|Quinella|Thermomonospora|Pilimelia|Catellatospora|Anaerofilum|Pullulanibacillus|Acetobacterium|Methanothermobacter|Desulfitobacterium|Moraxella|Thermoflavimicrobium|Actinocorallia|Caryophanon|Caloramator|Falcivibrio|Pimelobacter|Hydrogenibacillus|Helcococcus|Frigoribacterium|Methanobacterium|Thermopolyspora|Janibacter|Ammoniphilus|Isobaculum|Rummeliibacillus|Coprobacillus|Thermohalobacter|Tindallia|Microellobosporia|Actinosporangium|Actinopycnidium|Granulicatella|Anaerobacter|Cryptosporangium|Filobacillus|Ornithinimicrobium|Okibacterium|Salana|Subtercola|Oscillospira|Spirillospora|Gallicola|Desulfosporosinus|Thermobacillus|Micropruina|Couchioplanes|Seinonella|Agreia|Dorea|Amphibacillus|Granulicoccus|Millisia|Helcobacillus|Nitrolancetus|Oenococcus|Piscicoccus|Lactovum|Rhodoglobus|Aeribacillus|Parascardovia|Kineosphaera|Austwickia|Atopobium|Butyricicoccus|Shuttleworthia|Timonella|Atopobacter|Brevundimonas|Saccharomonospora|Mobilicoccus|Dielma|Senegalemassilia|Enorma|Brachyspira|Desulfitibacter|Haloglycomyces|Coprothermobacter|Pelotomaculum|Pelagibacter|Thermolithobacter|Thermacetogenium|Tumebacillus|Varibaculum|Tuberibacillus|Desulfurispora|Desulfovirgula|Aestuariimicrobium|Rhizobium|Marinactinospora|Acetitomaculum|Acaricomes|Lactonifactor|Eggerthia|Jonesia|Desmospora|Dermatophilus|Demetria|Gryllotalpicola|Humibacter|Hespellia|Hamadaea|Halalkalibacillus|Glaciibacter|Geosporobacter|Gelria|Garciella|Fusibacter|Terrisporobacter|Bavariicoccus|Fictibacillus|Clostridiisalibacter|Atopostipes|Atopococcus|Asaccharobacter|Erysipelothrix|Catelliglobosispora|Anaerovorax|Akkermansia|Faecalicoccus|Stackebrandtia|Sporotomaculum|Pelosinus|Sporomusa|Sporobacterium|Sporobacter|Sporanaerobacter|Sporacetigenium|Sphingopyxis|Solobacterium|Soehngenia|Smaragdicoccus|Shimazuella|Saccharibacillus|Sciscionella|Nakamurella|Propionicicella|Ruania|Proteocatella|Propionimicrobium|Oxalophagus|Paraoerskovia|Papillibacter|Methermicoccus|Alloscardovia|Eremococcus|Caldicellulosiruptor|Caldanaerobius|Anaerosporobacter|Anaerosphaera|Allofustis|Alkalibacter|Fischerella|cyanobacterium|Coriobacteriaceae|Thermoanaerobacterales|Pseudoxanthomonas|Paracoccus|Dolosigranulum|Alcanivorax|Campylobacter|Barnesiella|Bacteroides|Capnocytophaga|Eikenella|Peptostreptococcaceae|Thermocrispum|Amycolicicoccus|Caldibacillus|Parabacteroides|Prochlorothrix|Thermicanus|Thermobrachium|Actinospica|Turicella|Alloiococcus|Tepidanaerobacter|Nocardioidaceae|Methanosarcina|Fervidicella|Fervidicola|Spiroplasma|Dialister|Acidaminococcus|Turicibacter|Veillonellaceae|Selenomonas|Mobiluncus|Segniliparus|Megasphaera|Methylophilus|Sphaerobacter|Thermincola|Cellulosilyticum|Ralstonia|Lachnospiraceae|Lachnospiraceae|Parvimonas|Erysipelotrichaceae|Thermanaeromonas|Simonsiella|Gordonibacter|Bulleidia|Bacteroidales|Astrosporangium|Pseudoramibacter|Hafnia|Fusobacterium|Rubrobacter|Catonella|Megamonas|Actinobacterium|Abiotrophia/i){
	       	open (GRAM, ">./tmp/$job_id/$job_id.gram");
					close GRAM;
         }

		 	}#end if
	  }#end while
}

sub CopyFile2{
############################################################
#copy the parsed blast result file to 
#the file that is able to be download via http/ftp.
############################################################
my ($myinputfile, $myoutputfile,$myprogram ) = @_;
open(OUTPUT,">".$myoutputfile)   or die "Unable generate output file ".$myoutputfile." \n";
my $title="Query\t"."RDP_ID\t"."E-value\t"."Score\t"."Identity\t";
$title=$title."Description\t";
$title=$title."\n";	
print OUTPUT $title;
open(INPUT,"<".$myinputfile)   or die "Unable open input file ".$myinputfile." \n";
		while ( my $infileline = <INPUT>)           # retrieve file, line by line
			{
			  
			  print OUTPUT $infileline;
			}
close INPUT;
close OUTPUT;
}

sub trimwhitespace($){
########################################################	
# Remove whitespace from the start and end of the string
#########################################################
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}
