package MoreListingFrameworkColumns::Object::Field;

use strict;
use warnings;
use MT::Util qw( encode_html );

sub list_properties {
    return {
        id => {
            label   => 'ID',
            display => 'optional',
            order   => 1,
            base    => '__virtual.id',
            auto    => 1,
        },
        name => {
            sub_fields => [
                # A "Required" icon appears next to the field name. This was
                # set up in the Commercial.pack already, but for some reason is
                # not enabled.
                {
                    class   => 'required',
                    label   => 'Required',
                    display => 'default',
                },
                {
                    # `description` class is already styled so get around it by
                    # using the shorter `desc`.
                    class   => 'desc',
                    label   => 'Description',
                    display => 'optional',
                },
                {
                    class   => 'template_tag',
                    label   => 'Template Tag',
                    display => 'optional',
                },
            ],
            # Overwrite the existing HTML for the field.
            html => sub { cf_name_field(@_); },
        },
        # This is the "System Object" column
        obj_type => {
            display => 'optional',
        },
        basename => {
            display => 'optional',
            order   => 500,
        },
        options => {
            label => 'Field Options',
            col   => 'options',
            auto  => 1,
            order => 600,
        },
        default => {
            label => 'Default Value',
            auto  => 1,
            order => 601,
        }
    };
}

# The Custom Field "Name" field can be used to display lots of pertinent
# information.
sub cf_name_field {
    my ( $prop, $obj, $app ) = @_;
    my $name = MT::Util::encode_html($obj->name);
    my $tag  = MT::Util::encode_html($obj->tag);
    my $current_blog_id = $app->param('blog_id') || 0;
    my $blog_id = $obj->blog_id || 0;
    my $scope_html;

    if ( !$current_blog_id || $blog_id != $current_blog_id ) {
        my $scope = 'System';
        if ( $blog_id > 0 ) {
            my $blog = MT->model('blog')->load($blog_id);
            $scope = $blog->is_blog ? 'Blog' : 'Website';
        }
        my $scope_lc = lc $scope;
        my $scope_label = MT->translate($scope);
        $scope_html = qq{
            <span class="cf-scope $scope_lc sticky-label">$scope_label</span>
        };
    }

    my $required_label = MT->translate("Required");
    my $required = $obj->required
        ? qq{<span class="required sticky-label">$required_label</span>}
        : q{};

    my $desc = $obj->description
        ? '<div class="desc" style="margin-bottom: 5px;">' . $obj->description . '</div>'
        : '';

    my $code = '<div class="template_tag">Template tag: <code class="code">&lt;mt:'
        . $tag . ' /&gt;</code></div>';

    my $user = $app->user;
    if ( $user->is_superuser
         || $user->permissions($obj->blog_id)->can_do('administer_blog') )
    {
        my $edit_link = $app->uri(
            mode => 'view',
            args => {
                _type   => 'field',
                id      => $obj->id,
                blog_id => $obj->blog_id,
            }
        );
        return qq{
            $scope_html <a href="$edit_link">$name</a> $required $desc $code
        };
    } else {
        return "$scope_html $name $required $desc $code";
    }
}

# Add all of the Custom Fields as columns to the listing framework, so that
# objects can be sorted/filtered with CF data, too.
sub add_custom_field_columns {
    my ($menu) = @_;
    my $app    = MT->instance;

    my $iter = MT->model('field')->load_iter(
        undef,
        { sort => 'name', }
    );

    # Add Custom Fields with a high order number, which is an easy way to
    # ensure they're all grouped together.
    my $order = 10000;

    while ( my $field = $iter->() ) {
        # Check that the field is an available custom field type. If not, there
        # is no reason to add the field.
        next if !$app->registry( 'customfield_types', $field->type );

        my $cf_basename = 'field.' . $field->basename;

        $menu->{ $field->obj_type }->{ $field->basename } = {
            label   => $field->name || 'No field name.',
            display => 'optional',
            order   => $order++,
            condition => sub {
                my ($prop) = shift;

                # Show the field at the System Overview
                return 1 if !$app->blog;

                # Show the field if the field is a system-wide field
                return 1 if !$field->blog_id;

                # Show the field at the blog/website level
                return 1 if
                    $app->blog
                    && $app->blog->id eq $field->blog_id;

                # Show the field at the website level if the field is in a
                # child blog.
                my $field_blog = $app->model('blog')->load( $field->blog_id );
                return 1 if
                    $app->blog
                    && $app->blog->class eq 'website'
                    && $field_blog->parent_id eq $app->blog->id;

                return 0;
            },
            html => sub {
                my ( $prop, $obj, $app ) = @_;

                # Load the data and return the field value. If there is no
                # value, just return an empty string -- otherwise, "null" is
                # returned.
                return $obj->$cf_basename
                    || '';
            },
            filter_tmpl => '<mt:var name="filter_form_string">',
            grep => sub {
                my $prop = shift;
                my ( $args, $objs, $opts ) = @_;
                my $option = $args->{option};
                my $query  = $args->{string};

                my @result = grep {
                    filter_custom_field({
                        option => $option,
                        query  => $query,
                        field  => $_->$cf_basename,
                    })
                } @$objs;

                return @result;
            },
            # Make the column sortable
            bulk_sort => sub {
                my $prop = shift;
                my ($objs, $opts) = @_;
                return sort {
                    $a->$cf_basename cmp $b->$cf_basename
                } @$objs;
            },
        };
    }
    
}

# Filter custom fields with the specified text and option. This isn't perfect;
# it's really focused on parsing strings. Other, more complex, types of CF data
# probably can't be well-filtered by this basic capability.
sub filter_custom_field {
    my ($arg_ref) = @_;
    my $option = $arg_ref->{option};
    my $query  = $arg_ref->{query};
    my $field  = $arg_ref->{field};

    if ( 'equal' eq $option ) {
        return $field =~ /^$query$/;
    }
    if ( 'contains' eq $option ) {
        return $field =~ /$query/i;
    }
    elsif ( 'not_contains' eq $option ) {
        return $field !~ /$query/i;
    }
    elsif ( 'beginning' eq $option ) {
        return $field =~ /^$query/i;
    }
    elsif ( 'end' eq $option ) {
        return $field =~ /$query$/i;
    }
}

1;

__END__
