# String hound

Given a directory, StringHound recursively searches the directory
heirarchy looking for any hardcoded strings.  When found, it prints them
to standard out in the form:
<filename>: <line>    <string value>

In speak mode, Stringhound will also insert a suggested i18n conversion of
all strings it finds into the file it finds them in, as well as
insert the same key and translation into the default yml file
