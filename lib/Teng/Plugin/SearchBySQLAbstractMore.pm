package Teng::Plugin::SearchBySQLAbstractMore;

use strict;
use warnings;
use utf8;
use Carp ();
use Teng::Iterator;
use Data::Page;
use SQL::Abstract::More;

our @EXPORT = qw/search_by_sql_abstract_more search_by_sql_abstract_more_with_pager install_sql_abstract_more/;

sub search_by_sql_abstract_more {
    my ($self, $table_name, $where, $_opt) = @_;
    my %args;
    use Data::Dumper;
    if (ref $table_name eq 'HASH') {
        my $_opt = $table_name;
        $table_name = ref $_opt->{-from} eq 'ARRAY' ? $_opt->{-from}->[0] eq '-join'
            ? $_opt->{-from}->[1] : $_opt->{-from}->[0]
                : $_opt->{-from};
        $table_name =~s{\|.+$}{};
        %args = %$_opt;
    } else {
        $_opt->{from} ||= ($_opt->{-from} || $table_name);
        foreach my $key (keys %$_opt) {
            my $_k = $key =~m{^\-} ? $key : '-' . $key;
            $args{$_k} ||= $_opt->{$key};
        }
        $args{-where} = $where;
    }
    my $table = $self->schema->get_table($table_name) or Carp::croak("'$table_name' is unknown table");
    my ($sql, @binds) = SQL::Abstract::More->new->select(%args);
    my $sth = $self->dbh->prepare($sql) or Carp::croak $self->dbh->errstr;
    $sth->execute(@binds) or Carp::croak $self->dbh->errstr;
    my $itr = Teng::Iterator->new(
                                  teng             => $self,
                                  sth              => $sth,
                                  sql              => $sql,
                                  row_class        => $self->schema->get_row_class($table_name),
                                  table_name       => $table_name,
                                  suppress_object_creation => $self->suppress_row_objects,
                                 );

    return $itr;
}

sub replace_teng_search {
    undef &Teng::search;
    *Teng::search = \*search_by_sql_abstract_more;
}

sub install_sql_abstract_more {
    my ($self, $pager_plugin) = @_;
    Teng::Plugin::SearchBySQLAbstractMore->replace_teng_search;
    if ($pager_plugin) {
        (ref $self)->load_plugin('SearchBySQLAbstractMore::' . $pager_plugin,
                                 {alias => {search_by_sql_abstract_more_with_pager => 'search_with_pager'}});
    } else {
        (ref $self)->load_plugin('SearchBySQLAbstractMore::Pager::MySQLFoundRows',
                                 {alias => {search_by_sql_abstract_more_with_pager => 'search_with_pager'}});
    }
}

1;

=pod

=head1 NAME

Teng::Plugin::SearchBySQLAbstractMore - use SQL::AbstractMore as Query Builder for Teng

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Create complex SQL using SQL::Abstract::More (compatible usage with Teng's search).

 $teng->search_by_sql_abstract_more(
   'table1',
   { name => { like => '%perl%'},
     -and => [
          {x => 1},
          {y => {-or => [{'>' => 2}, {'<' => 10}]}},
     ],
   },
   {
     from     => ['table1|t1',
                  't1.id=t2.id'
                  'table2|t2',
                  't1.id=t3.table1_id,t2.id=t3.table2_id',
                  'table3|t3',
                 ],
     columns  => ['x', 'y', 'min(age) as min_age', 'max(age) as max_age'],
     group_by => ['x', 'y'],
     having   => ['max_age < 10'],
   },
 );
 # SELECT x, y, min(age) AS min_age, max(age) AS max_age
 # FROM table_name as t1
 # LEFT JOIN table_name2 ON t1.id=t2.table1_id
 # LEFT JOIN table_name3 ON t1.id=t3.table1_id AND t2.id=t3.table2_id
 # WHERE name like '%perl%' AND (x = 1 AND (y > 2 OR y < 10))
 # GROUP BY x, y HAVING max_age < 10
 # LIMIT 10 OFFSET 20;

Create complex SQL using power of SQL::Abstract::More (SQL::Abstract::More original usage).

 $teng->search_by_sql_abstract_more(
   {
     -columns  => ['x', 'y', 'min(age) as min_age', 'max(age) as max_age'],
     -from     => ['table1|t1',
                   't1.id=t2.id'
                   'table2|t2',
                   't1.id=t3.table1_id,t2.id=t3.table2_id',
                   'table3|t3',
                 ],
     -group_by => ['x', 'y'],
     -having   => ['max_age < 10'],
     -where => {
        name => { like => '%perl%'},
        -and => [
            {x => 1},
             {y => {-or => [{'>' => 2}, {'<' => 10}]}},
        ],
      },
   },
 );

Using pager

Compatible usage.

 $teng->search_by_sql_abstract_more(
   'table', {
     name => 1,
     age  => 10,
   },
   {
     -columns  => ['x', 'y'],
     -from     => ['table'],
     -page     => 2,
     -rows     => 20,
   },
 );

Originaly usage.

 $teng->search_by_sql_abstract_more(
   {
     -columns  => ['x', 'y'],
     -from     => ['table'],
     -where    => {
          name => 1,
          age  => 10,
     },
     -page     => 2,
     -rows     => 20,
   },
 );

=head1 METHODS

=head2 search_by_sql_abstract_more

see SYNOPSIS.

=head1 CLASS METHOD

=head2 replace_teng_search

If you want to replace C<search> method of original Teng, call this.

 Teng::Plugin::SearchBySQLAbstractMore->replace_teng_search;

It is useful when you wrap C<search> method in your module and call Teng's C<search> method in it
and you want to use same usage with SQL::Abstract::More.

=head2 install_sql_abstract_more

 $your_class->install_sql_abstract_more;

It call replace_teng_search and loads SearchBySQLAbstractMore::Pager::SQLFoundRows with alias option.
C<search> and C<search_with_pager> are replaced with them.

As first arugument, pager plugin name can be specified.
If you want to use SearchBySQLAbstractMore::Pager instead of SearchBySQLAbstractMore::Pager::SQLFoundRows,
pass 'Pager' as arugment.

 $your_class->install_sql_abstract_more('Pager');
 $your_class->install_sql_abstract_more('Pager::MySQLFoundRows'); # as same as no argument

=head1 AUTHOR

Ktat, C<< <ktat at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-teng-plugin-searchbysqlabstractmore at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Teng-Plugin-SearchBySQLAbstractMore>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Teng::Plugin::SearchBySQLAbstractMore

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Teng-Plugin-SearchBySQLAbstractMore>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Teng-Plugin-SearchBySQLAbstractMore>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Teng-Plugin-SearchBySQLAbstractMore>

=item * Search CPAN

L<http://search.cpan.org/dist/Teng-Plugin-SearchBySQLAbstractMore/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Ktat.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Teng::Plugin::SearchBySQLAbstractMore
