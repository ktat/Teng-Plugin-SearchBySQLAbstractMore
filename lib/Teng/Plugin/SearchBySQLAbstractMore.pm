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
    ($table_name, my $args) = _arrange_args($table_name, $where, $_opt);
    my $table = $self->schema->get_table($table_name) or Carp::croak("No such table $table_name");
    my ($sql, @binds) = SQL::Abstract::More->new->select(%$args);
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

sub _arrange_args {
    my ($table_name, $where, $_opt) = @_;
    my ($page, $rows, %args);
    if (ref $table_name eq 'HASH') {
        my $_opt = $table_name;
        $table_name = ref $_opt->{-from} eq 'ARRAY' ? $_opt->{-from}->[0] eq '-join'
                    ? $_opt->{-from}->[1]           : $_opt->{-from}->[0]
                                                    : $_opt->{-from};
        $table_name =~s{\|.+$}{};
        %args = %$_opt;
        if ($page = delete $args{-page}) {
            $rows = delete $args{-rows};
            $args{-offset} = $rows * ($page - 1);
            $args{-limit}  = $rows;
        }

    } else {
        $_opt->{from} ||= ($_opt->{-from} || $table_name);
        foreach my $key (keys %$_opt) {
            my $_k = $key =~m{^\-} ? $key : '-' . $key;
            $args{$_k} ||= $_opt->{$key};
        }
        $args{-where} = $where || {};

        if ($page = delete $args{page} || delete $args{-page}) {
            $rows = delete $args{rows} || delete $args{-rows};
            $args{-limit}  = $rows;
            $args{-offset} = $rows * ($page - 1);
        }

        _arrange_order_by_and_columns(\%args);
    }
    return($table_name, \%args, $rows, $page);
}

sub _arrange_order_by_and_columns {
    my ($args) = @_;
    if (exists $args->{-order_by}) {
        if (ref $args->{-order_by} eq 'HASH') {
            my ($column, $asc_desc) = each %{$args->{-order_by}};
            $asc_desc = lc $asc_desc;
            if ($asc_desc eq 'asc' or $asc_desc eq 'desc') {
                $args->{-order_by} = {'-' . $asc_desc, $column};
            }
            $args->{-order_by} = [{%{$args->{-order_by}}}];
        } elsif (ref $args->{-order_by} eq 'ARRAY') {
            foreach my $def (@{$args->{-order_by}}) {
                if (ref $def eq 'HASH') {
                    my ($column, $asc_desc) = each %{$def};
                    $asc_desc = lc $asc_desc;
                    if ($asc_desc eq 'asc' or $asc_desc eq 'desc') {
                        $def = {'-' . $asc_desc, $column};
                    }
                }
            }
        }
    }
    if (exists $args->{-columns}) {
        foreach my $col (@{$args->{-columns}}) {
            $col = $$col if ref $col;
        }
    }
}

sub replace_teng_search {
    undef &Teng::search;
    *Teng::search = \*search_by_sql_abstract_more;
}

sub install_sql_abstract_more {
    my ($self, %opt) = @_;
    my $class = ref $self ? ref $self : $self;
    if (not exists $opt{replace} or $opt{replace}) {
        Teng::Plugin::SearchBySQLAbstractMore->replace_teng_search;
    }
    if (my $pager_plugin = $opt{pager}) {
        if ($pager_plugin eq '1') {
            $class->load_plugin('SearchBySQLAbstractMore::Pager',
                                {alias => {search_by_sql_abstract_more_with_pager => 'search_with_pager'}});
        } else {
            if (lc($pager_plugin) eq 'pager') {
                $pager_plugin = 'Pager';
            } elsif (lc($pager_plugin) eq 'mysql_pager') {
                $pager_plugin = 'Pager::MySQLFoundRows';
            }
            $class->load_plugin('SearchBySQLAbstractMore::' . $pager_plugin,
                                {alias => {search_by_sql_abstract_more_with_pager => 'search_with_pager'}});
            #} elsif (ref $self and $self->dbh->{Driver}->{Name} eq 'mysql') {
            #    # object is passed and driver is mysql
            #    $class->load_plugin('SearchBySQLAbstractMore::Pager::MySQLFoundRows',
            #                        {alias => {search_by_sql_abstract_more_with_pager => 'search_with_pager'}});
        }
    }
}

1;

=pod

=head1 NAME

