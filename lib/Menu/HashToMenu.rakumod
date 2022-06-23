use v6.d;

class HashToMenu is export {
    use Menu::Simple;
    has %.hash;
    has @.menus;
    has $.menu is rw;
    has &.value-action;
    has &.value-processor;  # does arbitrary stuff to hash values

    multi method new(Hash:D $hash, &value-action) {
        self.bless(:$hash, :&value-action);
    }

    multi method new(Hash:D $hash, &value-action, &value-processor) {
        self.bless(:$hash, :&value-action, :&value-processor);
    }

    multi method new(Hash:D $hash, :&value-action, :&value-processor) {
        self.bless(:$hash, :&value-action, :&value-processor);
    }

    method execute() {
        self.menu.execute;
    }

    submethod TWEAK() {
        self.recurse(self.hash);
        return self.menu;
    }

    multi method recurse(Hash:D $hash, $sm?) {
        my $menu = $sm || Menu.new();  # initialize main menu
        push self.menus, $menu;
        for $hash.sort {
            when .value ~~ Hash {
                my $submenu = Menu.new;
                $menu.add-option(.key, :$submenu).add-submenu($submenu);
                self.recurse(.value, $submenu);
            }
            self.recurse(.key, .value, $menu);
        }
        self.menu = $menu;
    }

    multi method recurse($key, $value, $parent-menu) {
        $parent-menu.add-option($key.Str, $value);
        if self.value-action {
            if self.value-processor {
                my $processed-value = self.value-processor()($value);
                my &p = { self.value-action()($processed-value) };
                $parent-menu.add-action(&p);
            } else {
                $parent-menu.add-action(self.value-action);
            }
        }
    }

}

=begin pod

=head1 NAME

Menu::Generate - Generate a Simple::Menu object from a hash data structure

=head1 SYNOPSIS

Simple usage:
=begin code
use Menu::HashToMenu;

my %hash = 'Option A' => 'Value A',
    'Option B' => 'Value B',
    'Option C' =>
        {submenu1 =>
            { subsubmenu => 1},
            submenu2 => 'hello' };

my $menu = HashToMenu.new(%hash);
$menu.execute
=end code

Advanced usage with value actions and value processing:
=begin code
use Menu::HashToMenu;

my %hash =
    'Option A' => 'Value A',
    'Option B' => 'Value B',
    'Option C' =>
        {submenu1 =>
            { subsubmenu => 'hello'},
            'submenu option' => 'hello' };

my &processor = sub ($value_from_hash) { flip $value_from_hash };
my &action = sub ($processed_value) { say $processed_value };

my $menu = HashToMenu.new(%hash, &action, $processor);
$menu.execute
=end code

=head1 DESCRIPTION

The class's constructor accepts a require hash object and two optional arguments for
processing option values associated with an option. The class immediately returns a
L<Menu::Simple> object which can be executed directly.

The class can automatically generate nested submenus and the actions to be performed
when an option is selected.

=head2 METHODS

=head3 multi method new(Hash:D $hash, &value-action)
=head3 multi method new(Hash:D $hash, &value-action, &value-processor)
=head3 method new(Hash:D $hash, :&value-action, :&value-processor)

=head4 %hash

A hash representing the menu. Keys are used as the C<$display-string>
shown on the menu. Submenus are created by assigning a hash to a key.
Hash values that are not a hash are used as the C<$option-value> for
the option.

=head4 &action

This is the callable that will be performed when an option is selected.

=head4 &processor

This is the callable that can be used to process the value associated with a menu
before getting passed to the C<&action> callable. If no C<&processor> is supplied,
the value from the hash is passed directly to the option's C<&action> callable.

