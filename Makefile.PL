use inc::Module::Install;

name     'Teng-Plugin-SearchBySQLAbstractMore';
all_from 'lib/Teng/Plugin/SearchBySQLAbstractMore.pm';
author   q{Ktat <ktat@cpan.org>};
license  'perl';

build_requires 'Test::More';

auto_install;

WriteAll;