Teng::Plugin::SearchBySQLAbstractMore - use SQL::AbstractMore as Query Builder for Teng

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

  package MyApp::DB;
  use parent qw/Teng/;
  __PACKAGE__->load_plugin('SearchBySQLAbstractMore');

  package main;
  my $db = MyApp::DB->new(dbh => $dbh);
  my $page = $c->req->param('page') || 1;
  my ($rows, $pager) = $db->search_by_sql_abstract_more('user' => {type => 3}, {page => $page, rows => 5});
  
If you want to replace Teng search

  package MyApp::DB;
  use parent qw/Teng/;
  __PACKAGE__->load_plugin('SearchBySQLAbstractMore');
  __PACKAGE__->install_sql_abstract_more;
  # now, search method is replaced by search_by_sql_abstract_more

If you want to load pager at the same time

  # search_with_pager from SearchBySQLAbstractMore::Pager
  __PACKAGE__->install_sql_abstract_more(pager => 'Pager');
  # search_with_pager from SearchBySQLAbstractMore::Pager::MySQLFoundRows
  __PACKAGE__->install_sql_abstract_more(pager => 'Pager::MySQLFoundRows');

Create complex SQL using SQL::Abstract::More.

Compatible usage with Teng's search method.

 $teng->search_by_sql_abstract_more
    ('table1',
     { name => { like => '%perl%'},
       -and => [
                {x => 1},
                {y => [-or => {'>' => 2}, {'<' => 10}]},
               ],
     },
     {
      from     => ['-join',
                   'table1|t1',
                   't1.id=t2.id',
                   'table2|t2',
                   't1.id=t3.table1_id,t2.id=t3.table2_id',
                   'table3|t3',
                  ],
      columns  => ['x', 'y', 'min(age) as min_age', 'max(age) as max_age'],
      group_by => ['x', 'y'],
      having   => {'max_age' => {'<' => 10}},
     },
    );
 # SELECT x, y, min(age) as min_age, max(age) as max_age
 #   FROM table1 AS t1
 #     INNER JOIN table2 AS t2 ON ( t1.id = t2.id )
 #     INNER JOIN table3 AS t3 ON ( ( t1.id = t3.table1_id AND t2.id = t3.table2_id ) )
 #   WHERE ( ( ( x = ? AND ( y > ? OR y < ? ) ) AND name LIKE ? ) )
 #   GROUP BY x, y  HAVING ( max_age < ? );

SQL::Abstract::More original usage(as first argument, use hash ref instead of teble name):

 $teng->search_by_sql_abstract_more(
   {
     -columns  => ['x', 'y', 'min(age) as min_age', 'max(age) as max_age'],
     -from     => [-join,
                   'table1|t1',
                   't1.id=t2.id',
                   'table2|t2',
                   't1.id=t3.table1_id,t2.id=t3.table2_id',
                   'table3|t3',
                 ],
     -group_by => ['x', 'y'],
     -having   => {'max_age' => {'<' => 10'}},
     -where => {
        name => { like => '%perl%'},
        -and => [
            {x => 1},
            {y => [-or => {'>' => 2}, {'<' => 10}]},
        ],
      },
   },
 );
 # SQL is as same as the avobe code.

Using pager.

Compatible usage:

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

Originaly usage:

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
 $your_class->install_sql_abstract_more(replace => 1); # same as the above
 
 # use pager
 $your_class->install_sql_abstract_more(pager => 1);
 $your_class->install_sql_abstract_more(pager => 'mysql_pager');

It call replace_teng_search if replace option is not passed or replace option is true and
loads pager plugin with alias option. C<search> and C<search_with_pager> are installed.

This option can take the following options.

=head3 replace

If you don't want to replace Teng's search method, pass this option with false.

 $your_class->install_sql_abstract_more(replace => 0);

=head3 pager

Pass pager plugin name or 1.

 $your_class->install_sql_abstract_more(pager => 1);       # load SearchBySQLAbstractMore::Pager
 $your_class->install_sql_abstract_more(pager => 'Pager'); # same as the above
 $your_class->install_sql_abstract_more(pager => 'pager'); # same as the above

 $your_class->install_sql_abstract_more(pager => 'Pager::MySQLFoundRows');# load SearchBySQLAbstractMore::Pager::MySQLFoundRows
 $your_class->install_sql_abstract_more(pager => 'mysql_pager');          # same as the above

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

Copyright 2012 Ktat.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Teng::Plugin::SearchBySQLAbstractMore
