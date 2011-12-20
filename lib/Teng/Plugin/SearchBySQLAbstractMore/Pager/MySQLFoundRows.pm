package Teng::Plugin::SearchBySQLAbstractMore::Pager::MySQLFoundRows;

use strict;
use warnings;
use utf8;
use Carp ();
use Teng::Iterator;
use Data::Page;
use Teng::Plugin::SearchBySQLAbstractMore ();

our @EXPORT = qw/search_by_sql_abstract_more_with_pager/;

sub search_by_sql_abstract_more_with_pager {
    my ($self, $table_name, $where, $_opt) = @_;
    ($table_name, my($args, $rows, $page)) = Teng::Plugin::SearchBySQLAbstractMore::_arrange_args($table_name, $where, $_opt);

    my $table = $self->schema->get_table($table_name) or Carp::croak("No such table $table_name");

    my ($sql, @binds) = SQL::Abstract::More->new->select(%$args);
    $sql =~s{^\s*SELECT }{SELECT SQL_CALC_FOUND_ROWS }i;
    my $sth = $self->dbh->prepare($sql) or Carp::croak $self->dbh->errstr;
    $sth->execute(@binds) or Carp::croak $self->dbh->errstr;
    my $total_entries = $self->dbh->selectrow_array(q{SELECT FOUND_ROWS()});
    my $itr = Teng::Iterator->new(
                                  teng             => $self,
                                  sth              => $sth,
                                  sql              => $sql,
                                  row_class        => $self->schema->get_row_class($table_name),
                                  table_name       => $table_name,
                                  suppress_object_creation => $self->suppress_row_objects,
                                 );

    my $pager = Data::Page->new();
    $pager->entries_per_page($rows);
    $pager->current_page($page);
    $pager->total_entries($total_entries);
    return ([$itr->all], $pager);
}

=pod

=head1 NAME

Teng::Plugin::SearchBySQLAbstractMore::Pager::MySQLFoundRows - use SQL::AbstractMore as Query Builder for Teng

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Create complex SQL using power of SQL::Abstract::More (compatible usage with Teng's search).

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

Originaly usage(-page and -rows options are added).

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

=head2 search_by_sql_abstract_more_with_pager

C<search_by_sql_abstract_more> with paging feature.
additional parameter can be taken, C<page> and C<rows>.

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

1; # End of Teng::Plugin::SearchBySQLAbstractMore::Pager
