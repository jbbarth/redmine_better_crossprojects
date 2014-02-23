# Redmine plugin for better cross-projects views

Everything is explained here: http://www.redmine.org/issues/5920

## Screenshot

![redmine_better_crossprojects screenshot](http://jbbarth.com/screenshots/redmine_better_crossprojects.png)

## Installation

**This plugin is only compatible with Redmine 2.3.x ! See #7 for more informations about 2.4+ incompatibilities.**

Please apply general instructions for plugins [here](http://www.redmine.org/wiki/redmine/Plugins).

First download the source or clone the plugin and put it in the "plugins/" directory of your redmine instance. Note that this is crucial that the directory is named redmine_super_wiki !

Then execute:

    $ bundle install
    $ rake redmine:plugins

And finally restart your Redmine instance.


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
