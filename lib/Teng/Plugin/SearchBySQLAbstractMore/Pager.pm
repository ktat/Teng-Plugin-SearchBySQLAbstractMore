package Teng::Plugin::SearchBySQLAbstractMore::Pager;

use strict;
use warnings;
use utf8;
use Carp ();
use Teng::Iterator;
use Data::Page::NoTotalEntries;
use Teng::Plugin::SearchBySQLAbstractMore ();

our @EXPORT = qw/search_by_sql_abstract_more_with_pager/;

sub init {
    $_[1]->Teng::Plugin::SearchBySQLAbstractMore::_init();
}

# work around
push @EXPORT, qw/sql_abstract_more_instance/;
*sql_abstract_more_instance = \&Teng::Plugin::SearchBySQLAbstractMore::sql_abstract_more_instance;

sub search_by_sql_abstract_more_with_pager {
    my ($self, $table_name, $where, $_opt) = @_;
    ($table_name, my($args, $rows, $page)) = Teng::Plugin::SearchBySQLAbstractMore::_arrange_args($table_name, $where, $_opt);

    my $table = $self->schema->get_table($table_name) or Carp::croak("No such table $table_name");
    $args->{-limit} += 1;
    my ($sql, @binds) = $self->sql_abstract_more_instance->select(%$args);

    my $sth = $self->_execute($sql, \@binds);
    my $ret = [ Teng::Iterator->new(
                                    teng       => $self,
                                    sth        => $sth,
                                    sql        => $sql,
                                    row_class  => $self->schema->get_row_class($table_name),
                                    table_name => $table_name,
                                    suppress_object_creation => $self->suppress_row_objects,
                                   )->all];

    my $has_next = ( $rows + 1 == scalar(@$ret) ) ? 1 : 0;
    if ($has_next) {
        pop @$ret;
    }

    my $pager = Data::Page::NoTotalEntries->new
        (
         entries_per_page     => $rows,
         current_page         => $page,
         has_next             => $has_next,
         entries_on_this_page => scalar(@$ret),
        );
    return ($ret, $pager);
}

=pod

=head1 NAME

Teng::Plugin::SearchBySQLAbstractMore::Pager - pager plugin using SQL::AbstractMore as Query Builder for Teng

=head1 SYNOPSIS

see Teng::Plugin::SearchBySQLAbstractMore

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

Copyright 2012 Ktat.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Teng::Plugin::SearchBySQLAbstractMore::Pager
