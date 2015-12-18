package MoreListingFrameworkColumns::Object::Asset;

use strict;
use warnings;

sub list_properties {
    return {
        class => {
            display => 'optional',
            order   => 201,
        },
        description => {
            display => 'optional',
            order   => 300,
        },
        url => {
            label   => 'URL',
            display => 'optional',
            order   => 400,
            auto    => 1,
            html    => sub { MoreListingFrameworkColumns::CMS::url_link(@_) },
        },
        file_path => {
            label   => 'File Path',
            display => 'optional',
            order   => 401,
            auto    => 1,
        },
        file_name => {
            display => 'optional',
            order   => 402,
        },
        file_ext => {
            display => 'optional',
            order   => 403,
        },
        image_width => {
            display => 'optional',
            order   => 501,
        },
        image_height => {
            display => 'optional',
            order   => 502,
        },
        appears_in => {
            label   => 'Appears In...',
            display => 'optional',
            order   => 600,
            html    => sub { appears_in(@_); },
        },
        modified_on => {
            base    => '__virtual.modified_on',
            order   => 700,
            display => 'optional',
            auto    => 1,
        },
        modified_by => {
            base => '__virtual.modified_by',
        },
    };
}

# The "Appears In..." column displays links to the entries and pages that a
# given asset appears in.
sub appears_in {
    my ( $prop, $obj, $app ) = @_;
    my $html = '';

    # Find any asset-entry (or asset-page) associations.
    my @objectassets = $app->model('objectasset')->load({
        asset_id => $obj->id,
    });

    foreach my $objectasset (@objectassets) {
        my $ds = $objectasset->object_ds;
        # Try to load the associated object.
        if ( $app->model( $ds )->exist( $objectasset->object_id ) ) {
            my $assetobject = $app->model( $ds )->load(
                $objectasset->object_id
            );

            # If this is an Entry or Page, build the edit and view links.
            if ( $ds eq 'entry' || $ds eq 'page' ) {
                my $type = $assetobject->class_type;
                my $img = $app->static_path . 'images/nav_icons/color/'
                    . $type . '.gif';
                my $title_html = MT::ListProperty::make_common_label_html(
                    $assetobject, $app, 'title', 'No title'
                );

                my $permalink = $assetobject->permalink;
                my $view_img = $app->static_path
                    . 'images/status_icons/view.gif';
                my $view_link_text = MT->translate(
                    'View [_1]', $assetobject->class_label
                );
                my $view_link = $assetobject->status == MT::Entry::RELEASE()
                    ? qq{
                    <span class="view-link">
                      <a href="$permalink" target="_blank">
                        <img alt="$view_link_text" src="$view_img" />
                      </a>
                    </span>
                }
                    : '';

                $html .= qq{
                    <p>
                        <span class="icon target-type $type">
                          <img src="$img" />
                        </span>&nbsp;$title_html&nbsp;$view_link
                    </p>
                };
            }
            # Not an Entry or Page association.
            else {
                $html .= MT::ListProperty::make_common_label_html(
                    $assetobject, $app, 'label', 'No label'
                );
            }
        }
    }

    return $html;
}

1;

__END__
