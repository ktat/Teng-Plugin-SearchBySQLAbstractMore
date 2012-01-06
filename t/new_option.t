use t::Utils;
use Mock::Basic;
use Test::More;
Mock::Basic->load_plugin('SearchBySQLAbstractMore');

Teng::Plugin::SearchBySQLAbstractMore->new_option(sql_dialect => 'OLD_MYSQL');
eval {
    Teng::Plugin::SearchBySQLAbstractMore->_sql_abstract_more;
};
like $@, qr/^no such sql dialect/, 'no such sql dialect';
undef $@;
Teng::Plugin::SearchBySQLAbstractMore->new_option(sql_dialect => 'MySQL_old');
is ref Teng::Plugin::SearchBySQLAbstractMore->_sql_abstract_more, 'SQL::Abstract::More', 'SQL::Abstract::More object';

done_testing;
