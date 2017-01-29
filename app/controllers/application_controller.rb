class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  protected

  def hours_ago
    @hours_ago ||= params[:hours_ago].to_i if params[:hours_ago].present?
  end

  def source_ids
    @source_ids ||= params[:sources] || []
  end

  def author_ids
    @author_ids ||= params[:authors] || []
  end

  def tag_filters
    author_tags = author_ids.map{ |id| "author_#{id.parameterize}" }
    source_tags = source_ids.map{ |id| "source_#{id.parameterize}" }
    author_tags + source_tags
  end

  def numeric_filters
    hours_ago ? ["created_at>#{Time.now.to_i - hours_ago * 3600}"] : []
  end

  def sort
    @sort ||= begin
      if params[:sort] == 'popular'
        'shares_count + clicks_count desc'
      elsif params[:sort] == 'newest'
        'published_at desc'
      else
        '(shares_count + clicks_count) * 3600.0 / extract (\'epoch\' from (current_timestamp - published_at)) desc'
      end
    end
  end

  def page
    @page ||= params[:page].try(:to_i) || 1
  end
end
