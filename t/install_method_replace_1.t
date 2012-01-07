use strict;
use warnings;
use t::Utils;
use Mock::Basic;
use Test::More;
Mock::Basic->load_plugin('SearchBySQLAbstractMore');

my $dbh = t::Utils->setup_dbh;
my $db = Mock::Basic->new({dbh => $dbh});
undef &Teng::search;
ok not defined &Teng::search;
$db->install_sql_abstract_more(pager => 'Pager', replace => 1);
ok defined &Teng::search;

done_testing;