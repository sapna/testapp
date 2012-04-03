module Paperclip
  module Storage
    module Database

      def self.extended base
        base.instance_eval do
          if @options[:url] == '/system/:attachment/:id/:style/:filename'
            @options[:url]  = "/:class/:id/:attachment?style=:style"
          end
        end
        Paperclip.interpolates(:relative_root) do |attachment, style|
          begin
            if ActionController::AbstractRequest.respond_to?(:relative_url_root)
              relative_url_root = ActionController::AbstractRequest.relative_url_root
            end
          rescue NameError
          end
          if !relative_url_root && ActionController::Base.respond_to?(:relative_url_root)
            relative_url_root = ActionController::Base.relative_url_root
          end
          relative_url_root
        end
      end

      def instance_read_file(style)
        column = column_for_style(style)
        responds = instance.respond_to?(column)
        cached = self.instance_variable_get("@_#{column}")
        return cached if cached
        # The blob attribute will not be present if select_without_file_columns_for was used
        instance.reload :select => column if !instance.attribute_present?(column) && !instance.new_record?
        instance.send(column) if responds
      end

      def instance_write_file(style, value)
        setter = :"#{column_for_style(style)}="
        responds = instance.respond_to?(setter)
        self.instance_variable_set("@_#{setter.to_s.chop}", value)
        instance.send(setter, value) if responds
      end

      def file_contents(style = default_style)
        instance_read_file(style)
      end
      alias_method :data, :file_contents

      def exists?(style = default_style)
        !file_contents(style).nil?
      end

      # Returns representation of the data of the file assigned to the given
      # style, in the format most representative of the current storage.
      def to_file style = default_style

        if @queued_for_write[style]
          @queued_for_write[style]
        elsif exists?(style)
          tempfile = Tempfile.new instance_read(:file_name)
          tempfile.write file_contents(style)
          tempfile
        else
          nil
        end
      end
      alias_method :to_io, :to_file

      def path style = default_style
        nil
      end

      def assign uploaded_file

        # Assign standard metadata attributes and perform post processing as usual
        super

        # Save the file contents for all styles in ActiveRecord immediately (before save)
        @queued_for_write.each do |style, file|
          file.rewind
          instance_write_file(style, file.read)
        end

        # If we are assigning another Paperclip attachment, then fixup the
        # filename and content type; necessary since Tempfile is used in to_file
        if uploaded_file.is_a?(Paperclip::Attachment)
          instance_write(:file_name,       uploaded_file.instance_read(:file_name))
          instance_write(:content_type,    uploaded_file.instance_read(:content_type))
        end
      end

      def queue_existing_for_delete
        [:original, *styles.keys].uniq.each do |style|
          instance_write_file(style, nil)
        end
        instance_write(:file_name, nil)
        instance_write(:content_type, nil)
        instance_write(:file_size, nil)
        instance_write(:updated_at, nil)
      end

      def flush_writes
        after_flush_writes # allows attachment to clean up temp files
        @queued_for_write = {}
      end

      def flush_deletes
        @queued_for_delete = []
      end

      private

      def column_for_style style
        @options[:file_columns][style.to_sym]
      end
    end
  end
end

module Paperclip
  module Storage
    module Database
      module ControllerClassMethods
        def self.included(base)
          base.extend(self)
        end
        def downloads_files_for(model, attachment)
          define_method("#{attachment.to_s.pluralize}") do
            user_id = params[:id]
            user_id ||= params[:user_id]
            model_record = Object.const_get(model.to_s.camelize.to_sym).find(user_id)
            style = params[:style] ? params[:style] : 'original'
            send_data model_record.send(attachment).file_contents(style),
                      :filename => model_record.send("#{attachment}_file_name".to_sym),
                      :type => model_record.send("#{attachment}_content_type".to_sym)
          end
        end
      end
    end
  end
end

