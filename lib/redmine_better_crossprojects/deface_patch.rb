# See: https://github.com/railsdog/deface/issues/59


ActionView::Template.class_eval do
  unless instance_methods.include?(:initialize_with_deface_patch)
    def initialize_with_deface_patch(source, identifier, handler, details)
      if handler.class.to_s.demodulize == "ERB"
        initialize_without_deface_patch(source, identifier, handler, details)
      else
        initialize_without_deface(source, identifier, handler, details)
      end
    end
    alias_method_chain :initialize, :deface_patch
  end
end
