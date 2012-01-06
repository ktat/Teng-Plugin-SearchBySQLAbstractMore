use t::Utils;
use Mock::Basic;
use Test::More;
Mock::Basic->load_plugin('SearchBySQLAbstractMore');

my $dbh = t::Utils->setup_dbh;
my $db = Mock::Basic->new({dbh => $dbh});

$db->install_sql_abstract_more(pager => 'Pager', replace => 0);
ok not defined &Mock::Basic::search;

done_testing;