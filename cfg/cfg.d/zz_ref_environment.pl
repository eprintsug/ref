#
# EPrints Services - REF4 Add-on
#
# Built on REF v1.3
#


# Bazaar Configuration - should go in zz_ref.pl
$c->{plugins}{"Screen::REF::REF4::Listing"}{params}{disable} = 0;
$c->{plugins}{"Screen::REF::REF4::Edit"}{params}{disable} = 0;
$c->{plugins}{"Screen::REF::Report::REF4"}{params}{disable} = 0;
$c->{plugins}{"Export::REF4_XML"}{params}{disable} = 0;
$c->{plugins}{"Export::REF4_Excel"}{params}{disable} = 0;

# REF 4 Report
$c->{'ref'}->{'reports'} = [] if !defined $c->{'ref'}->{'reports'};
unshift @{$c->{'ref'}->{'reports'}}, ( 'REF4' );

# REF Environment Dataset definition

$c->{datasets}->{ref_environment} = {
	class => "EPrints::DataObj::REFEnvironment",
	sqlname => "ref_environment",
	datestamp => "datestamp",
	name => "ref_environment",
	columns => [qw( ref_environmentid year degrees ref_benchmarkid ref_subject )],
	index => 1,
	import => 1,
	order => 1,
};


# REF Environment Fields definition
$c->{fields}->{ref_environment} = [] if !defined $c->{fields}->{ref_environment};
unshift @{$c->{fields}->{ref_environment}}, (
	{ name => "ref_environmentid", type=>"counter", required=>1, can_clone=>0, sql_counter=>"ref_environmentid" }, 
#	{ name => "year", type=>"set", options=>[qw( 2008 2009 2010 2011 2012 )], input_style => 'small' },
	{ name => "year", type=>"set", options=>[qw( 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 )], input_style => 'small' },
	{ name => "degrees", type => "int", }, 
	{ name => "income",
		type => "compound",
		multiple => 1,
		fields => [
			{ sub_name => "source", 
                          type => "set", 
                          options=>[qw( 01_bis_research 
                                        02_uk_charities_comp 
                                        03_uk_charities_other 
                                        04_uk_gov 
					05_uk_industry 
                                        06_eu_gov 
					07_eu_charities
                                        08_eu_industry 
					09_eu_other 
					10_non_eu_charities 
					11_non_eu_industry 
                                        12_non_eu_other 
					13_other 
					14_nihr 
					14_sg_hscd 
					14_wg_nischr 
					14_ni_hscrd )], }, 
			{ sub_name => "value", type => "int", },
		],
	},
	{ name => "income_in_kind",
		type => "compound",
		multiple => 1,
		fields => [
			{ sub_name => "source", 
			  type => "set", 
			  options=>[qw( 14_nihr 
					14_sg_hscd 
					14_wg_nischr 
					14_ni_hscrd 
					15_bis_research )], }, 
			{ sub_name => "value", type => "int", },
		],
	},

        { name => "datestamp", type=>"timestamp", required=>0, import=>0,
       	        render_res=>"minute", render_style=>"short", can_clone=>0 },
        { name => "lastmod", type=>"timestamp", required=>0, import=>0,
       	        render_res=>"minute", render_style=>"short", can_clone=>0 },
	{
		name => "ref",
		type => "compound",
		multiple => 1,
		fields => [
			{ sub_name => "benchmarkid", type => "itemref", datasetid => "ref_benchmark", },
			{ sub_name => "uoa", type => "subject", top => "ref2014_uoas", },
		],
	},
);

push @{$c->{user_roles}->{admin}}, qw{
	+ref_environment/details
	+ref_environment/edit
	+ref_environment/view
	+ref_environment/destroy
};


# 
# REF 4 Environment data object
#

{
no warnings;

package EPrints::DataObj::REFEnvironment;

@EPrints::DataObj::REFEnvironment::ISA = qw( EPrints::DataObj );

sub get_dataset_id { "ref_environment" }

sub control_url { $_[0]->{session}->config( "userhome" )."?screen=REF::Edit&ref_environmentid=".$_[0]->id }

sub get_defaults
{
	my( $class, $session, $data, $dataset ) = @_;

        if( !defined $data->{ref_environmentid} )
        {
                $data->{ref_environmentid} = $session->get_database->counter_next( "ref_environmentid" );
        }

	$data->{lastmod} = $data->{datestamp} = EPrints::Time::get_iso_timestamp();

	return $data;
}

sub current_uoa
{
        my( $self ) = @_;

        my $bm = EPrints::DataObj::REFBenchmark->default( $self->{session} );

        return undef if !defined $bm;

        return $self->uoa( $bm );
}

sub uoa
{
	my( $self, $benchmark ) = @_;

	foreach my $ref (@{$self->value( "ref" )})
	{
		return $ref->{uoa} if $ref->{benchmarkid} == $benchmark->id;
	}

	return undef; # oops
}

sub commit
{
	my( $self, $force ) = @_;

	unless( $self->is_set( 'datestamp' ) )
	{
		$self->set_value( 'datestamp', EPrints::Time::get_iso_timestamp() );
	}

        if( scalar( keys %{$self->{changed}} ) == 0 )
        {
                # don't do anything if there isn't anything to do
                return( 1 ) unless $force;
        }

	$self->set_value( 'lastmod', EPrints::Time::get_iso_timestamp() );

	return $self->SUPER::commit( $force );
}

# Mappings for Exporters

# Unlike REF1 and REF2, those are hard-coded in the Report and Export plug-ins

} # end of package


#########################################################################
# REF 4 end
#########################################################################


1;

