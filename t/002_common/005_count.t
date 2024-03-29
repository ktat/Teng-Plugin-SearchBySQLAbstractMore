use lib '.';
use strict;
use warnings;
use t::Utils;
use Mock::Basic;
use Test::More;
Mock::Basic->load_plugin('SearchBySQLAbstractMore');
Mock::Basic->install_sql_abstract_more(pager => 'simple');

my $dbh = t::Utils->setup_dbh;
my $db = Mock::Basic->new({dbh => $dbh});
$db->setup_test_db;

subtest 'count' => sub {
    $db->insert('mock_basic',{
        id   => 1,
        name => 'perl',
    });

    is +$db->count('mock_basic' => 'id'), 1;

    $db->insert('mock_basic',{
        id   => 2,
        name => 'ruby',
    });

    is +$db->count('mock_basic' => 'id'), 2;
    is +$db->count('mock_basic' => 'id',{name => 'perl'}), 1;
};

done_testing;
