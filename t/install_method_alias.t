use t::Utils;
use Mock::Basic;
use Test::More;
Mock::Basic->load_plugin('SearchBySQLAbstractMore');

my $dbh = t::Utils->setup_dbh;
my $db = Mock::Basic->new({dbh => $dbh});

$db->install_sql_abstract_more(pager => 'Pager', alias => 'search');
ok defined &Mock::Basic::search;

$db->install_sql_abstract_more(pager => 'Pager', alias => 'search_complex');
ok defined &Mock::Basic::search_complex;

done_testing;