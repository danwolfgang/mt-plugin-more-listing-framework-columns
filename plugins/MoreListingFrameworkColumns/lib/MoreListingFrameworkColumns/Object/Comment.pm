package MoreListingFrameworkColumns::Object::Comment;

use strict;
use warnings;

sub list_properties {
    return {
        id => {
            label   => 'ID',
            display => 'optional',
            order   => 1,
            base    => '__virtual.id',
            auto    => 1,
        },
        # MT has the definition to show the IP address already, but for
        # whatever reason it's only to be displayed if the `ShowIPInformation`
        # config directive is enabled. So, just override that.
        ip => {
            # condition => sub { MT->config->ShowIPInformation },
            condition => 1,
        },
        url => {
            label   => 'Commenter URL',
            order   => 301,
            display => 'optional',
            auto    => 1,
            html    => sub { MoreListingFrameworkColumns::CMS::url_link(@_) },
        },
        email => {
            label   => 'Commenter Email',
            order   => 302,
            display => 'optional',
            auto    => 1,
        },
        entry => {
            bulk_html => sub { entry_link(@_); },
        },
    };
}

# The "Entry/Page" column has been defined already and shows a link to the Edit
# Entry/Edit Page screen for the associated entry/page. We want to add to this,
# to show a published page link, too.
sub entry_link {
    my $prop = shift;
    my ( $objs, $app ) = @_;
    my %entry_ids = map { $_->entry_id => 1 } @$objs;
    my @entries = MT->model('entry')->load(
        { id       => [ keys %entry_ids ], },
        { no_class => 1, }
    );
    my %entries = map { $_->id => $_ } @entries;
    my @result;

    for my $obj (@$objs) {
        my $id    = $obj->entry_id;
        my $entry = $entries{$id};
        if ( !$entry ) {
            push @result, MT->translate('Deleted');
            next;
        }

        my $type = $entry->class_type;
        my $img = MT->static_path . 'images/nav_icons/color/' . $type . '.gif';
        my $title_html = MT::ListProperty::make_common_label_html(
            $entry, $app, 'title', 'No title'
        );

        my $permalink = $entry->permalink;
        my $view_img = MT->static_path . 'images/status_icons/view.gif';
        my $view_link_text = MT->translate( 'View [_1]', $entry->class_label );
        my $view_link = $entry->status == MT::Entry::RELEASE()
            ? qq{
            <span class="view-link">
              <a href="$permalink" target="_blank">
                <img alt="$view_link_text" src="$view_img" />
              </a>
            </span>
        }
            : '';

        push @result, qq{
            <span class="icon target-type $type">
              <img src="$img" />
            </span>
            $title_html
            $view_link
        };
    }
    return @result;
}

1;

__END__
