use t::Utils;
use Mock::Basic;
use Test::More;
Mock::Basic->load_plugin('SearchBySQLAbstractMore');
Mock::Basic->install_sql_abstract_more(pager => 'Pager');
my $dbh = t::Utils->setup_dbh;
my $db = Mock::Basic->new({dbh => $dbh});
$db->setup_test_db;

$db->insert('mock_basic',{
    id   => 1,
    name => 'perl',
});

subtest 'single' => sub {
    my $row = $db->single('mock_basic',{id => 1});
    isa_ok $row, 'Teng::Row';
    is $row->id, 1;
    is $row->name, 'perl';
};

done_testing;
