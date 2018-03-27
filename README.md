# Redmine plugin for better cross-projects views

Everything is explained here: http://www.redmine.org/issues/5920

## Screenshot

![redmine_better_crossprojects screenshot](http://jbbarth.com/screenshots/redmine_better_crossprojects.png)

## Installation

Please apply general instructions for plugins [here](http://www.redmine.org/wiki/redmine/Plugins).

Requirements:

    ruby >= 2.1.0
    
Note that this plugin now depends on:
* **redmine_base_select2** which can be found [here](https://github.com/jbbarth/redmine_base_select2)
* **redmine_base_deface** which can be found [here](https://github.com/jbbarth/redmine_base_deface)

First download the source or clone the plugin and put it in the "plugins/" directory of your redmine instance. Note that this is crucial that the directory is named 'redmine_better_crossprojects' !

Then execute:

    $ bundle install
    $ rake redmine:plugins

And finally restart your Redmine instance.

This plugin is fully compatible with Redmine 2.x and 3.x. Please feel free to report any bug you encounter.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
