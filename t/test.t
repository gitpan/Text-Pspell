#!perl -w

use strict;
require Text::Pspell;

my $lastcase = 17;
print "1..$lastcase\n";

######################################################################
# Demonstrate the base class.


{ # Check scoping
        no strict 'vars';
        package Text::Pspell::test;
        @ISA = 'Text::Pspell';
        sub DESTROY { print "ok 1 destroyed by out of scope\n"; Text::Pspell::DESTROY(@_) }
        my $a = Text::Pspell::test->new;
}
print "ok 2\n";

my $speller = Text::Pspell->new;
print defined $speller ? "ok 3\n" : "not ok 3\n";

exit unless $speller;

print $speller->set_option('sug-mode','fast') ? "ok 4\n" : "not ok 4 " . $speller->errstr . "\n";


#print defined $speller->create_manager ? "ok 4\n" : "not ok 4 " . $speller->errstr . "\n";

print defined $speller->print_config ? "ok 5\n" : "not ok 5 " . $speller->errstr . "\n";

my $language = $speller->get_option('language-tag');

print defined $language ? "ok 6\n" : "not ok 6 " . $speller->errstr . "\n";

print defined $language && $language eq 'en' ? "ok 7 $language\n" : "not ok 7\n";

print $speller->check('test') ? "ok 8\n" : "not ok 8\n"; 

print $speller->suggest('testt') ? "ok 9\n" : "not ok 9\n";

my @s_words = $speller->suggest('testt');
print @s_words > 2 ? "ok 10 @s_words\n" : "not ok 10\n";

print defined $speller->print_config ? "ok 11\n" : "not ok 11 " . $speller->errstr . "\n";

print $speller->add_to_session('testt') ? "ok 12\n" : "not ok 12 " . $speller->errstr . "\n";
@s_words = $speller->suggest('testt');

print grep( { $_ eq 'testt' } @s_words ) ? "ok 13 @s_words\n" : "not ok 13\n";

print $speller->store_replacement('foo', 'bar') ? "ok 14\n" : "not ok 14 " . $speller->errstr . "\n";

@s_words = $speller->suggest('foo');
print grep( { $_ eq 'bar' } @s_words ) ? "ok 15 @s_words\n" : "not ok 15\n";

print $speller->clear_session ? "ok 16\n" : "not ok 16 " . $speller->errstr . "\n";
@s_words = $speller->suggest('testt');
print !grep( { $_ eq 'testt' } @s_words ) ? "ok 17 @s_words\n" : "not ok 17 @s_words\n";


