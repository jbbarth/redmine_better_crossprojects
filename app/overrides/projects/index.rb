# encoding: utf-8
Deface::Override.new :virtual_path  => 'projects/index',
                     :name          => 'add-search-form-to-projects-index',
                     :replace  => '#projects_list_and_exports',
                     :partial => "projects/form"
