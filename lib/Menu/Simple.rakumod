use v6.d;

unit module Simple;

class Menu { ... }

class Option {
    has Int $.option-number;
    has Str $.display-string is required;
    has Menu $.submenu is rw;
    has &.action is rw;
}

role Option-group {
    my %counters;
    has %.options;

    method display-group() {
        my $format = self.option-format ~ $.option-separator;
        for self.options.sort>>.kv -> ($k, $v) {
            printf $format, $k, $v.display-string;
        }
    }

    method add-option(Str:D :$display-string, Menu :$submenu, :&action) {
        my $counter = ++%counters{self.menuID};
        self.options{$counter} = Option.new(:&action, :$submenu, :$display-string, option-number => $counter);
        return self;
    }

    method add-options(List:D $options where { $options.all ~~ Str }) {
        for $options.all -> $display-string {
            self.add-option(:$display-string);
        }
        return self;
    }

    method get-option(Str:D $option-number) {
        self.options{$option-number};
    }

    method option-count() {
        return %counters{self.menuID};
    }

    multi method add-submenu(Menu:D $menu) {
        %.options{%counters{self.menID}}.submenu = $menu;
    }

    multi method add-submenu(Menu:D $menu, Int:D $option-number) {
        %.options{$option-number}.submenu  = $menu;
    }

}

class Menu does Option-group is export {
    my $ID = 0;
    has Int $.menuID = ++$ID;
    has Str $.option-format is rw = "%d - %s";
    has Str() $.selection is rw;
    has Str() $.validated-selection is rw = Nil;
    has Str $.option-separator is rw = "\n";
    has Str @.prompt = "\nMake selection: ";
    has Str $.error-msg = "\nSorry, invalid entry. Try again. ";

    method display() {
        self.display-group;
        self.display-prompt;
    }

    method display-prompt() {
        print self.prompt;
    }

    method get-selection() {
        self.selection = getc();
    }

    method validate-selection( --> Bool) {
        self.validated-selection = Nil;
        my $valid = False;
        try { $valid = self.selection > 0 && !(self.selection > self.option-count) };
        return $valid;
    }

    method process-selection() {
        if !self.validate-selection {
            self.error-msg.say;
            self.display-prompt;
        }
        self.validated-selection = self.selection;
        self.selection = Nil;
    }

    multi method menu-execute() {
        self.display;
        self.get-selection if !self.selection;
        self.process-selection;
        my $option = self.get-option(self.validated-selection);
        if $option.action {
            $option.action()();
        }
        return $option.submenu ?? $option.submenu.menu-execute !! $option;
    }
}

