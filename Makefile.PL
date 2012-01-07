use inc::Module::Install;

name     'Teng-Plugin-SearchBySQLAbstractMore';
all_from 'lib/Teng/Plugin/SearchBySQLAbstractMore.pm';
author   q{Ktat <ktat@cpan.org>};
license  'perl';

requires
    'Teng'                       => 0,
    'SQL::Abstract::More'        => 0,
    'Data::Page'                 => 0,
    ;

build_requires
    'Test::More' => 0,
    ;

author_tests('xt');
tests 't/*.t t/*/*.t';

resources
  bugtracker => 'https://github.com/ktat/Teng-Plugin-SearchBySQLAbstractMore/issues',
  repository => {
      url  => 'https://github.com/ktat/Teng-Plugin-SearchBySQLAbstractMore.git',
      web  => 'https://github.com/ktat/Teng-Plugin-SearchBySQLAbstractMore',
      type => 'git',
  };

auto_install;

WriteAll;

